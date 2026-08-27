# AnyVan-Privacy

The home for **"All Things Privacy"** at AnyVan. Two kinds of content live here:

- **Reusable tooling & pipelines** — the Data Subject Request (DSR) intake pipeline, internal
  dashboards, and their docs/scripts.
- **Investigation records & methodologies** — dated privacy / DSAR lookups, each a Markdown record
  with the reusable method captured alongside.

> **Working in this repo?** Read **`CLAUDE.md`** first — it's the operating guide (the PII rule, the
> golden rules, the work-stream map, and the house style). This README is the human-facing index.

> ⚠️ **PII & git history.** Most records here contain **customer personal data** and persist in git
> history. Keep records behind their CONFIDENTIAL banner, minimise what you commit, keep bulk
> verbatim transcripts out of git, and never commit secrets. See `CLAUDE.md`.

---

## Work-streams

### 1. DSR intake pipeline — Formstack → workflow-system → Freshdesk
Going live for **both UK customers (public) and internal admins** on **one Formstack form**, feeding
the existing **workflow-system → Freshdesk** (mirrors the live "Damage Claim - UK - Formstack"
workflow). The interim internal HTML form stays until Formstack is live; the `backend/` Lambda is
**superseded** and parked (not deployed).

| Path | What it is |
|---|---|
| `docs/conventions.md` | **Read first for this work-stream** — consolidated conventions & gotchas (Formstack **V2025** API, number/date formatting, Freshdesk `cf_*`, workflow-system). |
| `docs/go-live-guide.md` | **Start here** — the end-to-end, stage-by-stage runbook to take the form live. |
| `docs/formstack-dsr-build.md` | Build spec for the DSR form in Formstack (pages, conditional logic, file upload, EU region/retention/spam). |
| `workflow/build-formstack-form.js` | Builds/updates the Formstack form via the **V2025** API. `--dry-run` (no token), full create, or additive `--form <id>` for the live form. |
| `workflow/` | The workflow definition: `actions.json`, `config_prompt.md`, `user_prompt.md`, `create.sh`. |
| `docs/formstack-to-freshdesk-workflow.md` | Runbook to wire the form → workflow-system → Freshdesk. |
| `docs/dsr-field-mapping.md` | Single source of truth: form question → Formstack field id → Freshdesk field/tag. |
| `docs/freshdesk-custom-fields.md` | The `cf_*` custom fields to create in Freshdesk admin (and how to confirm live keys). |
| `dsr-intake-form.html` | Interim internal DSR form, live on AV Dashboards `operations/dsr-intake-form`. |
| `backend/` · `docs/backend-runbook.md` | Superseded self-hosted Lambda; kept as reference/fallback, not deployed. |
| `docs/public-hosting.md` | Hosting decision (Formstack) + the rejected self-hosted alternative. |
| `skills/anyvan-formstack-freshdesk/` | The org-shareable skill distilled from `docs/conventions.md`. See `skills/README.md`. |

**Status:** direction decided (all-Formstack, single form). Form **built** — id `6559077`, **aligned
to the official DSRR template** (all 8 statutory rights + Marketing Opt-Out, ID verification,
address, third-party contact, declaration). Pending: run the additive `--form 6559077` apply (fresh
PAT) + record the new field ids; finish builder config (EU/UK region, retention, reCAPTCHA, theme,
confirmation email); then create + promote the workflow. See `docs/go-live-guide.md`.

### 2. Privacy investigations / lookups & DSAR sweeps
"Find X about a customer" requests — one dated record per request, plus reusable methodology.

| Path | What it is |
|---|---|
| `booking-lookups/2026-08-18-phone-number-lookup-07497-700277.md` | Bookings by **phone** (customer / collection / delivery) or **postcode + date** — Template A/B SQL. |
| `booking-lookups/METHODOLOGY-communication-history.md` | The **channel → table map** for all comms (calls, SMS/WhatsApp, email, chat, tickets), query templates. |
| `booking-lookups/2026-08-21-communication-history-andrea-canoppia.md` | Worked comms-history record. |
| `booking-lookups/2026-08-21-customer-transcripts-jennifer-kershaw.md` | Worked transcripts record (WhatsApp/Live Chat/calls) + retrieval method. |
| `communication-lookups/2026-08-24-comms-lookup-…jonathanjamesstansbie…07736348212.md` | Worked "locate all comms to a contact" record. |
| `templates/record.md` | House-style skeleton for a new PII investigation record. |

### 3. SAR/DSAR comms-automation design
The blueprint for automating Subject Access & Portability requests (documentation only — no external
systems changed).

| Path | What it is |
|---|---|
| `dsr-privacy-request-workflow-design.md` | End-to-end workflow: trigger, identity gate, named Snowflake queries, action chain, officer sign-off. |
| `customer-communications-mapping.md` | Data backbone — email/SMS/WhatsApp/marketing sources, coverage, portability JSON shape. |
| `SAR-Comms-Lookup-Reference.md` | Calls / 2-way WhatsApp / live chat — Aircall vs Twilio recording access + author classification. |
| `dsr-intake-form-handoff.md` | Form spec / request-type taxonomy for this design package (see the overlap note in `CLAUDE.md`). |

### 4. Dashboards & phone-number matching
| Path | What it is |
|---|---|
| `sar-data-extract.html` | GDPR SAR extract dashboard — pulls a customer's data across 12 Snowflake sources; JSON (Art. 20) + CSV export. |
| `interaction-hub.html` | Interaction Hub dashboard (phone-lookup fix: client normalisation + server suffix match). |
| `interaction-hub/2026-08-26-call-recording-playback-diagnosis.md` | Diagnosis + fix design for call-recording playback/download in the hub. |

### 5. Secure delivery of call recordings (SAR/DSAR)
| Path | What it is |
|---|---|
| `call-recording-delivery/2026-08-20-secure-call-recording-delivery-options.md` | Options appraisal for a secure, GDPR-appropriate alternative to WeTransfer Free. |
| `templates/options-appraisal.md` | House-style skeleton for a vendor/options appraisal (no-PII, INTERNAL banner). |

---

## Deploying a dashboard to AV Dashboards
The pages already exist on the platform, so updates use an HTTP **`PUT`** (not the `update_dashboard`
MCP tool, which can truncate). Get a fresh 5-minute token via the `AV_Dashboards` MCP
`get_upload_token`, then:

```bash
jq -n --rawfile html dsr-intake-form.html \
  --arg path "operations/dsr-intake-form" \
  --arg title "Data Subject Request Form" \
  '{html:$html, path:$path, title:$title}' > payload.json

curl -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data @payload.json \
  "https://63g6ly45b0.execute-api.eu-west-1.amazonaws.com/production/upload"
```

Every upload is auto-versioned; roll back with the `AV_Dashboards` `rollback_dashboard` tool.
CloudFront caches the HTML — hard-refresh after deploying.

## Skills
- **`.claude/skills/privacy-records/`** — repo-scoped, auto-loads here; produces a new record/appraisal
  in house style with the PII guardrail.
- **`skills/anyvan-formstack-freshdesk/`** — packaged, org-shareable; the DSR-pipeline conventions.
