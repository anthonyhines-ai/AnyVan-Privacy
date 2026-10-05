# DSR form — step-by-step go-live guide

One sequential runbook to take the DSR intake form live for **UK customers (public)** and
**internal admins**, on Formstack → workflow-system → Freshdesk. Each stage says **who** does it,
**what** to do, and the **checkpoint** ("done when"). Deeper detail is in the linked docs.

> **MVP scope:** the initial launch uses ticket **tags + a structured description + one date
> custom field** (`cf_privacy_due_date` — the statutory deadline). That one field **already
> exists** in Freshdesk (label **Privacy Due Date**), so the only Stage 1 action is to **confirm
> its live `cf_*` key** via `GET /api/v2/ticket_fields`. The dropdown/text fields
> (`cf_dsr_type` etc.) stay deferred — a **Privacy Type** field now also exists and can be wired
> next once its key is confirmed. Start at Stage 2 for the form build.
> Stage 2 can be largely automated with `workflow/build-formstack-form.js`.
>
> **Progress:** Stage 2 is **largely done** — the form is built in the AnyVanforms account (**id
> `6559077`**, https://AnyVanforms.formstack.com/forms/anyvan__data_subject_request_dsr_2). The
> original field ids are recorded in `docs/dsr-field-mapping.md` and the form id is set in
> `workflow/create.sh`. **Still to do on the form:** run the additive `--form 6559077` apply (with
> a fresh PAT) to add the DSRR-template-alignment fields — all 8 statutory rights, ID verification,
> address, third-party contact, declaration — then record their ids (the `new` rows in the mapping
> doc). After that, finish the builder-only config (region/retention/reCAPTCHA/theme/confirmation
> email) and review/publish, then Stages 4–8 (workflow → launch).

```
Freshdesk fields ──► Formstack form ──► record field ids ──► create workflow (DRY_RUN)
      (Stage 1)         (Stage 2)          (Stage 3)              (Stage 4)
                                                                     │
   launch ◄── promote to ACTIVE ◄── test in DRY_RUN ◄────────────────┘
 (Stage 7-8)      (Stage 6)            (Stage 5)
```

## Access you'll need (gather first)
- **Freshdesk admin** (create ticket fields; read `GET /api/v2/ticket_fields`).
- **Formstack builder** login, on the account approved for UK PII (EU/UK data region).
- **workflow-system admin** login for `https://workflows.anyvan.com` (to copy a `WF_JWT` and to
  promote the workflow). The `workflow-editor` skill (`workflow_edit.py`) available locally.
- **Web/CMS access** to link the public form (privacy policy page) and the `/administer` console.

---

## Stage 1 — Freshdesk custom fields  · owner: Freshdesk admin
Detail: `docs/freshdesk-custom-fields.md`. **One field is required for the MVP:**
`cf_privacy_due_date` (**Privacy Due Date**, date). It **already exists** in Freshdesk — the only
action is to **confirm its live key** via `GET /api/v2/ticket_fields` and adjust
`workflow/actions.json` if Freshdesk suffixed it (a wrong key fails ticket-create with
`invalid_field`).

**Deferred (later, for structured filtering/reporting):** `cf_dsr_type`, `cf_requester_type`,
`cf_booking_reference`, `cf_tp_username` — confirm live keys the same way, then add them to
`custom_fields` in `workflow/actions.json`. A **Privacy Type** field (`cf_dsr_type`) already
exists and is the first candidate to wire next.

**Done when:** `cf_privacy_due_date`'s live key is confirmed and matches `workflow/actions.json`.

---

## Stage 2 — Build the Formstack form  · owner: Formstack builder
Detail: `docs/formstack-dsr-build.md`. `FORMSTACK_TOKEN` is a **V2025 Personal Access Token**
(`fs_pat_…`) — not an OAuth token, and the API base is `…/api/v2025` (a `…/api/v2` base 401s).
The PAT pasted during the first build is considered exposed; use a **freshly-rotated** one.

**The form already exists (id `6559077`)** — extend it with the additive updater rather than
recreating it (a full create would duplicate every field):
```bash
node workflow/build-formstack-form.js --form 6559077 --dry-run   # preview the additions
FORMSTACK_TOKEN=<fresh fs_pat_...> node workflow/build-formstack-form.js --form 6559077
```
This adds only the new DSRR-alignment fields and refreshes the request-type options; **record the
new field ids in `docs/dsr-field-mapping.md` afterwards** (the rows marked `new`).

**Building a fresh form instead?** Full create (prints the whole field-id map):
```bash
FORMSTACK_TOKEN=<fresh fs_pat_...> node workflow/build-formstack-form.js
# preview first with:  node workflow/build-formstack-form.js --dry-run
```
Then finish in the builder:
1. Set the four `sec_*` sections to **"Start a New Page"** for the 4-step layout.
2. Confirm the third-party **file upload** (PDF/JPG/PNG, 10MB/file) and the two hidden fields
   `source` + `agent` (for the admin entry point).
3. Configure: **EU/UK data region**, submission **retention** to the DSR policy minimum,
   built-in **reCAPTCHA**, AnyVan theme + WCAG pass, and a **confirmation email** quoting
   `DSR-UK-<submission id>` and the one-calendar-month timeline.
4. Decide the repeatable-call-rows approach (the script uses a structured free-text field —
   swap for repeatable rows in the builder if your plan supports it).

(Or build it by hand from `docs/formstack-dsr-build.md` if you'd rather not run the script.)

**Done when:** the form submits end-to-end in Formstack's preview and a test submission appears
in the Formstack submissions list.

---

## Stage 3 — Record the field ids  · owner: whoever built the form
Detail: `docs/dsr-field-mapping.md`.
1. Paste the **field-id map** the build script printed into the mapping table (or read ids from
   the builder if you built it by hand).
2. Note the form's **FORM ID** and, from the test submission's webhook/event, the
   **submission-id path** in the payload (the workflow-system normalises the Formstack webhook
   to camelCase, so the confirmed path is `{event.payload.uniqueId}`).

**Done when:** the mapping table has the field ids and the FORM ID + submission-id path are
known.

---

## Stage 4 — Create the workflow (lands DRY_RUN)  · owner: workflow-system admin
Detail: `docs/formstack-to-freshdesk-workflow.md`. Files in `workflow/`.
1. Fill the placeholders:
   - `workflow/create.sh` → `FORMSTACK_FORM_ID`.
   - `workflow/user_prompt.md` → submission-id path confirmed as `{event.payload.uniqueId}`
     (camelCase — normalised from the Formstack webhook; verified against a real event payload).
   (MVP `actions.json` carries one custom field — `cf_privacy_due_date` — plus tags + description;
   no dropdown/text `cf_*` yet.)
2. Confirm the event + tools exist (no JWT needed):
   ```bash
   python3 "$SK" catalogue --env prod        # SK = path to workflow_edit.py
   ```
3. Copy a `WF_JWT` from the admin UI header, then create:
   ```bash
   export WF_JWT="<paste>"
   bash workflow/create.sh
   ```
   Note the returned `workflow_id` + `version` (it's **DRY_RUN**).

**Done when:** `create.sh` returns a new DRY_RUN `workflow_id` with no validation errors.

---

## Stage 5 — Test in DRY_RUN  · owner: workflow-system admin
1. Submit a **real test** from the Formstack form for each requester type: customer SAR (with
   calls), TP limited deletion, third-party (with an auth file).
2. Inspect each run on the executions feed:
   ```bash
   python3 ~/.claude/skills/workflow-doctor/workflow_doctor.py executions --env prod --jwt "$WF_JWT" | head
   ```
   Verify: ticket created; subject `DSR-UK-<id> — <type> (<requester>)`; **tags** landed as
   separate values; the **description** carries all fields (booking ref, TP username, request
   detail); third-party **vision read** appears in the description.
3. Confirm the existing classifier picks it up on `FRESHDESK_TICKET_CREATED`:
   ```bash
   python3 ~/.claude/skills/workflow-editor/workflow_edit.py list --env prod --jwt "$WF_JWT" | grep -i freshdesk
   ```

**Done when:** all three test tickets are correct and the classifier routed them.
_(If tags don't render element-wise, apply the fallback in the workflow runbook and re-create.)_

---

## Stage 6 — Promote to ACTIVE  · owner: workflow-system admin (human review)
1. In `https://workflows.anyvan.com`, open the new DRY_RUN version, review actions + prompt.
2. **Promote it to ACTIVE** in the UI (the script intentionally cannot promote).

**Done when:** the workflow shows ACTIVE and a fresh submission raises a live ticket.

---

## Stage 7 — Launch the entry points  · owner: web/CMS + ops
1. **Customers:** publish the Formstack **public URL** — link it from the privacy policy / a
   `anyvan.com/privacy` page (or embed it).
2. **Staff:** link the **same form** from `/administer` with `?source=admin&agent=<adminId>`
   so staff-logged requests are attributed.

**Done when:** a customer can reach the public form without login, and staff can open it from
`/administer` with the hidden params populated.

---

## Stage 8 — Cutover & cleanup  · owner: privacy/ops
1. Announce the form to the privacy/CS team; point them at the `/administer` link.
2. Retire the interim custom dashboard form (or keep it as an internal fallback). The
   `backend/` Lambda stays parked (not deployed).
3. Confirm the downstream verification workflow is resourced for the higher public volume.

**Done when:** DSRs are arriving as Freshdesk tickets from the Formstack form and the team is
actioning them; the interim form is retired or clearly marked fallback.

---

## Rollback / safety
- **Workflow:** it stays DRY_RUN until you promote; to pull it after promotion, disable it in
  the admin UI (a new ACTIVE version supersedes, or set DISABLED). The interim custom form + its
  path remain available as fallback.
- **Freshdesk fields:** additive — creating them doesn't affect existing tickets.
- **Formstack:** unpublish the public URL to stop new public submissions immediately.

## Owner summary
| Stage | Owner | Needs |
|---|---|---|
| 1 Freshdesk fields _(confirm `cf_privacy_due_date` key; rest deferred)_ | Freshdesk admin | Freshdesk admin + API key |
| 2 Formstack form | Formstack builder | Formstack (EU/UK, UK-PII-approved) + API token for the script |
| 3 Field ids | form builder | — (script prints them) |
| 4 Create workflow | workflow-system admin | `WF_JWT`, `workflow_edit.py` |
| 5 Test | workflow-system admin | `WF_JWT` |
| 6 Promote | workflow-system admin | admin-UI access |
| 7 Launch | web/CMS + ops | CMS + `/administer` access |
| 8 Cutover | privacy/ops | — |
