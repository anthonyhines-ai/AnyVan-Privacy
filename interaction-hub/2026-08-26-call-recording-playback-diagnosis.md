# Interaction Hub — Call Recording Playback & Download: Diagnosis + Fix Design

> ⚠️ **CONFIDENTIAL — relates to customer call recordings (PII).**
> This record describes how customer phone-call recordings are stored and accessed.
> The customer number that triggered the investigation is redacted below. Do not add
> full customer numbers, names, or live presigned URLs (which embed AWS credentials)
> to this file — anything committed here persists in git history.

| | |
|---|---|
| **Record type** | Dashboard / data-pipeline diagnosis + solution design |
| **Date** | 2026-08-26 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Surface** | Interaction Hub — https://dashboards.anyvan.com/operations/interaction-hub |
| **Trigger** | "Located the calls, but the hub won't let me listen to or download the recording." |
| **Example call** | Inbound, human agents, 2026-07-30 & 2026-08-04. Customer `+44 7599 46XXXX`. |
| **Example recording** | `RE31977df15ace65f5733bb3db943d9696` (Twilio account `ACfe…b7c4`) |

---

## 0. TL;DR

The Interaction Hub **already has a "🎧 Listen to Recording" button** — but it only
renders when a call row carries a `RECORDING_URL`, and for the calls you are locating
that field is **empty**, so no button appears and there is nothing to download.

There is **no single bug**. Three gaps stack up:

1. **Data gap (the blocker for your calls).** The recording ID for **human-agent
   ("Admin") calls is never loaded into Snowflake.** The Admin branch of the query
   hard-codes `RECORDING_URL = NULL`. Verified: **0 of 74,975** admin voice calls in
   the last 7 days have any recoverable RecordingSID, and your specific recording
   `RE31977…` **does not exist anywhere in the warehouse.**
2. **Access gap.** Even the calls that *do* have a RecordingSID (Sophie AI only) build
   the URL `https://twilio-recordings.anyvan.com/recordings/{SID}`, which returns
   **401/404** in a browser. The real audio lives in the private S3 bucket
   `anyvan-twilio-recordings`, keyed `{AccountSID}/{RecordingSID}`, and needs a
   **presigned URL** (proven working, returns `audio/x-wav`). A static, warehouse-stored
   URL can never be a valid presigned URL.
3. **UX gap.** The button is a plain "open in new tab" link — no inline player, and no
   separate **Download** control.

**None of these can be fixed by editing the dashboard alone.** Fixing it end-to-end
needs (A) ingesting admin recording IDs into the warehouse and (B) a presigning
mechanism for the S3 bucket. Both need access/infra I don't have from here — that's
where I need your help. The good news: **the plumbing for (A) already exists** for the
"Amy" bot and just needs extending; **(B) is a well-trodden Snowflake pattern.**

---

## 1. How the hub works today

- Dashboard: `operations/interaction-hub` (static HTML on the AV Dashboards platform).
- The **Calls** tab loads the query `interaction_hub_calls`; the phone-lookup box (what
  you used) loads `interaction_hub_phone_lookup`. Both are public Snowflake queries.
- In the row-expand renderer, the listen button is gated exactly like this:

  ```js
  if (isCalls && r.RECORDING_URL) {
    // renders: 🎧 Listen to Recording  (an <a href=RECORDING_URL target="_blank">)
  }
  ```

  No `RECORDING_URL` → **no button, no download, nothing.**

- Both queries build calls from **two** sources UNION'd together:

  | Branch | Source table | `RECORDING_URL` produced |
  |---|---|---|
  | **Sophie AI** voice | `MART_SALES_OPS.PRODUCTION.SOPHIE_CALLS_INCREMENTAL` | `'https://twilio-recordings.anyvan.com/recordings/' || RECORDINGSID` (when present) |
  | **Admin** (human agent) voice | `CONFORMED.PRODUCTION.FCT_TWILIO_CALL_METRICS` | **`NULL::VARCHAR`** (hard-coded) |

