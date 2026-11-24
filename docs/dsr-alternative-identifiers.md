# DSR — alternative emails & authorised-third-party identifiers (lookup completeness)

> ℹ️ **INTERNAL — COMMERCIAL IN CONFIDENCE. Contains no customer personal data.** Process/design
> recommendation only.

| | |
|---|---|
| **Record type** | Improvement recommendation |
| **Date created** | 2026-11-24 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Data source** | DSR pipeline design (Formstack form 6559077 + `[UK] Privacy Submission Workflow` v43 + `sar-data-extract` dashboard) |
| **Subject** | Capturing and searching **all** of a data subject's identifiers in a SAR, incl. alternative emails and an authorised third party's own email |
| **Status** | Recommendation — needs DPO sign-off on form copy before building |

---

## 1. The gap
A Subject Access Request is only complete if we search **every** identifier the person used with
AnyVan. Today the intake and lookup are anchored to a **single data-subject email** (plus name and
phone):

- The **form** captures one primary email (`197276072`) and one alternative *phone* (`197276074`),
  but **no alternative email**. (The Authorised Third Party path does capture the acting party's own
  email, `199104352`.)
- The **live workflow's** identity/comms Snowflake queries (`dsr_customer_identity`,
  `dsr_marketing_emails`, `dsr_calls`, `dsr_chats`, `dsr_admin_notes`, …) bind a single `:email`.
- The **`sar-data-extract` dashboard** searches by one email (+ optional phone).

So if a customer used a **second email**, or a **third party authorised to act** (e.g. a family
member or solicitor) did the actual corresponding, any records under those addresses are **missed** —
an ICO completeness/accuracy risk on a statutory response.

## 2. Recommendation
1. **Form (Formstack 6559077):** add an optional **"Alternative email address(es) you may have used
   with AnyVan"** field for *all* requester types (not just Third Party). Keep the acting party's own
   email (`199104352`) for the Third Party path. Collect only what the requester volunteers — data
   minimisation still applies; this is for *locating* their data, not enriching our records.
2. **Workflow lookups:** let the identity + communications queries accept and **union a list of
   emails** (primary + any alternatives + the acting party's), the same way phone matching already
   unions `PRIMARY_PHONE_NUMBER`/`SECONDARY_PHONE_NUMBER` on the last-10 digits. Carry the acting
   party's email into the *search set*, clearly labelled, not only into the ticket reply-to.
3. **`sar-data-extract` dashboard:** accept multiple comma-separated emails and union the results, so
   a manual run matches what the automated workflow searches.

## 3. How to build (when approved)
- Form field: additive `node workflow/build-formstack-form.js --form 6559077` (then record the new
  field id in `docs/dsr-field-mapping.md`).
- Workflow: a new version (admin UI / workflow MCP) — widen the email bind to a list in the identity/
  comms queries in `workflow/snowflake_queries.json`, and prompt the model to pass every provided
  email. Re-reconcile the repo after.
- Dashboard: edit `sar-data-extract.html` + its queries to take multiple emails.

## 4. Governance notes
- No customer PII in this record. All three changes are about **search completeness**; none widens
  what we *retain*. The alternative-email field needs **DPO sign-off** on wording before it goes on
  the public form (keep it optional and framed as "to help us find your data").
