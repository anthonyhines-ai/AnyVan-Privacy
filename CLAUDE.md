# CLAUDE.md — AnyVan-Privacy

AnyVan's **"All Things Privacy"** repository. It holds two kinds of thing:

1. **Reusable tooling & pipelines** — the DSR intake pipeline (Formstack → workflow-system →
   Freshdesk), the internal dashboards, and their docs/scripts.
2. **Dated investigation records & methodologies** — privacy / DSAR-style customer lookups, each
   written up as one Markdown record, with the reusable know-how captured alongside so the next
   request is faster.

It is **not** the source of truth for policy — AnyVan's data-protection policy, retention schedule,
and DSAR procedure live in internal policy systems outside this repo. Records here *reference* those
and capture investigations/decisions. **Read this file first, then the deep guide for your
work-stream (below).**

---

## ⚠️ The rule that overrides everything — PII & git history
Most of this repo touches **customer personal data**, and **anything committed persists in git
history even if later deleted.**
- Commit PII only when the investigation genuinely needs it, and **minimise** — no more than it
  requires. Keep **bulk verbatim content** (full chat/call transcripts) **out of git**; deliver it
  to the requester as a separate export and note where it went.
- A record holding customer data leads with the **CONFIDENTIAL / PII** banner and closes with a
  retention note; a doc with **no** customer data uses the lighter **INTERNAL** banner and says so.
- **Never commit secrets.** Env-vars only — the Formstack PAT (`fs_pat_…` / `FORMSTACK_TOKEN`),
  Freshdesk API key, workflow JWT (`WF_JWT`). If one leaks into chat or a file, **rotate it**.
- **Twilio Account SID** (`AC` + 32 hex) is embedded in recording URLs and **GitHub push protection
  blocks it** — replace with `<TWILIO_ACCOUNT_SID>` (recoverable from the HubSpot call engagement /
  Twilio console when audio is actually needed).

## Golden rules (shared across all privacy work)
- **Snowflake is read-only** — `SELECT` against `PRODUCTION` only, never write, never dev/staging.
  Route table/column questions through the **`anyvan-data`** skill rather than guessing schema.
- **Normalise before matching.** Phone → `RIGHT(REGEXP_REPLACE(num,'[^0-9]',''),10)` (last 10
  digits; matches `0…`, `44…`, `+44…`, `whatsapp:+44…`). Postcode → `REPLACE(UPPER(pc),' ','')`.
  **Never** substring-match an account/user **ID** against phone digit strings.
- **Prelisting id ≠ listing id.** Quotes/deals carry 8-digit *prelisting* ids; only paid/confirmed
  jobs become a *listing* in `MASTER_LISTING` / `HARMONISED.PRODUCTION.LISTING`.
- **One customer can have several phone numbers**, and the number a requester gives may not be the
  one on the account — resolve identity from email + every phone and cross-confirm.
- **Metadata ≠ content.** `FACT_WHATSAPP_ACTIVITY` / `FACT_VOICE_ACTIVITY` say a contact happened;
  the transcript/body lives elsewhere (`HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE`, etc.).
- **Draft PR into `main`; there is NO CI** — a "pending" combined status with 0 checks is normal,
  **not** a failure. Validation is human review, so self-check before pushing.
- **Snowflake quirks:** `LISTING_TERRORITY` is an intentional schema typo (use as-is); `"FROM"` /
  `"TO"` are reserved words (double-quote them); `SNOWFLAKE.ACCOUNT_USAGE` is not authorised (use
  per-database `INFORMATION_SCHEMA`); `MASTER_LISTING` covers listings from 2022-01-01.

---

## Layout
```
docs/                       # DSR pipeline runbooks + conventions (see work-stream 1)
workflow/                   # the workflow-system definition + Formstack build script
backend/                    # superseded self-hosted Lambda — parked, NOT deployed
skills/                     # packaged, org-shareable skills (anyvan-formstack-freshdesk)
.claude/skills/             # repo-scoped skills that auto-load here (privacy-records)
templates/                  # house-style skeletons — copy one to start a new record
booking-lookups/            # dated PII investigation records + reusable methodologies
communication-lookups/      # dated "locate all comms to X" records
call-recording-delivery/    # secure-delivery options appraisals (SAR/DSAR)
interaction-hub/            # Interaction Hub diagnosis notes
sql/                        # standalone reusable queries (listing_calls_with_twilio_links.sql) and
                            # version-controlled copies of live dashboard queries missing a repo file
                            # (interaction_hub_phone_lookup.sql — backs interaction-hub.html)
handoffs/                   # dated session-handoff notes for in-progress technical work
retention/                  # dated retention-gap findings (e.g. call-recording retention)
scripts/                    # check_consistency.py — static repo/doc-drift check, see Change discipline
*.html                      # AV Dashboards pages (dsr-intake-form, interaction-hub, sar-data-extract)
customer-communications-mapping.md · SAR-Comms-Lookup-Reference.md · dsr-privacy-request-workflow-design.md
                            # the SAR/DSAR comms-automation design package (work-stream 3)
dsr-intake-form-handoff.md  # Formstack DSR form (id 6559077) spec — see "Known overlaps" below
```
Add a new topic subfolder when a genuinely new genre of record appears; one Markdown file per record.