Your calls (handled by human agents — e.g. the 17:21 → 17:23 transfer between two
agents) are **Admin** calls, so they fall in the branch that always returns `NULL`.

---

## 2. Root-cause findings (with evidence)

### Gap 1 — Admin recording IDs are not in the warehouse

- `FCT_TWILIO_CALL_METRICS` (the admin-call source) has **no recording column at all** —
  only `TASKSID`, `CONFERENCESID`, `WORKERCALLSID`, `CUSTOMERCALLSID`.
- `HARMONISED.PRODUCTION.TWILIO_EVENTS` *has* a `RECORDINGSID` column, but it does not
  join to admin calls. Recovery test over the last 7 days:

  | Admin voice calls | Recoverable via `CUSTOMERCALLSID` | via `WORKERCALLSID` | via `TASKSID` |
  |---:|---:|---:|---:|
  | **74,975** | **0** | **0** | **0** |

- Real (`RE…`) RecordingSID coverage, last 30 days:

  | Source | Rows | Rows with `RE…` sid | Distinct recordings |
  |---|---:|---:|---:|
  | `TWILIO_EVENTS` | 4,897,592 | 28,001 | 9,328 |
  | `SOPHIE_CALLS_INCREMENTAL` | 9,303 | 9,303 | 9,301 |

  The ~9.3k distinct recordings in `TWILIO_EVENTS` line up with the ~9.3k **Sophie AI**
  calls — i.e. the only recordings tracked in Snowflake are the AI ones. The hundreds of
  thousands of **human-agent** calls have none.
- Your specific recording `RE31977df15ace65f5733bb3db943d9696`: **0 rows** in
  `TWILIO_EVENTS`. Every event for your number carries a **blank** `RECORDINGSID`.
- The Flex Insights export `HARMONISED.PRODUCTION.TWILIO_FLEX_INSIGHTS_BI_TWILIO_TELEPHONY`
  is **aggregate metrics only** (handling/hold/queue times) — no RecordingSID, no media
  URL. Your Flex segment `d3f5407a-…` is not resolvable to a recording there.

**Conclusion:** for the calls you are locating, the hub has no RecordingSID, so it
**cannot build any link** — which is why there is no Listen button and nothing to
download.

### Gap 2 — Even with a RecordingSID, the built URL doesn't play

- The URL pattern comes from `SOPHIE_CALLS_INCREMENTAL.TASK_URL`, e.g.
  `https://twilio-recordings.anyvan.com/recordings/RE80ba…a319`.
- `https://twilio-recordings.anyvan.com/recordings/<sid>` → **HTTP 401**; site root → **404**.
  A normal browser click cannot play it.
- The audio actually lives in AnyVan's own **private** S3 bucket:
  `anyvan-twilio-recordings`, key `{AccountSID}/{RecordingSID}`
  (e.g. `ACfe…b7c4/RE31977…`). It requires a **presigned** URL — the Flex "download"
  link you pasted is exactly that (`X-Amz-Signature`, `X-Amz-Expires=3600`).
- Verified: the presigned URL returns **HTTP 206**, `Content-Type: audio/x-wav`. So the
  recording is present and playable — **only** via a freshly-signed URL. A static URL
  stored in the warehouse can never satisfy that signature, and the dashboard is static
  HTML that cannot (and must not) hold AWS credentials to sign requests itself.

### Gap 3 — UX

- The button is `<a href=RECORDING_URL target="_blank">` — no inline `<audio>` player,
  and no dedicated **Download** action. (Easy to fix, but pointless until Gaps 1–2 are
  resolved.)

---

## 3. The fix (two required workstreams, then a trivial dashboard change)

### Fix A — Load admin recording IDs into the warehouse *(data engineering)*

**The pattern already exists.** `HARMONISED.DEVELOPMENT.EVENT_AMY_RECORDING_COMPLETED`
already captures Twilio `recording.completed` events for the "Amy" bot, with
`RECORDING_ID`, `CALL_ID`, `TASK_SID`, `CUSTOMER_PHONE_NUMBER`, `EVENT_TIMESTAMP`. We
need the same for **Flex / human-agent** recordings, in **PRODUCTION**.

