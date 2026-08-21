# AnyVan-Privacy

Working repository for AnyVan Privacy investigations — customer-data lookups (bookings and
communication-history / DSAR-style requests) run against HubSpot (CRM) and the Snowflake
`PRODUCTION` warehouse (read-only).

> ⚠️ **Records here contain customer PII and persist in git history.** Restricted to authorised
> AnyVan Privacy / Operations staff; handle in line with AnyVan's data-protection policy and UK
> GDPR. Redact secrets (e.g. the Twilio Account SID in recording URLs) before committing.

## Structure

- **[`CLAUDE.md`](CLAUDE.md)** — operating guide: hard rules, identity-resolution order, the data
  map, and Snowflake gotchas. **Read first.**
- **`booking-lookups/`** — one dated Markdown record per request (`YYYY-MM-DD-<subject>.md`), plus
  two reusable methodology docs:
  - **`METHODOLOGY-communication-history.md`** — locate **all communication** across every channel
    (calls, SMS/WhatsApp, email, chat, tickets, reviews): the channel → table map + query
    templates.
  - **`2026-08-18-phone-number-lookup-07497-700277.md`** — booking-lookup methodology
    (Template A: phone across customer / collection / delivery; Template B: postcode + date).

## Conventions

- Snowflake access is **read-only** (`SELECT` against `PRODUCTION` only).
- Start every record with the confidentiality header; **redact secrets** before committing —
  GitHub push protection will block a Twilio Account SID (`AC…`) or API token.
- Develop on a `claude/...` branch and open a **draft** PR. Docs-only repo — there is no CI.
