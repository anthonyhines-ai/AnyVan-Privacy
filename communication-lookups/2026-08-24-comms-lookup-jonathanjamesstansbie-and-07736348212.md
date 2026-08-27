# Communications Lookup — `jonathanjamesstansbie@gmail.com` & `07736348212`

> ⚠️ **CONFIDENTIAL — CONTAINS CUSTOMER PERSONAL DATA (PII).**
> This record contains customer names, phone numbers, email addresses, home addresses,
> account IDs and message content. Access is restricted to authorised AnyVan Privacy /
> Operations staff and must be handled in line with AnyVan's data protection policy and
> UK GDPR. Do not share outside the business. Note that anything committed here persists
> in git history.

| | |
|---|---|
| **Record type** | Communications lookup / privacy investigation |
| **Date created** | 2026-08-24 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Data sources** | Snowflake `PRODUCTION` (read-only) · HubSpot CRM (read-only) |
| **Subject identifiers** | Email `jonathanjamesstansbie@gmail.com` · Phone `07736348212` (normalised `7736348212`, intl `+447736348212`) |

---

## 1. Request

> "Can we locate any emails, SMS's, WhatsApp and phone calls to the following contact
> information: **jonathanjamesstansbie@gmail.com** / number is **07736348212**"

Each of the four channels was searched independently against both identifiers, across
AnyVan's system-of-record tables (Twilio for voice/SMS/WhatsApp, the email/messaging
platform for email, and HubSpot CRM for any manually-logged engagements).

---

## 2. Result — headline

| Channel | Sent **to** / from the identifier | Verdict |
|---|---|---|
| 📧 **Email** → `jonathanjamesstansbie@gmail.com` | **0 emails ever sent.** Address only used to request an online quote (expired, never booked). | **None** |
| 💬 **SMS** → `07736348212` | 0 — every Twilio message to this number was WhatsApp, not SMS. | **None** |
| 🟢 **WhatsApp** ↔ `07736348212` | **6 messages** (5 automated outbound from AnyVan, 1 inbound reply). | **Found — 6** |
| 📞 **Phone calls** → `07736348212` | 0 across all four voice tables. | **None** |

**Bottom line:** the only genuine communications located are **6 WhatsApp messages** to/from
`07736348212` (March 2025 and August 2026). **No SMS, no phone calls, and no emails** were
ever sent to either identifier.

**⚠️ Two points worth flagging to Privacy / Ops (see §5):**
1. `07736348212` is **the customer's son's number, not the account holder's.** In March 2025
   the recipient replied on WhatsApp: *"this is her son… this may be the wrong number, if you
   could contact her on 07545703175."* Despite that, the number was still on the account for
   the **August 2026** booking and received a further WhatsApp on 2026-08-21.
2. The account phone/address has **since been corrected to `07545703175`**, so `07736348212`
   no longer matches any current account record — it is a historic (now-replaced) contact number.

---

## 3. Detailed findings by channel

### 3.1 📧 Email — `jonathanjamesstansbie@gmail.com`

**No email was ever sent to this address.** Confirmed zero across every email surface:

| Source checked | Table | Result |
|---|---|---|
| Transactional email events (send/deliver/open) | `HARMONISED.PRODUCTION.EVENTS_EMAIL` | 0 |
| Messaging platform (channel = email) | `HARMONISED.PRODUCTION.EVENTS_MESSAGING_MESSAGE` | 0 |
| Marketing email events | `HARMONISED.PRODUCTION.HUBSPOT_EVENTS_EMAIL_WIDE` | 0 |
| HubSpot logged email engagements | HubSpot `EMAIL` objects on contact `119375817269` | 0 |

**Only footprint of the address:** it was used to request an **online quote**.

| Field | Value |
|---|---|
| Pre-listing ID | `21982696` |
| Quote created | **2025-05-05** 19:48 |
| Status | **Expired** (never converted to a booking) |
| Captured email | `jonathanjamesstansbie@gmail.com` |
| HubSpot contact | `119375817269` — auto-created 2025-05-05, lifecycle stage *other*, **0 notes / 0 engagements**, no phone or name populated |

So the address exists in our systems purely as a lapsed quote enquiry; nothing was ever
sent to it.

