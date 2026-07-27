# AnyVan-Privacy

Source-of-truth for AnyVan's privacy tooling — starting with the **Data Subject
Request (DSR) intake form** and its Freshdesk integration.

## What's here

## Direction

Going live for **both UK customers (public) and internal admins** on **one Formstack form**,
feeding the existing **workflow-system → Freshdesk** (the paved road here — mirrors the live
"Damage Claim - UK - Formstack" workflow). Rationale and alternatives in
`docs/public-hosting.md`. The custom HTML form below stays as the **interim internal tool**
until Formstack is live; the `backend/` Lambda is **superseded** by the workflow-system path
and is parked (not deployed).

| Path | What it is |
|---|---|
| `docs/go-live-guide.md` | **Start here** — the end-to-end, stage-by-stage runbook (owners + commands + checkpoints) to take the form live. |
| `docs/formstack-dsr-build.md` | **Build spec** for the DSR form in Formstack (pages, conditional logic, file upload, EU region/retention/spam, two entry points). |
| `docs/formstack-to-freshdesk-workflow.md` | **Runbook** to wire the Formstack form → workflow-system → Freshdesk. |
| `workflow/build-formstack-form.js` | Script that **creates the Formstack form** (fields + conditional logic) via the Formstack v2 API and prints the field-id map. Runs `--dry-run` with no token. |
| `workflow/` | The workflow definition: `actions.json`, `config_prompt.md`, `user_prompt.md`, `create.sh`. |
| `docs/dsr-field-mapping.md` | Single source of truth: form question → Formstack field id → Freshdesk field/tag. |
| `docs/freshdesk-custom-fields.md` | The `cf_*` custom fields to create in Freshdesk admin (and how to confirm their live keys). |
| `dsr-intake-form.html` | The custom DSR form (vanilla HTML/JS/CSS). Live internally on AV Dashboards at `operations/dsr-intake-form` — **interim** staff tool. Includes the account-holder checkbox fix. |
| `backend/` | **Superseded** Lambda (Freshdesk ticket creator) + SAM template + tests. Kept as reference/fallback; not deployed in the Formstack direction. See `docs/backend-runbook.md`. |
| `docs/public-hosting.md` | Hosting decision (Formstack) + the rejected self-hosted alternative. |
| `docs/dsr-intake-form-handoff.md` | Original handoff notes describing the form. |

## Status

- **Direction:** all-Formstack, single form, both audiences (decided). Formstack is an approved
  UK-PII processor — no procurement gate.
- **Custom form:** live at `https://dashboards.anyvan.com/operations/dsr-intake-form`
  (internal, `@anyvan.com` login), in **test mode**. Checkbox bug fixed and deployed (v1).
  Interim staff tool until Formstack is live.
- **Next:** build the Formstack form (`docs/formstack-dsr-build.md`), then create the workflow
  (`docs/formstack-to-freshdesk-workflow.md`). Both need account/admin access — see those docs.
- **Backend Lambda:** built + tested, **superseded** by the workflow-system path; parked.

## Deploying the form to AV Dashboards

The form already exists on the platform, so updates use an HTTP **`PUT`** (not the
`update_dashboard` MCP tool, which can truncate). Get a fresh 5-minute token via the
`AV_Dashboards` MCP `get_upload_token`, then:

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

Every upload is auto-versioned; roll back with the `AV_Dashboards` `rollback_dashboard`
tool. CloudFront caches the HTML — hard-refresh after deploying.

## Test the backend locally

```bash
cd backend && node test/local-invoke.js
```

## Going live (summary — Formstack direction, MVP)

**Full runbook: `docs/go-live-guide.md`.** MVP maps to **tags + a structured description** — no
Freshdesk custom fields required. In brief:
1. Build the DSR form in Formstack — `node workflow/build-formstack-form.js` (or by hand from
   `docs/formstack-dsr-build.md`); record field ids in `docs/dsr-field-mapping.md`.
2. Create the workflow (Formstack → Freshdesk), test in DRY_RUN, promote in the admin UI —
   `docs/formstack-to-freshdesk-workflow.md` + `workflow/`.
3. Publish the public URL (customers) and link the form in `/administer` (staff); retire the
   interim custom form.
4. _Later (optional):_ add the `cf_*` custom fields for structured reporting —
   `docs/freshdesk-custom-fields.md`.

_Rejected alternative (self-hosted Lambda + S3/CloudFront) is documented in
`docs/public-hosting.md` and `docs/backend-runbook.md` for the record._
