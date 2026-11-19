# Phone Number Cross-Contact Investigation — `07495 514972`

> ⚠️ **CONFIDENTIAL — CONTAINS CUSTOMER PERSONAL DATA (PII).**
> This record contains customer names, phone numbers, home addresses, postcodes and account
> IDs. Access is restricted to authorised AnyVan Privacy / Operations staff and must be handled
> in line with AnyVan's data protection policy and UK GDPR. Do not share outside the business.
> Note that anything committed here persists in git history.

| | |
|---|---|
| **Record type** | Booking lookup / privacy investigation — third-party data disclosure via a mis-linked contact number |
| **Date created** | 2026-11-17 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Status** | **Open.** Freshdesk ticket due **2026-11-19**. Owner: Ant. Account-level fix (detach the number / stop SMS) not yet applied as of this record. |
| **Data source** | Snowflake `PRODUCTION` (read-only) + Freshdesk ticket #2379760 (quoted in `#riskops`/DM thread by Inathi Mxutu, 2026-11-17) |
| **Subject identifier** | Phone number `07495 514972` (normalised: `7495514972`) — complainant "Paula Brown" |

---

## 1. Request

Raised via Slack DM thread (Ant ↔ Inathi, 17 Nov 2026), relaying **Freshdesk #2379760**
("Subject Access & Deletion Request"), a formal data-protection complaint:

> "Paula Brown" says AnyVan has repeatedly texted her mobile (`07495514972`) with other
> customers' booking details (names/postcodes with a link). She says she contacted AnyVan
> for a quote for her mother's house move ~3 years ago and didn't go ahead; that she phoned
> ~3 months ago asking for her number to be removed; and that she received another such text
> on 15 October 2026. She has made a formal Art. 15 SAR + Art. 17 erasure request and flagged
> it as a possible reportable breach.

Ant's follow-up questions for this record:

1. Can we validate whether Paula actually called, and when?
2. How did this number get added to AnyVan's systems in the first place?
3. Who were the two listings tied to this number actually booked for?
4. Was Alison logged into her account when the second listing was created — i.e. is the
   account's contact number only ever updated when the customer is authenticated, which would
   explain why the correct number she gave on the second booking never overwrote the 2023 one?

---

## 2. Result

### 2.1 The number is not "shared" between two customers — it's one account, mis-linked

`PHONE_NUMBER_ID 4682918` (`+447495514972`) has existed in AnyVan's systems since
**2023-04-24 13:24:03** and has been linked to **exactly one** `USER_ID` the entire time:

| USER_ID | Full name | Email | Account created | Status | SMS transactional consent |
|---|---|---|---|---|---|
| `4886643` | Alison Read | `alisonlread@yahoo.co.uk` | 2023-04-24 13:49:31 | Active | **Yes (1)** |

`USER_PHONE_NUMBER` link: `IS_CONTACT = 1`, `IS_SMS = 1`, created 2023-04-24 14:49:33, **never
deleted**. This is the account's live SMS contact number today. There is no second customer
record anywhere in the warehouse holding this number — so this is not two accounts colliding;
it's one account whose on-file contact number belongs to someone else.

### 2.2 Did Paula call to ask for removal? — Not corroborated in any call system

Checked **every** call-level fact table available (`CONFORMED.PRODUCTION.FCT_VOICE_INTERACTIONS`
— the combined Twilio + Aircall table, all-time, all directions) and the WFM table
(`MART_SALES_OPS.PRODUCTION.FACT_VOICE_ACTIVITY`) for `07495514972` as either `TO_NUMBER` or
`FROM_NUMBER`:

**Zero rows, in either table, for any date.** The underlying `PHONE_NUMBER` record itself also
shows blank `LAST_CALLED` / `LAST_RECEIVED` / `LAST_SMS` fields.

