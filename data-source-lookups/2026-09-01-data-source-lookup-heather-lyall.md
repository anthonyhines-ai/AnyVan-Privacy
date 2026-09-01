# Data-source lookup — Heather Lyall / `heather.lyall00@hotmail.co.uk`

> ⚠️ **CONFIDENTIAL — CONTAINS CUSTOMER PERSONAL DATA (PII).**
> This record names an individual data subject and their email address (both supplied with the
> request). Access is restricted to authorised AnyVan Privacy / Operations staff and must be handled
> in line with AnyVan's data protection policy and UK GDPR. Do not share outside the business. Note
> that anything committed here persists in git history.

| | |
|---|---|
| **Record type** | Data-source / provenance investigation (UK GDPR Art. 14) — **nil return** |
| **Date created** | 2026-09-01 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Data source** | HubSpot CRM + Snowflake `PRODUCTION` schema (read-only) |
| **Subject identifier** | Email `heather.lyall00@hotmail.co.uk`; name **Heather Lyall** |

---

## 1. Request

> "heather.lyall00@hotmail.co.uk — Can you help find the source of how AnyVan got the information for
> this customer. Maybe also look using Heather Lyall as a name."

Interpreted as an **Article 14 "source of personal data"** question: where/how did AnyVan obtain this
person's details. Searched by both the **email** and the **name**.

---

## 2. Result — no data found (nil return)

An **exhaustive search across every customer-facing and lead-acquisition system** returned **no
record** matching this email or this name. AnyVan does **not** appear to hold personal data for this
individual under the identifiers provided, so **there is no data-acquisition source to report.**

The email `heather.lyall00@hotmail.co.uk` — the single most reliable identifier — appears in **none**
of the systems below.

| # | System / table | Searched by | Result |
|---|---|---|---|
| 1 | HubSpot **CONTACT** | email (exact, token, free-text, `hs_additional_emails`); name (exact, token, free-text) | **0 matches** |
| 2 | HubSpot **LEAD** | — | Not readable this session (`REQUIRES_REAUTHORIZATION`); leads are contact-associated and no contact exists — see §4 |
| 3 | `CONFORMED.PRODUCTION.DIM_USER_CUSTOMER` (account holders) | `EMAIL_ADDRESS` (exact + variants), `FULL_NAME` | **0 rows** |
| 4 | `HARMONISED.PRODUCTION.ADDRESS` (collection/delivery contacts on any booking) | `FIRSTNAME` + `LASTNAME` | **0 rows** |
| 5 | `HARMONISED.PRODUCTION.EVENTS_EMAIL` (email sends) | `EMAIL_ADDRESS` (exact + variants) | **0 rows** |
| 6 | `HARMONISED.PRODUCTION.EVENTS_MESSAGING_MESSAGE` (transactional/marketing) | `RESOLVED_USER_EMAIL`, `CHANNEL_RECIPIENT` | **0 rows** |
| 7 | `HARMONISED.PRODUCTION.EVENTS_LEADGEN_CREATED_PRE_LISTING` (partner leads → prelistings) | `CONTACT_EMAIL`, `CONTACT_FIRST_NAME` + `CONTACT_LAST_NAME` | **0 rows** |
| 8 | `HARMONISED.PRODUCTION.EVENTS_LEAD_GEN` (lead-gen API events) | `PAYLOAD` (email + name) | **0 rows** |
| 9 | `HARMONISED.PRODUCTION.EVENTS_AMY_LEAD` (AI voice-agent leads) | `LEAD_STATE`, `PROPERTY_VALUE` (email + name) | **0 rows** |
| 10 | `HARMONISED.PRODUCTION.FORMSTACK_FORM_SUBMISSION_DATA` (all form submissions, ~2.3M) | submitted `VALUE` (email) | **0 rows** |
| 11 | `HARMONISED.PRODUCTION.FRESHDESK_TICKET` (support tickets) | — | Table empty (no rows synced) |

> Note on the name search: HubSpot holds **48** contacts with the surname *Lyall*, but **none** is a
> *Heather* Lyall, and none carries the target email. Those other individuals are unrelated data
> subjects and are deliberately **not** reproduced here (data minimisation).

---

## 3. What a "source" would have looked like (had a record existed)

For context, if AnyVan **did** hold this person, the acquisition source would have surfaced as one of:

- **Self-service quote on anyvan.com** — a HubSpot CONTACT with `hs_analytics_source` =
  `ORGANIC_SEARCH` / `PAID_SEARCH` / `DIRECT_TRAFFIC` / `REFERRALS`, and a matching prelisting/deal.
- **Third-party lead-generation partner** — a row in `EVENTS_LEADGEN_CREATED_PRE_LISTING` carrying
  `PARTNER_NAME` / `ORIGIN_PARTNER_NAME` / `ORIGIN_PARTNER_URL` (the named partner is the source), or
  an `EVENTS_LEAD_GEN` event with `PARTNER_NAME` + payload.
- **Admin/agent-created** — a HubSpot CONTACT with `created_by_admin_id` populated (details taken over
  the phone by an AnyVan agent).
- **Collection/delivery contact on another customer's booking** — name + phone in
  `HARMONISED.PRODUCTION.ADDRESS` (i.e. a third party gave AnyVan her details as a move contact).

**None of these matched**, so none applies. There is no source to attribute.

---

## 4. Observations & caveats

- **The email is absent everywhere.** Email is normally the most stable key, so its total absence is
  strong evidence AnyVan holds nothing for this person under the details given.
