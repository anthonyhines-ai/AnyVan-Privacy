# AnyVan-Privacy — working guide for Claude

Conventions, identity-resolution order, the data map, and the gotchas for privacy / DSAR-style
customer lookups in this repo. **Read this before starting any lookup.**

## What this repo is
- A working store for AnyVan Privacy investigations — "find X about a customer" requests
  (booking lookups, communication-history / DSAR sweeps).
- Each request → **one dated Markdown record** under `booking-lookups/` (`YYYY-MM-DD-<subject>.md`).
- Reusable know-how lives in the methodology docs (see **Where the data lives**). When you learn
  something new, extend them — that is the point of this repo.

## Hard rules
1. **PII.** Every record holds customer personal data and **persists in git history**. Start each
   record with the confidentiality header (copy from an existing record) and never commit more
   than the investigation needs.
2. **Redact secrets before committing.** Twilio call-recording URLs embed the **Twilio Account
   SID** (`AC` + 32 hex). GitHub push protection **blocks** any commit containing it — replace it
   with `<TWILIO_ACCOUNT_SID>`. The SID is recoverable from the HubSpot call engagement or the
   Twilio console when audio is actually needed. Same for any API key/token.
3. **Snowflake is read-only.** `SELECT` against `PRODUCTION` only. Never write.
4. **Branch / PR.** Work on the designated `claude/...` branch and open a **draft** PR. This is a
   docs-only repo with **no CI** — a "pending" combined status with 0 checks is normal, not a
   failure.

## Identity resolution (do this first, in order)
1. HubSpot `search_crm_objects` on **CONTACT** by **email** (most reliable), then name, then
   phone. Phone numbers are **not unique** in HubSpot — check every identifier and watch for
   duplicate contacts (see the `anyvan-hubspot-triage` skill).
2. Contact → **associated DEALs**. Deal names embed a *prelisting* id + price, e.g.
   `Furniture - 28091313 / £310`.
3. Snowflake account: `CONFORMED.PRODUCTION.DIM_USER_CUSTOMER` by email + phone (last-10 match)
   → `USER_ID`.
4. **Prelisting id ≠ listing id.** Quotes/deals carry 8-digit *prelisting* ids (`28091313`); only
   **paid/confirmed** jobs become a *listing* (`9473099`) in `CONFORMED.PRODUCTION.MASTER_LISTING`
   / `HARMONISED.PRODUCTION.LISTING`. Not every deal converts — expect fewer listings than deals.

## Where the data lives
- **Bookings** (is there a job? where/when/who?) → `booking-lookups/2026-08-18-phone-number-lookup-07497-700277.md`
  (Template A: phone across customer / collection / delivery roles; Template B: postcode + date).
- **Communication** (calls, SMS/WhatsApp, email, chat, tickets, reviews) →
  `booking-lookups/METHODOLOGY-communication-history.md` (full channel → table map + templates).

## Snowflake gotchas
- **Phone match:** `RIGHT(REGEXP_REPLACE(num,'[^0-9]',''),10)` — matches `0…`, `44…`, `+44…`, and
  `whatsapp:+44…`.
- **`FROM` / `TO` are reserved words** — double-quote them (`"FROM"`, `"TO"`) in `TWILIO_CALL` /
  `TWILIO_MESSAGE`.
- **`SNOWFLAKE.ACCOUNT_USAGE` is not authorised** — discover tables/columns via per-database
  `INFORMATION_SCHEMA.TABLES` / `.COLUMNS`.
- **`LISTING_TERRORITY`** is an intentional schema typo — use it as-is.
- **Don't confuse the customer's number with AnyVan's own.** The contact's `anyvanPhoneNumber`
  (e.g. `020 4587 9764`) is a **call-tracking proxy**; it is distinct from both the inbound
  support line the customer dials and the AnyVan WhatsApp sender.

## Tools
- **Snowflake:** `mcp__Snowflake__sql_exec`. For authoritative table/column docs, the `anyvan-data`
  skill routes to the right table.
- **HubSpot:** `mcp__HubSpot__search_crm_objects` — objects `CONTACT`, `DEAL`, and engagements
  `EMAIL` / `CALL` / `NOTE` / `TASK` / `MEETING_EVENT`. There is **no** SMS/WhatsApp
  `COMMUNICATION` object. Associate engagements with **both** the contact and its deals — some
  link to only one.
- **AnyVan MCP:** `get_hubspot_contact_properties(contactId)`,
  `get_hubspot_deal_properties(prelistingId)`, `get_conversation_transcript(dealId)`
  (**Jiminny calls only** — returns nothing for Twilio Flex calls), `get_move_information(hash)`,
  `get_agent_information_for_move(hash)`.
- Consider `/fewer-permission-prompts` to allowlist the common read-only Snowflake / HubSpot /
  AnyVan-MCP calls and cut permission prompts on repeat lookups.