### 3.2 💬 SMS — `07736348212`

**None.** `HARMONISED.PRODUCTION.TWILIO_MESSAGE` (the SMS/WhatsApp system of record) returns
six rows for this number, **all six carrying the `whatsapp:` channel prefix** on both
sender and recipient — i.e. WhatsApp, not SMS. There are **no plain-SMS** messages.

### 3.3 🟢 WhatsApp — `07736348212`

**6 messages**, all via AnyVan's WhatsApp business number **`+447897012899`**. Times as stored (UTC).

| # | Timestamp | Direction | Status | Summary |
|---|---|---|---|---|
| 1 | 2025-03-03 20:32:59 | **Outbound** (AnyVan → customer) | read | "David" pre-move intro — *"…excited to be helping with your move!"* Move **DL1 2YZ → DL1 5BE, Thu 06 Mar 2025**, collection 10:00–15:00. |
| 2 | 2025-03-03 20:37:38 | **Inbound** (customer → AnyVan) | received | **"Hi, this is her son and I think this may be the wrong number, if you could contact her on 07545703175. Thanks"** |
| 3 | 2025-03-03 20:37:42 | **Outbound** | read | CS auto-welcome menu — booking **AV8750349**, DL1 2YZ → DL1 5BE, 6 Mar 2025, options 1/2/3. |
| 4 | 2025-03-04 18:01:42 | **Outbound** | read | Pre-move reminder — recap of times (*Pick-Up 06 Mar 25 10:00–15:00*), paid time-slot upsell. |
| 5 | 2025-03-05 18:01:42 | **Outbound** | read | Pre-move reminder — recap of times (*Pick-Up 07 Mar 25 10:00–15:00*), paid time-slot upsell. |
| 6 | 2026-08-21 15:27:39 | **Outbound** | delivered | "David" pre-move intro (repeat). Move **DL1 5BE → DL3 0NF, Wed 26 Aug 2026**, collection 12:00–16:00. |