- **The identifier supplied may not be the one on file.** Per `/CLAUDE.md`, the email/number a
  requester gives is not always the one on the account. If Heather Lyall is genuinely an AnyVan
  customer, her record may sit under a **different email and/or phone**. To pivot, we would need any
  one of: a **phone number**, an **alternative email**, a **postcode + move date**, or a
  **booking / listing / prelisting reference**.
- **Channels not searched (no key or no access):**
  - **Twilio voice / SMS / WhatsApp** (`TWILIO_CALL`, `TWILIO_MESSAGE`) key off a **phone number**,
    which was not provided — not searchable on email/name alone.
  - **HubSpot LEAD** object requires re-authorisation for read access in this session; however leads
    are always associated with a CONTACT (none exists here) and the three Snowflake lead mirrors
    (rows 7–9) all returned nil, so this is effectively covered.
  - Any system **outside Snowflake/HubSpot** (raw ad-platform audiences, a third-party lead vendor's
    own portal, backups) is out of scope for this search.
- **No positive evidence of prior erasure** was found. If a previous erasure/suppression is suspected,
  that would need to be confirmed against suppression/audit logs, which are outside this search.

**Suggested response posture:** treat as a **"no data held"** outcome. Either (a) respond that AnyVan
holds no personal data for the identifiers provided, or (b) ask the requester for an additional
identifier (phone, alternative email, or postcode + move date) and re-run before closing.

---

## 5. Methodology / learning (reusable)

Standard identity-resolution order (`/CLAUDE.md`): HubSpot CONTACT by email → name → phone; then
`DIM_USER_CUSTOMER` by email + phone → `USER_ID`; then bookings. Here it terminated at the first
step — no CONTACT, no `USER_ID` — so the search fanned out directly across the acquisition and
messaging tables by **email** and **name**.

**The go-to "source / provenance" table** is
`HARMONISED.PRODUCTION.EVENTS_LEADGEN_CREATED_PRE_LISTING`. For a "where did you get my data" request
it is the highest-value lookup, because it stores the contact details **alongside the originating
partner**:

```sql
-- "Source of data" / provenance lookup by email or name.
-- Swap the literals. PARTNER_NAME / ORIGIN_PARTNER_NAME / ORIGIN_PARTNER_URL name the source.
SELECT EVENT_TIMESTAMP, EVENT_SOURCE, PARTNER_NAME, ORIGIN_PARTNER_NAME, ORIGIN_PARTNER_URL,
       CONTACT_FIRST_NAME, CONTACT_LAST_NAME, CONTACT_EMAIL, CONTACT_PHONE,
       PRE_LISTING_ID, HUBSPOT_CONTACT_ID, HUBSPOT_DEAL_ID,
       PICKUP_POSTCODE, DELIVERY_POSTCODE, MOVE_DATE, MOVE_TYPE, LOCALE
FROM HARMONISED.PRODUCTION.EVENTS_LEADGEN_CREATED_PRE_LISTING
WHERE CONTACT_EMAIL ILIKE '%<local-part>%'
   OR (UPPER(CONTACT_FIRST_NAME) LIKE '%<FIRST>%' AND UPPER(CONTACT_LAST_NAME) LIKE '%<LAST>%')
ORDER BY EVENT_TIMESTAMP;
```

Companion acquisition/marketing tables worth sweeping when the above is empty (all keyed off email or
the payload, so searchable without a phone number):

| Purpose | Table | Source-bearing columns |
|---|---|---|
| Lead-gen API events | `HARMONISED.PRODUCTION.EVENTS_LEAD_GEN` | `PARTNER_NAME`, `EVENT_SOURCE`, `PAYLOAD` |
| AI voice-agent leads | `HARMONISED.PRODUCTION.EVENTS_AMY_LEAD` | `AFFILIATE_NAME`, `QUEUE_SOURCE`, `LEAD_STATE` |
| Email sends | `HARMONISED.PRODUCTION.EVENTS_EMAIL` | `SOURCE`, `EMAIL_EVENT_TYPE` |
| Transactional/marketing msgs | `HARMONISED.PRODUCTION.EVENTS_MESSAGING_MESSAGE` | `CHANNEL`, `TEMPLATE_KEY`, `RESOLVED_USER_*` |
| HubSpot contact origin | HubSpot `CONTACT` | `hs_analytics_source(_data_1/2)`, `hs_latest_source`, `hs_object_source_label`, `created_by_admin_id` |

Reuse the booking/phone SQL templates in
`booking-lookups/2026-08-18-phone-number-lookup-07497-700277.md` §5 (Template A: phone → customer /
collection / delivery) and the channel map in `booking-lookups/METHODOLOGY-communication-history.md`
once a phone number is available. Route any schema questions through the **`anyvan-data`** skill.
(`LISTING_TERRORITY` remains an intentional schema typo; `"FROM"` / `"TO"` are reserved words.)

---

## 6. Governance notes

- All Snowflake queries were **read-only** `SELECT` against `PRODUCTION`; HubSpot access was read-only.
- **Nil return:** no customer data was retrieved. The only PII in this record is the subject
  identifier that accompanied the request (name + email), retained here solely to evidence that an
  exhaustive search was performed. No third-party personal data is reproduced.
- Retain only as long as required to evidence handling of this request; dispose of / redact per the
  AnyVan retention schedule when no longer needed.

---

## 7. Sources

- AnyVan Snowflake warehouse (`CONFORMED.PRODUCTION`, `HARMONISED.PRODUCTION`) — read-only, 2026-09-01.
- HubSpot CRM (CONTACT search; LEAD object read requires re-authorisation) — 2026-09-01.
