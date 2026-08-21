# CLAUDE.md — AnyVan Privacy / Booking-Lookup workspace

Working notes for Claude Code sessions in this repo. Read this first — it points to the
reusable playbooks so you don't re-discover the data model each time.

## What this repo is

A private log of **privacy / booking / customer investigations** run against AnyVan's
Snowflake warehouse (read-only) and MCP tools. Each investigation is written up as a
**dated Markdown record** under `booking-lookups/`, and every record ends with a reusable
**"Methodology / Learning"** section. Treat those methodology sections as the knowledge
base — extend them, don't repeat the discovery.

## Reusable playbooks (start here)

| You need to… | Read | Key sources |
|---|---|---|
| Find bookings by a **phone number** (customer / collection / delivery contact), or by **postcode + date** | `booking-lookups/2026-08-18-phone-number-lookup-07497-700277.md` | `MASTER_LISTING`, `DIM_ADDRESS`, `DIM_USER_CUSTOMER`, `HARMONISED.LISTING`/`ADDRESS` |
| Retrieve **all comms transcripts** for a customer (**WhatsApp / Live Chat / calls**) | `booking-lookups/2026-08-21-customer-transcripts-jennifer-kershaw.md` | `TWILIO_CONVERSATION_MESSAGE` (bodies), `SOPHIE_LIVE_CHAT_INCREMENTAL`, `JIMINNY_CALL_TRANSCRIPT` / `CALL_TRANSCRIPT_SEGMENTS` |

## Golden rules (learned the hard way)

- **Read-only, `PRODUCTION` only.** Never write to Snowflake; never query dev/staging.
- **Prefer the `anyvan-data` skill** to route a question to the right table, then read the
  table's `information_schema` comment for its filters/pitfalls before querying. But note
  its routing is **not exhaustive** — e.g. for chat/WhatsApp *transcripts* it points at
  metadata tables; the message **bodies** are in `HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE`.
- **Normalise before matching.**
  - Phone → `RIGHT(REGEXP_REPLACE(num,'[^0-9]',''),10)` (last 10 digits; matches every stored format).
  - Postcode → `REPLACE(UPPER(pc),' ','')`.
  - **Never** substring-match an account/user **ID** against phone digit strings — it false-matches numbers that happen to contain that run.
- **One customer can have several phone numbers** — and the number a requester gives you
  may not be the one on the account. Resolve identity from **email + every phone**, and
  cross-confirm via booking ref / email appearing in the data.
- **`LISTING_ID` is the cross-channel join key** (bookings, chats, calls, addresses).
- **Metadata ≠ content.** `FACT_WHATSAPP_ACTIVITY` / `FACT_VOICE_ACTIVITY` tell you a
  contact happened; the transcript lives elsewhere (see the transcripts playbook).
- **`LISTING_TERRORITY`** is an intentional schema typo — use it as-is.

## Conventions for new records

- File name: `booking-lookups/YYYY-MM-DD-<type>-<subject>.md`.
- Start with the **PII warning header** and a metadata table (record type, date, raised by,
  data source, subject). End with a **Methodology / Learning** section and **Governance notes**.
- **PII in git:** these records contain customer PII and persist in git history. Commit the
  **investigation result + reusable method**; keep **bulk verbatim content** (full chat/call
  transcripts) **out of git** — deliver those to the requester as a separate export and note
  where it went. When in doubt, redact.

## Tooling notes

- **Snowflake:** `mcp__Snowflake__sql_exec` (read-only queries).
- **AnyVan MCP:** `get_hubspot_deal_properties` / `get_hubspot_contact_properties` /
  `get_move_information` / `get_conversation_transcript`. ⚠️ `get_conversation_transcript`
  is **Jiminny CALL transcripts by `dealId` only** — it is **not** WhatsApp/Live Chat.
- Deliverables the requester should see → send as a file (transcripts, exports); don't
  publish customer PII to a hosted artifact.