## Work-streams — read the deep guide for the one you're touching
1. **DSR intake pipeline (Formstack → workflow-system → Freshdesk).** **Read `docs/conventions.md`
   first** for the API/format/Freshdesk gotchas, then `docs/go-live-guide.md` (runbook),
   `docs/dsr-field-mapping.md` (the contract), and the **`anyvan-formstack-freshdesk`** skill.
   Live Formstack form is `6559077` — prefer the builder's additive `--form` mode over a rebuild.
2. **Privacy investigations / lookups & DSAR sweeps.** Produce one dated record in the house style
   (below); the **`privacy-records`** skill operationalises it. Reusable data maps:
   `booking-lookups/2026-08-18-phone-number-lookup-07497-700277.md` (phone/postcode+date) and
   `booking-lookups/METHODOLOGY-communication-history.md` (all comms channels → tables).
   *Identity resolution order:* HubSpot CONTACT by email → its DEALs → Snowflake
   `DIM_USER_CUSTOMER` by email+phone → `USER_ID`; then listings.
3. **SAR/DSAR comms-automation design.** `dsr-privacy-request-workflow-design.md` +
   `customer-communications-mapping.md` + `SAR-Comms-Lookup-Reference.md` — the blueprint for
   automating SAR/portability (Formstack → workflow assembles comms → Freshdesk → officer sign-off).
   *Overlaps work-stream 1 — keep the two aligned; see "Known overlaps to reconcile".*
4. **Dashboards & phone matching.** `interaction-hub.html`, `sar-data-extract.html`. AV Dashboards
   `runQuery` binds params **only** under `options.parameters`; phone-number storage differs per
   Snowflake table (use the last-10 suffix match); the Twilio recording proxy is Flex-scoped
   (open recordings in a new tab, never inline `<audio>`, never hardcode Basic-auth creds).
5. **Secure delivery of call recordings (SAR/DSAR).** `call-recording-delivery/…` +
   `templates/options-appraisal.md` — GDPR/ICO criteria for moving off WeTransfer Free.

## Records house style (work-streams 2 & 5)
Copy a `templates/` skeleton. Shape: `# H1` → **banner** (CONFIDENTIAL/PII or INTERNAL) →
two-column **metadata table** (Record type · Date created · Raised by · Data source · Subject;
add **Status** for appraisals) → numbered `## n.` sections split by `---`, data in tables, SQL in
fenced blocks → **Governance notes** (read-only confirmation, retention) → **Sources**.
File name `YYYY-MM-DD-kebab-case-slug.md` in a topic subfolder. Default "Raised by": **Anthony
Hines (anthony.hines@anyvan.com)** unless told otherwise.

## Tools cheat-sheet
- **Snowflake:** `mcp__Snowflake__sql_exec` (read-only). **HubSpot:** `mcp__HubSpot__search_crm_objects`
  — objects CONTACT / DEAL, engagements EMAIL / CALL / NOTE / TASK / MEETING_EVENT (no SMS/WhatsApp
  object); associate engagements with **both** the contact and its deals.
- **AnyVan MCP:** `get_hubspot_contact_properties` / `get_hubspot_deal_properties` (by prelisting id)
  / `get_move_information` / `get_conversation_transcript` — the last is **Jiminny call transcripts
  by `dealId` only**, not WhatsApp/Live Chat.
- **AV Dashboards:** `mcp__AV_Dashboards__*`; deploy dashboard HTML via `get_upload_token` → HTTP
  `PUT` (the `update_dashboard` MCP tool can truncate — see README).
- **Formstack V2025 API:** call via `node -e "fetch(...)"`, not `curl` — curl gives misleading 401/404s
  against `/api/v2025`. A 401 almost always means the wrong base URL (`/api/v2` instead of
  `/api/v2025`), not a bad token. `GET /form/{id}` returns `{}`; use `GET /forms?search=<name>`
  instead. See `docs/conventions.md` for the full diagnostic snippet.
- Org skills: **`anyvan-data`** (Snowflake routing), **`workflow-editor`** / **`workflow-doctor`**
  (workflow CRUD / diagnosis), **`anyvan-hubspot-triage`** (CRM/phone duplicate diagnosis).
  Consider `/fewer-permission-prompts` to allowlist the repeat read-only calls.

