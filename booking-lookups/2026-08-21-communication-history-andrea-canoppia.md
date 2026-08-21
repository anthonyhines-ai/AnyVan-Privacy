# Communication History Lookup — Andrea Canoppia

> ⚠️ **CONFIDENTIAL — CONTAINS CUSTOMER PERSONAL DATA (PII).**
> This record contains a customer's name, phone number, email, home postcodes, account/booking
> IDs and the content of messages sent to them. Access is restricted to authorised AnyVan
> Privacy / Operations staff and must be handled in line with AnyVan's data protection policy
> and UK GDPR. Do not share outside the business. Note that anything committed here persists in
> git history.

| | |
|---|---|
| **Record type** | Communication-history lookup / privacy investigation (DSAR-style) |
| **Date created** | 2026-08-21 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Data sources** | HubSpot CRM (via MCP) + Snowflake `PRODUCTION` (read-only) |
| **Subject identifiers** | Name `Andrea Canoppia` · Phone `07986 908755` (`+447986908755`) · Email `canopss@gmail.com` |

---

## 1. Request

> "Locate all communication between this customer and AnyVan:
> Full Name: **Andrea Canoppia**; Contact Number: **07986 908755**; Email: **canopss@gmail.com**."

## 2. Identity resolution

A **single, unambiguous** customer matched on all three identifiers — no duplicate contacts or
accounts were found.

| System | Identifier | Value |
|---|---|---|
| HubSpot | Contact ID | **15139171** |
| Snowflake | Customer `USER_ID` | **3770834** |
| — | Name | Andrea Canoppia |
| — | Email | canopss@gmail.com |
| — | Phone | +447986908755 |
| — | Contact created | 2020-11-13 |
| — | Lifecycle stage | customer |

