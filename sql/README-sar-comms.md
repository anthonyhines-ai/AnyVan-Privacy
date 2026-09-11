# SAR comms-surfacing — new queries + deploy manifest

New AV Dashboards named queries that surface **Marketing & Transactional email
and all other customer communications** for a SAR/DSAR. Built for
`operations/sar-data-extract` (email-keyed) and mirrored into
`operations/interaction-hub` (phone-keyed) — `EVENTS_MESSAGING_MESSAGE` carries
both `RESOLVED_USER_EMAIL` and `RESOLVED_USER_PHONE`, so the same design serves both.

Params follow the SAR dashboard convention: `:email` and `:phone_suffix`
(last-10 digits). Bind style is Snowflake `:name` (confirmed via the av-dashboards skill).

| Query file | Param | Channel(s) surfaced | Key tables |
|---|---|---|---|
| `sar_messaging.sql` | `:email` | Email + RCS + WhatsApp (body, subject, consent), 2026-05-19+ | `EVENTS_MESSAGING_MESSAGE` |
| `sar_comms_log.sql` | `:email` | Transactional send-log, all channels, 2022+ (subject/body in TOKENS) | `LISTING_COMMUNICATION` + `DIM_USER_CUSTOMER` |
| `sar_consent_history.sql` | `:email` | Marketing/consent opt-in-out change history | `HUBSPOT_CONTACT` → `HUBSPOT_CONTACT_PROPERTY_HISTORY` |
| `sar_whatsapp_twilio.sql` | `:phone_suffix` | One-way WhatsApp + SMS bodies (Twilio) | `TWILIO_MESSAGE` |
| `sar_twilio_conversations.sql` | `:phone_suffix` | Two-way WhatsApp/chat bodies, ~2026-05-01+ | `TWILIO_CONVERSATION_MESSAGE` + `_PARTICIPANT` |
| `sar_aircall.sql` | `:phone_suffix` | Aircall calls + recording URL | `AIRCALL_CALL` |

## Corrects a stale caveat
`sar-data-extract.html` currently warns "Mandrill transactional emails not yet in
Snowflake". That is **wrong** — there is no Mandrill table; transactional email is
served by `EVENTS_MESSAGING_MESSAGE` (body/subject) + `LISTING_COMMUNICATION` (log),
both in Snowflake and both surfaced above. The caveat text must be rewritten.

## Data blockers (leave as noted gaps, not surfaced)
- **Video Survey** — no Snowflake table exists (also a category on the live DSR form; flagged in go-live readiness).
- **Live chat** message bodies before ~April 2026 — not in Snowflake (pull from LiveChat.com manually).

## Deploy steps (mechanical; needs the AV Dashboards MCP authenticated)
For each query above:
1. Snowflake-validate the SQL (run with a real `:email`/`:phone_suffix` literal, `LIMIT 5`) — `sar_messaging` already validated.
2. `create_query` with the query name (= file stem), `sql_text` = file body, visibility `public`, cache 600s.
3. Wire into `sar-data-extract.html`: add a `QUERIES` entry (`needsPhone` = true for the `:phone_suffix` ones), a tab, and a panel (the generic `runOneQuery`/`buildTable` renders it).
4. Deploy the HTML: `get_upload_token` → HTTP **PUT** to the upload API (never `update_dashboard`). Increment query names on any SQL change (cache key = name).
5. Repeat the wiring for `interaction-hub.html` using `:phone_suffix` on `RESOLVED_USER_PHONE` for the messaging channels.

## Validation status — 2026-09-11
All six queries are **Snowflake-validated** (compile + column check; the `:email` /
`:phone_suffix` binds substituted with test literals so no customer rows were pulled).
`sar_messaging` was also shape-checked against live data.

| Query | Validated |
|---|---|
| sar_messaging | ✅ |
| sar_comms_log | ✅ |
| sar_consent_history | ✅ |
| sar_whatsapp_twilio | ✅ |
| sar_twilio_conversations | ✅ |
| sar_aircall | ✅ |

## Deploy — BLOCKED on the AV Dashboards connector re-auth
The AV Dashboards MCP currently requires re-authentication (claude.ai → Settings →
Connectors). Until it's reconnected, `create_query` / `get_upload_token` / PUT cannot run.
The wired HTML (`sar-data-extract.html`) is already committed but the **live dashboard is
unchanged** until the PUT in step 2. Once the connector is back, deploy is mechanical:

1. `create_query` for each of the six (query_name = file stem, sql_text = file body,
   visibility public, cache 600s).
2. `get_upload_token` → HTTP **PUT** `sar-data-extract.html` to the upload API
   (never `update_dashboard`, which truncates).
3. Hard-refresh; verify each new tab returns rows for a known customer email/phone.
4. Mirror into `interaction-hub.html` (phone-keyed: the messaging channels via
   `EVENTS_MESSAGING_MESSAGE.RESOLVED_USER_PHONE`) and PUT.
