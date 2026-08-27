# Customer Communications Mapping — SAR / Portability Handoff

> **Purpose:** Given a customer (or a booking/listing), reconstruct **every outbound communication AnyVan sent them** — email, SMS, WhatsApp, and HubSpot marketing — with **content, timestamps, delivery/preview links, and source of truth**. This is the data backbone for automating **Subject Access Requests (SAR)** and **Data Portability** exports.
>
> **Origin:** Derived from the UK Home Removal *Customer Journey — Communication* audit (July 2026, CEO request). Complements [`SAR-Comms-Lookup-Reference.md`](SAR-Comms-Lookup-Reference.md) (calls / WhatsApp / live-chat lookup incl. call recordings) and [`dsr-intake-form-handoff.md`](dsr-intake-form-handoff.md) (the DSR intake form + JSON payload convention). The automation that consumes this backbone is specified in [`dsr-privacy-request-workflow-design.md`](dsr-privacy-request-workflow-design.md).
>
> **Scope note:** examples below are scoped to UK consumer Home Removal (`en-gb`, non-AVB) but the sources are channel-wide — widen the listing filter for other categories/territories.
>
> **⚠️ Live-verification status:** the schema in this doc was **re-validated against live Snowflake on 2026-08-19** (see the "Verified 2026-08-19" callouts). Several facts in the original 2026-08-13 audit have been corrected — most importantly the email-body coverage (§4.1) and the extra-phones join path (§2). Everything here sits inside `HARMONISED.PRODUCTION` / `CONFORMED.PRODUCTION` (the workflow-system's allowed query scope — no `MART_*` needed).

---

## 1. TL;DR — the one spine + four enrichers

| Layer | Table | Gives you |
|---|---|---|
| **Spine** (all channels) | `HARMONISED.PRODUCTION.LISTING_COMMUNICATION` | Every automated send: channel, template, timestamp, recipient, content tokens, per-message admin preview id |
| Email body | `HARMONISED.PRODUCTION.EVENTS_MESSAGING_MESSAGE` | Rendered subject + body — **all email types, but only from 2026-05-19** (messaging-gateway era) |
| SMS body / WhatsApp body + delivery | `HARMONISED.PRODUCTION.TWILIO_MESSAGE` | Full WhatsApp body + Twilio delivery status; **the only source** for the automated WhatsApp intro / day-of messages. (SMS body is authoritative from the spine `TOKENS`.) |
| 2-way WhatsApp & live chat | `HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE` | Agent/bot conversational threads (see `SAR-Comms-Lookup-Reference.md`) |
| Marketing email | `HARMONISED.PRODUCTION.HUBSPOT_EMAIL_CAMPAIGNS` | Per-recipient HubSpot sends: name, subject, sent/open/delivered dates (**no body**) |

**No Mandrill/Mailchimp table exists** — transactional email is served by the messaging-gateway tables (`EVENTS_MESSAGING_MESSAGE` for the rendered body since 2026-05-19; `LISTING_COMMUNICATION` for the send log), **not Mandrill**. Calls are covered in `SAR-Comms-Lookup-Reference.md`.

---

## 2. Identity resolution (customer → keys)

Start from the booking or the email/phone and resolve the rest.

```sql
-- Listing → customer identity + comms consent
SELECT ml.LISTING_ID, ml.LISTING_USER_ID,
       c.FULL_NAME, c.EMAIL_ADDRESS, c.PRIMARY_PHONE_NUMBER, c.SECONDARY_PHONE_NUMBER,
       c.CONSENT_SMS_TRANSACTIONAL, c.CONSENT_SMS_MARKETING,
       ml.LISTING_CREATED_DATE          -- creation timestamp (TIMESTAMP_TZ)
FROM CONFORMED.PRODUCTION.MASTER_LISTING ml
LEFT JOIN CONFORMED.PRODUCTION.DIM_USER_CUSTOMER c ON c.USER_ID = ml.LISTING_USER_ID
WHERE ml.LISTING_ID = :listing_id;
```

> **✅ Verified 2026-08-19:** `MASTER_LISTING` (`LISTING_ID`, `LISTING_USER_ID`, `LISTING_CREATED_DATE`) and `DIM_USER_CUSTOMER` (`USER_ID`, `FULL_NAME`, `EMAIL_ADDRESS`, `PRIMARY_PHONE_NUMBER`, `SECONDARY_PHONE_NUMBER`, `CONSENT_SMS_MARKETING`, `CONSENT_SMS_TRANSACTIONAL`) all confirmed. `DIM_USER_CUSTOMER` carries **only SMS** consent flags — **email** marketing/transactional consent lives on `EVENTS_MESSAGING_MESSAGE.RESOLVED_USER_CONSENT_MARKETING/_TRANSACTIONAL`.

- **Extra phone numbers (⚠️ corrected path):** `USER_PHONE_NUMBER` does **not** carry the number string. Join through it:
  `HARMONISED.PRODUCTION.USER_PHONE_NUMBER` (`USER_ID`, `PHONE_NUMBER_ID`) → `HARMONISED.PRODUCTION.PHONE_NUMBER` (`PHONE_NUMBER_ID` → `FULL_NUMBER`, intl format **without `+`**, e.g. `447739058471`; also `NATIONAL_NUMBER`). For most SAR needs `DIM_USER_CUSTOMER.PRIMARY_PHONE_NUMBER` is simpler. See `SAR-Comms-Lookup-Reference.md` §3.
- `EMAIL_ADDRESS`, `PRIMARY_PHONE_NUMBER`, `FULL_NAME` are **PII** — SAR output is the subject's own data, but treat per DSR retention rules and mask in any *internal/shared* artefact (last-4 for phones).
- **Resolve ALL of the subject's identifiers** (multiple userIds/emails/phones/listings) before assembling — a SAR keyed to one email/listing can silently miss comms tied to another.
- Booking reference convention (from DSR form): `AV{listing_id}` → e.g. `AV9541974`.

---

## 3. The comms spine — `LISTING_COMMUNICATION`

- **Grain:** one row per message send. PK `LISTING_COMMUNICATION_ID`.
- **Keys:** `LISTING_ID` (booking) · `RECIPIENT_ID` (numeric FK to the user — **not** an email/phone; resolve downstream). *(WhatsApp rows sometimes have empty `RECIPIENT_ID` — join on `LISTING_ID`.)*
- **`TARGET`** ∈ `customer` / `provider` / `address` → **filter `= 'customer'`** for SAR.
- **`CHANNEL`** ∈ `email` / `sms` / `whats-app` / `call`.
- **⚠️ Always filter `DELETED_ROW = FALSE`** (soft-delete column — verified present).
- **`TYPE`** = template key (the "email name"). Common values → friendly labels:

  | `TYPE` | Friendly name |
  |---|---|
  | `booking-confirmation-new-with-validation` | Booking Confirmation |
  | `post-booking-t-minus-7-removals` | T-7 Days to Move |
  | `post-booking-t-minus-3-removals` | T-3 Days to Move |
  | `post-booking-t-minus-1-removals` | T-1 Day to Move |
  | `journey-timeslots` | Timeslots & Driver Tracking |
  | `driver-assigned` | Driver Details / Driver Assigned |
  | `track-driver` | Track Your Driver |
  | `invoice-payment-success` | Invoice Payment (success) |
  | `job-edited-pre-authorisation-new` | Booking Edited (pre-auth) |
  | `job-refunded` / `job-cancelled` | Refund / Cancellation |
  | `feedback-request` | Feedback (SMS + WhatsApp) |

- **`TOKENS`** is stored as **TEXT** → parse with `TRY_PARSE_JSON(TOKENS)`. **SMS body = `TRY_PARSE_JSON(TOKENS):message::string`.** Email tokens hold subject/header vars + CTA links; WhatsApp tokens hold template variables only. `TOKENS` is **not a rendered body** — for the rendered email body use `EVENTS_MESSAGING_MESSAGE` (§4.1).
- **`STATUS`** is **NUMBER** (a status code; `2` = dispatched has been the only value observed). **This is a dispatch flag, not a delivery receipt** — surface it as "dispatched", never "delivered".
- **`CREATED_AT`** send timestamp (`TIMESTAMP_TZ`, UTC). Spine coverage: email/SMS from 2022-01-01; **whats-app from 2025-03-17**.

```sql
SELECT LISTING_COMMUNICATION_ID, CHANNEL, TYPE, CREATED_AT, STATUS,
       TRY_PARSE_JSON(TOKENS):message::string AS sms_body
FROM HARMONISED.PRODUCTION.LISTING_COMMUNICATION
WHERE LISTING_ID = :listing_id AND TARGET = 'customer' AND DELETED_ROW = FALSE
ORDER BY CREATED_AT;
```

> **✅ Verified 2026-08-19:** all ten referenced columns exist (`LISTING_COMMUNICATION_ID`, `LISTING_ID`, `RECIPIENT_ID`, `TARGET`, `CHANNEL`, `TYPE`, `TOKENS`, `STATUS`, `CREATED_AT`, `DELETED_ROW`).

---

## 4. Per-channel content retrieval

### 4.1 Email — ⚠️ materially corrected
- **What/when (all emails):** spine (`CHANNEL='email'`). Template + timestamp for **every** email since 2022.
- **Rendered body + subject:** `HARMONISED.PRODUCTION.EVENTS_MESSAGING_MESSAGE` (`CHANNEL='EMAIL'`).
  - Join on `REQUEST_METADATA_CONTEXT:listingId::string = :listing_id` **or** `RESOLVED_USER_EMAIL = :email` **or** `USER_ID = :user_id`. Columns: `RENDERED_SUBJECT`, `MESSAGE` (rendered body), `TEMPLATE_KEY`, `CHANNEL`, `RESOLVED_USER_PHONE`, `RESOLVED_USER_CONSENT_MARKETING/_TRANSACTIONAL`, `EVENT_TIMESTAMP`.
  - **Coverage (verified 2026-08-19):** of **230,843** email rows, **100% have both `MESSAGE` and `RENDERED_SUBJECT`** — i.e. where an email is in this table, the full rendered content is present, **for all email types** (not just t-7/t-1 as the 2026-08-13 draft stated). **BUT the table only starts 2026-05-19** (messaging-gateway era; rollout ongoing). **Emails sent before 2026-05-19, or via a family not yet on the gateway, have no *extractable* body in the warehouse** — but they are **not invisible**: the spine (`LISTING_COMMUNICATION`, §3) logs **every send back to 2022** (template `TYPE` + timestamp), the **subject/vars are reconstructable from `TOKENS`**, and the **admin `/view` preview (§5) renders the actual message** for all email types (confirm it renders pre-2026-05-19 rows at build). So a SAR can always give the subject a **complete index of every email sent** (name + subject + date), and the officer can view/capture the rendered content via `/view` for older emails — only *bulk programmatic body extraction* is limited to 2026-05-19+. Check per-listing whether a stored body row exists before relying on warehouse text.
  - Strip HTML in-query with nested `REGEXP_REPLACE` (remove `<style>`/`<head>`, strip tags, decode entities) — preserve wording, trim footer boilerplate.
- **CTA/link previews inside the email:** the tokens/body contain `…/eclick/…/edit-instant/{listing_id}` and `/dashboard` links (the customer's booking-management links).

### 4.2 SMS
- **Body:** authoritative from spine `TRY_PARSE_JSON(TOKENS):message` (`CHANNEL='sms'`). **`EVENTS_MESSAGING_MESSAGE` is NOT an SMS source** (verified: only 3 SMS rows ever).
- **⚠ AnyVan removal SMS do NOT route through Twilio** → **no independent delivery receipt**; only the spine dispatch flag. (Only a Storage-team SMS and WhatsApp appear in Twilio.)

### 4.3 WhatsApp — three distinct sources, know which
- **Automated booking notifications with body:** `HARMONISED.PRODUCTION.TWILIO_MESSAGE`
  - `ID` = message SID; **`MM…`** = automated/template one-way sends (booking-intro "Hi, it's David…", day-of "today's the day…", feedback nudge, post-move loyalty offer); **`SM…`** = live CS agent/bot session.
  - Match on customer phone in `"TO"` (**double-quote — reserved word**; `"FROM"` likewise), format `whatsapp:+44…`; LIKE on trailing 9–10 digits. `BODY`, `DIRECTION` (`outbound-api`), `STATUS` (delivered/read), `DATE_SENT` (`TIMESTAMP_TZ`).
  - **Key gap:** the intro / day-of automated WhatsApps are **NOT in `LISTING_COMMUNICATION`** and their **body is NOT in `EVENTS_MESSAGING_MESSAGE`** (verified: 11,489 WhatsApp rows there, 0 with body) — **Twilio is their only body source**, and they have **no admin preview record** (see §5).
- **Templated WhatsApp in the spine:** `LISTING_COMMUNICATION` `CHANNEL='whats-app'` captures only the `feedback-request` template (body not stored — Twilio has it).
- **2-way conversational (CS/Sophie):** `HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE` (`AUTHOR`, `BODY`, `CONVERSATION_ID`, `CREATED_AT`; `AUTHOR` classifies channel — see `SAR-Comms-Lookup-Reference.md` §5). **Source cutover ~2026-05-01** (legacy Fivetran before, Kinesis after).

### 4.4 Calls & Live Chat
Fully documented in **`SAR-Comms-Lookup-Reference.md`** (`AIRCALL_CALL`, `TWILIO_EVENTS`/TaskRouter, `TWILIO_CONVERSATION_MESSAGE`, live chat). **Call-recording reality (verified 2026-08-19):** AnyVan runs **two** phone systems — **Aircall** recordings have a real URL in `AIRCALL_CALL.RECORDING` (servable from Snowflake); **Twilio** has only a Recording SID (`TWILIO_EVENTS.RECORDINGSID`) and needs the **Flex "copy link for download"** step to obtain the audio. A complete SAR must union calls + live chat in.

---

## 5. Admin per-message preview URL (the "inbuilt viewer" pattern)

Every `LISTING_COMMUNICATION` row is viewable in admin at:

```
https://www.anyvan.com/administer/instant-listings/{LISTING_ID}/listing-communications/{LISTING_COMMUNICATION_ID}/view
```

| Message | Has admin preview? |
|---|---|
| Email (all types) | ✅ (SMS/email content renders) |
| SMS (all types) | ✅ |
| WhatsApp `feedback-request` (templated) | ⚠️ record exists but **content view is a dead-end** |
| WhatsApp booking-intro / day-of (Twilio `MM…`) | ❌ no admin record — Twilio only |
| HubSpot marketing email | ❌ no admin record |

**Implication for SAR/portability:** for the ❌ / ⚠️ rows you must supply content another way — embed the body from Twilio, or an in-artefact viewer. (In the audit workbook this was solved with an **in-workbook "Comms Previews" tab** + internal hyperlinks, so previews travel with the file and need no login.)

---

## 6. HubSpot marketing email

The HubSpot MCP only returns **roll-ups** (first/last send/open dates, counts, last-email name). For an **enumerable per-recipient history**, use Snowflake.

**`HARMONISED.PRODUCTION.HUBSPOT_EMAIL_CAMPAIGNS`** — one row per send per contact.
- **Column names (⚠️ corrected — all carry the `HS_EMAIL_EVENT_EMAIL_` prefix; verified 2026-08-19):** `HS_EMAIL_EVENT_EMAIL_RECIPIENT`, `_NAME` (campaign/email name), `_SUBJECT`, `_SENT_DATE`, `_OPEN_DATE`, `_DELIVERED_DATE`, `_CAMPAIGN_ID`, `_CAMPAIGN_GROUP_ID`, `_DURATION`; plus `EVENT_TIMESTAMP`.
- **Identity is by email** (`HS_EMAIL_EVENT_EMAIL_RECIPIENT`) or HubSpot `CONTACT_ID` — **no AnyVan `USER_ID`/`LISTING_ID`** on this table (bridge via the subject's email address).
- **All datetime columns are UTC** (add +1h for BST display).

```sql
SELECT HS_EMAIL_EVENT_EMAIL_NAME, HS_EMAIL_EVENT_EMAIL_SUBJECT,
       HS_EMAIL_EVENT_EMAIL_SENT_DATE,
       IFF(HS_EMAIL_EVENT_EMAIL_OPEN_DATE IS NOT NULL,'opened','') AS opened
FROM HARMONISED.PRODUCTION.HUBSPOT_EMAIL_CAMPAIGNS
WHERE LOWER(HS_EMAIL_EVENT_EMAIL_RECIPIENT) = :email
ORDER BY HS_EMAIL_EVENT_EMAIL_SENT_DATE;
```

- **Journey scoping:** split **pre-booking** vs **as-part-of-this-booking** by comparing `_SENT_DATE` (UTC) to `MASTER_LISTING.LISTING_CREATED_DATE`. (A customer often has an earlier quote/nurture cycle months before — exclude for a booking-scoped view.)
- **⚠ Limitation:** the **rendered HTML/body of marketing emails is not extractable** — `MARKETING_EMAIL` read is permission-locked in HubSpot and no body exists in Snowflake. You get subject + name + open status. To get full rendered emails: unlock `MARKETING_EMAIL` read, or capture the "view in browser" URLs.
- HubSpot holds **no native SMS/WhatsApp** (a Sakari integration writes last-SMS-only contact fields — not a history).

---

## 7. Timezone & format conventions

- Warehouse timestamps are **UTC**; AnyVan operational display is **BST (UTC+1)** for these dates. **Never `DATEDIFF` a `TIMESTAMP_TZ` against a `TIMESTAMP_NTZ`** — cast the TZ side first (BST bug hides in GMT).
- SAR/portability JSON: **ISO-8601** (`+01:00` for BST, or `Z` for UTC), **snake_case** keys, `AV#######` refs. Portability deliverable = **CSV or JSON within one calendar month** (per DSR form).

---

## 8. Coverage matrix (what you can and can't produce today) — verified 2026-08-19

| Channel | Timeline (what/when) | Content/body | Delivery status | Per-message preview link |
|---|---|---|---|---|
| Transactional email | ✅ all (spine, 2022+) | ✅ full extractable **from 2026-05-19** (`EVENTS_MESSAGING_MESSAGE`); pre-2026-05-19 = full send index + subject (`TOKENS`) + admin `/view` renders content (just not extractable text) | dispatch flag (+ gateway status tables) | ✅ admin `/view` |
| SMS | ✅ all | ✅ full (`TOKENS.message`) | ❌ (not in Twilio) | ✅ admin `/view` |
| WhatsApp (automated intro/day-of) | via Twilio (2025+) | ✅ full (Twilio `TWILIO_MESSAGE`) | ✅ Twilio | ❌ none (Twilio only) |
| WhatsApp (feedback template) | ✅ spine (2025-03-17+) | ✅ (Twilio) | ✅ Twilio | ⚠️ admin view dead-end |
| WhatsApp / chat (2-way CS) | ✅ Twilio conv. (cutover 2026-05-01) | ✅ full | ✅ | — |
| HubSpot marketing email | ✅ per-recipient | ⚠️ subject + name only (no body) | delivered/open flags | ❌ (locked) |
| Calls — Aircall | ✅ 2023-05-11+ | ✅ **recording URL** (`AIRCALL_CALL.RECORDING`) | — | Aircall |
| Calls — Twilio | ✅ (SID sparse) | ⚠️ recording via **Flex download** (no warehouse URL) | — | Flex/Console |
| Live chat | see `SAR-Comms-Lookup-Reference.md` | partial (pre-Apr-26 gap) | — | LiveChat platform |

---

## 9. Data-quality layer (matters for SAR accuracy)

The send log records **dispatch events, not deliveries**, and it **over-counts** because some templates re-fire. Audit finding (UK Home Removal, emails since 2026-07-01): **4,986** (booking × email) instances where the same email was sent >1×, across **3,674 bookings (~36%)**, = **9,933 redundant emails**.
- **`post-booking-t-minus-3-removals` is not gated to T-3** — it re-fires on booking edits and payments (**90.3%** of duplicated-T-3 bookings also had an edit/payment; corr ≈ 0.37; avg ~3× when duplicated, up to 13×). The rest of the reminder ladder (t-7, t-1, confirmation, timeslots, track-driver, feedback) is essentially clean.
- `invoice-payment-success` / `job-edited-pre-authorisation-new` repeat heavily (57% / 53%) but **can be legitimate** (multiple payments/edits) — can't fully separate genuine repeats from duplicate-sends without payment/edit IDs.

**For SAR:** de-duplicate on `LISTING_COMMUNICATION_ID`, but preserve every distinct send (the subject received the duplicates). Flag `STATUS` as "dispatched" not "delivered".

---

## 10. SAR / portability assembly blueprint

```
Input: email and/or listing_id (and/or Freshdesk ticket → SAR-Comms-Lookup-Reference §2)
 1. Resolve identity: MASTER_LISTING ⋈ DIM_USER_CUSTOMER (+ USER_PHONE_NUMBER→PHONE_NUMBER for extra phones)
    → resolve ALL userIds/emails/phones/listings for the subject
 2. Spine: LISTING_COMMUNICATION WHERE (LISTING_ID = … OR RECIPIENT_ID = user)
           AND TARGET='customer' AND DELETED_ROW = FALSE
 3. Enrich:
      email     → EVENTS_MESSAGING_MESSAGE (rendered body where present, 2026-05-19+; else TOKENS)
      sms       → TOKENS.message
      whatsapp  → TWILIO_MESSAGE (by phone) + TWILIO_CONVERSATION_MESSAGE (2-way)
      marketing → HUBSPOT_EMAIL_CAMPAIGNS (by email)
      calls     → AIRCALL_CALL (recording URL) + TWILIO_EVENTS/TaskRouter (SID → Flex) — see companion
      livechat  → SAR-Comms-Lookup-Reference
 4. Normalise: one record per message → {channel, type, name, sent_at (ISO), direction,
      content, content_source, delivery_status, preview_url | recording_url | recording_sid, opened}
 5. Emit: JSON (snake_case, ISO-8601) or CSV; group per data_subject; include coverage_caveats[]
```

**Portability JSON shape** (as built in the audit; aligns with the DSR form payload):
```json
{
  "export": { "purpose": "SAR / Data Portability — communications",
              "scope": {}, "sources": {}, "coverage_caveats": [] },
  "data_subjects": [
    { "listing_id": 9541974, "booking_reference": "AV9541974",
      "data_subject": { "full_name": "...", "email": "...", "phone": "..." },
      "communications": [
        { "channel": "sms", "type": "journey-timeslots", "sent_at": "2026-07-29T13:23:00+01:00",
          "content": "...", "content_source": "anyvan_sms_gateway", "delivery_status": "dispatched",
          "preview_url": "https://www.anyvan.com/administer/instant-listings/9541974/listing-communications/39175631/view" }
      ] } ]
}
```

---

## 11. Open items / to unlock for full SAR automation

| Item | Why it matters | Action |
|---|---|---|
| Pre-2026-05-19 email bodies not *extractable* in-warehouse | Older emails have no stored body text | Still list them via the spine (name + subject from `TOKENS` + date) and view/capture content via admin `/view`; only bulk text extraction is limited |
| `MARKETING_EMAIL` read locked (HubSpot) | No rendered marketing-email HTML | Grant read scope, or capture "view in browser" URLs |
| Automated WhatsApp bodies not in-warehouse | Intro/day-of only in Twilio; no admin record | Persist to `LISTING_COMMUNICATION`, or Twilio API pull |
| AnyVan SMS not in Twilio | No independent delivery confirmation | Identify the SMS gateway's delivery log (gateway status tables) |
| Twilio call recordings: no warehouse URL | Only a Recording SID | Flex "copy link for download" (manual, v1); Twilio Recordings API step (later) |
| Pre-Apr-2026 live chat | Bodies not in Snowflake (metadata only) | Pull from LiveChat.com platform (manual) |
| `STATUS` semantics | Dispatch ≠ delivery | Confirm whether a per-channel delivery status exists (gateway status tables) |

---

## 12. Cross-references
- [`SAR-Comms-Lookup-Reference.md`](SAR-Comms-Lookup-Reference.md) — calls (Aircall + Twilio/Flex) / WhatsApp / live-chat lookup; recording access; author classification.
- [`dsr-intake-form-handoff.md`](dsr-intake-form-handoff.md) — DSR intake form, request types, JSON payload convention, Freshdesk custom fields.
- [`dsr-privacy-request-workflow-design.md`](dsr-privacy-request-workflow-design.md) — the end-to-end workflow-system automation that consumes this backbone.

*Compiled 2026-08-13 from the UK Home Removal Customer-Journey communications audit; schema re-verified against live Snowflake 2026-08-19.*