AnyVan-side numbers seen in the records (not the customer's own): inbound support line the
customer dialled **`+442086291363`**; dynamic call-tracking number shown to this customer
**`020 4587 9764` / `+442045879764`**; AnyVan WhatsApp business sender **`+447897012899`**.

### Associated bookings / quotes (context)

| HubSpot deal | Quote/prelisting | Type | Value | Created | Outcome |
|---|---|---|---|---|---|
| 61190469259 | 28091313 | Furniture | £310 | 2026-06-16 | **Won → paid booking, listing `9473099`** (Completed Paid) |
| 61171825802 | 28091294 | Removals | £330 | 2026-06-16 | Open quote — did not convert to a warehouse booking |
| 13123948394 | 14342690 | Furniture | £40 | 2023-04-24 | Old quote — did not convert |

The one confirmed paid job (**listing `9473099`**): Furniture, **N7 6RS → N8 7EB**, pickup date
2026-06-21, account 3770834. All located communications cluster around this June-2026 booking.

---

## 3. Result — communication timeline (all channels)

All times UTC. `[rec]` = call recording available on S3.

| # | When | Channel | Dir. | Detail |
|---|---|---|---|---|
| 1 | 2026-06-16 21:25 | Email | → cust | "AnyVan delivery - London prices from £335 🚚" (sent) |
| 2 | 2026-06-16 22:03 | Email | → cust | "Your AnyVan move from today 🏠" (sent) |
| 3 | 2026-06-17 11:19–11:27 | **Phone call** | cust → AV | Inbound, **7m30s**, agent **zante.petersen** `[rec]` |
| 4 | 2026-06-17 21:25 | Email | → cust | "Quick AnyVan follow up - London prices from £284 🚚" (sent) |
| 5 | 2026-06-17 22:04 | Email | → cust | "AnyVan removal quote follow-up 🏠 🚚" (sent/delivered) |
| 6 | 2026-06-18 17:06–17:08 | **Phone call** | cust → AV | Inbound, **2m29s**, agent **cadey.t** `[rec]` |
| 7 | 2026-06-18 17:13–17:22 | **Phone call** | cust → AV | Inbound, **8m59s**, agent **tashlyn.hass** `[rec]` |
| 8 | 2026-06-18 17:29 | WhatsApp | → cust | Booking confirmation from "David": N7 6RS → N8 7EB, Sat Jun 20, collection 10:00–16:00 (delivered) |
| 9 | 2026-06-20 07:03 | WhatsApp | → cust | Moving-day update: driver **Jasmit**, ETA 1–4PM, live tracking (**read**) |
| 10 | 2026-06-20 13:29–14:37 | **Phone call** | cust → AV | Inbound, **68m10s** (longest), agent **tashlyn.hass** `[rec]` |
| 11 | 2026-06-21 07:21 | Email | → cust | "Hooray, it's your AnyVan move today! 🚚" (delivered/sent; **opened** 07:42) |
| 12 | 2026-06-22 23:04 | WhatsApp | → cust | Post-move feedback request (delivered) |
| 13 | 2026-06-26 09:00 | WhatsApp | → cust | Loyalty: "15% OFF YOUR NEXT MOVE" (delivered) |
| 14 | 2026-06-26 09:05 | Email | → cust | "Andrea, we have one last thing for you…" (15% off) (sent) |

**Summary:** 4 inbound phone calls (all customer→AnyVan, all recorded), 4 outbound WhatsApp
messages (all AnyVan→customer), and ~6 outbound emails, all within **16–26 June 2026**. Plus
lifetime marketing e-mail activity since account creation (see §4.3).

---

## 4. Per-channel detail

### 4.1 Phone calls — `HARMONISED.PRODUCTION.TWILIO_CALL`

All four are **inbound, completed**, from `+447986908755` to the support line `+442086291363`
(Twilio Flex). No AI agent (Amy / Sophie) handled any of them; there are **no legacy Aircall**
records for this number.

| Twilio Call SID | Start (UTC) | Talk time | Agent | Recording ID (S3) |
|---|---|---|---|---|
| CA753c5c3b5a64d4015deaf4f2deb37f87 | 2026-06-17 11:19:36 | 7m30s | zante.petersen | RE19f5614dc7b9901916040fb1028f35fc |
| CA1deb51b81cd25b9f99a5bb092f4d8dac | 2026-06-18 17:06:10 | 2m29s | cadey.t | REa8c5ab843168dfd74d58cc124a642bc8 |
| CA46b031bd772b36503cb8ef12aa97fd55 | 2026-06-18 17:13:16 | 8m59s | tashlyn.hass | RE806ccf6b2e7dfddc79d0d162f14879dc |
| CA391ad5253931cb396e65fce68874278d | 2026-06-20 13:29:12 | 68m10s | tashlyn.hass | RE43a6fb6a7b51ce68d9864b9c69506f85 |

- Recordings live under
  `https://anyvan-twilio-recordings.s3.eu-west-1.amazonaws.com/<TWILIO_ACCOUNT_SID>/<RECORDING_ID>`
  (Twilio Account SID redacted from this record; retrieve it from the HubSpot call engagement or
  Twilio console when the audio is needed).
- **No text transcripts exist** for these calls — they are Twilio Flex recordings, not Jiminny
  calls (`EVENTS_CALL_TRANSCRIPTIONS` / `JIMINNY_CALL_TRANSCRIPT` returned nothing for these
  recordings). The audio is the only record of call content.
- Mirrored as HubSpot CALL engagements (IDs 111172336427, 111298822553, 111295999928,
  111430426253).

### 4.2 Messaging — `HARMONISED.PRODUCTION.TWILIO_MESSAGE` (WhatsApp)

Four **outbound** WhatsApp messages from AnyVan (`whatsapp:+447897012899`) to
`whatsapp:+447986908755`. **No inbound replies** from the customer exist in any messaging table
(`TWILIO_MESSAGE`, `TWILIO_CONVERSATION_MESSAGE`, `TWILIO_CONVERSATION_PARTICIPANT`,
`EVENTS_MESSAGING_MESSAGE` all returned no inbound / no two-way thread). Full message bodies are
retained in Snowflake; the timeline above summarises each.

### 4.3 Email

- **Itemised sends (June 2026)** — `HARMONISED.PRODUCTION.EVENTS_EMAIL`, source = HubSpot: the 6
  emails listed in the timeline (quote follow-ups, moving-day, loyalty). The customer **opened**
  only the "Hooray, it's your AnyVan move today!" email (2026-06-21 07:42).
- **Lifetime marketing (HubSpot contact counters):** 8 marketing emails sent, first
  2020-11-13, last 2026-06-26 ("FURN - Loyalty Campaign - Customer UK - 15% Discount - May 26"),
  1 opened, 1 click recorded. Older (pre-2026) marketing sends are reflected only in these
  lifetime counters, not itemised in `EVENTS_EMAIL`.
- **No 1:1 / inbound emails**: no HubSpot EMAIL engagements are associated with the contact or
  its deals — i.e. no evidence the customer emailed AnyVan directly, and no agent 1:1 emails.

### 4.4 Channels checked with NO matching records

For completeness, the following were searched and returned **nothing** for this customer:

- **Support tickets** — `FRESHDESK_TICKET` (table empty).
- **AI voice / chat** — Amy (`EVENTS_AMY_CALL`) and Sophie (`EVENTS_SOPHIE_CALL`,
  `EVENTS_SOPHIE_CHAT`) — no interactions.
- **Call-back requests** — `EVENTS_CALL_ME_BACK` — none.
- **Reviews & feedback** — no Trustpilot review from this customer
  (`TRUSTPILOT_PRIVATE_REVIEWS` matches for "Andrea C…" are **different people** — Clarke,
  Costa, Corra, etc. — none is Canoppia); no listing feedback (`HISTORIC_LISTING_FEEDBACK` for
  listing 9473099); no CSAT/NPS survey response (`FCT_CALL_CUSTOMER_SATISFACTION`).
- **HubSpot** — no NOTE, TASK, MEETING or SMS/WhatsApp `COMMUNICATION` objects on the contact.

---

## 5. Methodology / sources (reusable)

- **Identity:** HubSpot `search_crm_objects` on CONTACT by email/name → contact 15139171;
  Snowflake `CONFORMED.PRODUCTION.DIM_USER_CUSTOMER` by email + phone (last-10-digit match) →
  `USER_ID` 3770834. Bookings via the README's Template A (phone across customer / collection /
  delivery roles) → listing 9473099.
