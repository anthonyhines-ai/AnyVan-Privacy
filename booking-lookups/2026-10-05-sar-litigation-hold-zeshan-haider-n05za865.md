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

### 4.4 The retention-policy admission — DPO has now reviewed; one factual inconsistency to fix first
**Update, 2026-10-06:** Ant has spoken to the DPO. Agreed line: advise the customer of the date the
policy changed and confirm that **not updating the published privacy policy to reflect the revised
retention period was an oversight by AnyVan.** That's a reasonable, honest position and is reflected
in the draft at §6.

One thing needs fixing before it goes out: **two different start dates for the 3-month policy have
now been given, a year apart.**
- 2026-10-05 (Ant, this thread): "3 months, which we were doing between **April 2024** and May 2026."
- 2026-10-06 (Ant, this thread): "Instruction to delete recordings 3 months and older was first
  given on **4th April 2025**."

This record uses **4 April 2025** below, as the more recent and more specific of the two (a dated
instruction vs. a remembered month/year). But a specific date is exactly the kind of fact that will
be checked against a system record if this reaches court — **confirm which is correct against the
actual instruction/change record before it's put in writing to the customer**, not from memory a
second time.

### 4.5 Preservation-request timing vs. actual purge date — the policy detail now resolves the
### ambiguity, but execution still isn't evidenced
Ant has now clarified the cutover was **not retroactive**: the move back to 12 months applied only
"starting with recordings beginning on the 5th May 2026" — i.e. recordings created *before* that
date (including the 27–28 Feb 2026 calls) stayed on the old 3-month timer rather than being
regranted 12 months. That resolves the ambiguity flagged in the previous version of this section:
on this account, the Feb 2026 recordings were scheduled to purge around **late May 2026**, which is
*before* the customer's first written preservation request (no later than 20 Aug 2026) — so, if
accurate, no spoliation occurred.

What's still missing is **evidence that the purge actually ran on schedule**, as opposed to a
policy that says it should have. Recommend getting the actual job/run log from Engineering/Data
before this is relied on in a court filing — "the policy said it would be deleted" and "it was
deleted, and here's when" are different strengths of evidence, and only the second is unanswerable.

### 4.6 The "two recording systems" explanation — not yet confirmed against the call data
Ant's explanation for the partial delivery: AnyVan runs two recording systems, one for Sales
(12-month retention) and one for the rest of the business (3 months, in the window above); the
"initial call" already sent to the customer is from the Sales system, and once a call is
**transferred**, it moves to the other system — hence the supervisor-transfer continuation and
other calls aren't retained.

This is a plausible technical explanation, but **the data pulled for this record doesn't confirm
it**: all 37 calls found for this customer — from the first contact in June 2025 through to 22 Sept
2026, across five different AnyVan-side numbers (`+442038723050`, `+447700179827`,
`+442038616394`, `+443309127703`, `+442038687594`) — carry the **identical** Twilio `ACCOUNT_ID`
(`ACfe5f...`), and `TRUNK_ID`/`GROUP_ID` are blank throughout. Nothing in this table distinguishes a
"Sales system" call from any other. That doesn't mean the explanation is wrong — the split could
sit at a layer this table doesn't capture (e.g. which recording/storage pipeline a Flex task routes
to, independent of the Twilio account) — but it means **this record can't verify it, and neither
can a WeTransfer link**. Before this explanation goes to the customer (and possibly a court),
**get Telephony/Engineering to confirm, by call SID, which of the 27–28 Feb calls sat on which
system** — ideally naming the specific call(s) already delivered as "the Sales one(s)" so the claim
is checkable, not a general category statement.

### 4.7 Still open, and not addressed by the DPO conversation
Two gaps from the original investigation (§4.1, §4.3) haven't been mentioned as checked:
- **28 Feb calls** — six calls, including two of 19–24 minutes, on the **delivery** date. Nothing
  in the DPO conversation or Ant's note addresses these; "all calls on 27th are not available" was
  never extended to the 28th.
