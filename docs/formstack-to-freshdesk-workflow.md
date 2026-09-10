# Wiring the DSR Formstack form to Freshdesk (workflow-system)

Turns a DSR Formstack submission into a Freshdesk ticket via the workflow-system, mirroring the
existing **"Damage Claim - UK - Formstack"** workflow. The workflow only *creates* the ticket;
the existing `FRESHDESK_TICKET_CREATED` classifier routes it.

```
Formstack DSR submit ──FORMSTACK_FORM_SUBMITTED──► this workflow
   (AI eval: read submission, vision-check 3rd-party auth doc, map fields)
      └─► FRESHDESK_TICKET_CREATE (tags + description + cf_privacy_due_date)   ← MVP
              │
   FRESHDESK_TICKET_CREATED ──► existing classifier (routing/assignment)

   (later: add cf_* custom_fields, and an optional FORMSTACK_SUBMISSION_UPDATE
    to write the ticket id back — see docs/freshdesk-custom-fields.md)
```

Uses the **workflow-editor** skill (`workflow_edit.py`). Editing/creating always lands a
**DRY_RUN** version; **promotion to ACTIVE is a manual human step in the admin UI**
(https://workflows.anyvan.com) — the script cannot promote.

## Files in `workflow/`
- `actions.json` — the single `FRESHDESK_TICKET_CREATE` action (tags + a structured HTML
  description + the one `cf_privacy_due_date` date field).
- `config_prompt.md` — the AI config/system prompt (output contract + rules).
- `user_prompt.md` — the per-event instruction.
- `create.sh` — the `workflow_edit.py create` invocation tying it together.

> **MVP:** this workflow maps to ticket **tags + a structured HTML description + one date custom
> field** (`cf_privacy_due_date`, the statutory due date) — no dropdown/text custom fields, no
> submission write-back. `actions.json` is a single `FRESHDESK_TICKET_CREATE`. Adding the deferred
> `cf_*` dropdown/text fields later is a small edit (extend `custom_fields` and re-create a
> version) — see `docs/freshdesk-custom-fields.md`.

## Prerequisites
1. **Formstack form built** (`workflow/build-formstack-form.js` or `docs/formstack-dsr-build.md`)
   — you need its **FORM ID** and the submission-id path.
2. **`WF_JWT`** exported — "Copy token" in the admin UI header (prod token for prod; ~12h).

## Placeholders to fill before creating
| Placeholder | Where | What |
|---|---|---|
| `<FORMSTACK_FORM_ID>` | `create.sh` | the DSR form's numeric id (used in `event_filter`) |
| `{event.payload.UniqueID}` | `user_prompt.md` | the real submission-id path in a `FORMSTACK_FORM_SUBMITTED` payload — confirm from a test event or `catalogue` |

Confirm the event payload path and that `FORMSTACK_FORM_SUBMITTED` is live:
```bash
python3 "$SK" catalogue --env prod     # SK = path to workflow_edit.py; no JWT needed
```

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
   Confirm: ticket created; `subject` = `DSR-<id> — <type> (<requester>)`; **tags** rendered
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
