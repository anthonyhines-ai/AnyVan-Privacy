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

### 4.4b Wrong domain was being used, and the correct one gives better, sourced evidence
**Update, 2026-10-06:** the customer's own evidence (his screenshot, "Last updated: 21st September,
2023", quoting a 12-month figure) is from **anyvan.ie** — AnyVan's **Ireland** site. His booking is
a UK booking (territory `en-gb` in Snowflake, §2). The policy that actually applies to his booking
is published at **anyvan.com**, and the earlier draft's "last updated 21 September 2023" line was
carried over from the wrong document — it should never have gone in the letter.

Checked properly, via Wayback Machine snapshots (Ant's research, archived at
[this artifact](https://claude.ai/artifact/PYrEs1sZDA9w9fnjP4xZF4?sk=410ImVAa8syVpZ1h6siTYA)) and
independently re-confirmed live today:

| Date checked | Source | Finding |
|---|---|---|
| 2026-02-07 15:31 UTC | Wayback snapshot, anyvan.com/privacy-policy | "Call recordings will be securely stored for 12 months after the call was made..." |
| 2026-02-17 06:20 UTC | Wayback snapshot, anyvan.com/privacy-policy | Same wording, unchanged |
| 2026-05-04 19:01 UTC | Wayback snapshot, anyvan.com/privacy-policy | Same wording, unchanged (identical to a 13 May CMS backup) |
| 2026-05-15 09:54 UTC onward | Wayback snapshot → still live today | Page rewritten, "Last updated: 15th May 2026" — **same 12-month sentence retained**, word for word |
| 2026-10-06 (today) | Live fetch, anyvan.com/privacy-policy | Confirms "Last updated: 15th May 2026" and the same 12-month sentence are still live now |

**This is good news for AnyVan's position, stated accurately:** the public notice that actually
applies to this booking has said 12 months for call recordings, unchanged, through every captured
version from 7 Feb 2026 to today, including across the 5/8 May 2026 internal reversion date — it
was never edited to say 3 months, and wasn't edited at all on 5 May 2026 specifically (nearest
edits 17 Feb before, 15 May after, neither of which touched this figure). The oversight is
unchanged in substance: AnyVan's **internal** retention instruction diverged from this unchanged
**public** figure for the period in §4.4, and nobody updated the public notice to flag that
divergence. But the letter should no longer cite anyvan.ie or a 2023 "last updated" date — it
should point the customer to the correct site and rest on the unchanged-figure finding above, which
is now independently sourced and verifiable rather than copied from his own (wrong-domain)
screenshot.

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

### 4.6a **STOP — do not send the planned reply. Jiminny holds un-reviewed recordings that match the
### missing content, still within its 12-month retention.**
**Update, 2026-10-06, following Ant's clarification that the delivered call was from Jiminny
(12-month retention) and Twilio-only calls were 3-month:** that distinction was checked directly
against Jiminny. Searching Jiminny for this contact across 27–28 Feb 2026 returns **18 calls**, not
1. Ten of them fall on 27–28 Feb itself. They are logged oddly — routed through the Sales team's
HubSpot Dialer (hosts shown as "Sales Rep", tagged to unrelated "Pinlocal Lead" / "Removals –
25718241 Prospecting" lead records rather than this customer's actual booking) — which is almost
certainly why nobody thought to look for them there. But their content is unambiguous:

| Time (UTC) | Host | Duration | AI summary |
|---|---|---|---|
| 27 Feb 15:23:24 | Mo Isaacs | 1m 09s | Customer reports transport team refused items (van "full", false mold claim), fridge removed incorrectly, wrong sofa size taken. Escalated. |
| 27 Feb 15:43:41 | Polly R | 14s | No AI summary (too short to transcribe) |
| 27 Feb 15:50:38 | Joash Brown | 57s | Customer reports transport refused half the items, rude staff, items broken, substitute items taken without consent, team hadn't arrived after 14 min wait, needs to hand over keys next day. Escalated. |
| 27 Feb 16:37:48 | Leo M | 6s | No AI summary (too short) |
| 27 Feb 16:40:13 | Tashwille Hawkins | 29s | No AI summary (too short) |
| 27 Feb 16:17:12 | Curtis | 1m 04s | Customer reports a subcontractor being rude, **throwing items on the floor**, refusing to complete the job, claiming to be a third party. **"The call was escalated to a supervisor for further assistance."** |
| 27 Feb 18:47:19 | Brent C | 12s | No AI summary (too short) |
| 28 Feb 08:25:11 | Liam Jooste | 11s | No AI summary (too short) |
| 28 Feb 09:26:36 | Kevin M | 48s | No AI summary (too short to transcribe — worth listening to directly) |
| 28 Feb 12:03:52 | Amy Loubscher | 49s | Customer reports the team left items unassembled and **broke multiple beds**; needs a bed disassembled/reassembled urgently **"as they have nowhere to sleep"**; already filed a complaint about the broken items. |

**This is, in substance, the content the customer has been asking for since 17 September**:
Curtis's call is the escalation-to-a-supervisor moment; Amy Loubscher's call is, almost word for
word, the "nowhere to sleep" / broken-beds call he says was never provided. Both currently sit in
Jiminny, inside its 12-month retention, today.

**Update, 2026-10-06 (later): Ant has confirmed these Jiminny calls have already been provided to
the customer** — so the completeness gap this section raised is closed, not open. Leaving the
table above in place as the record of what was found and why (it's still the explanation for *why*
the already-delivered material exists on the 12-month Jiminny system rather than the 3-month Twilio
one — see §6), but the "do not send" instruction below no longer applies to §6, which has been
restored and finalised.

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
2. ~~Confirm the 3-month instruction date.~~ Confirmed 4 April 2025 — see §4.4.

3. ~~Review/disclose the Jiminny calls in §4.6a.~~ Confirmed 2026-10-06 — already provided to the
   customer; CRM re-linking (tagged to unrelated lead records) is tidy-up, not a blocker.
4. ~~Confirm the policy-reversion date.~~ Confirmed 8 May 2026, 2026-10-07 — see §6.

**Still open, lower priority — doesn't block §6:**
5. Check recording availability for the **28 Feb Twilio-only calls** (§4.1) and the call from
   **`+447423356056`** (§4.7), on the Twilio system specifically — the Jiminny side is resolved,
   but these were raised separately and haven't been confirmed either way.
6. Get the actual purge-job log from Engineering/Data confirming the pre-reversion Twilio
   recordings were deleted on schedule (§4.5) — the letter now states this as fact (§6), so this
   corroboration matters more than before, even though it's not needed to send.
7. Get Telephony/Engineering to confirm, by call SID, which system each call sits on (§4.6) — useful
   if the customer or his solicitor pushes back on the explanation, not needed to send §6.

---

## 6. Draft customer response — **restored 2026-10-07, for Ant's review and sending**

Ant has confirmed the §4.6a material has already reached the customer, so this draft now just needs
to answer the two things he's still asking for in writing: the retention-period discrepancy, and
why some calls survived and (on AnyVan's account) others didn't. Wording below reflects the
DPO-approved oversight admission and the confirmed Twilio-vs-Jiminny explanation.

**Update, 2026-10-07:** Ant asked for the specific dates to go back in, to make explicit that the
missing recordings were not deleted in response to the customer's request, or at any point after
it, but automatically, under a standing instruction that predates his first contact by well over a
year. That is a reasonable, and stronger, point to make, and the draft below now makes it directly
rather than leaving the reader to infer it.

**8 May 2026 confirmed by Ant, 2026-10-07.** The letter below uses that date throughout.

**One evidential gap this still rests on (§4.5):** the claim "this happened automatically, before
your request" is a policy-based inference, not yet a confirmed fact. The actual purge-job log for
these recordings hasn't been pulled. It's a reasonable claim to make on what's known today, but if
it's challenged, "the policy said it would happen" is weaker than "and here is the log showing it
did." Worth getting that log in hand in parallel, even if it isn't needed to send this letter.

**Domain correction, 2026-10-06 (§4.4b):** the earlier draft repeated the customer's own
"last updated 21 September 2023" claim, which is from anyvan.ie, AnyVan's Ireland site, not the
policy that applies to his UK booking. Rewritten below to point to the correct document
(anyvan.com) and rest on the unchanged-12-months finding, which is independently sourced
(§4.4b) rather than copied from his screenshot.

> Dear Mr Haider,
>
> Thank you for your patience, and please accept our apologies for the delay in responding to the
> points you raised. We have been investigating this matter internally with our engineering team
> and were waiting on their response before we could give you a complete and accurate answer.
>
> On the retention period you've asked about, we note that the privacy policy you referred to is
> published on anyvan.ie, which is AnyVan's Ireland site. As your booking was made in the United
> Kingdom, the privacy policy that applies to it is the one published at anyvan.com. That policy has
> stated, without change, that call recordings are retained for 12 months, including throughout the
> period of your move and up to today.
>
> Separately, on 4 April 2025, AnyVan set the retention period for one of our call recording systems
> to 3 months. This was a standing instruction, in place well over a year before your move and
> before you first contacted us. On 8 May 2026, this was reverted to 12 months for recordings made
> from that date onwards; it did not apply retroactively to recordings already subject to the
> 3 month period. The calls from your move on 27 and 28 February 2026 fell within that 3 month
> period, and would have reached the end of it by around the end of May 2026, before you first asked
> us, no later than 20 August 2026, to preserve all relevant recordings. We want to be clear that
> nothing was deleted in response to your request, or after it. Any deletion of these particular
> recordings happened automatically, under a standing instruction, before your request was made.
>
> We should have reflected the 3 month period in our published privacy policy while it was in
> force, and did not. That was an oversight on AnyVan's part, and we apologise for it. There is no
> separate customer facing notice of that internal instruction; it was recorded only internally.
>
> On why some recordings were available and others were not, AnyVan uses two separate call
> recording systems. Calls recorded through Jiminny are retained for 12 months. Calls recorded
> through Twilio were subject to the 3 month period described above at the time of your move. The
> recordings we have been able to provide to you came from the Jiminny system. Any corresponding
> Twilio only recordings from the 3 month period would, on this basis, no longer be available.
>
> We confirm again that your request to preserve all relevant recordings, call logs, transcripts and
> related notes remains logged and in place.
>
> Kind regards,
> AnyVan Privacy Team

This answers the four points in the customer's 2 October email in order: the policy in force at the
time (12 months, on the correct document for a UK booking, anyvan.com, not the Ireland site he
quoted), the evidence of the change (an internal instruction dated 4 April 2025, not a published
document, stated plainly rather than implied), where customers were told about the 3 month period
(nowhere, that's the admitted oversight), and whether the reversion was retrospective (no). It also
now makes, directly rather than by implication, the point Ant asked for: the recordings were not
deleted because of the request or after it, but automatically, under a standing instruction in
place well over a year before the customer first made contact. The opening apology gives a reason
for the delay since 17 September without going into the internal detail of what engineering was
asked and why. 8 May 2026 is confirmed (§6). Recommend Legal/DPO still give this specific wording a
final read given the active claim, particularly the non-retroactivity point and the timing
argument, which would be stronger with the purge-job log in §4.5/§5 step 6 in hand.

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
- Jiminny: `search_calls` (customer email/phone, date range 2026-02-01 to 2026-03-05,
  `with_crm_records: true`) plus `get_call` on each result for AI summaries (§4.6a).
- Privacy policy history (§4.4b): Wayback Machine snapshots of `anyvan.com/privacy-policy` (Ant's
  research, archived at
  https://claude.ai/artifact/PYrEs1sZDA9w9fnjP4xZF4?sk=410ImVAa8syVpZ1h6siTYA), cross-checked
  2026-10-06 against the live page at the same URL.

---

## 8. Governance notes

- Queries were **read-only** against Snowflake `PRODUCTION`.
- This document contains PII and references to live litigation. Do not share outside authorised
  Privacy/Operations/Legal staff. Retain only as long as the SAR and court proceedings require it,
  then redact/dispose per policy.
- **This record does not constitute Legal or DPO advice** and the draft in §6 is not an approved
  customer communication — both require sign-off before any reply is sent, given the active court
  claim. §9 raises the bar on this further.

---

## 9. Customer's response to §6, 2026-10-09: escalation, now a legal/regulatory matter, not just an
## operational SAR reply

The customer replied to the §6 letter rejecting the "oversight" framing outright. Summary of what
he's raised, not reproduced verbatim per the PII-minimisation rule (full text is in the Freshdesk
thread):

1. **Detrimental reliance.** He says he checked the published policy after the incident, read 12
   months, and decided not to request recordings immediately on that basis. He now says that if he'd
   known it was 3 months, he would have asked straight away, and that AnyVan's own admission may
   mean he has lost evidence because of it. This reframes the oversight as something with a direct,
   stated causal consequence for him, not just a transparency gap in the abstract.
2. **Formal UK GDPR citations.** Articles 5(1)(a), 12(1), 13(2)(a), 5(2). He's asking what legal
   basis AnyVan had to operate 3 months while publishing 12, and whether AnyVan has assessed this
   for UK GDPR non-compliance. He's also raised it as a potential wider issue (other customers who
   may have relied on the same published figure).
3. **Incomplete recordings, pressed further.** He's explicitly asking whether calls were "split
   between systems, interrupted, partially recorded, or otherwise affected," and whether further
   recordings, transcripts, call logs or metadata exist. This is a fair, specific question and one
   this investigation has a real lead on, not yet followed up: §4.6 found that durations recorded in
   Jiminny for several 27–28 Feb calls are much shorter than the overlapping Twilio call-log entries
   for what looks like the same conversation (e.g. a Jiminny call starting 19 seconds after a
   55-minute Twilio call ends). That's a plausible mechanical explanation for "partial" recordings,
   and it has not been confirmed with Telephony/Engineering. It should be now, because it's a direct
   answer to a direct question.
4. **Seven-day deadline, stated for a court evidence file**, a repeated preservation request, and an
   express reservation of rights to the ICO.

**This is no longer a wording question.** The customer is citing AnyVan's own written admission back
at AnyVan, in the context of active court proceedings, with GDPR articles and an ICO threat attached.
The "legal basis" and "does AnyVan accept this caused you to lose evidence" questions are not ones to
answer from this record, or from DPO sign-off alone, the way §6 was handled. They need actual legal
input (external solicitor, not just internal Legal/DPO review of wording) before any substantive
answer goes out. Answering them badly now is worse than answering a few days late.

**Recommended split response:**
- **Operational, answerable now:** get Telephony/Engineering to resolve the Jiminny/Twilio duration
  question in point 3 and give him a real, specific mechanical answer, re-confirm the preservation
  request is in place (again), and confirm receipt of this letter.
- **Legal/regulatory, needs solicitor input before answering:** the "on what legal basis" question,
  whether this has been assessed for UK GDPR non-compliance, and whether AnyVan accepts his
  reliance/evidence-loss argument. These should not be answered on the same timeline as the
  operational points just because he's asked them together.
- A short holding reply inside his 7-day window, acknowledging receipt, re-confirming preservation,
  and saying a substantive response is being prepared with legal input, is standard practice here
  and is not the same as ignoring the deadline.

### 9.1 Draft holding reply, for sending inside the 7-day window

This does not answer the GDPR or evidence-reliance questions. It buys the time for a solicitor to
do that properly.

> Dear Mr Haider,
>
> Thank you for your email. We take the points you have raised seriously, including the legal basis
> questions you have asked under UK GDPR, and we do not think they should be answered without proper
> legal review given how significant they are and the proceedings you have referred to.
>
> We confirm again that your request to preserve all relevant recordings, call logs, transcripts and
> related notes remains logged and in place, and that nothing has been deleted since you first asked
> us to preserve it.
>
> We are also looking further into your question about why some recordings appear incomplete, and we
> will come back to you with a specific answer on that point.
>
> We will respond substantively to the remaining points in your email, including the legal basis
> question, within [X] working days.
>
> Kind regards,
> AnyVan Privacy Team

Leave [X] for Ant/DPO to set once they know the solicitor's availability, rather than committing to
a number here.

This record flagged, before §6 was sent, that the oversight admission was a material statement in
active litigation and recommended Legal/DPO sign-off before sending it (§4.4, §6). That risk has now
materialised: the admission is being cited back. That's not a reason to have withheld it (the
underlying fact was true and the customer already had strong circumstantial evidence from his own,
albeit wrong-domain, screenshot), but it is the reason the next reply needs a higher bar of review
than the last one got.
