---
name: privacy-records
description: >
  Produce and file AnyVan privacy records and decision documents in the AnyVan-Privacy repo's house
  style. Use whenever working in the AnyVan-Privacy repo, or when Ant asks to create/record any of:
  a PII or booking lookup (find bookings by phone number, postcode, address, account/listing ID); a
  Subject Access Request (SAR / DSAR) note or data-subject request; a data-protection or privacy
  options appraisal / vendor comparison (e.g. secure file delivery, call-recording delivery, storage
  tooling); a retention, redaction, or disposal note; or any "add/write a privacy record or doc".
  Enforces the repo's filing conventions (YYYY-MM-DD-kebab-case.md in a topic subfolder), the
  metadata-table + numbered-section + governance-notes structure, the CONFIDENTIAL/PII vs INTERNAL
  banner rule, and the PII / git-history guardrail. Routes any warehouse question through the
  anyvan-data skill (Snowflake PRODUCTION, read-only). Do not use for building dashboards, or for
  audits already covered by the dedicated auditor skills.
---

# Privacy records (AnyVan-Privacy)

Workflow for producing a new record or decision document in the `AnyVan-Privacy` repo so it lands in
house style, filed correctly, with the PII guardrail applied. Read `CLAUDE.md` in the repo root first —
it is the authority; this skill operationalises it.

## 0. The rule that overrides everything — PII & git history

The repo can hold **customer personal data**, and **anything committed persists in git history even if
later deleted.** Before writing anything to a file:

- Decide whether the record genuinely needs customer data. If not, keep it out entirely.
- If it does, **minimise** — include only what the investigation requires.
- Never commit credentials, tokens, secrets, or actual call-recording files.

## 1. Classify the record → pick the template

- **Investigation / lookup / SAR note** (touches customer data) → copy `templates/record.md`
  and keep the **CONFIDENTIAL / PII** banner + closing retention note.
- **Options appraisal / vendor comparison / process analysis** (no customer data) → copy
  `templates/options-appraisal.md` and use the **INTERNAL — contains no customer data** banner.
- New genre → add a new topic subfolder; keep one file per record.

## 2. File it correctly

- Path: an existing topic subfolder (`booking-lookups/`, `call-recording-delivery/`, …) or a new one.
- Name: `YYYY-MM-DD-kebab-case-slug.md` (today's date, from the environment).
- Default author ("Raised by"): **Anthony Hines (anthony.hines@anyvan.com)** unless told otherwise.

## 3. Fill the house structure

H1 title → banner blockquote (PII or INTERNAL) → two-column metadata table (Record type · Date created ·
Raised by · Data source · Subject; add **Status** for appraisals) → numbered `## n.` sections split by
`---` rules, data in Markdown tables, SQL/code in fenced blocks → **Governance notes** to close →
**Sources** for any external research.

## 4. Data lookups

- Route table/column questions through the **`anyvan-data`** skill; don't guess schema.
- Snowflake `PRODUCTION` is **read-only**. `MASTER_LISTING` covers listings from 2022-01-01 onward.
- **`LISTING_TERRORITY` is an intentional typo** in the schema — use it as-is.
- Reuse the phone/postcode + date SQL templates in
  `booking-lookups/2026-08-18-phone-number-lookup-07497-700277.md` §5.

## 5. Research & recommendation discipline (appraisals)

- For anything handling personal data, anchor recommendations to the UK GDPR / ICO criteria:
  encryption (transit + at rest, ideally E2E) · password/code sent via a **separate** channel ·
  recipient verification · configurable expiry + revocation · UK/EU residency · **DPA (Art. 28)** ·
  audit trail · data minimisation & retention.
- Confirm org constraints up front: stack (**Google Workspace**, no Microsoft 365), budget appetite,
  and that the DPO signs off anything customer-facing.
- Mark pricing and unconfirmed third-party claims **indicative**; flag ICO wording as "verify against
  live ICO pages" (their site blocks automated fetch).
- Remember: this repo captures **records and decisions**, not policy — the data-protection policy and
  retention schedule live in internal systems outside the repo. Reference them; don't restate as fact.

## 6. Commit & PR

- Develop on a feature branch; open a **draft PR** into `main`. No CI — self-check before pushing.
- Re-read the finished record against `CLAUDE.md` and an existing example for house-style consistency,
  and confirm no unintended PII is present, before committing.
