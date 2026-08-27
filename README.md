# AnyVan-Privacy

AnyVan's privacy records repository — "All Things Privacy." A collection of Markdown **records and
decision documents** relating to data protection and UK GDPR: PII / booking lookups, Subject Access
Request (SAR / DSAR) work, options appraisals and vendor comparisons, and privacy process notes.

This repo holds **records and decisions, not policy** — AnyVan's data-protection policy and retention
schedule live in internal policy systems elsewhere. Records here reference them.

## Structure

| Path | What's in it |
|---|---|
| `booking-lookups/` | PII lookups / investigations (e.g. find bookings by phone number or postcode) |
| `call-recording-delivery/` | Secure delivery of customer call recordings (SAR/DSAR) — options & process |
| `templates/` | House-style skeletons — copy one to start a new record |
| `CLAUDE.md` | Full operating guide: conventions, the PII / git-history rule, data sources |

## Conventions (in brief)

- One Markdown file per record, in a topic subfolder, named `YYYY-MM-DD-kebab-case-slug.md`.
- Lead with a **CONFIDENTIAL / PII** banner when the file holds customer data; an **INTERNAL** banner
  when it doesn't.
- ⚠️ **Anything committed here persists in git history** — minimise PII, and never commit secrets.
- Read **[CLAUDE.md](./CLAUDE.md)** for the full document structure and rules before adding a record.
