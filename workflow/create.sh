#!/usr/bin/env bash
# Create the "DSR Intake - UK - Formstack" workflow in the workflow-system.
#
# Prerequisites:
#   - WF_JWT exported (copy "Copy token" from https://workflows.anyvan.com admin UI; ~12h).
#   - The Formstack DSR form built (docs/formstack-dsr-build.md) so you have its FORM ID and
#     the numeric field ids for the field_map below.
#   - The Freshdesk cf_* fields created and their LIVE keys/types confirmed via
#     GET /api/v2/ticket_fields (docs/freshdesk-custom-fields.md).
#
# This lands a DRY_RUN version. Promotion to ACTIVE is a manual, human-reviewed step in the
# admin UI — this script does NOT promote.
#
# Fill every <PLACEHOLDER> before running.
set -euo pipefail

SK="${CLAUDE_SKILL_DIR:-$HOME/.claude/skills/workflow-editor}/workflow_edit.py"
ENVv="${ENVv:-prod}"

# ---- placeholders you must set ------------------------------------------------
FORMSTACK_FORM_ID="<FORMSTACK_FORM_ID>"     # numeric Formstack form id of the DSR form
# In actions.json also replace:
#   {event.payload.UniqueID}  -> the actual submission-id path from a real event payload
#   field_FRESHDESK_TICKET_ID_FIELD -> the Formstack field id of a "Freshdesk Ticket ID" field
#   cf_formstack_id type/key  -> confirm against GET /api/v2/ticket_fields
# -------------------------------------------------------------------------------

cd "$(dirname "$0")/.."   # repo root, so the file paths below resolve

python3 "$SK" create --env "$ENVv" --jwt "$WF_JWT" \
  --name "DSR Intake - UK - Formstack" \
  --user-prompt-file workflow/user_prompt.md \
  --actions-file      workflow/actions.json \
  --set requires_ai_evaluation=true \
  --set 'subscribed_events=["FORMSTACK_FORM_SUBMITTED"]' \
  --set 'agentic_tools=["formstack_submission","formstack_upload","formstack_upload_interpret"]' \
  --set max_iterations=8 \
  --set "event_filter=payload.FormID == \"${FORMSTACK_FORM_ID}\"" \
  --set config_prompt="$(cat workflow/config_prompt.md)"

echo
echo "Created as DRY_RUN. Review and PROMOTE manually at https://workflows.anyvan.com."
echo "Then send a test submission per docs/formstack-to-freshdesk-workflow.md."
