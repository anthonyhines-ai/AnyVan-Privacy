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
skills/                     # packaged, org-shareable skills (anyvan-formstack-freshdesk)
.claude/skills/             # repo-scoped skills that auto-load here (privacy-records)
templates/                  # house-style skeletons — copy one to start a new record
booking-lookups/            # dated PII investigation records + reusable methodologies
communication-lookups/      # dated "locate all comms to X" records
call-recording-delivery/    # secure-delivery options appraisals (SAR/DSAR)
interaction-hub/            # Interaction Hub diagnosis notes
*.html                      # AV Dashboards pages (dsr-intake-form, interaction-hub, sar-data-extract)
customer-communications-mapping.md · SAR-Comms-Lookup-Reference.md · dsr-privacy-request-workflow-design.md
                            # the SAR/DSAR comms-automation design package (work-stream 3)
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

## Known overlaps to reconcile (don't let these drift)
- **Two DSR handoff docs:** `docs/dsr-intake-form-handoff.md` (work-stream 1's original) and
  `dsr-intake-form-handoff.md` at root (part of work-stream 3's design package). They describe the
  same Formstack form from different angles — reconcile into one when work-streams 1 and 3 next
  meet, and keep the `cf_*` decision consistent (work-stream 1 launched MVP = tags + description; 3
  specifies a `cf_` mapping for later).
- **SAR appears in three places:** the DSR form (1), the comms-automation design (3), and the
  self-service `sar-data-extract.html` dashboard (4). They're complementary, but state which is the
  operational path when you touch any of them.
