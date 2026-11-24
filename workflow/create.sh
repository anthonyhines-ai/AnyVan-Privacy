#!/usr/bin/env bash
# ⚠️ LEGACY / REFERENCE ONLY — do not treat this as able to reproduce the live workflow.
# The deployed "[UK] Privacy Submission Workflow [TEST]" is now edited via the admin UI /
# workflow-system MCP, NOT this script. As of the 2026-11-24 reconcile it is a 4-action
# SAR-assembly workflow (create ticket → private note w/ auth-file attachment → eventbus audit
# event → Formstack ticket-id write-back) backed by ~12 named Snowflake queries. This CLI shape
# (one --actions-file + scalar --set) cannot express that action chain, the snowflake_queries,
# the per-model inference profiles, or action_selection_mode. The authoritative, lossless copy of
# what is live is **workflow/deployed-v43.json**; config_prompt.md / user_prompt.md / actions*.json
# / snowflake_queries.json mirror it. The settings below are kept only as a readable record of the
# live scalar config, and the old workflow_edit.py CLI it calls is no longer shipped.
#
#   - WF_JWT exported (copy "Copy token" from https://workflows.anyvan.com admin UI; ~12h).
#   - This lands a DRY_RUN version; promotion to ACTIVE is a manual admin-UI step.
set -euo pipefail

SK="${CLAUDE_SKILL_DIR:-$HOME/.claude/skills/workflow-editor}/workflow_edit.py"
ENVv="${ENVv:-prod}"

# Overridable so the SAME script creates the test build and the live build:
#   TEST (routes to the sandbox Freshdesk group + env:test tag):
#     WF_NAME="[UK] Privacy Submission Workflow [TEST]" ACTIONS_FILE=workflow/actions.test.json bash workflow/create.sh
#   LIVE (defaults):
#     bash workflow/create.sh
WF_NAME="${WF_NAME:-[UK] Privacy Submission Workflow}"
ACTIONS_FILE="${ACTIONS_FILE:-workflow/actions.json}"

# ---- placeholders you must set ------------------------------------------------
FORMSTACK_FORM_ID="6559077"                 # DSR form id (built by build-formstack-form.js)
# Also confirm the submission-id path used in workflow/user_prompt.md ({event.payload.uniqueId})
# against a real FORMSTACK_FORM_SUBMITTED payload (run `python3 "$SK" catalogue --env prod`).
# -------------------------------------------------------------------------------

cd "$(dirname "$0")/.."   # repo root, so the file paths below resolve

python3 "$SK" create --env "$ENVv" --jwt "$WF_JWT" \
  --name "$WF_NAME" \
  --user-prompt-file workflow/user_prompt.md \
  --actions-file      "$ACTIONS_FILE" \
  --set requires_ai_evaluation=true \
  --set action_selection_mode=locked \
  --set 'subscribed_events=["FORMSTACK_FORM_SUBMITTED"]' \
  --set 'agentic_tools=["formstack_submission","formstack_upload","formstack_upload_interpret","snowflake_query","v4_listing_lookup"]' \
  --set max_iterations=16 \
  --set bedrock_model_id=eu.anthropic.claude-haiku-5-5 \
  --set "event_filter=payload.formId = \"${FORMSTACK_FORM_ID}\"" \
  --set config_prompt="$(cat workflow/config_prompt.md)"
  # NOTE: the live workflow ALSO carries 3 further actions (FRESHDESK_TICKET_COMMENT,
  # EVENTBUS_EVENT_PUBLISH, FORMSTACK_SUBMISSION_UPDATE) and the workflow/snowflake_queries.json
  # read-only queries, none of which this invocation sends — see workflow/deployed-v43.json.

echo
echo "Created as DRY_RUN. Review and PROMOTE manually at https://workflows.anyvan.com."
echo "Then send a test submission per docs/formstack-to-freshdesk-workflow.md."
