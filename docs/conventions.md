# AnyVan integration conventions & lessons learned

Hard-won specifics from building the DSR (Data Subject Request) pipeline
**Formstack form → workflow-system → Freshdesk**. Consolidated here so they carry forward to
the next Formstack/workflow/Freshdesk build instead of being re-discovered. If you change any of
these, update this file in the same PR.

---

## Formstack V2025 API

- **Base URL:** `https://www.formstack.com/api/v2025`. A `…/api/v2` base returns **401** with a
  `fs_pat_` token — the Personal Access Token is a **V2025** credential.
- **Auth:** `Authorization: Bearer fs_pat_…`. **Never commit the token** — pass it as an env var
  (`FORMSTACK_TOKEN`) only. If one is ever pasted into chat/a file, rotate it.
- **Create form:** `POST /forms` `{ "name": "…" }` → returns `id`.
- **Create field:** `POST /forms/{formId}/fields`. Payload shape:
  - common: `{ type, label, displayOrder, required?, hidden?, supportingText?, options? }`
  - `options`: array of `{ label, value }` (not bare strings).
  - **section:** `type:"section"`, empty `label`, and
    `attributes:{ startNewPage, heading, text }` — **page breaks are `startNewPage:true` on a
    section**, not a separate "page" object.
  - **rich text / info block:** `type:"richtext"`, empty `label`,
    `attributes:{ text:"<html>", textEditor:"wysiwyg" }`.
- **⚠️ Conditional-logic shape differs between CREATE and GET** (the single biggest gotcha):
  - **CREATE (legacy shape):**
    `logic:{ action:"show"|"hide", conditional:"all"|"any",
    checks:[{ field:"<fieldId>", condition:"equals", option:"<value>" }] }`
    — `action` must be **lowercase** (`"show"`, not `"Show"`).
  - **GET returns a different shape:**
    `{ action, operator, fields:[{ comparisonOperator:"==", fieldId, value }] }`.
  - So you **cannot round-trip** a GET response back into a CREATE — transform it first.
- **Update a field** (e.g. append options to an existing radio): `PUT /forms/{formId}/fields/{fieldId}`
  with `{ options:[…] }`. Use this to add choices without recreating the field/form.
- **Dates:** date / datetime fields accept **`YYYY-MM-DD`**.
- **Fields are referenced by numeric id, not label** — record every `field_<NNN>` id after a build
  (see `dsr-field-mapping.md`). Relabelling a field does not change its id; changing its *type* can.
- **Admin prefill:** hidden fields populated via query string `?field<ID>=value`; verify the exact
  prefix against the account before relying on it.
- The build script `workflow/build-formstack-form.js` is the source of truth for the field set and
  encodes all of the above; it supports `--dry-run`, a full create, and an additive
  `--form <id>` mode (adds only new fields + refreshes options on an existing form).

## Number / date formatting conventions (DSR)

- **Booking reference:** normalise by **prepending `AV` to a digits-only value**
  (`1234567` → `AV1234567`); leave already-prefixed refs untouched.
- **Statutory response deadline (“Privacy Due Date”):**
  base = submission date; **+ one calendar month** (same day-of-month next month; if that day
  doesn’t exist, the last day of next month); if the result lands on a Saturday, Sunday, or an
  **England & Wales bank holiday**, roll **forward** to the next working day; format **`YYYY-MM-DD`**.
- **Request type → canonical value / tag:** the Formstack radio submits an option *string*; map it
  to the canonical `dsr_type` + lowercase `request_type_tag` (full table in
  `dsr-field-mapping.md` and `../workflow/config_prompt.md`).
- **Never put personal data in a ticket subject.**

## Freshdesk

- **`cf_*` custom-field keys are derived from the label at creation time and change if you later
  change the field’s type** (e.g. a number field renamed becomes `cf_booking_reference594255`).
  A stale key fails ticket-create with `invalid_field`. **Always confirm live keys via
  `GET /api/v2/ticket_fields`** before wiring them.
