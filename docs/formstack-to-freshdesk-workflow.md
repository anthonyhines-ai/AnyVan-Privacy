# Wiring the DSR Formstack form to Freshdesk (workflow-system)

Turns a DSR Formstack submission into a Freshdesk ticket via the workflow-system, mirroring the
existing **"Damage Claim - UK - Formstack"** workflow.

## ⚠️ Deployed reality (v43 — reconciled 2026-11-24)
Much of the detail further down describes the original **MVP** (one action, tags + description) and
is kept for history. **What is actually live has moved well past it** — the repo files now mirror it
(`workflow/deployed-v43.json` is the lossless source of truth):

- **`[UK] Privacy Submission Workflow [TEST]` is v43, ACTIVE** (since 2026-10-29) and processing real
  submissions. The `[TEST]` in the name is cosmetic — **this is the production privacy intake.**
- It is a **4-action SAR-assembly workflow**, not a ticket-stamper:
  1. **`FRESHDESK_TICKET_CREATE`** — ticket with the request + verification tables; tags
     `["privacy","{request_type_tag}","{requester_type_tag}"]`; custom fields `cf_privacy_due_date`
     **and** `cf_privacy_request_type`.
  2. **`FRESHDESK_TICKET_COMMENT`** — a private note with the findings, **attaching** the uploaded
     proof-of-authorisation file(s).
  3. **`EVENTBUS_EVENT_PUBLISH`** — an audit event (identity result, scope, callout, ids).
  4. **`FORMSTACK_SUBMISSION_UPDATE`** — writes the `ticket_id` back to Formstack field `199789402`.
- It runs **~12 named read-only Snowflake queries** (`workflow/snowflake_queries.json`) to actually
  **assemble the SAR data**, scoped to what was requested. Agentic tools now include `snowflake_query`
  and `v4_listing_lookup`; model **Haiku 5.5**; `max_iterations` 16; `action_selection_mode` locked.
- **⚠️ Group targeting:** the live `FRESHDESK_TICKET_CREATE` still writes to the **sandbox** group
  **`31000119185`** (*Privacy [Ant Automation Testing]*), **not** the live Privacy queue `31000116264`.
  `env:test` has been dropped from the tags. Confirm this is the intended queue; flipping to the live
  queue is a one-field change (`workflow/actions.json` is the ready live-group variant).
- The subject is `[UK] <requester> Privacy Request [Ref: DSR-UK-{id}]` (the `DSR-UK-<id> — <type>`
  format mentioned in "Validate" below is **stale**).
- The workflow is now edited in the **admin UI / workflow-system MCP**; **`create.sh` is legacy** (its
  `workflow_edit.py` CLI is no longer shipped). After any UI edit, re-reconcile the repo from the live
  definition so these files stay truthful.

The workflow only *creates* the ticket; the existing `FRESHDESK_TICKET_CREATED` classifier routes it.

> **Gate 0 — the form must publish the event.** The workflow consumes `FORMSTACK_FORM_SUBMITTED`,
> which only fires if the Formstack form has a **webhook** to `https://events.anyvan.com/v1/formstack/form-submitted`.
> The Damage form (6200752) has one; the Privacy form (6559077) did **not** — so until the webhook
> exists, no submission reaches the workflow and **zero** tickets are created, however correct the
> workflow is. Create it with `workflow/create-webhook.mjs` (mirrors the Damage webhook; copies the
> HMAC signing secret at runtime — never printed/committed):
> ```bash
> export FORMSTACK_TOKEN="<fresh fs_pat_… PAT>"
> node workflow/create-webhook.mjs          # idempotent; aborts if one already exists
> node workflow/create-webhook.mjs --verify # list the form's webhooks
> ```
> **Verify:** after the workflow is ACTIVE, send one test submission and check the executions feed.
> An execution = `events.anyvan.com` accepted the signature. No execution = HMAC/registration issue;
> the signing secret may be per-form, so ask the platform team (tom.michaelis@anyvan.com) to register
> form 6559077. The webhook is form-level (prod) — the test/live split lives in the **workflow**
> (`actions.test.json` → sandbox group `31000119185`), not the webhook.

```
Formstack DSR submit ──FORMSTACK_FORM_SUBMITTED──► this workflow
   (AI eval: read submission, vision-check 3rd-party auth doc, map fields)
      └─► FRESHDESK_TICKET_CREATE (tags + structured HTML description)   ← MVP
              │
   FRESHDESK_TICKET_CREATED ──► existing classifier (routing/assignment)

   (later: add cf_* custom_fields, and an optional FORMSTACK_SUBMISSION_UPDATE
    to write the ticket id back — see docs/freshdesk-custom-fields.md)
```

