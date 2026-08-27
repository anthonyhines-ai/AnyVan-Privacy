# SAR Comms Lookup Reference — Calls, WhatsApp & Live Chat

> **Purpose:** the "other half" of the communications backbone — how to find a customer's **phone calls (with recordings), 2-way WhatsApp, and live-chat** for a SAR/DSR, starting from a **Freshdesk ticket** (or an email/phone/listing). Companion to [`customer-communications-mapping.md`](customer-communications-mapping.md) (email / SMS / automated WhatsApp / marketing) and consumed by [`dsr-privacy-request-workflow-design.md`](dsr-privacy-request-workflow-design.md).
>
> **⚠️ Provenance:** the original `SAR-Comms-Lookup-Reference.md` from the July 2026 audit was **not available in this repo** when this was written. This version is **reconstructed and re-validated against live Snowflake on 2026-08-19**. Where a convention could not be verified in-warehouse (e.g. the exact Flex deep-link format, the historic author-classification labels) it is marked **[confirm]** — reconcile with the original if it is exported.
>
> All tables below are in `HARMONISED.PRODUCTION` / `CONFORMED.PRODUCTION` (workflow-system allowed scope).

---

## 1. Scope

| In scope here | Covered in `customer-communications-mapping.md` |
|---|---|
| Voice calls + **recordings** (Aircall & Twilio) | Transactional email (body) |
| 2-way WhatsApp (CS/bot conversations) | SMS body |
| Live chat | Automated WhatsApp intro/day-of |
| Author/channel classification | HubSpot marketing email |

A **complete** SAR unions both documents.

---

## 2. Lookup flow from a Freshdesk ticket

A DSR/privacy Freshdesk ticket carries the requester's **email**, often a **phone**, and sometimes a **booking ref** (`AV#######`). Resolve to warehouse keys, then fan out per channel:

```
Freshdesk ticket
  → requester_email / phone / AV{listing_id}
    → CONFORMED.PRODUCTION.DIM_USER_CUSTOMER (by EMAIL_ADDRESS)  → USER_ID, PRIMARY_PHONE_NUMBER
    → CONFORMED.PRODUCTION.MASTER_LISTING     (by LISTING_ID)    → LISTING_USER_ID
    → HARMONISED.PRODUCTION.USER_PHONE_NUMBER → PHONE_NUMBER     → all FULL_NUMBERs
  → calls / whatsapp / chat filtered by phone (+ date range from the request)
```

The identity resolution SQL is in `customer-communications-mapping.md` §2. **Resolve every phone the subject has** before querying calls — a call may be on a secondary number.

---

## 3. Phone-number resolution & formats

- Primary: `DIM_USER_CUSTOMER.PRIMARY_PHONE_NUMBER` / `SECONDARY_PHONE_NUMBER` (already-resolved digits).
- All numbers: `USER_PHONE_NUMBER (USER_ID, PHONE_NUMBER_ID)` → `PHONE_NUMBER (PHONE_NUMBER_ID → FULL_NUMBER, NATIONAL_NUMBER)`.
- **Formats vary by source — normalise before matching:**
  - `PHONE_NUMBER.FULL_NUMBER`: intl **without `+`** → `447739058471`.
  - `TWILIO_MESSAGE."TO"/"FROM"`: `whatsapp:+44…` or `+44…` → match on trailing 9–10 digits (`LIKE '%739058471'`).
  - `AIRCALL_CALL.RAW_DIGITS`: customer phone as dialled.
  - `TWILIO_EVENTS_TASKROUTER_RESERVATIONS.NORMALIZED_CUSTOMERPHONENUMBER`: E.164-normalised — the **reliable** Twilio-side customer number.
- Match on the **trailing 9–10 digits** to bridge formats; never assume identical strings.

---

## 4. Calls & recordings — two systems

> **⚠️ Verified 2026-08-19:** AnyVan runs **two** telephony systems. `TWILIO_CALL`, `FCT_VOICE_INTERACTIONS`, and `FCT_TWILIO_CALL_METRICS` contain **no recording URL/SID**. `FCT_VOICE_INTERACTIONS` was **flagged unreliable by the data team** — do not use it as the call spine.

### 4.1 Aircall — recording URL available in-warehouse ✅
`HARMONISED.PRODUCTION.AIRCALL_CALL`
- `RECORDING` — URL/identifier for the audio (comment: *"the URL or identifier for the audio recording of the call, if available"*). ~70% of rows populated; coverage **2023-05-11 → today**.
- `RAW_DIGITS` — customer phone (match here). `STARTED_AT` / `ANSWERED_AT` / `ENDED_AT` are **TEXT** → wrap in `TRY_TO_TIMESTAMP(...)`. Also `DIRECTION`, `SID`, `USER_ID`.