- **5 outbound** (all automated — bot "David" intro, CS auto-menu, reminders). **1 inbound** (the son's reply, #2).
- Messages **#2 and #3** are the same thread mirrored into `TWILIO_CONVERSATION_MESSAGE`
  (Twilio Conversation `CH127cf778a4c443f9aad159b6d72131d3`) — the same messages, **not** additional ones.
- No human-agent WhatsApp: `MART_SALES_OPS.PRODUCTION.FACT_WHATSAPP_ACTIVITY` (agent-handled
  conversations) returns 0 for this number — consistent with all traffic being automated.
- A later, **separate** booking (`9594495`, placed the same evening while signed in) sent its own
  "David" WhatsApp — correctly to `07545703175` — at 2026-08-21 21:28:02 UTC. See §8.2.

### 3.4 📞 Phone calls — `07736348212`

**None.** Zero rows across every voice table:

| Table | Result |
|---|---|
| `HARMONISED.PRODUCTION.TWILIO_CALL` (raw call record, FROM/TO) | 0 |
| `CONFORMED.PRODUCTION.FCT_VOICE_INTERACTIONS` | 0 |
| `CONFORMED.PRODUCTION.FCT_TWILIO_CALL_METRICS` | 0 |
| `MART_SALES_OPS.PRODUCTION.FACT_VOICE_ACTIVITY` | 0 |

No inbound or outbound call to or from this number has ever been recorded.

### 3.5 One linked record that is **not** a direct communication

A single row surfaced in `EVENTS_MESSAGING_MESSAGE` when searching by the phone number, but
it is **not** a message sent to `07736348212`:

| Field | Value |
|---|---|
| Timestamp | 2026-08-21 15:18:16 |
| Channel | **EMAIL** |
| Actually sent to | `edwinastansbie@gmail.com` (the account holder's email) |
| Subject | "AnyVan Booking Confirmation & Driver Tracking" (listing `9593885`) |
| Why it matched | `+447736348212` was stored as the account's *resolved user phone* at send time |

It is included here for completeness/audit, but the message was an **email to
`edwinastansbie@gmail.com`**, not a communication to the target number or email.

---

## 4. Identity & context — who these identifiers belong to

Neither identifier matches a current AnyVan customer account (both return 0 in
`DIM_USER_CUSTOMER`), because the account has since been updated. Piecing the records
together, both trace to the **Stansbie household in Darlington**:

| Party | Details |
|---|---|
| **Account holder** | **Corrin Stansbie** — user `3609439`, email `edwinastansbie@gmail.com`, **current phone `07545703175`**. HubSpot contact `43728856` (lifecycle *evangelist* / repeat customer; last contacted 2026-08-24). |
| **`07736348212`** | The account holder's **son's** number (per his own inbound WhatsApp #2). Was the legacy contact number stored on the account; **since replaced by `07545703175`.** |
| **`jonathanjamesstansbie@gmail.com`** | Almost certainly the same son (Jonathan James Stansbie). Used once to request an online quote (2025-05-05, expired). Sparse HubSpot contact `119375817269`, no engagements. |

**Bookings under account `3609439`:**

| Listing | Route | Dates | Status | Contact name on file |
|---|---|---|---|---|
| `8750349` (AV8750349) | 18 Campion Road, **DL1 2YZ** → 41 Wordsworth Road, **DL1 5BE** (Darlington) | created 2025-03-03; pickup 2025-03-13 | **Cancelled** | "Miss Edwina" |
| `9593885` | 41 Wordsworth Road, **DL1 5BE** → 45 Zetland Street, **DL3 0NF** (Darlington) | created 2026-08-21; pickup 2026-08-26 | **Active** | "Corrin Stansbie" |
| `9594495` | (later booking placed the same evening, signed in — updated the account number; see §8.2) | created 2026-08-21 21:17 UTC | — | — |

The WhatsApp thread in §3.3 maps directly onto these: messages #1–#5 relate to the
2025 booking `8750349`, message #6 to the 2026 booking `9593885`. The current linked
address records now hold `07545703175`, confirming the number correction.

---

## 5. Privacy observations

1. **Wrong-number contact (mis-directed personal data).** In March 2025, AnyVan sent WhatsApp
   messages containing another person's booking details (Corrin Stansbie's move) to
   `07736348212`. The recipient replied that it was the **wrong number** and that it belonged
   to **"her son"**, supplying the correct number `07545703175`.
2. **Repeat mis-contact in 2026.** Despite the 2025 flag, `07736348212` was still the
   number on the account for the **August 2026** booking (`9593885`) and received a further
   automated WhatsApp on **2026-08-21**. Root cause and correction are set out in §8 —
   the initial booking was placed signed out (so it could not overwrite the saved account
   number), and a later signed-in booking that evening corrected it to `07545703175`.
3. **Email never contacted.** `jonathanjamesstansbie@gmail.com` generated a single online quote
   (2025-05-05) that expired; **no email, SMS, WhatsApp or call was ever sent to it.**
4. **All WhatsApp traffic was automated** (bot "David" intro, CS auto-menu, pre-move reminders)
   — no human agent messaged this number.

---

## 6. Methodology / learning (reusable)

How to run a "locate all communications for an email / phone" lookup. Swap the highlighted
literals; the phone match uses a `LIKE '%<last-10-digits>%'` catch-all that matches every
stored format (`07736348212`, `+447736348212`, `447736348212`, `whatsapp:+447736348212`).

### 6.1 Where each channel lives

| Channel | Table(s) | Key columns |
|---|---|---|
| **SMS & WhatsApp** (system of record) | `HARMONISED.PRODUCTION.TWILIO_MESSAGE` | `"FROM"`, `"TO"`, `BODY`, `DIRECTION`, `DATE_SENT`, `STATUS` — WhatsApp identified by a `whatsapp:` prefix on `FROM`/`TO` |
| WhatsApp (Conversations API view) | `HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE` (+ `_PARTICIPANT`) | `AUTHOR`, `BODY`, `CONVERSATION_ID` |
| Outbound messaging platform (email/SMS/WhatsApp/push) | `HARMONISED.PRODUCTION.EVENTS_MESSAGING_MESSAGE` | `CHANNEL`, `CHANNEL_RECIPIENT`, `RESOLVED_USER_PHONE`, `RESOLVED_USER_EMAIL`, `TEMPLATE_KEY`, `RENDERED_SUBJECT` |
| Inbound messages | `HARMONISED.PRODUCTION.EVENTS_MESSAGING_INBOUND_MESSAGE_RECEIVED` | `FROM_NUMBER`, `TO_NUMBER`, `MESSAGE_BODY`, `CHANNEL` |
| **Voice / calls** | `HARMONISED.PRODUCTION.TWILIO_CALL`; `CONFORMED.PRODUCTION.FCT_VOICE_INTERACTIONS` / `FCT_TWILIO_CALL_METRICS`; `MART_SALES_OPS.PRODUCTION.FACT_VOICE_ACTIVITY` | `"FROM"`/`"TO"` · `FROM_NUMBER`/`TO_NUMBER` · `FROMNUMBER`/`TONUMBER` · `CUSTOMERPHONENUMBER` |
| **Transactional email** | `HARMONISED.PRODUCTION.EVENTS_EMAIL` | `EMAIL_ADDRESS`, `EMAIL_SUBJECT`, `EMAIL_EVENT_TYPE`, `EVENT_TIMESTAMP` |
| **Marketing email** | `HARMONISED.PRODUCTION.HUBSPOT_EVENTS_EMAIL_WIDE` | `HS_EMAIL_EVENT_EMAIL_RECIPIENT`, `_SUBJECT`, `_TYPE` |
| Quote-stage email capture | `HARMONISED.PRODUCTION.PRE_LISTING_EMAIL` / `CONFORMED.PRODUCTION.MASTER_PRE_LISTING` | `EMAIL` / `USER_EMAIL`, `PRE_LISTING_ID`, `PRE_LISTING_STATUS` |
| CRM contact + logged engagements | HubSpot CRM (`CONTACT`, `EMAIL`, `CALL` objects) | search by email/phone; check engagements associated with the contact |

> ⚠️ Most tables above are `HARMONISED` source tables, used deliberately because a privacy
> "locate communications" request needs the raw to/from identifiers and message content, not
> an aggregated metric. They are the correct system of record for this task; the usual
> "prefer a CONFORMED/MART product" guidance is about metric verification, not applicable here.

### 6.2 Template — phone lookup (SMS / WhatsApp / calls)

```sql
-- Replace 7736348212 with the target number's last 10 digits.
-- SMS & WhatsApp
SELECT ID, DATE_SENT, DIRECTION, STATUS, "FROM", "TO",
       CASE WHEN "FROM" ILIKE 'whatsapp:%' OR "TO" ILIKE 'whatsapp:%' THEN 'WhatsApp' ELSE 'SMS' END AS channel,
       BODY
FROM HARMONISED.PRODUCTION.TWILIO_MESSAGE
WHERE "TO" LIKE '%7736348212%' OR "FROM" LIKE '%7736348212%'
ORDER BY DATE_SENT;

-- Calls (returns 0 rows = no calls)
SELECT * FROM HARMONISED.PRODUCTION.TWILIO_CALL
WHERE "TO" LIKE '%7736348212%' OR "FROM" LIKE '%7736348212%';
```

### 6.3 Template — email lookup

```sql
-- Replace the address. Check every email surface; 0 across all = "no email ever sent".
SELECT COUNT(*) FROM HARMONISED.PRODUCTION.EVENTS_EMAIL
  WHERE EMAIL_ADDRESS ILIKE 'jonathanjamesstansbie@gmail.com';
SELECT COUNT(*) FROM HARMONISED.PRODUCTION.HUBSPOT_EVENTS_EMAIL_WIDE
  WHERE HS_EMAIL_EVENT_EMAIL_RECIPIENT ILIKE '%jonathanjamesstansbie%';
SELECT * FROM HARMONISED.PRODUCTION.EVENTS_MESSAGING_MESSAGE
  WHERE LOWER(RESOLVED_USER_EMAIL) = 'jonathanjamesstansbie@gmail.com'
     OR LOWER(CHANNEL_RECIPIENT)   = 'jonathanjamesstansbie@gmail.com';
-- Quote-stage capture (why the address is on file at all)
SELECT PRE_LISTING_ID, PRE_LISTING_STATUS, USER_EMAIL, PRE_LISTING_CREATED_DATE
FROM CONFORMED.PRODUCTION.MASTER_PRE_LISTING WHERE USER_EMAIL ILIKE 'jonathanjamesstansbie@gmail.com';
```

### 6.4 Caveats

- **Phone match is last-10-digit `LIKE`.** For UK mobiles this is effectively unique; always
  eyeball the stored `FROM`/`TO` value (shown in results) when precision matters.
- **A phone match on `EVENTS_MESSAGING_MESSAGE` is not necessarily a message to that phone** —
  the number may be metadata (`RESOLVED_USER_PHONE`) on an email/push send (see §3.5). Read the
  `CHANNEL` + `CHANNEL_RECIPIENT` to see where it actually went.
- **Numbers get corrected.** A number no longer on the account (`DIM_USER_CUSTOMER` / `ADDRESS`
  return 0) can still have historic communications — always search the raw comms tables by the
  number itself, not just the account.
- **Timezone — mixed by table.** Comms/booking tables (`TWILIO_MESSAGE`, `EVENTS_MESSAGING_MESSAGE`, `LISTING`,
  `PRE_LISTING`) are **UTC**; `USER_PHONE_NUMBER` is **UK local (BST in summer)** — see §8. Confirm a table's
  basis before quoting a time, and convert before sharing externally.

---

## 7. Governance notes

- All Snowflake queries were **read-only** against `PRODUCTION`; HubSpot access was read-only.
- Voice (calls) was confirmed **nil** across four independent tables; SMS confirmed **nil**;
  email confirmed **nil** across four independent surfaces — reducing false-negative risk.
- This document contains PII (names, numbers, email addresses, home addresses, message content).
  Retain only as long as required for the investigation and redact/dispose per policy when no
  longer needed.

---

## 8. Addendum (2026-08-24) — where the number came from & who changed it

Follow-up questions during review: **where did we get `07736348212` from** (given listing `9593885`
is the mother's booking), and **who edited the number and when.**

> 🕒 **Timezone — mixed by table, so read each one carefully.** The comms & booking tables (`TWILIO_MESSAGE`,
> `EVENTS_MESSAGING_MESSAGE`, `LISTING`, `PRE_LISTING`) are **UTC** (verified: on booking `9593885`,
> `LISTING.CREATED_AT` `15:17:27` is 49 s before the confirmation email at `15:18:16 Z`).
> **`USER_PHONE_NUMBER.CREATED_AT` is UK local time (BST in summer)** — verified in §8.2: its account-number
> correction reads `22:17:51`, which is **BST = `21:17:51` UTC**, matching the subsequent signed-in booking
> `9594495` (`21:17:52` UTC) to the second. *(Correction: an earlier draft of this note mislabelled that
> `22:17:51` value as UTC / 23:17 BST — it is 22:17 BST = 21:17 UTC.)*

### 8.1 Source — a legacy account-profile number, not a booking entry

`07736348212` is a contact number stored on the **customer's AnyVan account** (`HARMONISED.PRODUCTION.USER_PHONE_NUMBER`,
user `3609439`) — **not** taken from the mother's booking. Two numbers are linked to the account:

| Number | Linked to account (`USER_PHONE_NUMBER.CREATED_AT`, **UK local / BST**) | Flags |
|---|---|---|
| **`+447736348212`** (target) | **2018-10-14 15:56** (GMT) | `IS_CONTACT` |
| `+447545703175` (mother's correct number) | **2026-08-21 22:17:51 BST** (= 21:17:51 UTC) | `IS_CONTACT`, `IS_SMS`, `IS_ALTERNATIVE` |

- The number has been the account's contact number since **October 2018**, and outbound comms resolve
  the recipient from this account/profile number (`RESOLVED_USER_PHONE`) — which is why the signed-out
  booking's automated messages went to it.
- **Every booking artefact held the _correct_ number `07545703175`:** the quote/checkout
  (`PRE_LISTING_PHONE_NUMBER`, all quote iterations across 2025 + 2026) and the collection/delivery
  address (`ADDRESS`). The wrong number was **never** entered on a booking — it came solely from the
  stale account profile. The old number `07736348212` is also **still linked** to the account (not removed).

> **Root cause:** outbound customer comms resolve the recipient from the **account-profile phone**, not the
> number entered on the booking — so a stale 2018 profile number overrode the correct booking contact number,
> until the account profile itself was updated by a later signed-in booking (see §8.2).

### 8.2 Who changed it, and when — confirmed

The account-number correction was **the customer's own doing, through a later booking made while signed in** —
not a CS-agent edit and not a manual profile change. Confirmed sequence for 21 Aug 2026 (booking/comms times
**UTC**; `USER_PHONE_NUMBER` time **BST**):

| Event | Time | Detail |
|---|---|---|
| `07736348212` linked to the account | **2018-10-14** | Legacy contact number since account setup; actor not in warehouse. |
| `07736348212` synced into HubSpot `43728856` | 2025-03-08 19:11 UTC | Automated `SOURCE = INTEGRATION` (id `1298926`) + workflow validation. No human. |
| **Initial** booking `9593885` placed **signed out** | **15:17:52 UTC** (quote `29590468` 15:09, blank `USER_ID` = guest) | Correct number captured on the booking's collection/delivery contact, but a signed-out booking **cannot write back to the account profile** (security), so the stale account number stayed. |
| → its automated comms | 15:18–15:27 UTC | Resolved from the **account** number → sent to the old `07736348212`. |
| **Subsequent** booking `9594495` placed **signed in** | **21:17:52 UTC** (`USER_ID 3609439`) | Being authenticated, this **updated the account's primary contact number** to `07545703175` (`USER_PHONE_NUMBER` `22:17:51` BST = `21:17:51` UTC — same second). |
| → its automated comms | 21:28:02 UTC | Resolved from the now-updated account number → correctly sent to `07545703175`. |

This matches the operational explanation from AnyVan Privacy/Ops and is corroborated end-to-end in the data: the
signed-out initial booking couldn't overwrite the saved number; the later signed-in booking did. The empty
warehouse actor logs (`LISTING_ADMIN_ACTION_LOG`, `FCT_LISTING_EDITS_ALL`, `USER_LOG` — no agent action at the
update time) are therefore expected — **no agent touched it**; the customer's own signed-in booking made the change.

### 8.3 Provenance tables (reusable)

| Question | Table | Key columns |
|---|---|---|
| What phone(s) are on the account & when added | `HARMONISED.PRODUCTION.USER_PHONE_NUMBER` ⋈ `PHONE_NUMBER` | `USER_ID`, `PHONE_NUMBER_ID`, `CREATED_AT`, `RAW_INPUT`, `IS_CONTACT`/`IS_SMS`/`IS_ALTERNATIVE`; `FULL_NUMBER` |
| What number the customer entered at quote | `HARMONISED.PRODUCTION.PRE_LISTING_PHONE_NUMBER` ⋈ `PHONE_NUMBER` | `PRE_LISTING_ID`, `PHONE_NUMBER_ID`, `ADMIN_ID` (who entered), `CREATED_AT` |
| Login state of a booking (guest vs signed in) | `HARMONISED.PRODUCTION.PRE_LISTING` / `LISTING` | `USER_ID` (blank = not signed in), `USER_EMAIL`, `CREATED_AT` |
| Who edited a booking (and how) | `MART_SALES_OPS.PRODUCTION.FCT_LISTING_EDITS_ALL` | `CHANGED_BY`, `USER_NAME`, `USER_TYPE`, `IS_ADMIN`/`IS_CUSTOMER`, `CHANGE_TYPE`, `DATE_CHANGED` (no contact-number field) |
| Admin actions on a listing | `HARMONISED.PRODUCTION.LISTING_ADMIN_ACTION_LOG` | `LISTING_ID`, `ACTION`, `USER_ID` (admin), `CREATED_AT`, `DETAILS` |
| HubSpot property change source/actor | `HARMONISED.PRODUCTION.HUBSPOT_CONTACT_PROPERTY_HISTORY` | `CONTACT_ID`, `NAME`, `VALUE`, `SOURCE`, `SOURCE_ID`, `TIMESTAMP` |

> ⚠️ `USER_PHONE_NUMBER` records **when** a number was linked but has no actor column; attribution here comes
> from correlating that timestamp with the signed-in booking that triggered it, not from a named-editor field.
