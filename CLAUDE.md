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

## Ways of working (lessons from the first build)
- **Done ≠ on `main`.** This work lives on a draft PR; it doesn’t help anyone until it’s merged.
  Mark the PR ready and merge to land the conventions/skill — a draft is not "delivered".
- **Don’t over-monitor.** A recurring PR check-in on a quiet, human-gated draft with **no CI**
  polls forever for zero signal (and burns tokens). Watch a PR only when there’s a live signal to
  catch — CI in flight, active reviewers, or merge-conflict risk — otherwise hand it back and stop.
- **Rotate the exposed token.** A live Formstack PAT (`fs_pat_…`) was pasted into chat during the
  first build — treat it as compromised: rotate it, and run the additive `--form 6559077` apply
  with a **fresh** `FORMSTACK_TOKEN`.
- **One source of truth for conventions.** `docs/conventions.md` is canonical; `CLAUDE.md`,
  `ONBOARDING.md`, and `skills/anyvan-formstack-freshdesk/` restate it. Change all in the **same
  PR** so they don’t drift. The **skill** (not the onboarding-guide tool, which failed) is the
  working org-shareable form.