- Auth: basic auth `apikey:X` base64-encoded.
- Native **`due_by` / `fr_due_by`** override SLA but are **not exposed** by the workflow-system’s
  `FRESHDESK_TICKET_CREATE` action → use a **custom date field** (`cf_privacy_due_date`) populated by
  the workflow instead. SLA/automation can’t do arbitrary date arithmetic.

## Jiminny Video Lookup (SAR/DSAR)

**Purpose:** Locate and retrieve video consultation recordings (property assessments, flat tours) during SAR data compilation.

### Search methodology (validated)
- **Primary method:** Jiminny UI search by **customer email address**
  - Enters Jiminny → Search/Filter section → enter customer email (e.g., `monibag2000@yahoo.com`)
  - Returns list of all calls/videos for that customer with date, time, agent name, type, duration
  - Verify date/time matches expected consultation (e.g., 17 June 2026 ~14:30)
  - Download MP4/MOV file to secure location

- **Alternative searches** (if email search returns no video):
  - Search by phone number (`07881361498` or `+447881361498`)
  - Search by booking reference (`9454215`)
  - Browse by agent name (if known from booking notes)

- **If not found in Jiminny:** Escalate to Interaction Hub team, Google Drive, or third-party assessment platforms (Robinhood, Tradify, etc.)

### MCP connector (optional, for transcripts only)
- **Tool:** `mcp__AnyVan_MCP__get_conversation_transcript`
- **Input:** HubSpot dealId (e.g., `60955982356`)
- **Output:** Full conversation transcript if deal is linked to Jiminny call
- **Use case:** Retrieve transcript after video file is located (not for locating videos)

### Important notes
- **Jiminny data is NOT in Snowflake** — direct UI search is the only reliable method
- **Video ownership:** Recording is AnyVan's; customer entitled to copy per GDPR Article 15
- **PII in video:** Redact agent name (e.g., "Alex York" → `[AGENT]`); confirm no issue with sharing property footage
- **Storage:** Jiminny is third-party processor — confirm DPA in place before delivery
- **Retention:** Keep copy 3 months post-delivery per retention policy

### Video lookup SLA
- **Locate & download video:** by Day 4–5 of SAR (before PII redaction review)
- **Verify playback:** confirm file plays, audio clear, duration matches Jiminny metadata
- **Include in archive:** add to encrypted SAR delivery (WeTransfer Plus, 7-day expiry)

### Detailed guide
- See `../booking-lookups/METHODOLOGY-jiminny-video-lookup.md` for step-by-step UI navigation, fallback locations, and troubleshooting

## Workflow-system

- Use the org **`workflow-editor`** skill (CRUD on definitions) and **`workflow-doctor`** skill
  (diagnose failed executions).
- Edits land in **DRY_RUN**; a **human promotes to ACTIVE** in the admin UI (`workflows.anyvan.com`).
- Events seen here: `FORMSTACK_FORM_SUBMITTED`, `FRESHDESK_TICKET_CREATED`.
  Actions: `FRESHDESK_TICKET_CREATE` (supports status / priority / type / tags / cc_emails /
  custom_fields — **not** `due_by`), `FORMSTACK_SUBMISSION_UPDATE`, `SCHEDULE_EVENT_UPSERT`.
- Agentic tools: `formstack_submission`, `formstack_upload`, `formstack_upload_interpret`
  (vision-checks uploaded docs — e.g. third-party authorisation letters).

## AV Dashboards (the interim internal form)

- Deploy via `get_upload_token` → HTTP `PUT` to the upload endpoint; **do not** use the
  `update_dashboard` MCP tool (it truncates). Versions are auto-incremented with rollback.
- `@anyvan.com` Google-OAuth gated; not a public channel.

## Source-of-truth pointers
- Field ids + option/tag vocab: `dsr-field-mapping.md`
- AI output contract & formatting rules: `../workflow/config_prompt.md`
- Formstack build spec: `formstack-dsr-build.md` · builder script: `../workflow/build-formstack-form.js`
- Workflow wiring runbook: `formstack-to-freshdesk-workflow.md`
- Freshdesk fields: `freshdesk-custom-fields.md`