```sql
SELECT SID, DIRECTION, RECORDING,
       TRY_TO_TIMESTAMP(STARTED_AT) AS started_at
FROM HARMONISED.PRODUCTION.AIRCALL_CALL
WHERE RIGHT(REGEXP_REPLACE(RAW_DIGITS,'[^0-9]',''), 9) = RIGHT(:phone_digits, 9)
  AND TRY_TO_TIMESTAMP(STARTED_AT)::date BETWEEN :from_date AND :to_date
ORDER BY started_at;
```
- **[confirm]** at build time whether `RECORDING` is a directly-playable HTTPS URL or an Aircall id needing the Aircall API (inspect one non-PII value).

### 4.2 Twilio — Recording SID only → Flex download ⚠️
No warehouse URL. Get the **Recording SID**, then retrieve via Flex.
- SID: `HARMONISED.PRODUCTION.TWILIO_EVENTS.RECORDINGSID` (also on `TWILIO_EVENTS_ARCHIVED`, `TWILIO_EVENTS_TASKROUTER_TASKS`). **Sparse** (only recording/call events carry it).
- **Reliable customer match:** `HARMONISED.PRODUCTION.TWILIO_EVENTS_TASKROUTER_RESERVATIONS.NORMALIZED_CUSTOMERPHONENUMBER` + `EVENTTIMESTAMP` (the direct call-table phone fields were flagged unreliable — often the worker's number). Hop reservation → task/conference → the recording SID.
- Amy (AI voice agent): `EVENTS_AMY_CALL.RECORDING_ID` / `AI_AMY_EVENTS.RECORDING_ID` — SIDs only.

**Officer retrieval runbook (v1 — the human-in-the-loop step):**
1. Workflow surfaces, per Twilio call: `recording_sid`, call timestamp, direction, matched number.
2. Officer opens the recording in **Twilio Flex** (Flex Insights / the Console call-recordings log). **[confirm]** exact Flex deep-link format — the July audit may have captured it; otherwise the media resource is `https://api.twilio.com/2010-04-01/Accounts/{AccountSid}/Recordings/{RecordingSid}.mp3` (auth-gated).
3. Use Flex's **"copy link for download"** → download the audio file.
4. **Attach the downloaded file to the Freshdesk ticket** for the SAR package. The customer receives the **file**, never the login-gated Flex/Twilio link.

*(Later enhancement: an external step that calls the Twilio Recordings API with the SID + Twilio credentials to mint the file automatically — deferred; see the workflow-design doc.)*

---

## 5. 2-way WhatsApp & live chat — `TWILIO_CONVERSATION_MESSAGE`

`HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE`
- Columns: `AUTHOR`, `BODY`, `CONVERSATION_ID`, `CREATED_AT` (`TIMESTAMP_TZ`), `PARTICIPANT_ID`, `SERVICE_ID`, `ID`.
- Tie to the subject via `AUTHOR` (identity/phone string) or resolve through `TWILIO_CONVERSATION_PARTICIPANT`.
- **Coverage caveat:** rows before **~2026-05-01** come from legacy Fivetran; after, from the Kinesis stream.

### Author / channel classification (reconstructed — **[confirm]** against the original)
`AUTHOR` distinguishes who sent each message; classify each row so the SAR pack reads as a conversation:

| `AUTHOR` shape | Classify as |
|---|---|
| `whatsapp:+44…` / a customer phone/identity | **Customer** (inbound) |
| An agent identity / `@anyvan.com` handle | **CS agent** (outbound) |
| A bot identity (e.g. `Sophie`) | **Automated/bot** |

Group by `CONVERSATION_ID`, order by `CREATED_AT`, label direction from the classification. For SAR, include the customer's own messages **and** AnyVan's replies (both are the subject's data / about the subject); **flag any third-party PII** in a thread for redaction before release.

---

## 6. Live chat (LiveChat.com)

- In-warehouse coverage is **metadata-level**; **message bodies before ~April 2026 are not in Snowflake**.
- For full transcripts pre-Apr-2026, pull from the **LiveChat.com platform** directly (manual export) and attach to the SAR pack.
- **[confirm]** the exact in-warehouse live-chat table name against `information_schema` at build (search `%LIVE_CHAT%` / `%LIVECHAT%`).

---

## 7. Cross-references
- [`customer-communications-mapping.md`](customer-communications-mapping.md) — email / SMS / automated WhatsApp / marketing + identity resolution SQL.
- [`dsr-intake-form-handoff.md`](dsr-intake-form-handoff.md) — intake form, request types, JSON payload.
- [`dsr-privacy-request-workflow-design.md`](dsr-privacy-request-workflow-design.md) — the automation.

*Reconstructed 2026-08-19 and validated against live Snowflake; merge with the original audit reference if exported.*
