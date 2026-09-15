# Interaction Hub — Call Transcripts: Matching, Coverage & In-Hub Viewer

> ℹ️ **INTERNAL — no customer data in this file.** It documents transcript *coverage*,
> join keys, and a design for viewing/exporting call transcripts. Verbatim transcript
> content is **not** stored here or in the dashboard HTML — it is read live from Snowflake
> and, for a data-subject, delivered as a separate redacted export (see §7).

| | |
|---|---|
| **Record type** | Dashboard / data-pipeline diagnosis + solution design |
| **Date created** | 2026-09-15 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Data source** | Snowflake PRODUCTION (read-only); AV Dashboards queries |
| **Subject** | Interaction Hub — phone-call transcript view, speaker split, in-call search |
| **Status** | Design agreed; hub UI + SQL staged in this PR; queue-enablement handoff open |

---

## 0. TL;DR
- **Transcripts with speaker labels already exist** in the warehouse (`CONFORMED.PRODUCTION.CALL_TRANSCRIPT_*`, live since 2026-07-20, ~2.3–2.6k calls/day, whisper-large-v3, dual-channel). `SPEAKER` is pre-resolved to **AGENT / CUSTOMER** — no diarisation guesswork needed.
- **"All our calls are transcribed" is not yet true.** On *answered* calls (last 7d) only ~23% carry a transcript. It is a **queue-coverage gap, not a broken join**: service/ops teams are broadly on (CS 78%, OTD 71%), **Sales / Lead-Gen / inbound & outbound sales lines are effectively off (~0–4%)** — the very calls a booking dispute turns on.
- **The join is solved:** `FCT_TWILIO_CALL_METRICS.WORKERCALLSID = CALL_TRANSCRIPT_*.CALL_SID` (agent leg) carries 100% of what's matchable; the customer-leg key adds nothing.
- **Bonus:** the same pipeline lands the Twilio `RE...` recording sid, so the long-standing admin **"Listen to Recording"** gap (see `2026-08-26-call-recording-playback-diagnosis.md`) is now fixable for transcribed calls with a query edit — no new pipeline.
- **Two tracks, agreed in parallel:** (A) ship the in-hub viewer; (B) hand off queue-enablement so coverage → ~100%.

---

## 1. What was asked
1. On opening a call, show **Transcription available / unavailable**, and if available a **View transcription** option.
2. **Categorise who is speaking** (agent vs customer).
3. **Soft search** within a call — e.g. was "floor(s)" discussed, by whom, or not at all.
4. **Download**, split by customer/admin, with non-subject PII (agent name, etc.) blanked for a customer/SAR copy — same discipline as call-recording SAR delivery.

---

## 2. Coverage diagnosis (read-only, 7-day window)

Answered Twilio voice calls (`TALKTIME > 0`) matched to a transcript, by team:

| Band | Teams (match %) |
|---|---|
| Broadly on | Customer Service 78% · TPSE 75% · On The Day 71% · Spain CS 69% · AVB Ops 61% · France CS 55% |
| Partial | Allocations 54% · Partner Success 54% · Spain Transport 54% · anyvan.com 44% · Service Incidents 44% · anyvan.de 44% · Storage 36% · France Transport 32% |
| **Effectively OFF** | **Inbound Team 3.6% · France V2 Sales 5.9% · Spain Inbound 3.3% · Spain Sales OB 1.5% · France V4 Sales 1.3% · Spain Lead Gen 1.0% · Outbound Over 700 0.9% · Lead Gen 0.8% · Outbound Under 700 0.3%** |

Headline numbers (7d): 75,088 conferences → 64,156 answered → **14,493 (≈23%) transcribed**; ~49,400 answered calls/week have no transcript. Reverse check: 86% of transcripts join back to the call table; ~14% belong to calls outside `FCT_TWILIO_CALL_METRICS` (likely Aircall / other legs).

**Two conclusions:** (a) sales/lead-gen/telephony queues aren't wired to the transcription event; (b) even "on" teams miss ~1 in 4 (recording not triggered, STT failures, very short calls).

---

## 3. Matching / join spec (canonical)

```sql
-- agent leg carries the match; customer leg adds nothing (verified 7d)
FCT_TWILIO_CALL_METRICS.WORKERCALLSID  =  CALL_TRANSCRIPT_CALLS.CALL_SID   (= '<hub row>.INTERACTION_ID')
-- transcript grain is RECORDING_ID; per-utterance detail:
CALL_TRANSCRIPT_SEGMENTS   (RECORDING_ID, SEGMENT_INDEX, SPEAKER, SEG_START, SEG_END, SEGMENT_TEXT)
CALL_TRANSCRIPT_CLASSIFIED (RECORDING_ID, AGENT_NAME, CALL_DIRECTION_FACT, …)   -- resolved role/name + direction
```
- Order utterances by `SEG_START` (the segment array is **not** chronological — table comment).
- `RECORDING_ID` is a Twilio `RE...` sid ⇒ also builds the recording proxy URL `https://twilio-recordings.anyvan.com/recordings/{RE...}`.
- Transferred/multi-leg calls: prefer keying the viewer on `RECORDING_ID` (the hub row now carries it) to avoid interleaving two legs.

Implemented in `sql/interaction_hub_calls.sql` (revised) + `sql/interaction_hub_call_transcript.sql` (new) + `sql/interaction_hub_phone_lookup.PATCH.md`.

---

