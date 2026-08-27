<!--
TEMPLATE — privacy record / investigation (e.g. PII / booking lookup, SAR/DSAR note).
Copy this file to a topic subfolder as YYYY-MM-DD-kebab-case-slug.md and fill it in.
Delete these comments.

PII RULE: if this record contains ANY customer personal data (names, phone numbers, addresses,
account IDs, references to recordings), keep the CONFIDENTIAL banner below and the retention note
at the end, and MINIMISE what you include — anything committed persists in git history. If the
record has no customer data, delete the CONFIDENTIAL banner and use the INTERNAL one from
templates/options-appraisal.md instead.
-->

# {{Title}} — `{{optional identifier, e.g. phone/postcode/listing ID}}`

> ⚠️ **CONFIDENTIAL — CONTAINS CUSTOMER PERSONAL DATA (PII).**
> This record contains {{what PII, e.g. customer names, phone numbers, addresses, account IDs}}.
> Access is restricted to authorised AnyVan Privacy / Operations staff and must be handled in line
> with AnyVan's data protection policy and UK GDPR. Do not share outside the business. Note that
> anything committed here persists in git history.

| | |
|---|---|
| **Record type** | {{e.g. Booking lookup / privacy investigation}} |
| **Date created** | {{YYYY-MM-DD}} |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Data source** | {{e.g. Snowflake — PRODUCTION schema (read-only query)}} |
| **Subject identifier** | {{e.g. Phone number `07xxx xxxxxx` (normalised: `7xxxxxxxxx`)}} |

---

## 1. Request

> {{quote the request verbatim}}

---

## 2. Result

{{Findings, in Markdown tables. Include only the data the investigation needs.}}

---

## 3. Observations

{{What the result means / any caveats.}}

---

## 4. Methodology / learning (reusable)

{{How this was done, so it can be repeated. For Snowflake lookups, reuse the SQL templates in
booking-lookups/2026-08-18-phone-number-lookup-07497-700277.md §5, and route schema questions
through the anyvan-data skill. Remember LISTING_TERRORITY is an intentional typo in the schema.}}

---

## 5. Governance notes

- Queries were **read-only** against Snowflake `PRODUCTION`.
- This document contains PII — retain only as long as required for the investigation and dispose of
  / redact per policy when no longer needed.
