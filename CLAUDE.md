# CLAUDE.md — AnyVan-Privacy

Operating guide for this repository. **Read this before creating or editing any record.** It captures
what the repo is, how records are structured, and the rules that must hold every time.

---

## What this repo is

AnyVan's **privacy records repository** — "All Things Privacy." It holds Markdown **records and decision
documents** relating to data protection / UK GDPR: PII / booking lookups, Subject Access Request (SAR /
DSAR) notes, options appraisals and vendor comparisons, and process documentation.

- **It is documentation, not code.** There is no build, no tests, no application. Every file is Markdown.
- **It is not the source of truth for policy.** AnyVan's actual data-protection policy, retention
  schedule, and DSAR procedure live in internal policy systems **outside this repo**. Records here
  *reference* those policies and capture investigations and decisions — they don't define policy.

**Default author** ("Raised by"): **Anthony Hines (anthony.hines@anyvan.com)** unless told otherwise.

---

## ⚠️ PII & git history — the rule that matters most

This repo can contain **customer personal data (PII)** — names, phone numbers, addresses, account IDs,
and (for call-recording work) references to recordings.

- **Anything committed here persists in git history, even if later deleted.** Treat every commit as
  permanent and public-to-the-business.
- Commit PII only when the record genuinely needs it, and **minimise** it — no more than the
  investigation requires.
- When a file contains PII, lead with the **CONFIDENTIAL / PII banner** (see `templates/`) and close with
  a **retention note**.
- When a file is analysis *about* a process, tool, or vendor with **no customer data**, say so explicitly
  and use the lighter **INTERNAL** banner instead.
- Never commit credentials, tokens, or secrets.

---

## Layout

Records live in **topic subfolders**, one Markdown file per record:

```
booking-lookups/            # PII lookups / investigations (find bookings by phone, postcode, etc.)
call-recording-delivery/    # secure delivery of customer call recordings (SAR/DSAR) — options & process
templates/                  # house-style skeletons — copy one to start a new record
.claude/skills/             # repo-scoped skills that auto-load when working here
CLAUDE.md · README.md       # this guide + human-facing orientation
```

Add a new topic subfolder when a genuinely new genre of record appears; keep it one file per record.

---

## File naming

`YYYY-MM-DD-kebab-case-slug.md` — date-prefixed, lower-case, hyphenated. Examples:
`2026-08-18-phone-number-lookup-07497-700277.md`, `2026-08-20-secure-call-recording-delivery-options.md`.

---

## Document structure (house style)

Every record follows this shape — the `templates/` files are ready-to-copy skeletons:

1. `# H1 title`, with an optional inline-code identifier.
2. **Banner blockquote** — `CONFIDENTIAL / PII` if it holds customer data; otherwise
   `INTERNAL — commercial in confidence · contains no customer data`.
3. **Metadata table** (two columns): **Record type · Date created · Raised by · Data source · Subject**
   (add **Status** for appraisals / decision docs).
4. **Numbered `## n.` sections** separated by `---` rules. Data goes in Markdown tables; SQL / code in
   fenced blocks.
5. **Governance notes** as the closing section — read-only confirmation, PII / retention note.
6. **Sources** at the end for any external research, with a *"verify before quoting"* flag on anything
   that couldn't be confirmed (e.g. pages that block automated fetch, indicative pricing).

Keep records **scannable** (tables, short sections) but **auditable** (sources, governance).

---

## Data sources

- Warehouse: **Snowflake `PRODUCTION`**, **read-only**. Route table / column questions through the
  **`anyvan-data`** skill (authoritative dbt-maintained docs) rather than guessing schema.
- Common tables: `CONFORMED.PRODUCTION.MASTER_LISTING`, `DIM_ADDRESS`, `DIM_USER_CUSTOMER`; harmonised
  sources `HARMONISED.PRODUCTION.LISTING` / `ADDRESS`.
- **Known schema quirk:** `LISTING_TERRORITY` is an **intentional typo** in the schema — use it as-is.
- `MASTER_LISTING` covers listings from **2022-01-01** onward.
- Reusable lookup SQL (phone / postcode + date) lives in
  `booking-lookups/2026-08-18-phone-number-lookup-07497-700277.md` §5 — reuse those templates.

---

## Working in this repo (git)

- Develop on a feature branch; open a **draft PR** into `main`.
- **No CI is configured** — validation is human review, so self-check before pushing.
- Don't rewrite history on shared branches.

---

## Related skills

- **`privacy-records`** (repo-scoped, in `.claude/skills/`) — auto-loads the workflow for producing a new
  record or appraisal in this house style, including the PII guardrail and filing conventions.
- **`anyvan-data`** — Snowflake table / column routing for any data lookup.
