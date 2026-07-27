# AnyVan-Privacy

Source-of-truth for AnyVan's privacy tooling — starting with the **Data Subject
Request (DSR) intake form** and its Freshdesk integration.

## What's here

| Path | What it is |
|---|---|
| `dsr-intake-form.html` | The DSR intake form (vanilla HTML/JS/CSS, no build step). Deployed to AV Dashboards at `operations/dsr-intake-form`. Includes the account-holder checkbox fix and backend submit-wiring behind a config flag. |
| `backend/handler.js` | AWS Lambda that turns a form submission into a Freshdesk ticket (+ private note + attachments) and returns the DSR reference. Zero dependencies (Node 18+ native `fetch`). |
| `backend/template.yaml` | AWS SAM template — Lambda + API Gateway `POST /dsr`. |
| `backend/test/local-invoke.js` | Offline test that stubs `fetch` and checks ticket/tag/custom-field/attachment shaping. |
| `docs/freshdesk-custom-fields.md` | The `cf_*` custom fields to create in Freshdesk admin (and how to confirm their live keys). |
| `docs/backend-runbook.md` | How to deploy the backend and wire the form to it. |
| `docs/public-hosting.md` | Options for a customer-facing (unauthenticated) deployment — a later, infra-led phase. |
| `docs/dsr-intake-form-handoff.md` | Original handoff notes describing the form. |

## Status

- **Form:** live at `https://dashboards.anyvan.com/operations/dsr-intake-form`
  (internal, `@anyvan.com` login required). Currently in **test mode** — on submit it
  renders the JSON payload rather than sending it.
- **Checkbox bug:** fixed and deployed (v1).
- **Backend:** written and tested here; **not yet deployed** (needs AWS + Freshdesk admin).
  Follow `docs/backend-runbook.md`.

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

## Going live (summary)

1. Create the Freshdesk custom fields — `docs/freshdesk-custom-fields.md`.
2. Deploy the backend and note the API endpoint — `docs/backend-runbook.md`.
3. Set `CONFIG.API_ENDPOINT` in `dsr-intake-form.html`, remove the test banner, redeploy.
4. (Optional, later) stand up customer-facing hosting — `docs/public-hosting.md`.
