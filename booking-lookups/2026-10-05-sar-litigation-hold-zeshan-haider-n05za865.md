# Subject Access Request & Litigation-Hold — Zeshan Haider · Claim `N05ZA865`

> ⚠️ **CONFIDENTIAL — CONTAINS CUSTOMER PERSONAL DATA (PII).**
> This record contains the customer's name, phone numbers, email address, booking/listing IDs, and
> call metadata (dates, times, durations — no audio or transcripts). Access is restricted to
> authorised AnyVan Privacy / Operations staff and must be handled in line with AnyVan's data
> protection policy and UK GDPR. Do not share outside the business, and do not share this document
> with the customer or in court proceedings without DPO/Legal review. Note that anything committed
> here persists in git history.

| | |
|---|---|
| **Record type** | SAR (UK GDPR Art. 15) + litigation-hold investigation |
| **Date created** | 2026-10-05 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Data source** | Freshdesk correspondence thread · Snowflake `PRODUCTION` (`DIM_USER_CUSTOMER`, `MASTER_LISTING`, `TWILIO_CALL`) — read-only |
| **Subject** | Zeshan Haider · `07867337470` (normalised `7867337470`) · zeshan.haider.mh@gmail.com · County Court Claim No. `N05ZA865` |

---

## 1. Request

Zeshan Haider is a claimant in active County Court proceedings (`N05ZA865`) against AnyVan arising
from a removal on **27 February 2026**. He has made, via the Freshdesk/complaints thread:

1. A **formal SAR** (UK GDPR Art. 15) for all call recordings, call logs, transcripts, and
   customer-service/complaint notes relating to the move and his subsequent complaint, plus any
   calls immediately before/after it.
2. A **formal evidence-preservation request** — asking AnyVan not to delete, overwrite, or destroy
   any relevant recordings, logs, transcripts or notes while the request and court proceedings are
   unresolved. First made no later than **20 Aug 2026** (per the thread) and repeated at least twice
   since.
3. Identity verification, completed **23 Aug 2026**: email `zeshan.haider.mh@gmail.com`, phone
   `07867337470` (corrected same day from an initial typo), and a second number given for his wife,
   written as `074233565056` (12 digits — see §4.3, likely a transposition of a valid 11-digit
   mobile).

