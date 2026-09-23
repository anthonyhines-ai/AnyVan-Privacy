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

## Deploy — ✅ DONE 2026-09-11 (was blocked on connector re-auth; now live)
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

## Deployed — 2026-09-11 ✅
All six queries created (visibility `public`, matching the existing `sar_*` queries so the
whole privacy team can run the dashboard) and the wired HTML pushed to the live dashboard:
**https://dashboards.anyvan.com/operations/sar-data-extract**

Query IDs: sar_messaging, sar_comms_log, sar_consent_history, sar_whatsapp_twilio,
sar_twilio_conversations, sar_aircall. `sar_messaging` and `sar_aircall` verified on-platform
(0 rows for a non-existent email / phone — binds work). Dashboard auto-versioned; rollback via
`rollback_dashboard` if needed.

**Governance note:** the queries are `public` (any @anyvan.com user who can open the dashboard can
run them; they surface customer PII). This matches the existing SAR queries. Tighten to `shared`
(privacy-team emails) via `update_query` if stricter control is wanted.

**Still to do:** mirror the messaging channels into `interaction-hub.html` (phone-keyed via
`EVENTS_MESSAGING_MESSAGE.RESOLVED_USER_PHONE`).

## Consolidation rebuild — agreed spec (2026-09-18)
Ant's feedback: 19 tabs is overkill. Agreed target = **10 tabs**, consolidating by medium
with the sub-type shown as a column. Consent folded into Profile.

**Target tabs:** Overview · Profile (+ consent/opt-out history) · Bookings (Listings + Pre-Listings)
· Payments · Stripe · Emails · Calls · Messages · Freshdesk · Feedback

**New unified queries (replace the per-channel ones):**
- `sar_emails_all` (:email) — TYPE column. UNION:
  - Marketing → `HARMONISED.PRODUCTION.EVENTS_EMAIL` (from live `sar_hubspot_emails`: EVENT_TIMESTAMP, EMAIL_EVENT_TYPE, EMAIL_SUBJECT, EMAIL_ADDRESS)
  - Transactional → `EVENTS_MESSAGING_MESSAGE` WHERE CHANNEL='EMAIL' (RENDERED_SUBJECT, MESSAGE)
  - System log → `LISTING_COMMUNICATION` WHERE CHANNEL='email' (TOKENS:subject)
  - Pre-Listing → source from live `sar_prelisting_emails` [FETCH its SQL — not yet captured]
- `sar_calls_all` (:phone_suffix) — TYPE column. UNION:
  - Twilio → `HARMONISED.PRODUCTION.TWILIO_CALL` (from live `sar_calls`: DIRECTION, STATUS, "FROM","TO", START_TIME, DURATION)
  - Aircall → `AIRCALL_CALL` (+ RECORDING url) — from sql/sar_aircall.sql
  - Transcript → source from live `sar_call_transcripts` [FETCH its SQL]
- `sar_messages_all` (:phone_suffix) — TYPE column. UNION:
  - WhatsApp/SMS → `TWILIO_MESSAGE` ('whatsapp:' prefix ⇒ WhatsApp else SMS) — from sql/sar_whatsapp_twilio.sql
  - 2-way chat → `TWILIO_CONVERSATION_MESSAGE` + `_PARTICIPANT` — from sql/sar_twilio_conversations.sql
  - Removal SMS → `LISTING_COMMUNICATION` WHERE CHANNEL='sms'
  - Live Chat → source from live `sar_sms`/live-chat query [FETCH — confirm table]
- `sar_bookings` (:email) — TYPE column (Listing / Pre-Listing). Combine live `sar_listings` [FETCH]
  + pre-listing records.

**Profile:** fold consent in — `HUBSPOT_CONTACT_PROPERTY_HISTORY` (from sql/sar_consent_history.sql)
+ `HUBSPOT_CONTACT_LIST_MEMBER` (marketing lists) + `DIM_USER_CUSTOMER` SMS-consent flags.

**Retire (delete_query) once the unions are live:** sar_hubspot_emails, sar_prelisting_emails,
sar_listing_comms, sar_calls, sar_sms, sar_call_transcripts, and my six (sar_messaging,
sar_comms_log, sar_consent_history, sar_whatsapp_twilio, sar_twilio_conversations, sar_aircall).

**Live source tables captured:** `sar_hubspot_emails`→`EVENTS_EMAIL`; `sar_calls`→`TWILIO_CALL`
(ID, DIRECTION, STATUS, "FROM", "TO", START_TIME, END_TIME, DURATION); `sar_sms`→`TWILIO_MESSAGE`
(same table as WhatsApp — SMS vs WhatsApp distinguished by the `whatsapp:` prefix on FROM/TO).
**Still to fetch before authoring the unions** (needs AV Dashboards MCP up): the live SQL of
`sar_prelisting_emails`, `sar_call_transcripts`, `sar_listings`.

**Deploy:** create the 4 unions → validate each in Snowflake → restructure HTML to the 10 tabs
(generic runOneQuery/buildTable handles rendering; each merged tab shows its TYPE column) →
get_upload_token → PUT → retire the old queries. Auto-versioned; rollback if needed.

**Data gap (unchanged):** Video Survey has no Snowflake table.
