# Methodology — Communication-history / DSAR lookup (reusable)

How to locate **all communication** between a customer and AnyVan across every channel. This is
the companion to the booking-lookup methodology in
`2026-08-18-phone-number-lookup-07497-700277.md` — that one finds *bookings*; this one finds
*conversations*. Distilled from the Andrea Canoppia lookup (2026-08-21).

> Handle per the PII + secret-redaction rules in `/CLAUDE.md`. All Snowflake access is read-only.

---

## 0. Inputs & identity resolution

Start from whatever identifiers you're given (name / phone / email) and resolve to stable keys
**before** searching channels:

1. HubSpot `search_crm_objects` on **CONTACT** by email → name → phone → **HubSpot contact id**
   and its **associated deals** (deal name = `<Type> - <prelistingId> / £<price>`).
2. `CONFORMED.PRODUCTION.DIM_USER_CUSTOMER` by email + phone (last-10) → **`USER_ID`**.
3. Bookings via Template A in the booking-lookup doc → **`LISTING_ID`(s)** (paid jobs only) and
   the **prelisting id(s)** from the deals.

You then have the full key-set to fan out with: **phone (last-10), email, `USER_ID`, HubSpot
contact id, listing id(s), prelisting id(s)**, and later the **Twilio call SIDs / recording IDs**.

Remember **prelisting id ≠ listing id** (see `/CLAUDE.md`), and that most channels key off a
subset of these — the map below names which.

---

## 1. Channel → table map

The core deliverable. All tables are in `HARMONISED.PRODUCTION` unless noted. Match on the
right-hand key(s).

| Channel | Table(s) | Match key(s) |
|---|---|---|
| Voice calls (current) | `TWILIO_CALL` | `"FROM"` / `"TO"` (last-10) |
| Call → listing link | `TWILIO_CALL_TO_LISTING_MAPPING` | `EVENT_ID` (call SID), `LISTING_ID`, `PRE_LISTING_ID` |
| Voice calls (legacy) | `AIRCALL_CALL` | `RAW_DIGITS` (last-10) |
| Recording → transcript | `EVENTS_CALL_TRANSCRIPTIONS` | `RECORDING_ID` (`RE…`) |
| Jiminny transcripts | `JIMINNY_CALL_METADATA`, `JIMINNY_CALL_TRANSCRIPT` | `EVENT_ID`; or AnyVan MCP `get_conversation_transcript(dealId)` |
| AI voice agents | `EVENTS_AMY_CALL`, `EVENTS_SOPHIE_CALL` | `CALL_SID`, `CALLER_ID`, `LISTING_ID` |
| Call CSAT / NPS | `CONFORMED.PRODUCTION.FCT_CALL_CUSTOMER_SATISFACTION` | `CONTACT_ID`, `LAST_TWILIO_CALL_SID`, `LISTING_ID_ASSOCIATED`, `PRE_LISTING_ID_ASSOCIATED` |
| SMS / WhatsApp (one-way) | `TWILIO_MESSAGE` | `"FROM"` / `"TO"` (last-10); WhatsApp stored as `whatsapp:+44…` |
| Two-way conversations | `TWILIO_CONVERSATION_MESSAGE` + `TWILIO_CONVERSATION_PARTICIPANT` | `PARTICIPANT_IDENTITY`, `AUTHOR` |
| Transactional messaging | `EVENTS_MESSAGING_MESSAGE` | `RESOLVED_USER_PHONE` / `RESOLVED_USER_EMAIL` / `USER_ID` |
| Email events (itemised) | `EVENTS_EMAIL` | `EMAIL_ADDRESS` |
| Email (HubSpot wide) | `HUBSPOT_EVENTS_EMAIL`, `HUBSPOT_EMAIL_CAMPAIGNS` | email |
| AI chat (Sophie) | `EVENTS_SOPHIE_CHAT` | `LISTING_ID`, `CONVERSATION_SID` |
| Call-back requests | `EVENTS_CALL_ME_BACK` | `PRE_LISTING_ID`, `CALLBACK_PRE_LISTING_HASH` |
| Support tickets | `FRESHDESK_TICKET` | (empty as of 2026-08 — check anyway) |
| Reviews | `TRUSTPILOT_PRIVATE_REVIEWS` | `CONSUMER_DISPLAY_NAME` (fuzzy — verify, see §4) |
| Listing feedback | `HISTORIC_LISTING_FEEDBACK` | `LISTING_ID` |

The schema evolves — when in doubt, discover with a per-DB `INFORMATION_SCHEMA` sweep (§3.5),
filtering names on `%TWILIO%|%MESSAGE%|%EMAIL%|%CALL%|%CHAT%|%TICKET%|%REVIEW%|%FEEDBACK%`.

---

## 2. HubSpot (CRM) side

- Engagement objects: `CALL`, `EMAIL`, `NOTE`, `TASK`, `MEETING_EVENT`. **No** `COMMUNICATION`
  object — SMS/WhatsApp are **not** in HubSpot; find them in Twilio/Snowflake.
- Search each engagement type associated with **both** the contact **and** its deals
  (`filterGroups[].associatedWith`); some engagements link to only one. (In the Canoppia case, one
  of four calls was linked to the contact but no deal.)
- Twilio calls appear as `CALL` engagements titled "Twilio flex call …" carrying
  `hs_call_recording_url` (S3), `hs_call_from_number` / `hs_call_to_number`, disposition, duration.
