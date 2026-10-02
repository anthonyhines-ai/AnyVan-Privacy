# UK DSR intake — DRY_RUN test findings (2026-10-02)

> **INTERNAL** — no customer data (the test submission used synthetic sample values). Consolidated
> from the `claude/dsr-dryrun-findings` branch (former PR #25) onto this branch. Two claims from
> that branch were **corrected on consolidation** — see the webhook row and the expected-subject
> note below.

Fired one Customer-SAR test submission at form `6559077` via the Formstack V2025 API to exercise
the DRY_RUN workflow `d6ad9a00-757a-4e48-961e-428646024574` (v1, `[UK] Privacy Submission
Workflow [TEST]`). Submission id **`1502835200`**.

## Outcome summary

| Check | Result |
|---|---|
| Form 6559077 state | **Active** (`formSettings.isActive: true`), captcha off, 0 prior submissions. The go-live caveat that the form was still in DRAFT is **stale**. |
| Webhook wiring | **Per-form webhook IS the delivery mechanism — corrected.** Verified 2026-10-02: the live **Damage Claim Form `6200752`** (the form the "Damage Claim - UK - Formstack" workflow filters on) has a per-form webhook `id 7831758` → `https://events.anyvan.com/v1/formstack/form-submitted`. The Privacy form `6559077` had **none** (`webhooks: []`), so it published no `FORMSTACK_FORM_SUBMITTED` event. The earlier "account-wide, not per-form" note came from checking form `5500224` ("Report Damage Claim"), a **different, unrelated form** that happens to have no webhook — not the Damage form the workflow consumes. See `docs/formstack-to-freshdesk-workflow.md` (Gate 0) and `workflow/create-webhook.mjs`. |
| Test submission | Fired + persisted (9 fields verified via GET). |
| Freshdesk ticket | **Depends on the workflow's state at fire time (2026-10-02 09:53:13 BST) AND on the webhook existing.** With no webhook on `6559077` at fire time, no event reached the workflow, so no `FRESHDESK_TICKET_CREATE` ran regardless of DRY_RUN/ACTIVE. Once the webhook exists and the workflow is ACTIVE, the test build creates a real ticket in **sandbox group `31000119185`** (tag `env:test`), not the main privacy queue. |
| Execution inspection | Pending — requires the `workflow-doctor` tooling + a `WF_JWT`; not runnable from the cloud container (plugin not installed there). |

## Expected proposed ticket (verify in workflow-doctor against submission 1502835200)

Values below follow the current `workflow/config_prompt.md` (source of truth):

- subject: `[UK] SAR Privacy Data Request | Requester Type: A Customer [1502835200]`
  (**corrected** from the earlier `DSR-UK-…` format — this branch matches the Formstack
  notification subject exactly)
- requester_email: `jane.test.sample+dsr-test@anyvan.com`
- dsr_type / requester_type: `SAR` / `Customer`
- tags: `privacy, dsr, sar, customer, source:dsr-form, env:test`
- group_id: `31000119185` (sandbox), status 2, priority 2
- cf_privacy_due_date: `2026-11-02` (submission Fri 2026-10-02 + 1 calendar month = Mon 2026-11-02;
  no weekend / E&W bank-holiday roll). Note the config prompt now **prefers** the form's computed
  Privacy Due Date field `197302298` when populated, falling back to this calculation.
- privacy_type (advisory; not rendered in the description, which mirrors the Formstack template):
  `Subject Access Request (SAR)`
- booking reference in description: `AV9123456` (digits-only → AV-prefixed)

## Findings — live form has drifted from `docs/dsr-field-mapping.md`

1. **Checkbox fields cannot be written via the Formstack V2025 submission API.**
   `POST /forms/6559077/submissions` with body `{ fields: [ { id, value: { value: <X> } } ] }`
   persists every scalar / radio / datetime field. **Both** checkbox fields —
   SAR data categories (`197276090`) and Declaration (`197276108`) — silently store **empty**
   under every encoding tried (~30: bare array, `{value:[…]}`, `{values:[…]}`, index-keyed
   objects, `useOtherValue`/`otherValue` siblings, newline/semicolon/pipe/JSON-string joins,
   `type` discriminators, with and without the controlling field present). Radio writes fine with
   the same wrapper and a single string, so this is specific to the `checkbox` type. Impact: any
   API-driven submission or automated test cannot set SAR categories or the declaration; they must
   go through the hosted form, or be carried in a free-text field. (This run carried them in
   *Additional Information*.)

2. **Phone (`197276073`) is now conditional**, shown only when SAR data categories include
   `Call Recording/s` or `Chat Transcript/s`. The mapping table still lists it as requester-type
   "all". Under the test categories (Personal Details / Booking & Account) the phone field is not
   shown and carries no value.

3. **Account-holder confirmation (`197276087`) no longer exists on the live form.** The mapping
   still lists it → `account-holder-confirmed` tag + description line. Nothing populates that tag.

## Submission API shape (confirmed, for reference)

- Endpoint: `POST https://www.formstack.com/api/v2025/forms/{formId}/submissions`
- Body: `{ "fields": [ { "id": "<fieldId-as-string>", "value": { "value": <string> } }, … ] }`
  - `id` must be a string; a top-level `value` must be an **object** `{ value: … }` (a bare string → 500).
  - Scalar / email / radio / datetime: inner `value` is the literal string; dates as `YYYY-MM-DD`.
  - **checkbox: no working encoding found (see finding 1).**
- `GET /submissions/{id}` returns `data[]` of `{ field, label, type, displayValue, parsedValue }`.
- `DELETE /submissions/{id}` removes a submission (used to clean up format-discovery probes).
