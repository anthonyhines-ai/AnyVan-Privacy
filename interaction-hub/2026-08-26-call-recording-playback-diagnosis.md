# Interaction Hub — Call Recording Playback & Download: Diagnosis + Fix Design

> ⚠️ **CONFIDENTIAL — relates to customer call recordings (PII).**
> This record describes how customer phone-call recordings are stored and accessed.
> The customer number that triggered the investigation is redacted. **Never** put
> full customer numbers, or the Twilio API key / proxy credentials, into this file,
> the dashboard HTML, or any commit — anything committed here persists in git history.

| | |
|---|---|
| **Record type** | Dashboard / data-pipeline diagnosis + solution design |
| **Date** | 2026-08-26 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Surface** | Interaction Hub — https://dashboards.anyvan.com/operations/interaction-hub |
| **Trigger** | "Located the calls, but the hub won't let me listen to or download the recording." |
| **Example call** | Inbound, human agents, transferred 17:21→17:23 (Vanessa → John), 30 Jul 2026. Customer `+44 7599 46XXXX`. |
| **Example recording** | `RE31977df15ace65f5733bb3db943d9696` → `call_sid CAba0ceb1c1dbf5b08fb5eb44ba7e64a14`, 73s, dual-channel |

---

## 0. TL;DR (revised after live verification)

The audio access problem is **already solved** by an existing service; the real and
only gap is a **data** one.

- **Playback/download access works today** via the proxy `twilio-recordings.anyvan.com/recordings/{RecordingSid}`. It is **account-wide** (serves human-agent calls too, not just Sophie), sits behind **HTTP Basic Auth** (a Twilio API key), and 302-redirects to the S3 object. Verified end-to-end against the example **admin** recording: with auth → `302 → 206 audio/x-wav`; without auth → `401`. This is exactly what the **Sophie QA Review** board uses.
- **The one real gap:** for **human-agent ("Admin") calls, the RecordingSid never lands in Snowflake**, so the Interaction Hub has nothing to build the proxy URL from → no "Listen" button, nothing to download. (Sophie AI calls already carry the RecordingSid and already build the working proxy URL — so those already play in the hub via the same mechanism.)
- **The unblocker** you provided (the Twilio API key) confirms the fix is small: the Twilio API maps `RecordingSid → call_sid`, and that `call_sid` equals the **`WORKERCALLSID`** already stored against the call in the warehouse. So we only need to **land RecordingSid↔CallSid into Snowflake** (webhook or backfill) and have the two hub queries emit the same proxy URL for admin calls.

My earlier draft proposed building a Snowflake external stage / presigning layer. **That is no longer needed** — the proxy is the presigning layer and it already works. Scope shrinks to one data pipeline + a two-line change in each of two queries.

---

## 1. How the hub works today

- The **Calls** tab runs query `interaction_hub_calls`; the phone-lookup box runs `interaction_hub_phone_lookup`.
- In the row-expand renderer the listen button is gated on a URL:

  ```js
  if (isCalls && r.RECORDING_URL) { /* renders 🎧 Listen (a link that opens RECORDING_URL) */ }
  ```

  No `RECORDING_URL` → no button, no download.

- Both queries UNION two branches:

  | Branch | Source | `RECORDING_URL` today |
  |---|---|---|
  | **Sophie AI** voice | `MART_SALES_OPS.PRODUCTION.SOPHIE_CALLS_INCREMENTAL` | `'https://twilio-recordings.anyvan.com/recordings/' \|\| RECORDINGSID` (present) |
  | **Admin** (human agent) voice | `CONFORMED.PRODUCTION.FCT_TWILIO_CALL_METRICS` | **`NULL::VARCHAR`** (hard-coded) |

- The **Sophie QA Review** board (`customer-comms/sophie-chat-review_v5`) plays a recording with `window.open(r.url)`, where `url = r.TASK_URL` and `sophie_calls_v5 = SELECT * FROM SOPHIE_CALLS_INCREMENTAL`. `TASK_URL` is that same proxy URL. It embeds **no** credentials — the browser prompts for Basic Auth on first open and caches it for the session.

