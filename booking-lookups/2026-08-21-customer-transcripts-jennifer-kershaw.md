# Customer Comms Transcripts — Jennifer (Jen) Kershaw

> ⚠️ **CONFIDENTIAL — CONTAINS CUSTOMER PERSONAL DATA (PII).**
> This record contains a customer name, phone numbers, email, booking reference and a
> summary of support conversations. Access is restricted to authorised AnyVan Privacy /
> Operations staff and must be handled in line with AnyVan's data protection policy and
> UK GDPR. Do not share outside the business. Note that anything committed here persists
> in git history.
>
> **Verbatim chat transcripts are deliberately NOT committed here** (see §6 Governance).
> The full author-labelled transcript export was delivered to the requester separately.

| | |
|---|---|
| **Record type** | Customer comms / transcript retrieval (privacy investigation) |
| **Date created** | 2026-08-21 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Data source** | Snowflake — `PRODUCTION` schema (read-only query) + AnyVan MCP |
| **Subject** | Jennifer Kershaw · `jen.lee27@hotmail.com` · `07359 196 589` |

---

## 1. Request

> "Find all Transcripts from WhatsApp & Live Chat for this Customer:
> Jennifer Kershaw / Jen.lee27@hotmail.com / 07359 196 589"

---

## 2. Identity resolved

| Field | Value |
|---|---|
| AnyVan User ID | `5993294` |
| Account name | "Jen" (signs off "Jen and John") |
| Email | `jen.lee27@hotmail.com` (agent re-confirmed in the 29 Jun chat) |
| Account phone | `+44 7772 342936` |
| Phone supplied by requester | `+44 7359 196589` |
| Booking | **AV 9446777** — Croft (WA3 7EN) → Leyland (PR25 4ZN), move 19 Jun 2026 |
| Account created | 2026-06-03 |

**Two phones, one customer.** The email is registered to the account holding
`447772342936`; the requester supplied `447359196589`. Both are the same person — the
`447359196589` chat is about the same booking and the agent confirmed the same email.
Always search **every** number, not just the account number.

---

## 3. Result

| Channel | Found | Detail |
|---|---|---|
| **WhatsApp** | **3 conversations** | `CHdc483ad8…` 12 Jun (Sophie AI only); `CH7b307c26…` 18–19 Jun (AI + agents Keeno Hendricks, Ayanda Mafani, Yoliswa Fetyu, Sally G); `CH47aa38f9…` 28–29 Jun from `447359196589` (agent Andrea Henniker, damage claim) |
| **Live Chat / webchat** | **None** | No Sophie webchat, no Twilio webchat, nothing in the live-chat bookings table. Legacy `LIVE_CHAT` table stopped recording 2025-05-22, before this account existed. |
| **Voice calls** | 4 (no transcript) | 3/18/19 Jun on booking 9446777. These were **CS/On-The-Day** calls, **not Jiminny sales calls** → no Jiminny transcript; no CS transcript segments surfaced (two were <10s / no talk time). |

**Notable content (for any complaint/claim context):** in the 18 Jun chat the customer
objects that she **was not told she was talking to AI** and the agent acknowledges the
AI bot mis-recorded the first-floor items (driving a disputed £18 access charge); the
29 Jun chat is a **damage-claim** follow-up where she'd waited >1 week with no claim form.

---

## 4. What we learned (why this was slower than it needed to be)

