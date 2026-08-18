# AnyVan — Formstack → workflow-system → Freshdesk conventions

Reusable, hard-won conventions for building **Formstack forms that feed the workflow-system and
raise Freshdesk tickets** at AnyVan. First proven on the DSR (Data Subject Request) pipeline; the
API quirks and formatting rules apply to any such integration. Keep this updated as we learn more.

## Formstack V2025 API
- **Base:** `https://www.formstack.com/api/v2025` (a `…/api/v2` base 401s with a `fs_pat_` token —
  Personal Access Tokens are **V2025**).
- **Auth:** `Authorization: Bearer fs_pat_…`. **Never commit the token** — env var only; rotate if leaked.
- **Create form:** `POST /forms {name}` → `id`. **Create field:** `POST /forms/{id}/fields`.
  - `options` are `{label, value}` objects; **page breaks** = `attributes.startNewPage:true` on a
    `section` field; rich-text blocks use `attributes:{text, textEditor:"wysiwyg"}`.
- **⚠️ Conditional logic differs between CREATE and GET:**
  - CREATE (legacy): `logic:{action:"show"|"hide" (lowercase), conditional:"all"|"any",
    checks:[{field, condition:"equals", option}]}`.
  - GET returns `{action, operator, fields:[{comparisonOperator:"==", fieldId, value}]}`.
  - **Don’t round-trip GET→CREATE** — transform first.
- **Add options to an existing field:** `PUT /forms/{id}/fields/{fieldId} {options}` (no rebuild).
- Dates accept **`YYYY-MM-DD`**. Fields are referenced by **numeric id, not label** — record ids
  after building. Prefer an **additive update** over recreating a live form.

## Formatting conventions
- **Booking reference:** prepend `AV` to a digits-only value (`1234567` → `AV1234567`); leave
  prefixed refs alone.
- **Statutory deadlines:** base date **+ one calendar month**, then roll forward off weekends /
  England-&-Wales bank holidays to the next working day; format `YYYY-MM-DD`.
- **Dropdown/radio → canonical value:** the form submits an option *string*; map it explicitly to
  your canonical value + a lowercase tag. Keep the map in one source-of-truth doc.
- Never put personal data in a ticket subject.

## Freshdesk
- **`cf_*` keys derive from the label and change if the field’s type changes** → a stale key fails
  with `invalid_field`. **Confirm live keys via `GET /api/v2/ticket_fields`** before wiring.
- Native `due_by`/`fr_due_by` aren’t exposed by the workflow action → use a **custom date field**
  the workflow populates.

## Workflow-system
- Use the **`workflow-editor`** skill (edit definitions) and **`workflow-doctor`** skill (diagnose
  runs). Edits land **DRY_RUN**; a **human promotes to ACTIVE** in the admin UI.
- `FRESHDESK_TICKET_CREATE` supports status/priority/type/tags/cc_emails/custom_fields — **not**
  `due_by`. Agentic tools include `formstack_submission` and `formstack_upload_interpret`
  (vision-check uploaded documents).

## AV Dashboards
- Deploy via `get_upload_token` → HTTP `PUT`; **don’t** use `update_dashboard` (truncates).
  `@anyvan.com`-gated, not a public channel.

_Canonical version-controlled copy lives in `anthonyhines-ai/AnyVan-Privacy` at
`docs/conventions.md` + `CLAUDE.md`._
