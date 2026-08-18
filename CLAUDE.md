# CLAUDE.md — AnyVan-Privacy

Privacy tooling: the **DSR (Data Subject Request) intake pipeline**
**Formstack form → workflow-system → Freshdesk**.

## Read first
**`docs/conventions.md`** — consolidated, hard-won conventions and gotchas (Formstack V2025 API,
number/date formatting, Freshdesk `cf_*` caveats, the workflow-system). Read it before touching
the form, the builder, or the workflow, and keep it updated in the same PR when anything changes.

## Repo map
- `workflow/build-formstack-form.js` — builds/updates the live Formstack form via the V2025 API
  (`--dry-run`, full create, or additive `--form <id>`). Source of truth for the field set.
- `workflow/config_prompt.md` · `user_prompt.md` · `actions.json` · `create.sh` — the
  workflow-system definition (raises the Freshdesk ticket on `FORMSTACK_FORM_SUBMITTED`).
- `docs/dsr-field-mapping.md` — form ↔ Formstack field id ↔ Freshdesk field/tag (prevents drift).
- `docs/formstack-dsr-build.md` · `formstack-to-freshdesk-workflow.md` · `freshdesk-custom-fields.md`
  · `go-live-guide.md` · `public-hosting.md` — build/wiring/go-live runbooks.
- `dsr-intake-form.html` — interim internal form on AV Dashboards (retired once Formstack is live).
- `backend/` — a superseded self-hosted Lambda ticket-creator; parked as reference, **not deployed**.
- `skills/anyvan-formstack-freshdesk/` — the reusable, org-shareable skill distilled from
  `docs/conventions.md` (same conventions, generalised beyond DSR). Package with
  `skill-creator`'s `package_skill.py` to get the uploadable `.skill`; see `skills/README.md`.

## Guardrails (learned the hard way)
- **Never commit secrets.** The Formstack PAT (`fs_pat_…`) and any API keys are env-vars only
  (`FORMSTACK_TOKEN`); if one leaks into chat or a file, rotate it.
- **Formstack conditional-logic shape differs between CREATE and GET** — don’t round-trip; see
  `docs/conventions.md`.
- **Confirm Freshdesk `cf_*` keys live** via `GET /api/v2/ticket_fields` before wiring them.
- Workflow edits land **DRY_RUN**; a human promotes to ACTIVE in the admin UI.
- Formstack form `6559077` is **live** — prefer the builder’s additive `--form` mode over a rebuild.