AnyVan (Ina Mxutu, Privacy Team) delivered a partial set of recordings via a 3-day WeTransfer link
on **17 Sept 2026**, citing a retention-policy change on **5 May 2026** (3 months → 12 months) as
the reason some material "may no longer be available." The customer disputes **completeness**
(a call cutting off mid-transfer-to-supervisor; a call about having "nowhere to sleep" not
provided at all; his wife's number never checked) and has, separately, asked **four times** for
documentary evidence of when/why the stated 12-month retention period (per AnyVan's privacy policy,
last updated 21 Sept 2023) became a 3-month period in practice, citing UK GDPR Art. 12/13
transparency requirements. As of today this is still open — Ant's internal note of 25 Sept records
"awaiting a response from the DPO" with no reply yet logged.

---

## 2. Identity & booking resolution

| Field | Value |
|---|---|
| Snowflake `USER_ID` | `5867861` |
| Full name | zeshan haider |
| Email (matches) | Zeshan.haider.mh@gmail.com |
| Primary phone (matches, post-correction) | `+447867337470` |
| Secondary phone on file | *(none stored)* |

**Two listings found for this user, not one** — the move spans two calendar dates:

| Listing ID | Category | Status | Pickup date | Delivery date | Created |
|---|---|---|---|---|---|
| `9269436` | Furniture | Completed Paid | 2026-02-27 | 2026-02-27 | 2026-02-08 |
| `9298817` | Furniture | Completed Paid | 2026-02-28 | 2026-02-28 | 2026-02-27 |

**This matters**: the complaint narrative (items "thrown on the road," broken beds, "nowhere to
sleep") reads as an overnight disruption spanning a collection/delivery split across **27→28
February**, not a single day. Inathi's internal note of 11 Sept ("All calls on 27th are not
available — as per CX request") scopes the search to the 27th only. **Calls on the 28th have not
been represented as searched anywhere in the thread** — see §3.

---

## 3. Call metadata located — `HARMONISED.PRODUCTION.TWILIO_CALL`, 27–28 Feb 2026

Metadata only (call log: direction, numbers, start/end time, duration) — **no audio, no
transcript**. This table is a sync of Twilio's call-log API and is a separate system from the
recording store itself (see §4.2); its continued presence does **not** by itself prove the audio
still exists.

| Time (UTC) | Direction | From → To | Duration | Note |
|---|---|---|---|---|
| 27 Feb 09:07:20–09:07:27 | inbound | customer → `...616394` | 7s | |
| 27 Feb 14:28:01–15:23:05 | inbound | customer → `...179827` | **55m 04s** | long call — candidate for disputed content |
| 27 Feb 15:36:04–15:43:39 | inbound | customer → `...179827` | 7m 35s | |
| 27 Feb 15:43:43–15:50:13 | inbound | customer → `...179827` | 6m 30s | |
| 27 Feb 15:48:01–15:49:32 | inbound | **`+447423356056`** → `...616394` | 1m 31s | **wife's number — see §4.3** |
| 27 Feb 15:51:04–15:51:26 | outbound-api | `...723050` → customer | 22s | |
| 27 Feb 15:57:45 | inbound, no-answer | customer → `...723050` | 0s | |
| 27 Feb 15:57:50–16:17:05 | inbound | customer → `...179827` | **19m 15s** | long call — candidate for disputed content |
| 27 Feb 16:36:58–16:37:39 | inbound | customer → `...179827` | 41s | |
| 27 Feb 16:37:53–16:38:09 | inbound | customer → `...179827` | 16s | |
| 27 Feb 16:38:27–16:39:49 | inbound | customer → `...179827` | 1m 22s | |
| 27 Feb 17:38:03–17:38:09 | inbound | customer → `...179827` | 6s | |
| 27 Feb 17:38:14–17:38:51 | inbound | customer → `...179827` | 37s | |
| 27 Feb 17:43:22–18:47:08 | inbound | customer → `...179827` | **1h 03m 46s** | **longest call — prime candidate for the disputed supervisor-transfer / accommodation conversation** |
| 28 Feb 07:43:10–07:43:45 | inbound | customer → `...179827` | 35s | not previously flagged as searched |
| 28 Feb 08:00:59–08:25:02 | inbound | customer → `...179827` | **24m 03s** | not previously flagged as searched |
| 28 Feb 09:22:53–09:26:03 | inbound | customer → `...179827` | 3m 10s | |
| 28 Feb 09:42:17–09:46:28 | outbound-api | `...723050` → customer | 4m 11s | |
| 28 Feb 11:44:06–12:03:41 | inbound | customer → `...179827` | **19m 35s** | not previously flagged as searched |
| 28 Feb 12:11:14–12:13:51 | outbound-api | `...723050` → customer | 2m 37s | |
| 28 Feb 13:21:46–13:23:31 | inbound | customer → `...616394` | 1m 45s | |
| 28 Feb 15:16:55–15:17:12 | inbound | customer → `...723050` | 17s | |
| 28 Feb 15:17:36–15:18:47 | inbound | customer → `...616394` | 1m 11s | |
| 28 Feb 18:27:15–18:27:18 | inbound | customer → `...723050` | 3s | |

Earlier, unrelated contact (booking-enquiry period) also exists: three short calls between
2025-06-18 and 2026-02-09, outside the scope of this complaint. One further short inbound call from
the customer's number appears on **2026-09-22** (11s) — post-dates the complaint; not investigated
here.

---

## 4. Discrepancies and open questions — **read before responding to the customer**

### 4.1 Search scope has been "27th only" — the 28th has not been checked
Inathi's note says calls on "the 27th" are unavailable. The booking data shows the job split across
two listings, 27th (pickup) and 28th (delivery), and the call log shows **six calls on the 28th**,
including two 19–24 minute calls. Nothing in the thread indicates these were pulled, checked for
recording availability, or considered in what was sent to the customer.

### 4.2 Metadata surviving ≠ the audio surviving — this needs a direct check, not an inference
`TWILIO_CALL` is Twilio's **call-log** sync (`HARMONISED.PRODUCTION.TWILIO_CALL`); it has no
recording ID or URL column, and it still holds these records today — over 7 months after the call
date, well past the "3 months" quoted to the customer. That's expected: call-log retention and
**recording** retention are different systems with different purge schedules per CLAUDE.md's own
metadata-vs-content rule. **The presence of this log entry says nothing about whether the audio
file still exists in Twilio Flex.** Before telling the customer (or a court) that "no further
recordings are available," someone needs to check the **Twilio Flex recording store directly** for
each call SID above — particularly the three long calls — rather than relying on the retention
narrative alone. This record does not establish that check has been done.

### 4.3 The wife's call exists and has not been searched
The customer gave `074233565056` on 23 Aug (12 digits — not a valid UK mobile as written). The call
log shows an inbound call from **`+447423356056`** at 15:48 on 27 Feb — an 11-digit number one digit
off from what he typed (`074233565056` vs `07423356056`), consistent with a transcription slip
rather than a wrong number. **This number has not been searched in any reply sent so far** — every
response in the thread addresses only the primary number. It should be searched (and the recording,
if it exists, checked) before any "we've provided everything" statement goes back to the customer.

### 4.4 The retention-policy admission needs DPO/Legal sign-off before it's put in writing
AnyVan's public privacy policy (last updated 21 Sept 2023, still showing 12 months on the live
anyvan.ie page per the customer's own screenshot) states a 12-month retention for call recordings.
Ant's internal account is that the **actual** retention in force between **April 2024 and 5 May
2026** was 3 months, i.e. the published policy was wrong for that window. Two things follow:
- Putting "our published policy was inaccurate for ~2 years" in writing to a litigant, in an active
  court claim, where the customer has already raised UK GDPR Art. 12/13 transparency obligations
  four times, is a materially different kind of statement than routine SAR correspondence — it's an
  admission that could be used in the proceedings. **This should go to the DPO/Legal before being
  sent**, not be sent on operational sign-off alone (Ant's own 25 Sept note already flags "awaiting
  DPO" — that hasn't been resolved, it should be, before the next customer reply).
- The exact *change* document/evidence the customer is asking for (four times now) — i.e. what
  internal policy or system record shows the 3-month period and its effective date — has not been
  produced in the thread. If it doesn't exist as a discrete document, that itself is an answer worth
  giving the customer and the DPO, rather than continuing to not engage with the question.

### 4.5 Preservation-request timing vs. actual purge date is still unverified
The 3-month retention window (Apr 2024–5 May 2026) would put the natural purge of 27–28 Feb 2026
recordings at roughly **late May 2026** — which is *before* the customer's first written
preservation request (no later than 20 Aug 2026). On the facts as currently understood, that would
mean no spoliation occurred: the material was gone before the hold was asked for. But that depends
entirely on (a) the 5 May 2026 policy change not having been applied retroactively to recordings
already in the purge queue, and (b) the purge actually having run on schedule in May. **Neither has
been confirmed against an actual system/job log** — the record so far is a verbal account, and this
is exactly the kind of fact a court would expect to be evidenced, not asserted. Recommend getting
this confirmed in writing from Engineering/Data before it's relied on in any response.

---

## 5. Recommended next steps (not yet actioned)

1. Search `TWILIO_CALL` (and the Flex recording store directly) for `+447423356056` across the full
   history, not just 27–28 Feb — confirm with the customer whether this is in fact his wife's
   number.
2. Check Twilio Flex directly for recording availability against the 24 call SIDs on 27–28 Feb
   above (not inferred from this metadata) — especially the three calls over 15 minutes.
3. Get the DPO's actual response (requested by Ant on 25 Sept, still outstanding) before sending
   anything that states or implies the published privacy policy was inaccurate.
4. Ask Engineering/Data for the actual retention-job record for this listing's recordings (not a
   verbal recollection) — does it show a purge date, and was the 5 May 2026 policy change applied
   retroactively to recordings already past 3 months at that point?
5. Only once 1–4 are done, send a substantive reply — see the draft in §6, which is deliberately
   **not** a final "we've given you everything" statement, because on the facts above that isn't
   yet established.

---

## 6. Draft customer response — **FOR ANT'S REVIEW ONLY; DO NOT SEND without DPO/Legal sign-off**

This draft intentionally does **not** adopt the "nothing more exists" framing from the internal
note, for the reasons in §4. It commits to concrete follow-up instead of closing the question.

> Dear Mr Haider,
>
> Thank you for your patience, and for the further detail in your recent emails.
>
> We want to address two separate points you've raised, clearly and in writing.
>
> **On the completeness of the recordings already sent:** we are re-checking our systems against
> the specific calls you've described — including the call that was transferred to a supervisor,
> the call concerning accommodation arrangements, and any calls associated with the second number
> you provided for your wife. We are not yet in a position to confirm this is complete, and we would
> rather tell you that honestly than close this down prematurely. We will come back to you with a
> substantive answer by [date — recommend no more than 5–7 working days].
>
> **On the retention-period question:** we understand you've asked several times for documentary
> evidence of when and why our stated retention period changed, and we recognise this hasn't been
> answered yet. We are treating this properly rather than giving you a partial answer, and our Data
> Protection Officer is reviewing it. We will respond to this specific point directly, in writing,
> separately from the recordings question above.
>
> We confirm again that we have logged your request to preserve all recordings, call logs,
> transcripts and related notes while your claim is ongoing, and that request remains in place.
>
> Kind regards,
> AnyVan Privacy Team

---

## 7. Methodology / sources

- Identity: `CONFORMED.PRODUCTION.DIM_USER_CUSTOMER` matched on email and normalised phone
  (`RIGHT(REGEXP_REPLACE(...),10)`).
- Bookings: `CONFORMED.PRODUCTION.MASTER_LISTING` filtered on `LISTING_USER_ID`.
- Calls: `HARMONISED.PRODUCTION.TWILIO_CALL`, matched on normalised `"FROM"`/`"TO"` for the primary
  number and both plausible readings of the wife's number (`4233565056` literal, `7423356056`
  transposed) — only the transposed reading returned a match.
- No `RECORDING_ID`/`RECORDING_URL` column exists on `TWILIO_CALL` (confirmed via
  `INFORMATION_SCHEMA.COLUMNS`) and `TWILIO_CALL_TO_LISTING_MAPPING` holds no rows for these call
  SIDs — recording existence must be checked directly in Twilio Flex, not inferred from this table.
- Correspondence summary is drawn from the Freshdesk/complaints thread supplied for this
  investigation; full verbatim correspondence is **not** reproduced here per the PII-minimisation
  rule — refer to the live Freshdesk ticket for the complete exchange.

---

## 8. Governance notes

- Queries were **read-only** against Snowflake `PRODUCTION`.
- This document contains PII and references to live litigation. Do not share outside authorised
  Privacy/Operations/Legal staff. Retain only as long as the SAR and court proceedings require it,
  then redact/dispose per policy.
- **This record does not constitute Legal or DPO advice** and the draft in §6 is not an approved
  customer communication — both require sign-off before any reply is sent, given the active court
  claim.