## Skills in this repo
- **`.claude/skills/privacy-records/`** — repo-scoped, auto-loads here; produces a new record/appraisal
  in house style with the PII guardrail.
- **`skills/anyvan-formstack-freshdesk/`** — packaged & **org-shareable** (see `skills/README.md`),
  distilled from `docs/conventions.md`; generalises the Formstack/workflow/Freshdesk conventions.

## Ways of working (lessons from the builds)
- **Done ≠ on `main`.** Work on a draft PR doesn't help anyone until it's merged.
- **Don't over-monitor.** No recurring check-ins on a quiet, human-gated draft with no CI — it polls
  for zero signal. Watch a PR only when there's a live signal to catch.
- **Rotate exposed tokens** (a Formstack `fs_pat_…` was pasted in chat during the first build) and
  apply live changes with a fresh one.
- **Single source of truth.** `docs/conventions.md` is canonical for work-stream 1; `CLAUDE.md`,
  `ONBOARDING.md`, and the skills restate it — change all in the **same PR** so they don't drift.

## Change discipline (added 2026-11-12, after a full project sweep found repo drift — and a
sibling incident on the AntxClaudexAnyVan repo's Payment Management dashboard)

Every drift bug found in that sweep was a rule someone had already written down, not enforced —
this section exists to make the rules hard to skip, not just to restate them.

- **A query *name* on AV Dashboards can have several saved versions, and a dashboard is pinned to
  one specific version of it — never assume `execute_query`/`get_query` called WITHOUT
  `dashboard_id` shows you what a dashboard actually runs.** Called bare, it can return a different
  (older, unpinned) saved version of the same name. This bit a sibling repo hard: a sweep diagnosed
  a live query as broken from a bare-name call, "fixed" it, and deployed a regression that wiped out
  real, already-live features. **Always pass `dashboard_id`** when inspecting or diagnosing any of
  this repo's three dashboards (`dsr-intake-form`, `interaction-hub`, `sar-data-extract`).
- **Before redeploying a dashboard's HTML from the repo copy, diff the repo file against the
  actual live HTML first** (`get_dashboard_html`) — a repo copy that's silently fallen behind real,
  already-shipped features will regress the dashboard the moment you redeploy it.
- **Docs and the thing they describe change in the same commit.** A new top-level folder, a
  retired/superseded doc, a status change (e.g. "DSR form built and live," not "placeholder IDs") —
  update `CLAUDE.md`'s Layout block and the relevant doc in the same commit, not "later." Run
  `python3 scripts/check_consistency.py` before committing anything that touches a dashboard, a
  query, `CLAUDE.md` itself, or a record under a PII-bearing folder — it catches layout drift, a
  dashboard referencing a query with no repo file, a missing PII banner, and committed secrets,
  mechanically.
- **Don't write "reconcile later" with no owner or date.** That's how the two DSR handoff docs sat
  apparently-overlapping for weeks before this sweep found they were never actually duplicates.
  Either fix it now, or give it an owner and a date.
- For a broader check than the static script catches (e.g. "does this doc still match what's
  actually live on the platform or in the workflow-system, not just what's in this repo"), use the
  `session-alignment-check` skill (`.claude/skills/session-alignment-check/`) at the end of a
  session that touched any of the above.

## Known overlaps (reconciled 2026-11-11 — keep this note current, not the docs it points at)
- **Two DSR handoff docs — NOT duplicates of the same form.** `docs/dsr-intake-form-handoff.md`
  documents the **interim, bespoke AV-Dashboards HTML wizard** (`dsr-intake-form.html`, live at
  `operations/dsr-intake-form`) — it predates the Formstack decision and doesn't mention Formstack
  at all. Root `dsr-intake-form-handoff.md` documents the **Formstack form** (id `6559077`) that
  **recreates** that same question logic per `docs/formstack-dsr-build.md` — the long-term
  replacement, per the explicit decision in `docs/public-hosting.md`. Both docs are now corrected
  to say this and cross-link each other; don't let either drift back into implying they're
  describing the same artefact. `docs/dsr-field-mapping.md` is the single source of truth for live
  Formstack field ids and the actual `cf_*` decision (MVP = tags + description + one date field,
  `cf_privacy_due_date`; a fuller `cf_*` mapping is later work, tracked there) — root
  `dsr-intake-form-handoff.md`'s own field-id table is a superseded pre-build draft, not current.
- **SAR appears in three places:** the DSR form (1), the comms-automation design (3), and the
  self-service `sar-data-extract.html` dashboard (4). They're complementary, but state which is the
  operational path when you touch any of them. Current operational path for SAR/access requests:
  the Formstack form → workflow-system → Freshdesk (work-stream 1); the comms-automation design (3)
  is the blueprint for assembling the actual export once a ticket lands; `sar-data-extract.html` (4)
  is a separate self-service extract tool, not part of the Formstack pipeline.
