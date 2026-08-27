# Booking (Listing) → Call & Recording Lookup (Twilio)

A runbook for finding **every voice call associated with an AnyVan booking** and
producing the Twilio links needed to review or share each one. Built for privacy /
DSAR / complaint investigations, where all telephony touchpoints for a customer's
booking have to be found and evidenced.

Input is a listing/booking ID — e.g. from the admin URL
`/administer/instant-listings/{listing_id}/manage`.

Output per call:
- **Twilio Flex Insights** drill-down ("Copy link")
- **Twilio Console** call log (recording playback)
- **Recording download** (S3 presigned link)

> **Privacy:** this document contains no customer data on purpose. When you *run*
> the method, the results are personal data (names, numbers, recordings) — handle
> per AnyVan's data-protection policy and see [PII notes](#pii--privacy-notes).

---

## TL;DR — data flow

```
listing_id
  ├─ HARMONISED.PRODUCTION.LISTING            → USER_ID, PICKUP_ADDRESS, DELIVERY_ADDRESS
  ├─ booking customer number                  → DIM_USER_CUSTOMER
  ├─ collection & delivery contact numbers    → ADDRESS (pickup / delivery)
  ▼
FCT_VOICE_INTERACTIONS  (match on listing_id OR any of the 3 numbers)
  ▼  CONFERENCE_ID
TWILIO_FLEX_INSIGHTS_BI_TWILIO_TELEPHONY      → Flex Insights "Copy link"
  ▼  Conference SID / Call SID
Twilio Recordings API → S3 presigned URL      → recording download
```

Reusable query: [`sql/listing_calls_with_twilio_links.sql`](../sql/listing_calls_with_twilio_links.sql).

---

## Step 1 — Resolve the booking's phone numbers

Three numbers matter, and they are frequently **three different people**.

| Role | Table | Key (from `LISTING`) | Number column(s) |
|---|---|---|---|
| Booking customer | `CONFORMED.PRODUCTION.DIM_USER_CUSTOMER` | `USER_ID` | `PRIMARY_PHONE_NUMBER`, `SECONDARY_PHONE_NUMBER` |
| Collection contact | `HARMONISED.PRODUCTION.ADDRESS` | `PICKUP_ADDRESS` → `ADDRESS_ID` | `PHONE_NUMBER`, `MOBILE_PHONE_NUMBER` |
| Delivery contact | `HARMONISED.PRODUCTION.ADDRESS` | `DELIVERY_ADDRESS` → `ADDRESS_ID` | `PHONE_NUMBER`, `MOBILE_PHONE_NUMBER` |

`LISTING` = `HARMONISED.PRODUCTION.LISTING`; relevant columns `USER_ID`, `PICKUP_ADDRESS`,
`DELIVERY_ADDRESS` (both address columns hold an `ADDRESS_ID`).

> ⚠️ **The caller is often NOT the lead booking customer.** It is regularly the
> collection or delivery contact. Always resolve and search **all three** numbers.
> In the case that seeded this runbook, *every* call came from the collection
> contact's number and the booking customer's own number had **zero** calls.

---

## Step 2 — Find all calls

Table: `CONFORMED.PRODUCTION.FCT_VOICE_INTERACTIONS`
Grain: **one row per call participant (admin leg)** — a transferred call appears as
multiple rows sharing the same `CONFERENCE_ID`.

Match a call to the booking by **either**:
- `TWILIO_LISTING_ID = {listing_id}`, **or**
- `FROM_NUMBER` / `TO_NUMBER` matching any of the three numbers from Step 1.

> ⚠️ **Do not rely on `TWILIO_LISTING_ID` alone.** It is admin-entered / remapped
> during the call and is frequently `NULL` or wrong. The phone-number cross-check is
> what catches untagged calls. Seed case: only **1 of 3** calls carried the listing
> ID; the other two were found *only* via the phone match.

Key columns:

| Column | Use |
|---|---|
| `CALL_DATE_TIME` | Timestamp (**UTC**; UK is +1 in BST) |
| `CALL_DIRECTION` | 14 distinct values — not just inbound/outbound (incl. HubSpot variants) |
| `FROM_NUMBER` / `TO_NUMBER` | Inbound: FROM = customer, TO = AnyVan queue. Outbound: reversed |
| `CALLER_ROLE` | `Customer` / `Admin` / `TP` (NULL if number not recognised) |
| `QUEUE_NAME` | Queue/workflow the call came through |
| `WORKER_FULL_NAME` | Agent who handled the leg |
| `TALK_TIME_SECS` | Talk duration |
| `CONFERENCE_ID` | **Join key to Flex Insights** (Step 3) |
| `CUSTOMER_CALL_ID` / `WORKER_CALL_ID` | CallSids for Console links (only from **Apr 2025** onward) |
| `TWILIO_LISTING_ID` / `TWILIO_PRE_LISTING_ID` | Admin-entered attribution (unreliable) |

---

## Step 3 — Flex Insights "Copy link" (already in the warehouse)

Table: `HARMONISED.PRODUCTION.TWILIO_FLEX_INSIGHTS_BI_TWILIO_TELEPHONY`
(an aggregated export from Flex Insights).

- The **`CONVERSATION` column *is* the ready-made "Copy link"** drill-down URL.
- **Join to a call on `CONVERSATION_ATTRIBUTE_4 = CONFERENCE_ID`.**
- Attribute slots (positions vary by call type; verified for **inbound voice**):

