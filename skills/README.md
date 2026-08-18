# Skills

Reusable Claude skills distilled from this repo's hard-won conventions, kept here under version
control so they evolve alongside the code and docs they describe.

## `anyvan-formstack-freshdesk/`
AnyVan's **Formstack → workflow-system → Freshdesk** integration conventions, generalised beyond the
DSR pipeline that first proved them: the Formstack V2025 API quirks (the CREATE-vs-GET
conditional-logic mismatch, additive updates over rebuilds), the number/date formatting rules
(booking-reference normalisation, statutory one-calendar-month deadlines), the Freshdesk `cf_*`
caveats, and the workflow-system `DRY_RUN` → human-promote flow.

It's the same material as [`docs/conventions.md`](../docs/conventions.md) — the doc is the in-repo
reference for people reading this repo; the skill is the packaged, org-shareable form that loads
automatically when future Formstack/workflow/Freshdesk work comes up. **Keep the two in sync**: when
you change a convention, update both in the same PR.

### Packaging & installing
The folder is the editable source. To produce the uploadable `.skill` bundle (a zip), run the
`skill-creator` packager:

```bash
python -m scripts.package_skill /path/to/AnyVan-Privacy/skills/anyvan-formstack-freshdesk <output-dir>
# run from the skill-creator skill directory so the `scripts` module resolves
```

Then upload the resulting `anyvan-formstack-freshdesk.skill` to the org's skill library (or drop the
folder into a local `.claude/skills/` directory) so it's available across sessions.