- **The wife's number** — confirmed in Snowflake as `+447423356056` (one digit different from the
  `074233565056` the customer typed): **one call**, 27 Feb 15:48:01–15:49:32 (91 seconds), same
  Twilio account as everything else. This has not been searched or mentioned in any reply sent to
  the customer so far.

**"We can confirm we've provided you with everything we still retain" is only true once these two
are actually checked** (same system/recording-store check as the main set — if they sit in the
"3-month" system they'll likely be gone too, but that still needs confirming rather than assuming,
precisely because of §4.6).

---

## 5. Recommended next steps

**Done:**
1. ~~Get the DPO's response on the retention-policy wording.~~ Done, 2026-10-06 — see §4.4.

**Still open, recommended before the next customer reply:**
2. Confirm which start date is correct for the 3-month instruction — **April 2024** or
   **4 April 2025** (§4.4) — against the actual instruction/change record, not from memory.
3. Get Telephony/Engineering to confirm the "two recording systems" explanation **by call SID**
   (§4.6) — which system the already-delivered call sits on, and that the 27–28 Feb calls not yet
   delivered genuinely sit on the 3-month system.
4. Check recording availability for the **28 Feb calls** and for the call from **`+447423356056`**
   (§4.7) on whichever system(s) they turn out to sit on, before telling the customer "everything
   we still retain" has been provided.
5. Get the actual purge-job log from Engineering/Data confirming the Feb 2026 recordings were
   deleted on schedule (§4.5) — useful corroboration to hold in reserve given the litigation, even
   though it doesn't change what goes to the customer now.

Steps 2–4 are quick checks, not a reason to delay the customer reply indefinitely — the policy
explanation (§6) is ready to send now; it's specifically the closing "we've provided everything"
line that should wait on 3–4.

---

## 6. Draft customer response — **FOR ANT'S REVIEW; the policy paragraph is DPO-approved, the
## completeness paragraph needs §5 steps 3–4 done first (or a conscious decision to send without them)**

**Update, 2026-10-06:** the DPO has agreed the retention-policy explanation below. I've kept the
"two recording systems" wording Ant proposed, but labelled it as an explanation that should be
confirmed by call SID first (§4.6) — it's a specific, checkable technical claim, not a form answer,
and a litigant's solicitor can ask AnyVan to substantiate it. I've held back the "we've provided
everything we still retain" line until the 28 Feb calls and the wife's number are actually checked
(§4.7) — not because I doubt the retention story, but because that specific sentence is a factual
representation in an active claim, and right now it hasn't been tested against two leads this
record found that weren't in any reply sent so far. If Ant wants to send the full version
(including that line) now, that's his call to make knowingly — flagging it is mine.

> Dear Mr Haider,
>
> Thank you for your patience while we looked into this further.
>
> **On the retention period:** our Privacy Policy, last updated 21 September 2023, stated that call
> recordings are retained for 12 months. On 4 April 2025, AnyVan's internal instruction changed this
> to 3 months; this reverted back to 12 months for recordings made on or after 5 May 2026. We should
> have updated our published Privacy Policy to reflect the 3-month period at the time, and did not —
> that was an oversight on our part, and we apologise for it.
>
> **On the recordings themselves:** AnyVan operates two separate call-recording systems — one for
> our Sales team, which retains recordings for 12 months, and one for the rest of the business,
> which was subject to the 3-month period above at the time of your move. The initial call we
> provided to you sits on the Sales system. Once a call is transferred to another part of the
> business — as happened during your move — it is recorded and retained separately, under the
> shorter period that was in force at the time. [We are completing a final check of our systems for
> any further recordings linked to your booking, including calls on 28 February and any from the
> second number you provided, and will confirm the position to you by [date].]
>
> We confirm again that your request to preserve all relevant recordings, call logs, transcripts and
> related notes remains logged and in place.
>
> Kind regards,
> AnyVan Privacy Team

The bracketed sentence is the piece that depends on §5 steps 3–4. If those checks come back clean
(nothing further on the 3-month system, as expected), replace it with a plain "we have provided you
with everything we still retain" — at that point it will actually be true, not just asserted.

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
