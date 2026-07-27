# DSR form — step-by-step go-live guide

One sequential runbook to take the DSR intake form live for **UK customers (public)** and
**internal admins**, on Formstack → workflow-system → Freshdesk. Each stage says **who** does it,
**what** to do, and the **checkpoint** ("done when"). Deeper detail is in the linked docs.

> **MVP scope:** the initial launch uses ticket **tags + a structured description** — no
> Freshdesk custom fields — so **Stage 1 is optional and can be skipped**; start at Stage 2.
> Stage 2 can be largely automated with `workflow/build-formstack-form.js`.

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

## Stage 1 (OPTIONAL — skip for MVP) — Freshdesk custom fields  · owner: Freshdesk admin
Detail: `docs/freshdesk-custom-fields.md`. **Not needed for the MVP launch** (tags + description
carry everything). Do this later for structured filtering/reporting: create `cf_dsr_type`,
`cf_requester_type`, `cf_booking_reference`, `cf_tp_username`, confirm their live keys via
`GET /api/v2/ticket_fields`, then add `custom_fields` back into `workflow/actions.json`.

**Done when (if doing it):** the `cf_*` keys/types are confirmed from the live `ticket_fields`
response and added to the workflow action.

---

## Stage 2 — Build the Formstack form  · owner: Formstack builder
Detail: `docs/formstack-dsr-build.md`. **Automated route (recommended):**
```bash
FORMSTACK_TOKEN=<your oauth token> node workflow/build-formstack-form.js
# preview first with:  node workflow/build-formstack-form.js --dry-run
```
This creates the form with all fields + conditional logic and **prints the field-id map**. Then
finish in the builder:
1. Set the four `sec_*` sections to **"Start a New Page"** for the 4-step layout.
2. Confirm the third-party **file upload** (PDF/JPG/PNG, 10MB/file) and the two hidden fields
   `source` + `agent` (for the admin entry point).
3. Configure: **EU/UK data region**, submission **retention** to the DSR policy minimum,
   built-in **reCAPTCHA**, AnyVan theme + WCAG pass, and a **confirmation email** quoting
   `DSR-<submission id>` and the one-calendar-month timeline.
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
   **submission-id path** in the payload (the workflow uses `{event.payload.UniqueID}` as a
   placeholder — replace with the real path).

**Done when:** the mapping table has the field ids and the FORM ID + submission-id path are
known.

---

## Stage 4 — Create the workflow (lands DRY_RUN)  · owner: workflow-system admin
Detail: `docs/formstack-to-freshdesk-workflow.md`. Files in `workflow/`.
1. Fill the placeholders:
   - `workflow/create.sh` → `FORMSTACK_FORM_ID`.
   - `workflow/user_prompt.md` → confirm the submission-id path (`{event.payload.UniqueID}`)
     against a real event payload.
   (MVP `actions.json` has no `cf_*` placeholders — it's tags + description only.)
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
   Verify: ticket created; subject `DSR-<id> — <type> (<requester>)`; **tags** landed as
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
| 1 Freshdesk fields _(optional, later)_ | Freshdesk admin | Freshdesk admin + API key |
| 2 Formstack form | Formstack builder | Formstack (EU/UK, UK-PII-approved) + API token for the script |
| 3 Field ids | form builder | — (script prints them) |
| 4 Create workflow | workflow-system admin | `WF_JWT`, `workflow_edit.py` |
| 5 Test | workflow-system admin | `WF_JWT` |
| 6 Promote | workflow-system admin | admin-UI access |
| 7 Launch | web/CMS + ops | CMS + `/administer` access |
| 8 Cutover | privacy/ops | — |
