# DSR field mapping (single source of truth)

The contract between the **Formstack form** and the **workflow → Freshdesk** wiring (`workflow/`).

> **Live form.** Form id **`6559077`**, now named **"AnyVan UK - Privacy Requests"**
> (https://anyvanforms.formstack.com/forms/anyvan_uk_privacy_requests). The `field_<NNN>` ids below
> are read from the **live** form definition (2026-09-02). This form was hand-edited in the builder
> and has **diverged from the original DSRR build script** (`workflow/build-formstack-form.js`) — the
> ids/labels/options here are authoritative; the build script is being reconciled to match.
>
> **MVP:** no Freshdesk custom fields except `cf_privacy_due_date` — everything else lands in
> **ticket tags + the HTML description**. The `cf_*` column is the **later** mapping (add per
> `docs/freshdesk-custom-fields.md`).
>
> **⚠️ Divergence from the DSRR template — mapped as-is, tracked in `docs/dsr-go-live-readiness.md`:**
> only **5 of 8** statutory rights are offered (no Restriction / Objection / Automated
> Decision-Making / Withdrawal of Consent); there is **no acting-party name/email/phone** for a
> third party (so `requester_email` falls back to the data subject); the **account-holder
> confirmation** and the hidden **`source`/`agent`** admin-prefill fields have been removed; and
> there is **no Identity Verification section / ID upload / postal address / typed signature**.

| Form question | Requester types | Formstack field id | Destination (MVP) | Later `cf_*` |
|---|---|---|---|---|
| Are You……. (requester type) | all | `197276069` | `requester_type` + `requester_type_tag` + subject | `cf_requester_type` |
| Full name [of the Data Subject] | all | `197276071` | description | — |
| Email Address (data subject) | all | `197276072` | **`requester_email`** (all paths — see note) | — |
| AnyVan Booking Reference/s [If Any] | all | `197276080` | description (AV-prefixed) | `cf_booking_reference` |
| Business type (Sole Trader / Ltd or Partnership) | TP | `197276081` | → `requester_type` (TP Sole/Ltd) | — |
| Trading name | TP sole | `197276082` | description | — |
| Registered Company / Partnership Name | TP ltd | `197276083` | description | — |
| Transport Partner Username | TP | `197276084` | description | `cf_tp_username` |
| Authorisation details | Third Party | `197276085` | description | — |
| Proof of authorisation (file, PDF/JPG/PNG) | Third Party | `197276086` | vision-summarised into description | — |
| What would you like us to do? (5 options — below) | all | `197276089` | `dsr_type` + `request_type_tag` + subject | `cf_dsr_type` |
| What data would you like to access? (SAR cats) | SAR | `197276090` | description | — |
| Phone Number | all | `197276073` | ticket `phone` + description | — |
| Alternative phone number | all | `197276074` | description | — |
| Call/Video Recordings — From Date | SAR (calls/video) | `197277114` | description | — |
| Call/Video Recordings — To Date | SAR (calls/video) | `197277122` | description | — |
| Chat Method Used | SAR (chat) | `197276094` | description | — |
| Chat Transcripts — From Date | SAR (chat) | `197276092` | description | — |
| Chat Transcripts — To Date | SAR (chat) | `197668331` | description | — |
| Email Correspondence — From Date | SAR (email) | `197668332` | description | — |
| Email Correspondence — To Date | SAR (email) | `197276093` | description | — |
| All Data — Earliest Interaction | SAR (all) | `197276095` | description | — |
| All Data — Most Recent Interaction | SAR (all) | `197276096` | description | — |
| Why are you requesting this Data? | SAR (all) | `197276097` | description | — |
| What data would you like deleted? (scopes) | Deletion | `197276099` | description | — |
| Which data needs correcting? | Rectification | `197276100` | description | — |
| Please provide the correct information | Rectification | `197276101` | description | — |
| Marketing Opt-Out note | Marketing Opt-Out | `197276103` (richtext) | — (guidance only) | — |
| Data Portability note (CSV/JSON, 30 days) | Data Portability | `197276105` (richtext) | — (guidance only) | — |
| Additional Information | all | `197276106` | description | — |
| Declaration | all | `197276108` | required to submit | — |
| Privacy Due Date (hidden) | all | `197302298` | **ignore** — static default; the workflow computes `privacy_due_date` | — |

> **Requester-email note.** The live form has no acting-party email field, so `requester_email` is
> always the data subject's email (`197276072`); the workflow flags in the description that a third
> party's own contact email was not captured.

## "What would you like us to do?" — options → `dsr_type` / `request_type_tag`
The request-type radio (`197276089`) offers **5** options on the live form:

| Option string (Formstack) | `dsr_type` | `request_type_tag` |
|---|---|---|
| Subject Access Request | SAR | `sar` |
| Correct My Data | Rectification | `rectification` |
| Delete My Data | Deletion | `deletion` |
| Data Portability | Portability | `portability` |
| Marketing Opt-Out | Marketing Opt-Out | `marketing-opt-out` |

> Not offered on the live form (DSRR template has them): Restrict Processing, Object to Processing,
> Automated Decision-Making, Withdraw Consent — see the go-live readiness follow-ups.

## "Are You……." — options → `requester_type` / `requester_type_tag`
| Option string (Formstack) | `requester_type` | `requester_type_tag` |
|---|---|---|
| A Customer | Customer | `customer` |
| A Transport Partner (+ Business type) | TP Sole Trader / TP Limited | `tp` |
| An Authorised Third Party | Third Party | `third-party` |

## SAR data categories (`197276090`, checkbox)
`Personal Details Held` · `Booking & Account Details` · `Call Recording/s` · `Chat Transcript/s` ·
`Email Correspondence` · `Video Survey [If Completed]`.
(Chat Method `197276094`: `WhatsApp` · `Live Chat [Via AnyVan.com]` · `Both` · `Unsure`.)

## Derived / meta
| Value | Source | Destination |
|---|---|---|
| `requester_type` | requester-type + business type | subject + `requester_type_tag` (`customer`/`tp`/`third-party`) |
| `requester_email` | data-subject email (`197276072`) — no acting-party email on the live form | ticket requester |
| Reference | Formstack submission id | `DSR-<id>` in subject + confirmation |
| `privacy_due_date` | **computed** (submission date + 1 calendar month, rolled off weekends / England-&-Wales bank holidays) | `cf_privacy_due_date` |
| Tags | derived | `privacy`, `dsr`, `<request_type_tag>`, `<requester_type_tag>`, `source:dsr-form` |

## Later (when adding Freshdesk custom fields)
`cf_dsr_type`, `cf_requester_type`, `cf_booking_reference`, `cf_tp_username` — see
`docs/freshdesk-custom-fields.md`; then put those `custom_fields` back into `workflow/actions.json`.
Confirm every `cf_*` live key/type via `GET /api/v2/ticket_fields` (the key changes if the field
type changes).