- **Phone normalisation:** `RIGHT(REGEXP_REPLACE(num,'[^0-9]',''),10) = '7986908755'` — matches
  every stored format (`07986 908755`, `+447986908755`, `447986908755`, `whatsapp:+4479869…`).
- **Communication tables queried (`HARMONISED.PRODUCTION` unless noted):**
  `TWILIO_CALL`, `TWILIO_MESSAGE`, `TWILIO_CONVERSATION_MESSAGE`,
  `TWILIO_CONVERSATION_PARTICIPANT`, `EVENTS_MESSAGING_MESSAGE`, `EVENTS_EMAIL`,
  `EVENTS_SOPHIE_CHAT`, `EVENTS_SOPHIE_CALL`, `EVENTS_AMY_CALL`, `EVENTS_CALL_ME_BACK`,
  `EVENTS_CALL_TRANSCRIPTIONS`, `AIRCALL_CALL`, `TRUSTPILOT_PRIVATE_REVIEWS`,
  `HISTORIC_LISTING_FEEDBACK`, `FRESHDESK_TICKET`, and
  `CONFORMED.PRODUCTION.FCT_CALL_CUSTOMER_SATISFACTION`. Match keys: phone (last-10),
  email, `USER_ID` 3770834, HubSpot contact 15139171, listing 9473099, prelistings
  28091294 / 28091313 / 14342690, and the four Twilio call SIDs / recording IDs.
- **HubSpot (via MCP):** contact + deal properties; EMAIL / CALL / NOTE / TASK / MEETING_EVENT
  engagements associated with the contact and the three deals.

### Caveats

- Call **content** is available only as audio (S3); no machine transcripts exist.
- Communications are overwhelmingly **outbound** (AnyVan → customer, automated WhatsApp + email).
  The customer's own contributions to the record are the **4 inbound phone calls** (audio only).
- Marketing-email history before 2026 is available only as HubSpot lifetime counters.
- Searches are not territory-restricted; only the UK `en-gb` account matched.

## 6. Governance notes

- All Snowflake queries were **read-only** against `PRODUCTION`.
- This document contains PII — retain only as long as required for the investigation and
  redact/dispose per policy when no longer needed. Call recordings remain in the Twilio/S3
  store and are subject to the same policy.
