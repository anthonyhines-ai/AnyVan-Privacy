# Formstack V2025 API — payload shapes & gotchas

Everything needed to create/update AnyVan Formstack forms via the API. Read this before writing a
create or update call — the shapes are non-obvious and one of them (conditional logic) actively
differs between the write and read paths.

## Table of contents
- Auth & base URL
- Create a form
- Create a field (common payload + per-type specifics)
- Conditional logic — the CREATE vs GET mismatch (the big one)
- Update an existing field (additive changes without a rebuild)
- Dates, ids, and admin prefill
- Build-script pattern

## Auth & base URL
- **Base:** `https://www.formstack.com/api/v2025`. Using `…/api/v2` with an `fs_pat_` token returns
  **401** — the Personal Access Token is a V2025 credential. If you get a 401, check the base path
  before you doubt the token.
- **Auth header:** `Authorization: Bearer fs_pat_…`. The token is an env var (`FORMSTACK_TOKEN`)
  only — never commit it; rotate if it ever leaks.

## Create a form
```
POST /forms
{ "name": "AnyVan — Data Subject Request (DSR)" }
→ { "id": 6559077, ... }
```

## Create a field
```
POST /forms/{formId}/fields
```
Common payload:
```json
{
  "type": "text",
  "label": "Full name",
  "displayOrder": 3,
  "required": true,
  "hidden": false,
  "supportingText": "As it appears on your account",
  "options": [ { "label": "Yes", "value": "yes" } ]
}
```
Per-type specifics:
- **`options`** are `{label, value}` objects — **not** bare strings. Applies to radio, checkbox,
  select.
- **`section`** (used for page breaks and headings): `type: "section"`, an **empty `label`**, and
  `attributes: { startNewPage, heading, text }`. A **page break is `startNewPage: true` on a
  section** — there is no separate "page" object.
- **`richtext`** (info / guidance block): `type: "richtext"`, empty `label`, and
  `attributes: { text: "<p>…html…</p>", textEditor: "wysiwyg" }`.
- **File upload**: a file-type field; set the accepted extensions and size cap in the field config.
  Put "copies only, never originals" style guidance in `supportingText` where relevant.

## Conditional logic — the CREATE vs GET mismatch (the big one)
The shape you **POST to create** logic is different from the shape a **GET returns**. You cannot take
a GET response and feed it straight back into a create — transform it first.

**CREATE (what you POST) — legacy shape:**
```json
{
  "logic": {
    "action": "show",
    "conditional": "all",
    "checks": [
      { "field": "197276089", "condition": "equals", "option": "Access My Data (SAR)" }
    ]
  }
}
```
- `action` is **lowercase** (`"show"` / `"hide"`) — `"Show"` is rejected.
- `conditional` is `"all"` or `"any"`.
- each check is `{ field, condition, option }`, and `field` is the numeric id **as a string**.

**GET (what the API returns) — different shape:**
```json
{
  "action": "show",
  "operator": "all",
  "fields": [
    { "comparisonOperator": "==", "fieldId": "197276089", "value": "Access My Data (SAR)" }
  ]
}
```
Note `operator` vs `conditional`, `fields` vs `checks`, `comparisonOperator`/`fieldId`/`value` vs
`condition`/`field`/`option`. Round-tripping GET→CREATE silently produces logic that does nothing.

## Update an existing field (additive changes without a rebuild)
Re-running a full create **duplicates every field**. To change a live form, target the field:
```
PUT /forms/{formId}/fields/{fieldId}
{ "options": [ { "label": "…", "value": "…" }, ... ] }
```
Use this to append choices to an existing radio/dropdown. To add whole new fields, POST only the new
ones (with their own conditional logic) and record the ids afterwards.

## Dates, ids, and admin prefill
- **Dates:** date / datetime fields accept `YYYY-MM-DD`.
- **Field ids:** fields are referenced by **numeric id, not label**. Record every `field_<NNN>` id
  after a build — the workflow reads by id. Relabelling keeps the id; **changing a field's type can
  change it** (this is also why Freshdesk `cf_*` keys drift — see the Freshdesk section of SKILL.md).
- **Admin prefill:** hidden fields can be populated from the query string as `?field<ID>=value`
  (e.g. a hidden `source`/`agent` pair to record who logged a staff-entered submission). Verify the
  exact prefix against the account before relying on it.

## Build-script pattern
Encode all of the above once in a build script rather than hand-crafting calls. The AnyVan reference
implementation is `workflow/build-formstack-form.js` in `anthonyhines-ai/AnyVan-Privacy`, which
supports three modes:
- `--dry-run` — print the full planned structure, make no API calls.
- full create — build a fresh form + fields + logic and print the id map.
- `--form <id>` (additive) — create only new fields and `PUT` new options onto existing fields of a
  live form, so a running form is extended without duplication.
