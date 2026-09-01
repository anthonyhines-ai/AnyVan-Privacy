# Comms / data lookup — Heather Tarte · `heather.lyall00@hotmail.co.uk` · `B50 4QN`

> ⚠️ **CONFIDENTIAL — CONTAINS CUSTOMER PERSONAL DATA (PII).**
> This record contains a named individual, their email address and a home address.
> Access is restricted to authorised AnyVan Privacy / Operations staff and must be handled in line
> with AnyVan's data protection policy and UK GDPR. Do not share outside the business. Note that
> anything committed here persists in git history.

| | |
|---|---|
| **Record type** | Data-subject lookup / privacy investigation (nil-match) |
| **Date created** | 2026-09-01 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Data source** | Snowflake — `PRODUCTION` schema (read-only) · HubSpot CRM (read-only) |
| **Subject identifiers** | Email `heather.lyall00@hotmail.co.uk` · Name *Heather Tarte* · Address *20 Russet Way, Bidford-on-Avon, B50 4QN* |

---

## 1. Request

> "heather.lyall00@hotmail.co.uk / Heather Tarte / 20 russet way bidford on Avon, b50 4qn —
> Can you locate anything for this information? [Likely marketing email]"

---

## 2. Result — **NIL MATCH**

AnyVan holds **no record** of this individual against any of the three identifiers. Every system
that could carry a customer, lead, marketing or communication footprint was checked and returned
nothing for the subject.

| Identifier checked | System / table | Records found |
|---|---|---|
| Email `heather.lyall00@hotmail.co.uk` | HubSpot CRM (contact search) | **0** |
| Email | `HUBSPOT_CONTACT` warehouse export (5.1M rows, incl. spelling variants) | **0** |
| Email | `DIM_USER_CUSTOMER` (customer accounts) | **0** |
| Email | `EVENTS_EMAIL` (itemised email sends / opens / clicks) | **0** |
| Email | `HUBSPOT_EMAIL_CAMPAIGNS` (marketing campaign sends) | **0** |
| Email | `EVENTS_MESSAGING_MESSAGE` (transactional SMS / WhatsApp / email) | **0** |
| Name *Heather Tarte* / *Heather Lyall* | HubSpot CRM · `DIM_USER_CUSTOMER` · `HARMONISED.ADDRESS` | **0** |
| Address *20 Russet Way, B50 4QN* | `MASTER_LISTING` + `DIM_ADDRESS` (pickup/delivery postcode) | **0 at no. 20** |
| Address *20 Russet Way, B50 4QN* | `HARMONISED.ADDRESS` (contact records at postcode) | **0 for subject** |

### The "likely marketing email" flag is **not** supported

There is no marketing footprint of any kind — the address is on **no** HubSpot list, **no** campaign
send, and **no** email-event stream. If this was raised as a marketing-suppression / opt-out request,
there is **nothing to suppress**: AnyVan is not, and on this data has never been, emailing it.

---

## 3. Context — the postcode is known, the subject is not

`B50 4QN` (Russet Way) is a live AnyVan postcode: **5 completed bookings** touch the street. All are
at **different door numbers** (nos. 8, 25, 42, 43, and one postcode-only record) and tied to
**unrelated customer accounts** — none is no. 20, and none carries the name *Heather Tarte/Lyall*.
Neighbours having used AnyVan is not a record of this data subject; third-party details are
deliberately excluded from this note per the PII / git-history rule.

Two things worth flagging for whoever raised this:

- **Name ≠ email.** The email local-part surname (*lyall*) does not match the supplied name
  (*Tarte*). The two may be different people, or a personal email unconnected to AnyVan.
- **Nothing to action.** No data is held to export, redact, suppress or delete. If a data subject
  submits a formal SAR/erasure on these identifiers, the correct response is a documented
  **"no personal data held"**.

---

## 4. Methodology / learning (reusable)

Identity-resolution order per `booking-lookups/METHODOLOGY-communication-history.md` §0, run to
exhaustion because the first hops were empty. No phone number was supplied, so the last-10 phone
rule was not used; matching keyed on **email** (exact + `LIKE` variants) and **name** + **postcode**.

- **Email is the strongest key for a "marketing email" query.** Check both the itemised stream
  (`EVENTS_EMAIL`) **and** the marketing-campaign table (`HUBSPOT_EMAIL_CAMPAIGNS`, keyed on
  `HS_EMAIL_EVENT_EMAIL_RECIPIENT`) — a marketing-only address can be in one and not the other.
- **HubSpot lives in Snowflake too.** When the HubSpot MCP search returns nothing, confirm against
  the warehouse export `HARMONISED.PRODUCTION.HUBSPOT_CONTACT` (match on `PROPERTY_EMAIL`; this
  export carries no first/last-name column, so name search must go via `DIM_USER_CUSTOMER` /
  `HARMONISED.ADDRESS`).
- **Postcode ≠ address.** A full-postcode hit set (`REPLACE(UPPER(pc),' ','')='B504QN'`) returns the
  whole street; read the **door number** in `LISTING_PICK_UP_ADDRESS` / `LISTING_DELIVERY_ADDRESS`
  before concluding a match. Reuse Template B in
  `booking-lookups/2026-08-18-phone-number-lookup-07497-700277.md` §5.5.

Tables queried (all read-only): `CONFORMED.PRODUCTION.DIM_USER_CUSTOMER`, `.MASTER_LISTING`,
`.DIM_ADDRESS`; `HARMONISED.PRODUCTION.ADDRESS`, `.EVENTS_EMAIL`, `.HUBSPOT_EMAIL_CAMPAIGNS`,
`.HUBSPOT_CONTACT`, `.EVENTS_MESSAGING_MESSAGE`; HubSpot CRM contact search.

### Caveat

`MASTER_LISTING` covers listings from **2022-01-01** onward. A pre-2022 booking would not surface
full context here — but with no account, email or CRM record either, a pre-2022 relationship is
highly unlikely. The name sweep was targeted (*heather* + *tarte* / *lyall*); a materially different
spelling would not be caught.

---

## 5. Governance notes

- Queries were **read-only** against Snowflake `PRODUCTION` and HubSpot; no data was written.
- Third-party (neighbour) personal data returned during the postcode sweep has been **excluded** from
  this record — only aggregate counts and door numbers are retained, per the PII / git-history rule
  in `/CLAUDE.md`.
- This document contains the subject's PII — retain only as long as required for the investigation
  and dispose of / redact per AnyVan's retention schedule when no longer needed.

---

## Sources

- `booking-lookups/METHODOLOGY-communication-history.md` — identity resolution + channel→table map.
- `booking-lookups/2026-08-18-phone-number-lookup-07497-700277.md` §5 — postcode/booking SQL templates.
