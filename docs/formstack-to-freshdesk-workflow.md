# Wiring the DSR Formstack form to Freshdesk (workflow-system)

Turns a DSR Formstack submission into a Freshdesk ticket via the workflow-system, mirroring the
existing **"Damage Claim - UK - Formstack"** workflow. The workflow only *creates* the ticket;
the existing `FRESHDESK_TICKET_CREATED` classifier routes it.

```
Formstack DSR submit ──FORMSTACK_FORM_SUBMITTED──► this workflow
   (AI eval: read submission, vision-check 3rd-party auth doc, map fields)
      └─► FRESHDESK_TICKET_CREATE (cf_* + tags + cf_formstack_id)
      └─► FORMSTACK_SUBMISSION_UPDATE (write ticket id back)  [optional]
              │
   FRESHDESK_TICKET_CREATED ──► existing classifier (routing/assignment)
```

Uses the **workflow-editor** skill (`workflow_edit.py`). Editing/creating always lands a
**DRY_RUN** version; **promotion to ACTIVE is a manual human step in the admin UI**
(https://workflows.anyvan.com) — the script cannot promote.

## Files in `workflow/`
- `actions.json` — the two actions (`FRESHDESK_TICKET_CREATE`, `FORMSTACK_SUBMISSION_UPDATE`).
- `config_prompt.md` — the AI config/system prompt (output contract + rules).
- `user_prompt.md` — the per-event instruction.
- `create.sh` — the `workflow_edit.py create` invocation tying it together.

## Prerequisites
1. **Formstack form built** (`docs/formstack-dsr-build.md`) — you need its **FORM ID** and the
   numeric **field ids**, recorded in `docs/dsr-field-mapping.md`.
2. **Freshdesk fields** created and their live keys/types confirmed
   (`docs/freshdesk-custom-fields.md`): `cf_dsr_type`, `cf_requester_type`,
   `cf_booking_reference`, `cf_tp_username`, and the existing `cf_formstack_id`.
3. **`WF_JWT`** exported — "Copy token" in the admin UI header (prod token for prod; ~12h).

## Placeholders to fill before creating
| Placeholder | Where | What |
|---|---|---|
| `<FORMSTACK_FORM_ID>` | `create.sh` | the DSR form's numeric id (used in `event_filter`) |
| `{event.payload.UniqueID}` | `actions.json` (×3) | the real submission-id path in a `FORMSTACK_FORM_SUBMITTED` payload — confirm from a test event or `catalogue` |
| `field_FRESHDESK_TICKET_ID_FIELD` | `actions.json` | Formstack field id of a "Freshdesk Ticket ID" field for the write-back (or delete this action if not writing back) |
| `cf_formstack_id` type/key | `actions.json` | confirm via `GET /api/v2/ticket_fields`; sent as a typed number by default |

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
   or switch to a follow-up update); `cf_*` mapped; `cf_formstack_id` set; the third-party
   vision read appears in the description.
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