- Contact-level marketing counters (`numberOfMarketingEmailsSent` / `…Opened` / `…Clicked`, first
  / last send dates) are a **lifetime** summary that can exceed what `EVENTS_EMAIL` itemises —
  pre-current-year sends may appear only in these counters.

---

## 3. Query templates

Swap the highlighted literals. Phone key = last 10 digits (e.g. `07986 908755` → `7986908755`).

### 3.1 Calls
```sql
SELECT ID, DIRECTION, STATUS, "FROM", "TO", START_TIME, END_TIME, DURATION, QUEUE_TIME
FROM HARMONISED.PRODUCTION.TWILIO_CALL
WHERE RIGHT(REGEXP_REPLACE(COALESCE("FROM",''),'[^0-9]',''),10)='7986908755'
   OR RIGHT(REGEXP_REPLACE(COALESCE("TO",''),'[^0-9]',''),10)='7986908755'
ORDER BY START_TIME;
```

### 3.2 SMS / WhatsApp (bodies included)
```sql
SELECT ID, DATE_SENT, DIRECTION, STATUS, "FROM", "TO", BODY
FROM HARMONISED.PRODUCTION.TWILIO_MESSAGE
WHERE RIGHT(REGEXP_REPLACE(COALESCE("FROM",''),'[^0-9]',''),10)='7986908755'
   OR RIGHT(REGEXP_REPLACE(COALESCE("TO",''),'[^0-9]',''),10)='7986908755'
ORDER BY DATE_SENT;
```

### 3.3 Transactional messaging (phone / email / user)
```sql
SELECT EVENT_TIMESTAMP, CHANNEL, CHANNEL_RECIPIENT, TEMPLATE_KEY, RENDERED_SUBJECT,
       LEFT(MESSAGE,500) AS MESSAGE_PREVIEW, RESOLVED_USER_EMAIL, RESOLVED_USER_PHONE, USER_ID
FROM HARMONISED.PRODUCTION.EVENTS_MESSAGING_MESSAGE
WHERE LOWER(COALESCE(RESOLVED_USER_EMAIL,''))='canopss@gmail.com'
   OR RIGHT(REGEXP_REPLACE(COALESCE(RESOLVED_USER_PHONE,''),'[^0-9]',''),10)='7986908755'
   OR USER_ID='3770834'
ORDER BY EVENT_TIMESTAMP;
```

### 3.4 Email (aggregate the event stream to distinct sends)
```sql
SELECT SOURCE, EMAIL_EVENT_TYPE, EMAIL_SUBJECT,
       COUNT(*) AS n, MIN(EVENT_TIMESTAMP) AS first_ts, MAX(EVENT_TIMESTAMP) AS last_ts
FROM HARMONISED.PRODUCTION.EVENTS_EMAIL
WHERE LOWER(EMAIL_ADDRESS)='canopss@gmail.com'
GROUP BY 1,2,3 ORDER BY last_ts;
```

### 3.5 Discover tables / columns (ACCOUNT_USAGE is not authorised)
```sql
SELECT TABLE_NAME, ROW_COUNT FROM HARMONISED.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA='PRODUCTION' AND TABLE_NAME ILIKE '%TWILIO%' ORDER BY TABLE_NAME;

SELECT COLUMN_NAME, DATA_TYPE FROM HARMONISED.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='PRODUCTION' AND TABLE_NAME='TWILIO_MESSAGE' ORDER BY ORDINAL_POSITION;
```

Reuse the booking-lookup doc's **Template A** to link phone → customer / collection / delivery
across listings, and **Template B** for postcode + date.

---

## 4. Caveats (learned)

- **Not all calls have transcripts.** Twilio Flex calls have **S3 audio only** —
  `get_conversation_transcript` and `EVENTS_CALL_TRANSCRIPTIONS` return nothing for them. Only
  **Jiminny** calls carry machine transcripts. Say so explicitly: the audio is the only record of
  call content.
- **Redact the Twilio Account SID** from any recording URL before committing (GitHub push
  protection blocks `AC…`). Keep the `RECORDING_ID` — it's enough to re-fetch the audio.
- **Trustpilot name matching is noisy.** `CONSUMER_DISPLAY_NAME ILIKE 'Andrea C%'` returned many
  *different* people (Clarke, Costa, Corra…). Never attribute a review on name alone — corroborate
  with listing/date, or treat as "no match".
- **Direction skew.** Most "communication" is **outbound automation** (WhatsApp + email). The
  customer's own inbound contributions are usually the **phone calls** (audio only). Flag this so
  the reader doesn't mistake it for a two-way text thread.
- Searches are **not** territory-restricted; add a `LISTING_TERRORITY` filter only if required.
- Reserved words `"FROM"` / `"TO"`; the `LISTING_TERRORITY` typo; and the last-10 phone rule — all
  as noted in `/CLAUDE.md`.

---

## 5. Record structure (what to write)

One dated record under `booking-lookups/` with:
1. **Request** (verbatim) + confidentiality header.
2. **Identity resolution** — the resolved key-set as a table; call out duplicates or "single,
   unambiguous match".
3. **Cross-channel timeline** — every communication, all channels, chronological, UTC.
4. **Per-channel detail** — including a **"channels checked with NO records"** section (proves the
   search was exhaustive, not just lucky).
5. **Methodology / sources** — the exact tables + keys queried (so the next person can rerun).
6. **Governance** — read-only confirmation + PII retention note.