This does **not** prove the call didn't happen — it means there is no record of it in the
telephony systems this warehouse captures (Twilio/Aircall). Possible explanations: it went to a
line/channel not wired into these fact tables, it was never answered/logged, or it was handled
by email/webchat rather than voice. **Cannot be validated from AnyVan's data; flagging as a gap**
— worth asking Paula for the date/time she called so it can be checked against raw telephony
logs directly, if those are held longer/elsewhere.

### 2.3 How the number was added — admin-entered during the original 2023 enquiry

`PRE_LISTING_PHONE_NUMBER` history for this phone (all rows `TYPE = 3`, all admin-entered):

| Admin ID | Admin | Team | When |
|---|---|---|---|
| `4424534` | Liam Barreiro | Sales — South Africa Inbound CT | 2023-04-24 13:48:46 (first) |
| `4658765` | Shaun Gae | Operations — Storage | 2023-04-24 14:13:16 |
| *(unattributed)* | — | — | 2023-04-29 13:28:47 |
| `4862958` | Loyiso Mxobo | Customer Service | 2023-04-30 08:08–11:49 (5 touches) |
| `4615492` | Nhlakanipho Mdlalose | Customer Service | 2023-04-30 10:08:49 |

The number was entered by a **Sales** admin during an inbound enquiry at 13:48, one minute
*before* the customer account itself was created (13:49:31) — consistent with a phone/chat
enquiry that converted into an account almost immediately. It was then reused by several
different Customer Service/Operations admins against further pre-listing attempts over the
following week, all against the same `PHONE_NUMBER_ID` (not re-typed each time) — i.e. admins
were pulling up the existing record, not independently mis-keying the same number by accident.

**Critically, a second phone number was captured in the same initial window:**
`PHONE_NUMBER_ID 4682950` (`+447940491389`) was created **2023-04-24 13:35:12** — 13 minutes
*before* Paula's number — but was **never promoted to account-level contact** (no
`USER_PHONE_NUMBER` row at all; it only ever appears on booking **address** records, see 2.4).

