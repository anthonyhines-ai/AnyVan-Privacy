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
| **Status** | **Live (2026-09-18)** — call transcripts re-applied onto the full v52 dashboard after an incident (below). Emails/SMS/identity/chat transcripts + Twilio & Jiminny call transcripts all present. |

---

## 0. TL;DR
- **Transcripts with speaker labels already exist** in the warehouse (`CONFORMED.PRODUCTION.CALL_TRANSCRIPT_*`, live since 2026-07-20, ~2.3–2.6k calls/day, whisper-large-v3, dual-channel). `SPEAKER` is pre-resolved to **AGENT / CUSTOMER** — no diarisation guesswork needed.
- **Two transcript systems, not one (corrected 2026-09-15).** The Twilio pipeline (`CALL_TRANSCRIPT_*`) covers **CS / On The Day / Ops / Transport / Storage** (~2.3–2.6k calls/day). **Sales / Lead-Gen / inbound & outbound sales are transcribed in Jiminny** (`JIMINNY_CALL_METADATA` + `JIMINNY_CALL_TRANSCRIPT`, ~2.7–3.2k calls/day, speaker-separated, 768k calls to date). The hub currently reads only the Twilio pipeline, so sales calls *appear* untranscribed there (~0–4% match) but are in fact fully transcribed in Jiminny. Bringing sales into the hub means **integrating Jiminny** (§5), not switching on Twilio transcription.
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

> **Correction (2026-09-15):** the table below is the **Twilio pipeline only**. Sales / lead-gen
> calls read ~0% here because they are transcribed in **Jiminny** — a separate store (§5), verified
> current (~2.7–3.2k sales calls/day, teams: Inbound Sales, Lead Generation, Outbound Sales, ES/FR/DE/IT
> V2/V4 Sales). The two pipelines together cover both sides of the business.

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

## 5. Track B — integrate Jiminny as the sales transcript source
Sales calls are **already transcribed in Jiminny** (verified 2026-09-15). Track B is therefore a
**hub-integration** job, not a transcription-enablement one.

**Source tables (`HARMONISED.PRODUCTION`):**
- `JIMINNY_CALL_METADATA` — one row per sales call: `EVENT_ID`, `ANYVAN_USER_EMAIL/_TEAMNAME` (agent),
  `PARTICIPANTS` (JSON array; the **non-organizer participant carries the customer `phone`**),
  `EXTERNAL_PROVIDER_ID` (dialler CDR id — *not* a Twilio call sid), talk-time stats, `ACTUAL_START_TIME`.
- `JIMINNY_CALL_TRANSCRIPT` — one row per utterance: `EVENT_ID`, `PARTICIPANTNAME`, `ISORGANIZER`
  (**TRUE = AnyVan agent, FALSE = customer** — deterministic speaker split), `TRANSCRIPT`, `STARTSAT`, `ENDSAT`.

**Built in this PR:**
1. `sql/interaction_hub_jiminny_transcript.sql` — utterances by `EVENT_ID`, ordered by `STARTSAT`,
   speaker from `ISORGANIZER` (validated against PROD). Same output shape as the Twilio transcript
   query, so the hub's transcript pane renders it unchanged.
2. `sql/interaction_hub_jiminny_calls.sql` — sales calls for a customer phone: regex the quoted
   `phone` values out of `PARTICIPANTS`, normalise to last-10, match `:phone_suffix` (validated end
   to end — e.g. `07720 178163` → a live Inbound Sales call). Emits `TRANSCRIPT_SOURCE='jiminny'`.
3. `interaction-hub.html` — phone-lookup mode now merges Jiminny sales calls alongside the Twilio
   results (resilient: a missing/failed Jiminny query leaves phone results intact); the transcript
   loader dispatches on `TRANSCRIPT_SOURCE` (jiminny → by `EVENT_ID`, else Twilio → by call sid).