Uses the **workflow-editor** skill (`workflow_edit.py`). Editing/creating always lands a
**DRY_RUN** version; **promotion to ACTIVE is a manual human step in the admin UI**
(https://workflows.anyvan.com) — the script cannot promote.

## Customer reply handling — auto-merge (`freshdesk-merge-dsr-replies.mjs`)
The customer confirmation is sent by **Formstack**, so a customer's reply has no Freshdesk ticket id
to thread on and Freshdesk opens a **new** ticket (`Re: Your AnyVan Privacy Request: Reference
DSR-<id>`) instead of threading onto the original. `workflow/freshdesk-merge-dsr-replies.mjs` merges
each reply ticket back into its original.

- **Match key:** the submission id — reply subject `…DSR-<id>`, original subject `… [<id>]`.
- **Safety (PII queue):** merges only when there is **exactly one** original with that id **and the
  requester is the same contact** (`requester_id`), within the privacy groups only. DRY-RUN by
  default; `--apply` executes; `--once <id>` tests a single reply. Anything ambiguous is skipped for
  a human.
- **Deploy:** run the `--apply` form on a schedule (cron / scheduler), or import its match logic into
  a webhook handler fed by a Freshdesk Ticket-Creation rule.
- **Structural alternative (not taken):** sending the acknowledgement from Freshdesk instead of
  Formstack would make replies thread natively and remove the need for this merge. Chosen path is
  the merge; revisit if reply volume grows.

> **Not runnable from the cloud session** (no Freshdesk API access there, and merge is destructive).
> Always run the DRY-RUN first and confirm the "WOULD MERGE" lines before `--apply`.

## Files in `workflow/`
- `deployed-v43.json` — **lossless snapshot of the live workflow** (source of truth after any UI edit).
- `actions.json` / `actions.test.json` — the **4-action** chain (create → private comment w/ auth-file
  attachment → eventbus audit → Formstack submission write-back). `actions.test.json` is exactly what
  is deployed (sandbox group `31000119185`); `actions.json` is the identical chain pinned to the live
  Privacy group `31000116264`, ready for the go-live flip.
- `snowflake_queries.json` — the ~12 named read-only queries the workflow runs to assemble the SAR.
- `config_prompt.md` — the AI config/system prompt (checks, output contract, mappings, rules).
- `user_prompt.md` — the per-event instruction.
- `create.sh` — **legacy / reference only** (see the header in the file; its CLI is no longer shipped).

> **(Historical — superseded by v43; see "Deployed reality" at the top.)**
> **MVP:** this workflow maps to ticket **tags + a structured HTML description + one date custom
> field** (`cf_privacy_due_date`, the statutory deadline). No dropdown/text custom fields and no
> submission write-back yet. `actions.json` is a single `FRESHDESK_TICKET_CREATE`. Adding the
> dropdown `cf_*` fields later is a small edit (extend `custom_fields` and re-create a version) —
> see `docs/freshdesk-custom-fields.md`.

## Prerequisites
1. **Formstack form built** (`workflow/build-formstack-form.js` or `docs/formstack-dsr-build.md`)
   — you need its **FORM ID** and the submission-id path.
2. **`WF_JWT`** exported — "Copy token" in the admin UI header (prod token for prod; ~12h).

## Placeholders to fill before creating
| Placeholder | Where | What |
|---|---|---|
| `<FORMSTACK_FORM_ID>` | `create.sh` | the DSR form's numeric id (used in `event_filter`) |
| `{event.payload.uniqueId}` | `user_prompt.md` | the submission-id path in a `FORMSTACK_FORM_SUBMITTED` payload — **confirmed camelCase** (the workflow-system normalises the raw Formstack webhook `UniqueID`/`FormID` to `uniqueId`/`formId`) |

Confirm `FORMSTACK_FORM_SUBMITTED` is live (lists event **names** only — it does NOT expose the payload shape):
```bash
python3 "$SK" catalogue --env prod     # SK = path to workflow_edit.py; no JWT needed
```
To confirm the payload **path/casing**, inspect a real event instead — either a live sibling
workflow's config (`workflow_edit.py get <id>`, e.g. the Damage Claim UK workflow whose
`event_filter` is `payload.formId = …`) or a real execution
(`workflow_doctor.py exec <id> --json` → `event_payload.payload`). Verified: keys are `uniqueId` / `formId`.

## Create (lands DRY_RUN)
```bash
export WF_JWT="<paste from admin UI>"
bash workflow/create.sh
```
Note the returned `workflow_id` + `version`.

## Validate, then promote (manual)
1. In the admin UI, open the new DRY_RUN version and review the actions/prompt.
2. Send a **test submission** from the Formstack form (do this per requester type: customer SAR
   with calls, TP limited deletion, third-party with an auth file).
3. Check the run on the executions feed (workflow-doctor):
   ```bash
   python3 ~/.claude/skills/workflow-doctor/workflow_doctor.py executions --env prod --jwt "$WF_JWT" | head
   ```
   Confirm: ticket created; `subject` = `DSR-UK-<id> — <type> (<requester>)`; **tags** rendered
   correctly (verify the templated array elements landed as separate tags — if the handler
   doesn't element-render arrays, have the model emit the two type tags into the description
   or switch to a follow-up update); the **description** carries every field (booking ref, TP
   username, request detail); the third-party vision read appears in the description.
4. Confirm the existing classifier fired on `FRESHDESK_TICKET_CREATED`:
   ```bash
   python3 ~/.claude/skills/workflow-editor/workflow_edit.py list --env prod --jwt "$WF_JWT" | grep -i freshdesk
   ```
5. **Promote to ACTIVE manually** in the admin UI once the DRY_RUN run looks right.

## Notes
- `requires_ai_evaluation: true` is required for the Formstack read/vision tools — the create
  command sets it and provides both `config_prompt` and `user_prompt` (non-empty, as required).
- The default model (Haiku 4.5) is fine for this mapping; bump to a Sonnet/Opus id in `create.sh`
  (`--set bedrock_model_id=…`) only if the mapping proves unreliable.
- Keep `actions.json`/prompts in this repo as the source of truth; edit here and re-create a new
  version rather than hand-editing in the UI (browser autofill has corrupted fields before).