Your example calls are Admin calls, so they hit the `NULL` branch → no button.

---

## 2. Root cause (verified)

1. **Admin RecordingSids are not in the warehouse.** `FCT_TWILIO_CALL_METRICS` has no recording column; the query hard-codes `NULL`. `TWILIO_EVENTS.RECORDINGSID` is blank for admin calls (0 of 74,975 admin voice calls in 7 days were recoverable by any join key; the ~9.3k distinct RE-sids/month present there are the Sophie calls). The example recording is absent from Snowflake entirely.
2. **Access is NOT the blocker.** The proxy already serves any RecordingSid account-wide behind Basic Auth and redirects to `s3://anyvan-twilio-recordings/{AccountSid}/{RecordingSid}` (`audio/x-wav`). Verified against the admin example.
3. **Transfers = multiple legs/recordings.** The 17:21→17:23 transfer is one customer call across two agent legs (Vanessa, then John), each its own conference/leg and potentially its own recording. Whatever we build must list *all* recordings for a call, not assume one.

### Verified mechanism (example)
```
Twilio API:  RE31977df15ace65f5733bb3db943d9696
             → call_sid = CAba0ceb1c1dbf5b08fb5eb44ba7e64a14   (= WORKERCALLSID in warehouse)
             → source=StartCallRecordingAPI, channels=2, duration=73s, 30 Jul 2026 16:21:53
             → media_url = s3://anyvan-twilio-recordings/ACfe…b7c4/RE31977…
Proxy:       GET twilio-recordings.anyvan.com/recordings/RE31977…  (Basic Auth) → 302 → 206 audio/x-wav
```

---

## 3. Fix — two options, both small

Access is done. We only need admin calls to carry a RecordingSid so the hub can build the (already-working) proxy URL. Pick one:

### Option A — Land RecordingSid↔CallSid in Snowflake (recommended; native to the hub)

1. **Ingest.** Add a Twilio **recording status callback** (`recording.completed`) on the voice/Flex flow → land into `HARMONISED.PRODUCTION.TWILIO_RECORDING_COMPLETED` with `{RECORDING_SID, ACCOUNT_SID, CALL_SID, CONFERENCE_SID, CHANNELS, DURATION, DATE_CREATED, SOURCE, STATUS}`. This mirrors the existing `HARMONISED.DEVELOPMENT.EVENT_AMY_RECORDING_COMPLETED` capture (fields `RECORDING_ID`, `CALL_ID`, `TASK_SID`, …) — the plumbing pattern already exists for the Amy bot; extend it to Flex/admin and promote to PRODUCTION.
2. **Backfill** history once with the Twilio Recordings API (`GET /2010-04-01/Accounts/{AccountSid}/Recordings.json?DateCreatedAfter=…`, paginated), writing the same columns.
3. **Join & expose.** In both `interaction_hub_calls` and `interaction_hub_phone_lookup`, replace the admin branch's `NULL::VARCHAR AS RECORDING_URL` with a lookup:

   ```sql
   LEFT JOIN (
     SELECT CALL_SID, MAX(RECORDING_SID) AS RECORDING_SID
     FROM HARMONISED.PRODUCTION.TWILIO_RECORDING_COMPLETED
     WHERE RECORDING_SID LIKE 'RE%'
     GROUP BY CALL_SID
   ) rec
     ON rec.CALL_SID = c.WORKERCALLSID          -- verified join key; also try CUSTOMERCALLSID / CONFERENCESID as fallbacks
   ...
   CASE WHEN rec.RECORDING_SID IS NOT NULL
        THEN 'https://twilio-recordings.anyvan.com/recordings/' || rec.RECORDING_SID
        ELSE NULL END AS RECORDING_URL
   ```

   For transferred/multi-leg calls, prefer listing all matched RecordingSids (one Listen link per leg) rather than `MAX`.