1. **The `anyvan-data` routing table is incomplete for transcripts.** It routes
   "Calls/voice/WhatsApp/comms" to `FACT_VOICE_ACTIVITY` / `FACT_WHATSAPP_ACTIVITY` —
   but those are **metadata only** (`FACT_WHATSAPP_ACTIVITY` comment: *"No message
   content or conversation transcript. This is metadata only."*). The **message bodies**
   live in `HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE`.
2. **The AnyVan MCP `get_conversation_transcript` is Jiminny CALL-only** (input =
   HubSpot `dealId`). It does **not** return WhatsApp or Live Chat. Don't reach for it
   for chat.
3. **Find chats by the customer's phone as the message AUTHOR, not via the participant
   table.** `TWILIO_CONVERSATION_PARTICIPANT.PARTICIPANT_IDENTITY` returned **0** matches;
   `TWILIO_CONVERSATION_MESSAGE.AUTHOR = 'whatsapp:+44…'` was the reliable finder.
4. **Author strings are %-encoded with `_` for `%`** and must be decoded to be readable
   (see §5.5).
5. **Don't substring-match an ID against phone digits.** `ILIKE '%5993294%'` false-matched
   an unrelated number containing that digit run. Reuse the last-10-digit phone rule.
6. **`LISTING_ID` + the booking reference in the message body are the cross-channel keys**
   to catch webchat that has no phone author.

---

## 5. Methodology / Learning (reusable) — retrieving ALL customer comms transcripts

Reuse the steps + templates below; swap the highlighted literals. Companion to the phone
→ booking methodology in `2026-08-18-phone-number-lookup-07497-700277.md`.

### 5.1 Where the comms data lives

| Data | Table | Notes |
|---|---|---|
| **WhatsApp + webchat message bodies** (source of truth) | `HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE` | `CONVERSATION_ID` (CH…), `AUTHOR`, `BODY`, `INDEX`, `CREATED_AT`. Join `TWILIO_CONVERSATION` (header/state) and `TWILIO_CONVERSATION_PARTICIPANT`. |
| WhatsApp **metadata** (no bodies) | `MART_SALES_OPS.PRODUCTION.FACT_WHATSAPP_ACTIVITY` | `CUSTOMERPHONENUMBER`, `TASKID` (WT…), team, listing, timings. Good for "did they contact us / which team". |
| Flattened **human-agent** chat transcript | `MART_SALES_OPS.PRODUCTION.CS_QA_CHAT_BASE` | `TRANSCRIPT_TEXT` ready-made, but only convos with ≥4 msgs **and** an `@anyvan.com` agent; `CUSTOMER_PHONE` can be null → not a reliable finder. |
| **Sophie WhatsApp** (AI) enriched | `MART_SALES_OPS.PRODUCTION.SOPHIE_CHATS_INCREMENTAL` | `CUSTOMERPHONENUMBER`, `CALLSID` (=CH…), sentiment/escalation. Sophie-routed only. |
| **Sophie Live Chat / webchat** enriched (has transcript) | `MART_SALES_OPS.PRODUCTION.SOPHIE_LIVE_CHAT_INCREMENTAL` | `CUSTOMER_NUMBER`, `CUSTOMER_NAME`, `CONVERSATION_SID`, `TRANSCRIPT_TEXT`, `LISTING_ID`. |
| **Call transcripts — Jiminny (sales)** | `HARMONISED.PRODUCTION.JIMINNY_CALL_TRANSCRIPT` (by `EVENT_ID`) + MCP `get_conversation_transcript(dealId)` | Link calls→listing via `HARMONISED.PRODUCTION.TWILIO_CALL_TO_LISTING_MAPPING`. |
| **Call transcripts — CS / On-The-Day** | `CONFORMED.PRODUCTION.CALL_TRANSCRIPT_SEGMENTS` / `CALL_TRANSCRIPT_CALLS` (durable) · `HARMONISED.PRODUCTION.EVENTS_CALL_TRANSCRIPTIONS` (~15-day retention) | Customer resolved in `CALL_TRANSCRIPT_CLASSIFIED` (uses reservation `normalized_customerphonenumber`, not `customer_phone`). |
| Call **metadata** (did a call happen?) | `CONFORMED.PRODUCTION.FCT_VOICE_INTERACTIONS` | `TWILIO_LISTING_ID`, direction, `TALK_TIME_SECS`, `CALLER_ROLE`, `CONFERENCE_ID`. |
| On-platform TP↔customer messages | `HARMONISED.PRODUCTION.MESSAGE` | Marketplace messaging, not chat/WhatsApp. |
| **Legacy** live chat | `HARMONISED.PRODUCTION.LIVE_CHAT` | **Stopped 2025-05-22** — irrelevant for post-2025 customers. |

### 5.2 Step 1 — resolve identity (get USER_ID + every phone + listings)

```sql
-- Swap the email / phone. Phone key = last 10 digits (see phone-lookup doc §5.3).
SELECT USER_ID, FULL_NAME, EMAIL_ADDRESS, PRIMARY_PHONE_NUMBER, SECONDARY_PHONE_NUMBER,
       SYSTEM_CREATED_DATE
FROM CONFORMED.PRODUCTION.DIM_USER_CUSTOMER
WHERE LOWER(EMAIL_ADDRESS) = LOWER('jen.lee27@hotmail.com')
   OR RIGHT(REGEXP_REPLACE(COALESCE(PRIMARY_PHONE_NUMBER,''),'[^0-9]',''),10)   = '7359196589'
   OR RIGHT(REGEXP_REPLACE(COALESCE(SECONDARY_PHONE_NUMBER,''),'[^0-9]',''),10) = '7359196589';
```
Collect **all** numbers: the account number(s) here **and** any number the requester gave
(they can differ — this customer's supplied number was not on the account).

### 5.3 Step 2 — find the chat conversations (by phone as AUTHOR)

```sql
-- Returns one row per conversation the customer authored in (WhatsApp = 'whatsapp:+44…').
SELECT conversation_id, MIN(created_at) first_msg, MAX(created_at) last_msg,
       COUNT(*) msgs, MIN(author) sample_author
FROM HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE
WHERE RIGHT(REGEXP_REPLACE(COALESCE(author,''),'[^0-9]',''),10) IN ('7772342936','7359196589')
GROUP BY conversation_id ORDER BY first_msg;
```
Catch webchat with **no phone author** by also sweeping by listing and by booking ref:
```sql
-- webchat linked to the booking
SELECT * FROM MART_SALES_OPS.PRODUCTION.SOPHIE_LIVE_CHAT_INCREMENTAL WHERE listing_id = 9446777;
-- any conversation whose body mentions the booking ref or email
SELECT DISTINCT conversation_id FROM HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE
WHERE REGEXP_REPLACE(body,'[^0-9]','') LIKE '%9446777%'
   OR LOWER(body) LIKE '%jen.lee27@hotmail.com%';
```

### 5.4 Step 3 — pull the transcript

```sql
SELECT conversation_id, index, created_at, author, body
FROM HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE
WHERE conversation_id IN ('CHdc483ad8…','CH7b307c26…','CH47aa38f9…')
ORDER BY conversation_id, index, created_at;
```

### 5.5 Author decoding (apply when rendering)

`AUTHOR` is %-encoded with `_` standing in for `%` (`_2E`→`.`, `_40`→`@`, `_20`→space):

| Author pattern | Who |
|---|---|
| `whatsapp:+44…` | **Customer** |
| the conversation SID itself (`CH…`) | Automated **bot menu / system** |
| `agent` | **Sophie** (AI assistant) |
| `firstname_2Elastname_40anyvan_2Ecom` | **Human agent** → `firstname.lastname@anyvan.com` |

### 5.6 Step 4 — calls (optional)

```sql
-- Did calls happen?
SELECT call_date_time, sys_source, call_direction, talk_time_secs, conference_id
FROM CONFORMED.PRODUCTION.FCT_VOICE_INTERACTIONS WHERE twilio_listing_id = 9446777;
-- Jiminny transcript for those calls (sales calls only)
WITH map AS (SELECT event_id FROM HARMONISED.PRODUCTION.TWILIO_CALL_TO_LISTING_MAPPING WHERE listing_id = 9446777)
SELECT j.* FROM HARMONISED.PRODUCTION.JIMINNY_CALL_TRANSCRIPT j JOIN map ON map.event_id = j.event_id;
```

### 5.7 Pitfalls

- **Metadata ≠ transcript** — `FACT_WHATSAPP_ACTIVITY` / `FACT_VOICE_ACTIVITY` have no bodies.
- **Participant table is unreliable for finding the customer** — identity was empty; use `AUTHOR`.
- **Never substring-match an ID vs phone digits** (`'%5993294%'` matched an unrelated phone). Use `RIGHT(…,10)`.
- **`CS_QA_CHAT_BASE.CUSTOMER_PHONE` / `EVENTS_CALL_TRANSCRIPTIONS` `customer_phone` are unreliable** — don't use as the finder.
- **Legacy `LIVE_CHAT` ended 2025-05-22** — "Live Chat" now means Twilio webchat.
- **Empty `body` rows** usually mean a media/screenshot attachment.

---

## 6. Governance notes

- Queries were **read-only** against Snowflake `PRODUCTION`; MCP calls were read-only.
- **PII minimisation:** this committed record holds identity + a conversation **inventory
  and summary** only. **Full verbatim chat logs were intentionally kept out of git** (they
  were delivered to the requester as a standalone export). Escalate to a redacted export
  rather than pasting raw transcripts into version control.
- Retain only as long as required for the investigation; redact/dispose per policy.

## 7. Suggested improvement to the central `anyvan-data` skill

The comms row in the `anyvan-data` routing table points only at the metadata facts. Suggest
adding a **transcript** line so future sessions skip the discovery cost:

> **Chat/WhatsApp/webchat transcripts (message bodies)** → `HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE` (find by `AUTHOR` phone; `FACT_WHATSAPP_ACTIVITY` is metadata only). **Call transcripts** → `JIMINNY_CALL_TRANSCRIPT` (sales) / `CALL_TRANSCRIPT_SEGMENTS` (CS).
