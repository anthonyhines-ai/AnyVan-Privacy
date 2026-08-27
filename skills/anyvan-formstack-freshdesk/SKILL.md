---
name: anyvan-formstack-freshdesk
description: >
  AnyVan Formstack → workflow-system → Freshdesk integration conventions. Use this WHENEVER
  building, editing, or debugging any AnyVan Formstack form, wiring a Formstack submission into
  the workflow-system, or mapping fields onto a Freshdesk ticket — even if only one piece is
  mentioned. Trigger on: Formstack form building or the V2025 API (fs_pat tokens, POST /forms,
  conditional/show-hide logic, page breaks, richtext, file uploads); workflow-system definitions
  that raise Freshdesk tickets (FORMSTACK_FORM_SUBMITTED, FRESHDESK_TICKET_CREATE, DRY_RUN then
  promote); Freshdesk custom fields (cf_ keys, ticket_fields, due dates / SLA); or formatting rules
  like AnyVan booking-reference normalisation and statutory one-calendar-month deadlines. Encodes
  the hard-won gotchas — CREATE-vs-GET conditional-logic mismatch, cf_ keys changing with a field's
  type, due_by not exposed by the workflow action — so they apply automatically. First proven on
  the DSR (Data Subject Request) pipeline; the rules generalise to any such build.
---

# AnyVan Formstack → workflow-system → Freshdesk

Hard-won conventions for AnyVan's standard intake pattern: a **Formstack form** feeds the
**workflow-system**, which raises a **Freshdesk ticket**. These specifics cost real debugging time
the first time round (on the DSR / Data Subject Request pipeline). They carry forward here so the
next build applies them instead of rediscovering them.

The three parts are independent — a task may touch only one. Read the section you need. If you
change any convention while working, update this skill in the same change so it stays true.

```
Formstack form  ──FORMSTACK_FORM_SUBMITTED──▶  workflow-system  ──FRESHDESK_TICKET_CREATE──▶  Freshdesk ticket
 (V2025 API)                                   (AI eval + actions)                            (cf_* fields + tags)
```

---

## 1. Formstack V2025 API

Full payload shapes and worked JSON are in **`references/formstack-v2025-api.md`** — read it before
writing any create/update call. The essentials and the traps:

- **Base URL is `https://www.formstack.com/api/v2025`.** A `…/api/v2` base returns **401** with an
  `fs_pat_` token — the Personal Access Token is a **V2025** credential, not a legacy one. This 401
  looks like an auth failure and sends you chasing the token; it's the base path.
- **⚠️ Conditional-logic shape differs between CREATE and GET — the single biggest gotcha.** What
  you POST to create show/hide logic is *not* the shape a GET returns, so you **cannot round-trip**
  a GET response back into a create. Transform it first. (Both shapes are in the reference file.)
  Also: the logic `action` must be **lowercase** (`"show"`, not `"Show"`).
- **Prefer an additive update over a rebuild on a live form.** Re-running a full create duplicates
  every field. To add choices to an existing radio/dropdown, `PUT /forms/{id}/fields/{fieldId}` with
  the new `options`; to add fields, POST only the new ones. Never recreate a form that's in use.
- **Fields are referenced by numeric id, not label.** Record every `field_<NNN>` id after a build —
  the workflow reads by id. Relabelling a field keeps its id; **changing its type can change it.**
- **Page breaks** are `attributes.startNewPage: true` on a `section` field — not a separate "page"
  object. **Options** are `{label, value}` objects, not bare strings. **Rich-text/info blocks** use
  `type: "richtext"` with `attributes: { text, textEditor: "wysiwyg" }`.
- **Dates** accept `YYYY-MM-DD`.

## 2. Formatting conventions (map raw submission values to clean ticket data)

The form submits whatever the user typed plus option *strings*. Normalise before they hit the
ticket:

- **AnyVan booking reference:** prepend `AV` to a digits-only value (`1234567` → `AV1234567`);
  leave an already-prefixed ref untouched.
- **Statutory / SLA deadlines (e.g. a "due date"):** base date **+ one calendar month** (same
  day-of-month next month; if that day doesn't exist, the last day of next month), then if the
  result is a Saturday, Sunday, or an **England & Wales bank holiday**, roll **forward** to the next
  working day. Format `YYYY-MM-DD`. SLA/automation can't do this arithmetic — compute it in the
  workflow (see §3).
- **Dropdown / radio → canonical value:** the form submits an option *string*; map it **explicitly**
  to your canonical value plus a lowercase tag token, and keep that map in one source-of-truth doc
  so the form, the workflow prompt, and the mapping doc never drift.
- **Never put personal data in a ticket subject.**

## 3. Freshdesk

- **`cf_*` custom-field keys are derived from the field label at creation and change if you later
  change the field's *type*** (e.g. a number field becomes `cf_booking_reference594255`). A stale
  key fails ticket-create with `invalid_field`. **Always confirm the live keys via
  `GET /api/v2/ticket_fields`** before wiring them into a workflow. Auth is basic `apikey:X`,
  base64-encoded.
- **Native `due_by` / `fr_due_by` are not exposed by the workflow-system's `FRESHDESK_TICKET_CREATE`
  action.** To set a deadline on the ticket, add a **custom date field** and have the workflow
  populate it with the computed date (§2) — don't expect SLA to derive it.

## 4. Workflow-system

- Use the org **`workflow-editor`** skill to CRUD workflow definitions and the **`workflow-doctor`**
  skill to diagnose a failed execution. Don't hand-roll curl or touch DynamoDB directly.
- **Every edit lands in `DRY_RUN`; a human promotes it to `ACTIVE`** in the admin UI
  (`workflows.anyvan.com`). Never assume your change is live — say it's staged pending promotion.
- Events you'll see: `FORMSTACK_FORM_SUBMITTED`, `FRESHDESK_TICKET_CREATED`. Actions:
  `FRESHDESK_TICKET_CREATE` (supports status / priority / type / tags / cc_emails / custom_fields —
  **not** `due_by`), `FORMSTACK_SUBMISSION_UPDATE`, `SCHEDULE_EVENT_UPSERT`.
- Agentic tools available in the eval step: `formstack_submission` (read the submission JSON — call
  it first), `formstack_upload`, and `formstack_upload_interpret` (vision-check an uploaded document,
  e.g. a third-party authorisation letter). Record the read in the description; don't block ticket
  creation on it.

## 5. Secrets — never commit them

The Formstack PAT (`fs_pat_…`), the Freshdesk API key, and the workflow JWT (`WF_JWT`) are
**env-vars only** — never hard-coded, never committed, never pasted into a doc or a ticket. If one
ever leaks into chat or a file, treat it as compromised and rotate it.

## Worked example — the DSR pipeline

The canonical, working implementation of all of the above lives in the
`anthonyhines-ai/AnyVan-Privacy` repo (Data Subject Request intake). When building something new,
read it as a reference:
- `workflow/build-formstack-form.js` — the V2025 build script (dry-run, full create, and additive
  `--form <id>` mode). Source of truth for a real field set + conditional logic.
- `workflow/config_prompt.md` — the AI output contract (subject/description/tags + the option-string
  → canonical value/tag map + the deadline rule).
- `docs/conventions.md` — the long-form version of this skill (kept in sync with it).
- `docs/dsr-field-mapping.md` — a real Form-question → field-id → Freshdesk-field/tag table.