Options, best first:

1. **Twilio Event Streams / `recording.completed` status callback → warehouse.**
   Subscribe to the recording-status callback on the Flex TaskRouter/voice flow and land
   `{RecordingSid, AccountSid, CallSid, ConferenceSid, TaskSid, Duration, DateCreated}`
   into e.g. `HARMONISED.PRODUCTION.TWILIO_RECORDING_COMPLETED`. Real-time; mirrors the
   Amy table.
2. **Scheduled backfill via Twilio Recordings API.** For CallSids already in
   `FCT_TWILIO_CALL_METRICS`, call
   `GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings.json` and store the
   returned RecordingSid(s). Good for history/backfill.

Then admin calls join cleanly:
`FCT_TWILIO_CALL_METRICS.CUSTOMERCALLSID = <recordings>.CALL_ID` (or `WORKERCALLSID` /
`CONFERENCESID`).

**Owner:** Data Engineering + whoever holds Twilio account access.
**I can produce:** the dbt model + the exact join, and the callback field mapping.
**I cannot:** call Twilio (no auth token here) or deploy a pipeline.

### Fix B — Serve the private recordings via presigned URLs *(Snowflake + AWS)*

**Option B1 — Snowflake external stage + `GET_PRESIGNED_URL` (recommended).**
Fits the dashboard model perfectly: the query returns a ready-to-use, short-lived URL
per row; nothing new to run.

```sql
-- 1) Storage integration (ACCOUNTADMIN)
CREATE STORAGE INTEGRATION twilio_recordings_int
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::<AWS_ACCOUNT_ID>:role/snowflake-twilio-recordings'
  STORAGE_ALLOWED_LOCATIONS = ('s3://anyvan-twilio-recordings/');

-- 2) Read the Snowflake principal + external id, paste them into the IAM role trust policy
DESC INTEGRATION twilio_recordings_int;  -- STORAGE_AWS_IAM_USER_ARN, STORAGE_AWS_EXTERNAL_ID

-- 3) External stage over the bucket root
CREATE STAGE HARMONISED.PRODUCTION.TWILIO_RECORDINGS_STAGE
  STORAGE_INTEGRATION = twilio_recordings_int
  URL = 's3://anyvan-twilio-recordings/';
```

AWS IAM role permissions policy (attach to `snowflake-twilio-recordings`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:GetObjectVersion"],
      "Resource": "arn:aws:s3:::anyvan-twilio-recordings/*" },
    { "Effect": "Allow",
      "Action": ["s3:ListBucket", "s3:GetBucketLocation"],
      "Resource": "arn:aws:s3:::anyvan-twilio-recordings" }
  ]
}
```

Query change (both `interaction_hub_calls` and `interaction_hub_phone_lookup`), once
Fix A supplies `ACCOUNT_SID` + `RECORDING_SID` for admin calls too:

```sql
CASE
  WHEN RECORDING_SID IS NOT NULL AND ACCOUNT_SID IS NOT NULL
  THEN GET_PRESIGNED_URL(
         @HARMONISED.PRODUCTION.TWILIO_RECORDINGS_STAGE,
         ACCOUNT_SID || '/' || RECORDING_SID,
         3600)                       -- 1-hour validity, regenerated on each dashboard load
  ELSE NULL
END AS RECORDING_URL
```

`GET_PRESIGNED_URL` returns a URL that serves the object with its stored
`Content-Type: audio/x-wav`, so it plays in an `<audio>` element and downloads on demand.

**Option B2 — finish the `twilio-recordings.anyvan.com` proxy.** The domain already
exists (returns 401) and is referenced in `SOPHIE_CALLS_INCREMENTAL.TASK_URL`, so this
was clearly intended. A small service (Lambda/CloudFront) holding AWS creds would map
`/recordings/{SID}` → `s3://anyvan-twilio-recordings/{AccountSID}/{SID}` and stream it,
gated behind dashboard auth. More moving parts and an auth story to build; only pick this
if there's a reason to keep recordings behind an app endpoint rather than presigned URLs.