## 4. Speaker attribution
- **Primary:** `CALL_TRANSCRIPT_SEGMENTS.SPEAKER` is already `AGENT` / `CUSTOMER` (dual-channel, ~50/50 split observed) — used directly for the bubbles.
- **Deterministic cross-check (Ops rule):** `CALL_DIRECTION_FACT` (populated; 24 nulls in 30d) —
  **inbound** = customer called AnyVan (caller = customer); **outbound** = AnyVan called customer (caller = agent). Surfaced as a context line and used to sanity-check the channel mapping. This removes reliance on label-confidence for the ambiguous minority.

---

## 5. Enablement handoff — close the coverage gap (Track B)
**Goal:** every answered customer call transcribed, so "not found" in search reliably means "not discussed."

**Owner to confirm:** Sales Ops / Data Eng — `CALL_TRANSCRIPT_*` is "Sales Ops (Call Transcript Analysis)"; voice data owner **Dylan Stemmet**, contact-centre business owner **Gareth Farquharson** (per table comments). The transcription is driven by the `AGENT_CALL_TRANSCRIBED` tracking-api event (`HARMONISED.PRODUCTION.EVENTS_CALL_TRANSCRIPTIONS`).

**Asks:**
1. Enable call transcription on the **Sales, Lead-Gen and inbound/outbound sales** Twilio queues (highest-value, currently ~0–4%).
2. Investigate the ~25% miss inside "on" teams (recording-not-started vs STT failure vs sub-threshold duration).
3. Confirm whether the ~14% of transcripts outside `FCT_TWILIO_CALL_METRICS` are Aircall — if so, add an Aircall spine so those calls are reachable from the hub.
4. Publish an expected coverage %/SLA so the hub can show a truthful availability rate.

---

## 6. Hub UI spec (Track A — in this PR)
On expanding a call:
- **Status chip:** `📝 Transcription available` / `🔒 Transcription unavailable` (gated on `TRANSCRIPT_AVAILABLE`).
- **View Transcription** (lazy-loads `interaction_hub_call_transcript`): agent/customer bubbles, colour-coded, timestamped; a direction context line (inbound/outbound).
- **Search within call:** highlights + filters matching utterances; shows a match count; when a term isn't found it states explicitly *"not found ≠ not discussed"* if the call is only partially transcribed — guards against mis-use in disputes.
- **Download:** internal (full) and **customer copy** (agent identifiers generalised to "ANYVAN AGENT", card-like digit runs masked) — see §7.
- **Admin "Listen to Recording"** now lights up for transcribed admin calls (proxy URL from `RECORDING_ID`).

Graceful degradation: if the transcript query isn't deployed or returns nothing, the pane shows "unavailable" rather than erroring.

---

## 7. Redaction / SAR export design
Two audiences, one source:
- **Internal (ops/dispute):** full transcript, agent named, speaker-split. Access is the existing dashboard auth.
- **Customer / SAR copy:** the data subject may receive **their** call, but third-party / non-subject PII is minimised —
  - agent name & email → generalised label ("ANYVAN AGENT"); *(deterministic — we know the agent)*;
  - card-like digit sequences (13–16 digits) → masked *(regex; Twilio should pause recording during card capture, but spoken digits can still land)*;
  - **other third-party PII in free speech** (a neighbour, another customer, an address unrelated to the subject) → **manual redaction pass required before release** — a Cortex/regex assist can flag candidates, but a human signs off, exactly as for call-recording SAR delivery (`call-recording-delivery/`).
- File naming: speaker-split lines prefixed `CUSTOMER:` / `AGENT:`; filename carries listing/call id + copy type. This is the transcript analogue of sending a call recording for a DSAR — log delivery per the SAR operational checklist.

---

## 8. Deployment plan (gated on sign-off)
1. Create new query `interaction_hub_call_transcript` (additive; safe).
2. Replace `interaction_hub_calls` with the revised SQL (additive columns; back-fills admin recording URL).
3. Apply the `interaction_hub_phone_lookup` patch for parity.
4. Deploy `interaction-hub.html` via `get_upload_token` → HTTP `PUT` (not `update_dashboard`, which can truncate).
5. Verify: a known CS call shows agent/customer split; search highlights; an untranscribed sales call shows "unavailable"; admin Listen opens `302 → 206 audio/x-wav`.

---

## 9. Governance notes
- Snowflake accessed **read-only** (`SELECT` against PRODUCTION); no writes.
- No customer PII committed in this record or the dashboard HTML; transcript content stays in Snowflake and is read live behind dashboard auth. Customer-facing exports are redacted + human-signed-off before release (§7).
- Recording playback stays behind the existing Basic-Auth proxy; never embed the Twilio key in the hub.
- Retention: transcripts exist only from 2026-07-20; the hub's 12-month phone-lookup window will show "unavailable" for older calls until history accrues.

## 10. Sources
- Snowflake (read-only): `CONFORMED.PRODUCTION.CALL_TRANSCRIPT_CALLS` / `CALL_TRANSCRIPT_SEGMENTS` / `CALL_TRANSCRIPT_CLASSIFIED`; `FCT_TWILIO_CALL_METRICS`; `MART_SALES_OPS.PRODUCTION.CS_QA_VOICE_BASE` / `CALL_SPEAKER_ROLES` / `CALL_TRANSCRIPT_NORMALISED`; coverage & join tests (7d).
- AV Dashboards queries `interaction_hub_calls` (`3FMEoLMS0TRU0niESsyKpb5dUln`), `interaction_hub_phone_lookup` (`3FWzBkT0qCZzI4X6N2kEDg317ZS`).
- Prior: `interaction-hub/2026-08-26-call-recording-playback-diagnosis.md`.