### Option B — Teach the proxy to resolve by CallSid (no warehouse change)

The hub already has `WORKERCALLSID`/`CUSTOMERCALLSID` for admin calls. If the proxy gains a route like `GET /recordings/by-call/{CallSid}` (list that call's recordings via the Twilio API, redirect to the audio; return all legs for a transferred call), the hub can emit `RECORDING_URL = '…/recordings/by-call/' || WORKERCALLSID` with zero pipeline work. Faster, but needs the proxy's code owner and doesn't populate the warehouse for other uses.

### Dashboard UX (either option) — optional, I can do this in the hub
Matching Sophie's `window.open` is the minimum and already works. Nicer: inline `<audio controls preload="none" src=RECORDING_URL>` plus an explicit `⬇️ Download` link, and — for transfers — one player per leg.

---

## 4. Auth & security (please action)

- **Rotate the Twilio API key** that was shared in chat once this is set up; treat it as exposed.
- The proxy uses **HTTP Basic Auth with a Twilio API key**. Today reviewers type it into the browser prompt; it is **not** embedded in the Sophie board's HTML (good — keep it that way; never embed it in the Interaction Hub either). Distributing a Twilio API secret to every QA reviewer is a smell — consider evolving the proxy to **session/SSO auth** (dashboard cookie) or short-lived signed tokens so no human handles the raw key. Not required to fix playback, but recommended.
- Recordings are customer PII; access should stay behind auth and be logged.

---

## 5. Handoff pack (self-contained)

**Owners:** Data Eng (ingestion + query edits) and/or the proxy service owner (Option B); a Twilio admin for the status callback + key rotation.

**Deliverables, ready to hand over:**
1. **Ingestion table** `HARMONISED.PRODUCTION.TWILIO_RECORDING_COMPLETED` — columns as in §3.1; source = Twilio `recording.completed` status callback; model on the `EVENT_AMY_RECORDING_COMPLETED` precedent.
2. **Backfill script** — Twilio Recordings API, paginate `Recordings.json?DateCreatedAfter=`, upsert `{recording_sid, call_sid, conference_sid, channels, duration, date_created, source}`.
3. **Query edits** — the `LEFT JOIN` + `CASE` above, applied to both `interaction_hub_calls` and `interaction_hub_phone_lookup` (I can make these via the AV Dashboards MCP once the table exists).
4. **Dashboard UX** — inline player + download + per-leg links (I can implement).
5. **Test plan** —
   - Join coverage: `% admin voice calls (FCT_TWILIO_CALL_METRICS, 7d) with a matched RecordingSid` (expect high; investigate misses via CUSTOMERCALLSID/CONFERENCESID).
   - Playback: for a sample, open the built proxy URL → expect `302 → 206 audio/x-wav`.
   - Transfer case: the example call resolves to a Listen link per leg.

**What unblocks me to finish the hub side now:** the ingestion table populated (even a backfilled snapshot). Then the query + dashboard changes are quick and I'll push them.

---

## 6. Evidence appendix (all read-only / metadata + auth checks)

- Dashboards/queries via AV Dashboards MCP: `interaction_hub_calls`, `interaction_hub_phone_lookup`, `sophie_calls_v5` (= `SELECT * FROM SOPHIE_CALLS_INCREMENTAL`), and the `sophie-chat-review_v5` HTML (`url = r.TASK_URL`, `window.open`).
- Snowflake (read-only): source-table schemas; 7-day admin-recovery join test (0/74,975); 30-day RecordingSid coverage; example number + recording lookups; `EVENT_AMY_RECORDING_COMPLETED` schema.
- Access checks: proxy for the admin recording → `302 → 206 audio/x-wav` with Basic Auth, `401` without; Twilio Recordings API `RE… → call_sid` (= WORKERCALLSID), `media_url` in `anyvan-twilio-recordings`. Credentials were used transiently for verification only and are recorded nowhere.
</content>