Best-supported read: on the original 2023 enquiry, two numbers were captured — most likely the
customer's own (`...491389`) and a second number given as an alternative/third-party contact
(Paula's). The wrong one of the two was the one flagged as the account's primary SMS contact,
and that error was never corrected in three years, surviving a second booking in 2026.

### 2.4 The two listings — both genuinely "Alison Read," not Paula

| | Listing `7836294` | Listing `9580942` |
|---|---|---|
| Title | Furniture Delivery, Salisbury → Bournemouth | Home move, Bournemouth → Bideford |
| Created / Completed | 2023-04-24 / 2023-05-03 | 2026-08-14 / 2026-10-16 |
| Pickup contact name | Alison Read (`SP4 8DL`) | Alison Read (`BH10 5EP`) |
| Delivery contact name | Alison Read (`BH10 5EP`) | Alison Read (`EX39 5BE`) |
| **Contact phone on address** | `+447495514972` (Paula's) | `+447940491389` (the other number) |
| Account (USER_ID) | `4886643` | `4886643` |

Both jobs are the same real person, "Alison Read" — the Bournemouth delivery postcode on job 1
is the same as the Bournemouth pickup postcode on job 2, i.e. she moved *into* Bournemouth in
2023 and *out* of it to Bideford in 2026. **Neither booking is "a stranger's move"** in the sense
Paula's complaint implies two different customers' data — it's one customer's two house moves.
The issue is purely that the account's SMS contact field still points at Paula's number, three
years after it should have been Alison's own.

### 2.5 Which number is actually "live" — confirms the misdirection

| | `07495514972` (Paula — account SMS contact) | `07940491389` (the other number) |
|---|---|---|
| Calls (`FCT_VOICE_INTERACTIONS`, all-time) | **0** | 2 (outbound, 25 May 2026 & **14 Aug 2026** — the day listing `9580942` was created) |
| WhatsApp (`FACT_WHATSAPP_ACTIVITY`, all-time) | **0** | 8 inbound messages, 19 Sep – 14 Oct 2026 |

The 8 WhatsApp messages line up exactly with the "WA -" admin notes logged against listing
`9580942` between 19 Sep and 13 Oct 2026 (dimensions, address, cancellation request, TV-bracket
query, etc.). **Alison genuinely communicates on `07940491389`.** Paula's number has never once
been used to call, be called, or message AnyVan — it only receives the transactional SMS AnyVan's
system fires from the stale account-level contact field.

### 2.6 Was the second listing created while logged in? — No; it started as an anonymous quote

This is the key mechanism, not just a contributing detail. The pre-listing that became listing
`9580942` is `PRE_LISTING_ID 27477247`:

| Field | Value |
|---|---|
| Created | **2026-05-15 13:28:01** — three months before the listing itself (14 Aug) |
| `USER_ID` | **blank — not logged in / no account attached at creation** |
| Identified by | Email only (`alisonlread@yahoo.co.uk`) |
| Quote progress | `STAGE_LAST = STAGE_MAX = 6` (reached the final quote stage) |
| Phone captured on this quote | `+447940491389` — her correct, current number — entered by Admin `5562494`, 2026-05-15 13:34:35 |

So the correct number *was* captured, at source, for this job. But the quote was anonymous —
there was no authenticated session to attach it to the account at that point. It sat
unconverted for three months, then became a live listing on 14 Aug 2026, at which point it was
**reconciled to Alison's existing 2023 account by matching the email address**, not by her
logging in. An email-match reconciliation updates which account a booking belongs to; it does
not — and, per this investigation, evidently did not — write back to that account's own
`USER_PHONE_NUMBER` / primary-contact record. That field only changes through an authenticated
account/profile action, and none occurred here: the quote was anonymous, the conversion was an
automated email match, and every edit after that (see 2.5, and the one genuine customer
self-edit on 11 Sep 2026, `IS_CUSTOMER = 1` in `FCT_LISTING_EDITS_ALL`) touched listing details
(volume, dates, special instructions), not account contact settings — there is no contact-number
field anywhere in that edit surface to begin with.

This is the direct answer to "how did the account end up contacting Paula about the 2026 job
specifically": the booking's own correct number never had a path back to the account record,
because the booking was never created inside an authenticated session for that account.

---

## 3. Observations

- **Root cause, two parts.** (1) A data-entry/field-selection error from the original 24 April
  2023 enquiry — the wrong one of two numbers captured that day was flagged as the account's
  primary SMS contact. (2) A genuine product gap that let it persist: the second booking (2026)
  started as an **anonymous quote**, reached and gave a correct, current number, and was only
  reconciled to the 2023 account **by email match at conversion**, not by an authenticated
  session — and an email-match reconciliation does not update the account's own contact-number
  field. There is no self-service path in the data that ever touches that field once an account
  exists; it only gets set once, at account creation, from whatever the first — possibly
  anonymous, possibly erroneous — contact capture happened to be.
- **Not a cross-account bug.** There is only one customer account behind this number. Paula's
  framing ("other customers' data") is understandable from her side — she has no way of knowing
  it's the same person each time — but the underlying mechanism is a single stale field, not a
  matching/lookup bug mixing up two separate customers.
- **Paula's own account of events doesn't fully match the data**, and that gap matters for how
  we respond: she says she enquired and didn't book; a real, paid, completed job did follow
  (listing `7836294`, completed 3 May 2023) on the number she gave. Worth being factual rather
  than accusatory in the SAR response — simply that the number has been linked to one AnyVan
  account since April 2023 and we've now corrected it.
- **This is still live and ongoing.** SMS transactional consent is still flagged `1` on the
  account, the number is still attached, and nothing has been technically changed as of this
  record — the risk of another disclosure remains until the account record is corrected.
- **The "phoned 3 months ago" request, if it happened, was not actioned** — there's no evidence
  in telephony data either way, but the practical fact is the number is still live today, so
  whatever contact occurred didn't result in the number being removed.

---

## 4. Methodology / learning (reusable)

For a "my number is getting someone else's texts" complaint, don't stop at
`DIM_USER_CUSTOMER` (it only shows each user's *current* primary/secondary number). Instead:

1. Find the `PHONE_NUMBER_ID` for the number (`HARMONISED.PRODUCTION.PHONE_NUMBER`, match on
   last-10-digits of `FULL_NUMBER`/`NATIONAL_NUMBER`).
2. Join to `HARMONISED.PRODUCTION.USER_PHONE_NUMBER` on `PHONE_NUMBER_ID` (not the other way via
   `DIM_USER_CUSTOMER`) to see **every** account that number has ever been linked to, and whether
   it was ever flagged `IS_CONTACT`/`IS_SMS`. This is the only way to tell "one account, stale
   number" apart from "two accounts, genuine collision."
3. Check `HARMONISED.PRODUCTION.PRE_LISTING_PHONE_NUMBER` joined on the same `PHONE_NUMBER_ID`
   for the `ADMIN_ID`/timestamp history of who first captured it and how it was reused.
4. Pull the booking's own **address-level** contact number (`HARMONISED.PRODUCTION.ADDRESS` —
   `FIRSTNAME`/`LASTNAME`/`PHONE_NUMBER`/`MOBILE_PHONE_NUMBER`), not just the account-level
   field — bookings can (and did, here) carry a different, more current number than the account
   record.
5. Cross-check both candidate numbers against `CONFORMED.PRODUCTION.FCT_VOICE_INTERACTIONS`
   (all-time, both `TO_NUMBER`/`FROM_NUMBER`) and `MART_SALES_OPS.PRODUCTION.FACT_WHATSAPP_ACTIVITY`
   to see which number the customer is *actually* using — the one with real call/WA history is
   almost certainly the right one to leave on the account.
6. To check a specific alleged call: search `FCT_VOICE_INTERACTIONS` on the number with no date
   filter first. Zero rows ever (not just zero in the period asked about) is a materially
   different, stronger finding than "none in the last 3 months" — say which one you found.
7. To test "was the booking that's actually causing the disclosure made while logged in,"
   don't check whether the customer *ever* logged in during the account's life (they likely did,
   for something else) — find the specific `PRE_LISTING` row tied to that `LISTING_ID` and check
   its `USER_ID` **at that pre-listing's own creation**. A blank `USER_ID` there, even if the
   listing now sits under a populated account, means it started anonymous and was reconciled by
   email later — which is the step that explains a stale account-level contact field.

---

## 5. Governance notes

- All queries were **read-only** against Snowflake `PRODUCTION`
  (`PHONE_NUMBER`, `USER_PHONE_NUMBER`, `PRE_LISTING_PHONE_NUMBER`, `LISTING`, `ADDRESS`,
  `ADMIN_LISTING_NOTES`, `DIM_USER_CUSTOMER`, `DIM_ADMIN_HIERARCHY_SUPERSTATE`,
  `FCT_VOICE_INTERACTIONS`, `FACT_VOICE_ACTIVITY`, `FACT_WHATSAPP_ACTIVITY`).
- No write/update was made to any customer record as part of this investigation — the account
  still has Paula's number attached as of the date of this record (see Status above).
- This document contains PII — retain only as long as required for the SAR/breach handling and
  dispose of / redact per policy once closed.
- **Open item, owner, date:** detach `PHONE_NUMBER_ID 4682918` from `USER_ID 4886643` (or at
  minimum withdraw SMS consent) and respond to Freshdesk #2379760 — **Ant, due 2026-11-19.**

### Sources
- Slack DM thread, Ant ↔ Inathi Mxutu, 2026-11-17 (relaying Freshdesk #2379760).
- Snowflake `PRODUCTION` schema, queried 2026-11-17.
