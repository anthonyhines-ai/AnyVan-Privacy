# AnyVan-Privacy

Project location on GitHub for all things privacy.

## DSR / SAR communications automation — design package

This repo holds the design for automating **Subject Access Requests (SAR)** and **Data
Portability** requests: a customer submits a Formstack privacy form → the workflow-system
resolves their identity and assembles every communication AnyVan sent them → it drops the pack
into a Freshdesk ticket with an audit note → a **privacy officer verifies, signs off, and
shares** the deliverable.

### The documents (read in this order)

| Doc | What it covers |
|---|---|
| [`customer-communications-mapping.md`](customer-communications-mapping.md) | **Data backbone** — the Snowflake/HubSpot/Twilio tables for email, SMS, WhatsApp & marketing, with content sources, coverage and the portability JSON shape. Schema verified against live Snowflake 2026-08-19. |
| [`SAR-Comms-Lookup-Reference.md`](SAR-Comms-Lookup-Reference.md) | **Calls, 2-way WhatsApp & live chat** — Aircall vs Twilio recordings (incl. the Twilio Flex "copy link for download" runbook), author classification. |
| [`dsr-intake-form-handoff.md`](dsr-intake-form-handoff.md) | **Formstack intake form** — fields, request-type taxonomy, JSON payload convention, Freshdesk `cf_` mapping. |
| [`dsr-privacy-request-workflow-design.md`](dsr-privacy-request-workflow-design.md) | **The automation** — trigger, identity gate, named Snowflake queries, action chain, output pack, validation checklist, build/promote steps. |

### Status

Design package only — no external systems have been changed. Building the Formstack form and
the (DRY_RUN) workflow is the next cycle; it needs the workflow-system JWT, the live Formstack
`field_<NNN>` IDs, and the Freshdesk `cf_` names — see the workflow-design doc §12.

### Key decisions baked in

- **Identity:** three-point cross-check (name / email / phone vs our system), routed by requester type (customer · TP · third-party→manual admin check) + **mandatory privacy-officer sign-off** before any release.
- **Delivery:** workflow assembles → Freshdesk note → officer compiles & shares, **or** exports the file from a parameterised DSR **AV Dashboard** (workflow → Snowflake → dashboard).
- **Call recordings:** Aircall URL direct from Snowflake; Twilio via the Flex download-and-attach step.
- **Validation:** an explicit completeness / SLA / third-party-PII-redaction checklist on every ticket.