| Attribute | Holds |
|---|---|
| `CONVERSATION_ATTRIBUTE_2` | Call-type label (`inbound`, `AdHoc Outbound Call`, `HubSpot/…`, `Outbound WhatsApp Response`) |
| `CONVERSATION_ATTRIBUTE_4` | **Conference SID** (`CF…`) — or Conversations SID (`CH…`) for WhatsApp/chat |
| `CONVERSATION_ATTRIBUTE_6` | Primary **Call SID** (`CA…`) |
| `CONVERSATION_ATTRIBUTE_7` | **Listing ID** |

- Coverage is a **rolling window** (~7 weeks observed). Check freshness first:
  ```sql
  SELECT MIN(TRY_TO_DATE(DATE,'MM/DD/YYYY')), MAX(TRY_TO_DATE(DATE,'MM/DD/YYYY'))
  FROM HARMONISED.PRODUCTION.TWILIO_FLEX_INSIGHTS_BI_TWILIO_TELEPHONY;
  ```

> ⚠️ **Segment-ID nuance.** A conversation has multiple *segments* (one per
> agent/leg). The Flex **UI** "Copy link" gives the segment you are *viewing*; the
> **warehouse** stores its own canonical segment for the conversation. They usually
> differ — that is expected, both open the same conversation. **Never join on the
> segment UUID; join on Conference SID (or Call SID).**

---

## Step 4 — URL templates & where each part comes from

**Environment constants (AnyVan Twilio — non-secret config):**

| Constant | Value |
|---|---|
| `ACCOUNT_SID` | `AC…` — the AnyVan Twilio account SID; substitute the real value at use time (intentionally not stored here — GitHub secret-scanning flags Twilio Account SIDs) |
| Recordings S3 bucket | `anyvan-twilio-recordings` |
| S3 region | `eu-west-1` |
| Console home region | `us1` |

> The real `ACCOUNT_SID` is the `ACxxxx…` value in the `accounts/…` path segment of
> any Flex Insights link (e.g. the `flex_insights_copy_link` column the query
> returns), or on the Twilio Console home page.

### A. Copy link — Flex Insights drill-down
```
https://services.twilio.com/flex-insights-drilldown/accounts/{ACCOUNT_SID}/segments/{SEGMENT_ID}
```
Source: stored whole in `TWILIO_FLEX_INSIGHTS_BI_TWILIO_TELEPHONY.CONVERSATION`
(join on Conference SID). Nothing to build — read it out.

### B. Copy current position — drill-down + playback offset
```
https://services.twilio.com/flex-insights-drilldown/accounts/{ACCOUNT_SID}/segments/{SEGMENT_ID}?<position_param>=<seconds>
```
Base = the Copy link. The trailing part encodes where the audio scrubber was paused.
That offset is a **runtime UI value** and is **not stored anywhere**.

> 🔧 **TODO — confirm the exact parameter.** Capture one real "Copy current position"
> string from the Flex player, diff it against the Copy link for the same segment,
> and record the exact param here (candidates: `?t=`, `?position=`, `#…`).

### C. Copy download link — S3 presigned recording
```
https://{BUCKET}.s3.{REGION}.amazonaws.com/{ACCOUNT_SID}/{RECORDING_SID}?{SIGV4_PRESIGN}
```
- **Stable object identity** (share-safe *reference*, not a working link):
  `s3://anyvan-twilio-recordings/{ACCOUNT_SID}/{RECORDING_SID}`
- `{RECORDING_SID}` — **not in the warehouse** (`TWILIO_EVENTS.RECORDINGSID` is empty
  for these tasks; no recordings table exists). Fetch it live from Twilio:
  ```
  GET https://api.twilio.com/2010-04-01/Accounts/{ACCOUNT_SID}/Recordings.json?ConferenceSid={CONFERENCE_SID}
  # or ?CallSid={CALL_SID}
  ```
- `{SIGV4_PRESIGN}` — a short-lived AWS SigV4 signature (`X-Amz-Expires=3600` → **1
  hour**), minted on demand from temporary STS credentials. **Cannot be stored or
  reconstructed; regenerate per share. Never commit a live presign.**

### D. Twilio Console call log (recording playback)
```
https://console.twilio.com/us1/monitor/logs/calls/{CALL_SID}
```
Use `CUSTOMER_CALL_ID` (the inbound customer leg). The `us1` segment is the account
home region — swap if the account is regionalised elsewhere. Requires being logged
into the AnyVan Twilio account.

---

## Field source map

| URL part | Static const | Warehouse | Live API | Runtime only |
|---|:--:|:--:|:--:|:--:|
| Account SID / bucket / region | ✅ | | | |
| Full Copy-link URL (segment) | | ✅ `CONVERSATION` | | |
| Conference SID / Call SIDs (join keys) | | ✅ `FCT_VOICE_INTERACTIONS` | | |
| Recording SID | | | ✅ Twilio Recordings API | |
| S3 presign query string | | | | ✅ AWS STS |
| Playback offset ("current position") | | | | ✅ Flex UI |

---

## PII / privacy notes

- Keep this repo **free of customer data**. Do **not** commit real phone numbers,
  names, emails, person-linked SIDs (Conference/Call/Recording/Segment), or a live
  S3 presign.
- Query results are personal data — handle per the data-protection policy.
- For anything shared beyond the immediate investigation, **mask phone numbers to
  the last 4 digits** and **drop agent emails**.
- The Twilio **account SID is deliberately masked** here (GitHub secret-scanning
  blocks it); the bucket and region are non-secret config. The real secrets — the
  Twilio auth token and AWS credentials — are never in this repo.

## Provenance

Derived from an August 2026 investigation of a single listing: distinguishing the
booking customer's number from the collection/delivery contact numbers, and
reverse-engineering the Flex Insights / Console / S3-recording URL structures from
links supplied out of the live Flex player.