**Owner:** Snowflake ACCOUNTADMIN + AWS/DevOps (IAM role).
**I can produce:** all SQL + the IAM JSON (above).
**I cannot:** create the IAM role or run ACCOUNTADMIN DDL from here.

### Fix C — Dashboard UX *(I can do this now)*

Once a working `RECORDING_URL` exists, replace the single link with:

```js
if (isCalls && r.RECORDING_URL) {
  var audio = document.createElement('audio');
  audio.controls = true; audio.preload = 'none'; audio.src = r.RECORDING_URL;
  content.appendChild(audio);

  var dl = document.createElement('a');
  dl.className = 'convo-btn convo-btn-primary';
  dl.href = r.RECORDING_URL;
  dl.setAttribute('download', 'call_' + (r.INTERACTION_ID || 'recording') + '.wav');
  dl.textContent = '⬇️ Download Recording';
  actions.appendChild(dl);
}
```

(Cross-origin S3 may ignore the suggested filename and, if the object is served
`inline`, open rather than download; if that matters we set
`response-content-disposition=attachment` on the presign — B2 can do this trivially,
B1 cannot, so note it as a follow-up.)

---

## 4. Sequencing & ownership

| Step | What | Owner | Blocks |
|---|---|---|---|
| A | Ingest admin `recording.completed` (RecordingSid ↔ CallSid) to PRODUCTION | Data Eng + Twilio access | The whole thing for admin calls |
| B | Storage integration + external stage (or finish proxy) | Snowflake ACCOUNTADMIN + AWS/DevOps | Any playback at all |
| Query | Add `GET_PRESIGNED_URL`, join recordings into both queries | Me (via AV Dashboards MCP) | needs A + B |
| C | Inline player + Download button | Me (dashboard HTML) | needs a live URL |

**Fastest path to *any* working playback:** B1 (stage) + point the **Sophie** branch at
`GET_PRESIGNED_URL` — that lights up the ~9k/month AI calls immediately. Admin calls (the
bulk, and the ones in your example) need **A** first.

## 5. What I need from you to proceed

1. **Presigning approach:** B1 (Snowflake external stage — recommended) or B2 (finish the
   `twilio-recordings.anyvan.com` proxy)?
2. **Access / owners:** who can (or can you) run the ACCOUNTADMIN DDL + create the AWS IAM
   role, and who owns the Twilio account for the recording-status callback / API?
3. **Scope confirmation:** are *all* admin recordings in `anyvan-twilio-recordings/{AccountSid}/{RecordingSid}`, and is `ACfe…b7c4` the only Twilio account (or is there one per region)?

Give me #1 and a green light on #2 and I'll wire the query + dashboard (Fix C, and the
query side of B) and hand your data/DevOps owners the exact, copy-paste DDL + IAM policy
above.

---

## 6. Evidence appendix (queries run, read-only)

- Dashboard source: `get_dashboard_html('operations/interaction-hub')`; queries
  `interaction_hub_calls`, `interaction_hub_phone_lookup` (AV Dashboards MCP).
- `FCT_TWILIO_CALL_METRICS`, `TWILIO_EVENTS`, `SOPHIE_CALLS_INCREMENTAL` column
  inspections; the 7-day admin-recovery join test; 30-day RecordingSID coverage counts;
  lookup of the example number and recording; `TWILIO_FLEX_INSIGHTS_BI_TWILIO_TELEPHONY`
  schema + segment lookup; `EVENT_AMY_RECORDING_COMPLETED` schema.
- Access checks: presigned S3 URL → HTTP 206 `audio/x-wav`;
  `twilio-recordings.anyvan.com/recordings/<sid>` → HTTP 401, root → HTTP 404.
- All Snowflake access was **read-only** (metadata + `SELECT`).
</content>
</invoke>