**Follow-ups:**
- Include Jiminny sales calls in the 7-day **Calls tab** list too (currently they surface via phone
  lookup — the dispute investigator's path). Needs a phone→listing map for the country/category columns.
- The AnyVan MCP `get_conversation_transcript` resolves a Jiminny transcript **by dealId** — a per-deal
  fallback where a participant phone is missing.
- Confirm Jiminny covers *all* sales calls (it captures Jiminny-dialled/recorded calls) vs a residual
  that bypasses it.

**Residual Twilio-side items (separate, lower priority):**
- ~25% miss inside "on" CS/ops teams (recording-not-started vs STT failure vs sub-threshold duration).
- ~14% of Twilio transcripts fall outside `FCT_TWILIO_CALL_METRICS` (possible Aircall) — confirm and add a spine if needed.

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

## 8. Deployment — DONE (2026-09-16)
1. ✅ Created queries `interaction_hub_call_transcript`, `interaction_hub_jiminny_transcript`,
   `interaction_hub_jiminny_calls` (all additive).
2. ✅ `interaction_hub_calls` updated → dashboard pinned **v9** (RECORDING_ID / TRANSCRIPT_AVAILABLE /
   CALL_DIRECTION; admin RECORDING_URL back-filled).
3. ✅ `interaction_hub_phone_lookup` updated → dashboard pinned **v12** (same additive columns; full
   revised SQL in `sql/interaction_hub_phone_lookup.sql`, which supersedes the earlier PATCH note).
4. ✅ `interaction-hub.html` published via `get_upload_token` → HTTP `PUT` (HTTP 200).
5. ✅ Verified through the platform: revised phone-lookup returns the new columns; the deployed
   `interaction_hub_jiminny_calls` returns a live sales call (`07720 178163` → Inbound Sales,
   `TRANSCRIPT_AVAILABLE=true`, `TRANSCRIPT_SOURCE='jiminny'`). Spot-check in the UI: a sales phone
   lookup shows the Jiminny call and its agent/customer transcript; a CS call shows the split + search;
   admin Listen opens the recording.

---

## 8a. Incident & recovery (2026-09-18)
**What happened.** The 2026-09-16 publish pushed the dashboard HTML **from the repo**, which was ~3 weeks behind the live dashboard (repo ≈ v25 / 20 Aug; live at v52 / 15 Sep). The live hub had ~15 uncommitted HTML iterations (v26→v52) made directly on the platform — the **Emails** and **SMS** tabs, phone/email/name **identity search**, and the **chat-transcript viewer**. Publishing the repo file (as v55) reverted all of it for ~2 days.

**Root cause.** The repo was treated as the source of truth but was never kept in sync with the live dashboard; the publish step did not diff against live first.

**Recovery.**
1. `rollback_dashboard` → v52 (restored Emails/SMS/identity/chat transcripts instantly; live as v56).
2. Pulled the live v52 HTML, **re-synced the repo `interaction-hub.html` to it** (this is the fix that stops recurrence), then re-applied the call-transcript feature *onto the v52 base* — reusing v52's own transcript bubble styling and its redacted-PDF builder (agent already anonymised), adding an in-call search box; sales calls merged into the phone lookup via `interaction_hub_jiminny_calls`.
3. Re-published (HTTP 200) and validated.

**No data was lost** — the SQL changes (calls, phone_lookup) were supersets of the live queries; the three transcript queries are additive. `interaction_hub_phone_lookup` is now superseded on the phone panel by v52's `interaction_hub_identity_lookup` (kept, harmless).

**Prevention.** Always `get_dashboard_html` and diff against live before publishing this dashboard; treat the **live platform as source of truth** and commit its HTML back to the repo after any live edit.

## 8b. Emails tab — transactional source fix (2026-09-18)
**Reported:** for a booked customer (two accounts — `…@icloud.com` + `…@outlook.com`, one phone) the Emails tab showed one "Marketing" email and **no transactional**, despite a live booking.

**Root cause (evidenced):**
- Classification was by **source table**, not purpose: everything in `EVENTS_MESSAGING_MESSAGE` labelled Transactional, everything in `EVENTS_EMAIL` labelled Marketing.
- Platform reality: **Marketing = HubSpot** (`EVENTS_EMAIL`, 100% `source='hubspot'`); **Transactional = Mandrill**, which has **no governed warehouse table** (only ad-hoc `MART_SALES_OPS.DEVELOPMENT.TMP_TAHA_MANDRILL_*` scratch). The tab's "Transactional" source (`EVENTS_MESSAGING_MESSAGE`, the messaging gateway) only holds data from **2026-05-19** and was empty for this customer — so booking confirmations never appeared.
- The real per-booking send log **is** in the warehouse: `HARMONISED.PRODUCTION.LISTING_COMMUNICATION` (typed `booking-confirmation`, `checklist`, `invoice-payment-success`, …), keyed by `LISTING_ID`.
- Duplicate accounts: identity resolved only the searched email, so the other account's comms were invisible.

**Fix (deployed):**
- `interaction_hub_emails` → **Transactional from `LISTING_COMMUNICATION`** (`CHANNEL='email'`, `TARGET='customer'`, typed by `TYPE`); Marketing stays HubSpot `EVENTS_EMAIL` (`source='hubspot'`). Identity **fans out across duplicate accounts sharing a phone** → their user_ids → listings → comms. (`sql/interaction_hub_emails.sql`, dashboard pinned SQL v2.)
- `interaction_hub_email_kpis` repointed to the same sources (`sql/interaction_hub_email_kpis.sql`, v3) so the tiles match the list.
- Validated on the reported customer: 13 emails across both accounts, incl. the 13 Sep **Booking Confirmation** as Transactional. System-wide sanity: transactional ~5–6k/day (booking-confirmation top), marketing ~20–25k/day.

**Notes / limits:**
- `LISTING_COMMUNICATION` stores type/channel/recipient/timestamp but **not subject or body** → emails are labelled by type ("Booking confirmation"), metadata-only (consistent with the tab's design). `MESSAGE_ID` (Mandrill id) is usually blank.
- HubSpot also sends some operational emails (e.g. day-of-move) — these still read **Marketing** because they are HubSpot sends (platform truth). Acceptable; revisit only if a purpose overlay is wanted.
- Phone-linking merges accounts sharing a number — right for SAR/dispute completeness, small over-merge risk if a phone is genuinely shared; the identity card shows how many accounts matched.
- Proper follow-up for Data Eng: **ingest Mandrill** into a governed table if a true send-event (with subject/status) transactional source is wanted beyond the app's `LISTING_COMMUNICATION` log.

## 8c. Emails tab — lifecycle classifier + Customer/Transport-partner toggle (2026-09-18)
**Driver:** Ant reviewed the per-customer comms export and set the classification rule. It is **lifecycle-based, not platform-based** — the same HubSpot email is Marketing or Transactional depending on *when* in the booking journey it was sent. This **supersedes §8b's note** that day-of-move HubSpot sends "read Marketing… acceptable" (they now read **Transactional**).

**The rule (customer's data-subject view):**

| Stage | Rule | Category |
|---|---|---|
| Before any listing exists | quote / price nurture | **Marketing** |
| Listing created → job completed | anything about the live job (incl. agent-generated HubSpot day-of-move) | **Transactional** |
| After completion / no active job | "come back" re-engagement | **Marketing** |
| Customer contacts us (inbound) | Freshdesk | **Operational** |
| Sent to the driver/TP about the job | not the customer's data | **Not customer-facing** → shown under the TP toggle |

**Transport-partner (TP) view** — the customer's booking also generates comms *to* the allocated driver. Same lifecycle logic keyed on allocation, not the customer window:
- `route-match` / `route-match-back` = job **offers** (pre-allocation) → **TP-Marketing**.
- `driver-assigned` / `driver-reminder` / `job-changed` / `job-completed` / `driver-deallocated` = servicing an allocated job → **TP-Transactional**.
Rationale: **both parties can raise a data-subject request**, so the hub must surface TP-facing comms too.

**Classifier (deployed in `interaction_hub_emails`, dashboard SQL v3):**
```sql
-- HubSpot (no listing_id): test the send against the customer's booking windows
CASE WHEN EXISTS (SELECT 1 FROM cust_windows w          -- MASTER_LISTING per linked user
                  WHERE send_ts >= w.LISTING_CREATED_DATE
                    AND send_ts <= COALESCE(w.LISTING_COMPLETED_DATE, CURRENT_TIMESTAMP()))
     THEN 'Transactional' ELSE 'Marketing' END           -- in-window = Transactional
-- LISTING_COMMUNICATION (per-booking): customer target = Transactional; provider target:
CASE WHEN TARGET='provider' AND TYPE ILIKE 'route-match%' THEN 'TP-Marketing'
     WHEN TARGET='provider'                               THEN 'TP-Transactional'
     ELSE 'Transactional' END
```
New `PARTY` column (`customer` | `transport_partner`) drives a **Customer / Transport-partner toggle** on the Emails tab (client-side filter, no re-fetch; Freshdesk hidden on the TP side).

**Validated:** the rule reproduced Ant's own manual categorisation **30/30** on the full export, and the live pinned query returns the email-subset **22/22** correctly for the reported customer — the day-of-move HubSpot email now **Transactional**, the pre-listing quote **Marketing**, provider comms split TP-Marketing (4) / TP-Transactional (5).

**Scope / limits:**
- **KPI tiles left as-is** — they are a *system-wide* monitor and the lifecycle test needs per-recipient booking windows, too heavy to apply across all sends inside the 30s query budget. The per-customer list (the SAR-relevant path) is what changed. Flagged to Ant; revisit if the tiles must match the new definition.
- TP class is a **type→class heuristic** now (route-match% = offer). Booking-scoped and exact for the validated set; a precise allocation-timestamp classifier is deferred to the **TP-subject search** phase (search by TP → all their jobs; needs a resolver via the provider/allocation dimension, as TPs are not in `DIM_USER_CUSTOMER`).
- Same metadata-only, no-body, phone-linked-identity properties as §8b.

## 8d. Transport-partner data-subject search (2026-09-18)
**Driver:** both parties to a booking can raise a data-subject request, so the hub must answer a **TP's** request too — every job comm we sent that TP across *all* their bookings, not just one customer's job. Delivers the "TP-search next" step flagged in §8c.

**Key finding — exact attribution, no allocation-window guesswork.** `HARMONISED.PRODUCTION.LISTING_COMMUNICATION` carries **`RECIPIENT_ID`**; for `TARGET='provider'` rows that is the TP's `USER_ID` in `CONFORMED.PRODUCTION.DIM_USER_TRANSPORTPROVIDER`. One listing can involve several TPs over its life (deallocations, route-match offers to multiple drivers, final assignment — Ellie's Sep job hit 6 drivers), and `RECIPIENT_ID` keeps each comm tied to the TP that actually received it. So the allocation-timestamp classifier I'd expected to need isn't required for attribution.

**Query (`interaction_hub_tp_emails`, new, public):** resolve the TP by `mode` = user id (`USER_ID`/`ID`) · name (`FULL_NAME`/`NICKNAME`) · phone (last-10 of `PRIMARY`/`SECONDARY_PHONE_NUMBER`) · email → `USER_ID`, then `LISTING_COMMUNICATION` where `TARGET='provider' AND RECIPIENT_ID = USER_ID AND CHANNEL='email'`. Class as §8c (route-match% = TP-Marketing, else TP-Transactional). Returns `LISTING_ID` per row so each comm is traceable to its job.

**Validated:** Titi Preda (`USER_ID 5435275`) → **133 provider emails across 102 distinct jobs** in 200 days (3 TP-Marketing, 130 TP-Transactional), `RECIPIENT_ID` scoped to that one TP; name / phone / email all resolve to the same id.

**UI:** the Emails tab's **Customer / Transport Partner** toggle now switches the *search subject*. In Transport-Partner mode the search box accepts a TP name/id/phone/email and lists that TP's comms across all jobs; the drawer shows the `Listing` each comm belongs to. Customer mode is unchanged. Export carries `PARTY` + `LISTING_ID`.

**Limits / next:** email-only for now (SMS/WhatsApp to TPs exist in `LISTING_COMMUNICATION` and can be added the same way); the current customer-search query still returns booking-scoped provider rows but the tab now routes TP viewing through the dedicated search; a two-way/inbound TP contact channel (if any) is out of scope. Redaction for a TP export mirrors §7 (blank the *other* party's PII — here the customer's).

## 9. Governance notes
- Snowflake accessed **read-only** (`SELECT` against PRODUCTION); no writes.
- No customer PII committed in this record or the dashboard HTML; transcript content stays in Snowflake and is read live behind dashboard auth. Customer-facing exports are redacted + human-signed-off before release (§7).
- Recording playback stays behind the existing Basic-Auth proxy; never embed the Twilio key in the hub.
- Retention: transcripts exist only from 2026-07-20; the hub's 12-month phone-lookup window will show "unavailable" for older calls until history accrues.

## 10. Sources
- Snowflake (read-only): `CONFORMED.PRODUCTION.CALL_TRANSCRIPT_CALLS` / `CALL_TRANSCRIPT_SEGMENTS` / `CALL_TRANSCRIPT_CLASSIFIED`; `FCT_TWILIO_CALL_METRICS`; `MART_SALES_OPS.PRODUCTION.CS_QA_VOICE_BASE` / `CALL_SPEAKER_ROLES` / `CALL_TRANSCRIPT_NORMALISED`; coverage & join tests (7d).
- AV Dashboards queries `interaction_hub_calls` (`3FMEoLMS0TRU0niESsyKpb5dUln`), `interaction_hub_phone_lookup` (`3FWzBkT0qCZzI4X6N2kEDg317ZS`), `interaction_hub_emails` (`3J3TLtoFXR6NHz2NgOaI7uDxdMG`, SQL v3), `interaction_hub_tp_emails` (`3JUqzkcjNB05zLDUcwu9YXkjPkB`, §8d).
- Lifecycle classifier (§8c): `HARMONISED.PRODUCTION.LISTING_COMMUNICATION`, `HARMONISED.PRODUCTION.EVENTS_EMAIL`, and `CONFORMED.PRODUCTION.MASTER_LISTING` (`LISTING_CREATED_DATE` / `LISTING_COMPLETED_DATE` booking windows). Rule reproduced Ant's manual categorisation 30/30.
- TP search (§8d): `CONFORMED.PRODUCTION.DIM_USER_TRANSPORTPROVIDER` (TP identity) + `LISTING_COMMUNICATION.RECIPIENT_ID` (exact per-TP attribution). Routed via the `anyvan-data` skill.
- Prior: `interaction-hub/2026-08-26-call-recording-playback-diagnosis.md`.
