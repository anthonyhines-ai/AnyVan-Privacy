# DSR backend — deploy & wiring runbook

This connects the DSR intake form to Freshdesk so submissions raise real tickets.
Everything here needs AWS + Freshdesk admin access, so it is **not** done from the
Claude Code session that authored the code — follow it in an environment with those
credentials.

## Architecture

```
dsr-intake-form.html  ──POST JSON──►  API Gateway  ──►  Lambda (backend/handler.js)
                                                              │
                                                              ├─ POST /api/v2/tickets   (create ticket + custom fields + tags)
                                                              └─ POST /api/v2/tickets/{id}/notes  (private note + attachments)
                                                              │
                                                     FRESHDESK_TICKET_CREATED event
                                                              │
                                                     existing workflow-system classifier  ──► routing/assignment
```

The Lambda's only job is to create the ticket. The existing **workflow-system**
classifier (a workflow subscribed to `FRESHDESK_TICKET_CREATED`) handles routing — we
do not build a classifier here. Confirm one exists with the `workflow-editor` tooling:

```bash
python3 ~/.claude/skills/workflow-editor/workflow_edit.py list --env prod --jwt "$WF_JWT" | grep -i freshdesk
# and inspect any workflow whose subscribed_events include FRESHDESK_TICKET_CREATED
```

## Prerequisites

1. **Freshdesk custom fields** created and their live `cf_*` keys confirmed — see
   [`freshdesk-custom-fields.md`](./freshdesk-custom-fields.md).
2. **Freshdesk API key** stored in AWS Secrets Manager (note the secret ARN). The key is
   used as basic-auth username with password `X`.
3. **Freshdesk domain** subdomain (e.g. `anyvan` → `https://anyvan.freshdesk.com`).
4. AWS SAM CLI (or CDK/console equivalent) and credentials for the target account/region.

## Deploy (AWS SAM)

From `backend/`:

```bash
sam build
sam deploy --guided \
  --stack-name dsr-intake-backend \
  --parameter-overrides \
    FreshdeskDomain=anyvan \
    FreshdeskApiKeySecretArn=arn:aws:secretsmanager:eu-west-1:<acct>:secret:freshdesk_api_key-XXXX \
    FreshdeskGroupId=<optional group id> \
    AllowedOrigin=https://dashboards.anyvan.com
```

Note the `ApiEndpoint` output — that is the URL the form posts to.

If any live `cf_*` key differs from the defaults, add the matching `CF_*` env var to the
function (via the template `Environment.Variables` or the console) before real traffic.

## Wire the form to the endpoint

In `dsr-intake-form.html`, set the endpoint:

```js
const CONFIG = { API_ENDPOINT: 'https://<api-id>.execute-api.eu-west-1.amazonaws.com/Prod/dsr' };
```

Then redeploy the dashboard (see the repo README for the exact `PUT` command) and remove
the `INTERNAL TEST MODE` banner. While `API_ENDPOINT` is `''` the form stays in test mode
and renders the payload on screen instead of sending it.

## Verify end-to-end

1. Open the form, submit a test request of each requester type.
2. Confirm a Freshdesk ticket is created with the right subject, tags, custom fields, and a
   private note; the third-party case should have the uploaded file attached.
3. Confirm the classifier workflow fired (check its execution feed):
   ```bash
   python3 ~/.claude/skills/workflow-doctor/workflow_doctor.py executions --env prod --jwt "$WF_JWT" | head
   ```
4. Confirm the form displays the returned `dsr_reference`.

## Troubleshooting

- **`invalid_field` on ticket create** → a `cf_*` key is stale; re-run the `ticket_fields`
  lookup and set the `CF_*` env var.
- **`datatype_mismatch`** → a custom field is a *number* type; send the typed form
  `{ "cf_x": { "value": "…", "type": "number" } }` (adjust `buildCustomFields`).
- **429** → the handler already retries honouring `Retry-After`; sustained 429s mean the
  Freshdesk plan's rate limit is being hit by other traffic.
- **Attachment rejected** → check file type/size; Freshdesk caps total attachment size per
  request (20MB) — the form already limits to 10MB per file.
- Failed Freshdesk responses are logged to CloudWatch (and, in the workflow-system,
  surface in Datadog under `service:workflow-system`).
