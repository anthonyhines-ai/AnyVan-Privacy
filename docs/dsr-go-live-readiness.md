# DSR / Privacy Request pipeline — go-live readiness

**INTERNAL — no customer PII.** The single source of truth for *what's left* before the
**"AnyVan UK - Privacy Requests"** Formstack form (id `6559077`) → workflow-system → Freshdesk goes
live. Companion to `docs/go-live-guide.md` (the stage-by-stage *how*); this file is the current
state + the outstanding items. Last updated 2026-09-02.

---

## Current state
- **Form** `6559077` is built, renamed **"AnyVan UK - Privacy Requests"**, and was hand-edited in the
  builder — so it **diverged** from the original DSRR build script and is now **mapped as-is**.
- **Contract + workflow prompts** re-pointed at the live form: `docs/dsr-field-mapping.md` (32 live
  fields/ids/options), `workflow/config_prompt.md`, `workflow/user_prompt.md`.
- **`workflow/actions.json`** = a single `FRESHDESK_TICKET_CREATE` wiring one custom field,
  `cf_privacy_due_date`.
- **Not done:** the workflow has **never been created** (no `workflow_id`); the **trigger is not
  chosen**; the **Email Output** is not configured.

## Blockers before go-live
| # | Item | State | Owner | Secret |
|---|---|---|---|---|
| 1 | **Verify the Formstack→workflow event bridge** for form `6559077`, then choose the trigger — Formstack-event (workflow creates the ticket, recommended) vs Freshdesk-event (Email Output creates it, workflow enriches) | 🔴 | Workflow admin | `WF_JWT` |
| 2 | **Configure the Email Output** — requester confirmation (Art. 12(3): reference + one-month timeline + privacy@anyvan.com); or, if trigger = Freshdesk-event, the notification that raises the ticket | 🔴 | Formstack builder | `FORMSTACK_TOKEN` |
| 3 | **Confirm the `cf_privacy_due_date` live key** via `GET /api/v2/ticket_fields`; adjust `actions.json` if suffixed | 🟠 | Freshdesk admin | Freshdesk key |
| 4 | **Create the DRY_RUN workflow** (`workflow/create.sh`) — records a `workflow_id` | 🔴 | Workflow admin | `WF_JWT` |
| 5 | **Confirm the submission-id path** `{event.payload.UniqueID}` against a real `FORMSTACK_FORM_SUBMITTED` payload | 🔴 | Workflow admin | `WF_JWT` |
| 6 | **Confirm the `FRESHDESK_TICKET_CREATED` classifier** exists and routes the `privacy`/`dsr` tags | 🟠 | Workflow admin | `WF_JWT` |
| 7 | **DRY_RUN test** — 3 requester types (Customer SAR w/ calls; TP; Authorised Third Party w/ auth file) | 🔴 | Workflow admin | `WF_JWT` |
| 8 | **Promote DRY_RUN → ACTIVE** (manual, human-reviewed in the admin UI — the script cannot promote) | 🔴 | Workflow admin (Ant) | — |
| 9 | **Launch** — publish the public URL from the privacy policy; resource the downstream verification for public volume; retire the interim AV Dashboards form | 🔴 | Privacy/ops + web | — |

## Form divergences — mapped as-is; decide whether to fix (each needs a fresh `FORMSTACK_TOKEN`)
1. **Only 5 of 8 statutory rights** (SAR, Rectification, Deletion, Portability, Marketing Opt-Out) —
   no Restriction / Objection / Automated Decision-Making / Withdrawal of Consent. Compliance
   narrowing: the rest fall to privacy@ by email.
2. **No acting-party name/email/phone** for an Authorised Third Party → `requester_email` falls back
   to the *data subject's* email; the person who lodged the request can't be identified/contacted
   from the form.
3. **No account-holder confirmation; no hidden `source`/`agent`** → no account-holder attestation; no
   `/administer` staff attribution.
4. **No Identity Verification section / ID upload / postal address / typed signature** — less than
   the DSRR template.
5. **Hidden "Privacy Due Date" field** (`197302298`) carries a **static default** — the workflow
   computes the deadline instead; consider removing the field or making it a Formstack calculation.
6. **"Video Survey" SAR category** has **no Snowflake source** (see dashboard follow-ups) — drop the
   category or mark it manual-retrieval, so we don't invite requests we can't fulfil from data.

## SAR dashboard follow-ups — surface Marketing & Transactional email + other comms (sequence after go-live)
Target: `sar-data-extract.html`. It **already** surfaces marketing email (HubSpot Emails tab) and the
transactional send-log (Comms tab → `LISTING_COMMUNICATION`).
- **Add:** transactional email **body/subject** (`EVENTS_MESSAGING_MESSAGE`, 2026-05-19+; log
  `LISTING_COMMUNICATION`, 2022+); **push**; **WhatsApp bodies** (`TWILIO_MESSAGE` +
  `TWILIO_CONVERSATION_MESSAGE`); **SMS re-sourced** to `LISTING_COMMUNICATION` (Twilio misses removal
  SMS); **live chat**; a **marketing-consent history** view (`HUBSPOT_CONTACT_PROPERTY_HISTORY`).
- **Lever:** `EVENTS_MESSAGING_MESSAGE` is one table covering email + SMS + WhatsApp + push.
- **Fix the stale caveat:** the dashboard's "Mandrill transactional emails not yet in Snowflake" note
  is **wrong** — there is no Mandrill table; transactional email is the messaging-gateway tables.
- **Data blockers:** Video Survey (no table), live-chat bodies before ~April 2026.
- **Build via** AV Dashboards named server-side queries (`get_query`/`update_query`) + Snowflake schema
  confirmation. Verify which table `sar_hubspot_emails` uses, and whether `HUBSPOT_CONTACT_LIST_MEMBER`
  exists.

## Secrets (env-vars only; **none currently set** in the working environment)
- `WF_JWT` — workflow verify/create/promote (workflows admin UI, ~12h).
- `FORMSTACK_TOKEN` (freshly rotated) — any form / Email-Output change via the V2025 API.
- Freshdesk API key — confirm the `cf_privacy_due_date` live key.

## Sources
`docs/dsr-field-mapping.md` · `docs/go-live-guide.md` · `docs/formstack-to-freshdesk-workflow.md` ·
`docs/freshdesk-custom-fields.md` · `workflow/config_prompt.md` · `workflow/actions.json` ·
`customer-communications-mapping.md` · `sar-data-extract.html`.
