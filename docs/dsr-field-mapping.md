# DSR field mapping (single source of truth)

The contract between the **Formstack form** and the **workflow → Freshdesk** wiring (`workflow/`).

> **Built.** The form exists in the AnyVanforms account — **form id `6559077`**
> (`AnyVan — Data Subject Request (DSR)`), created by `workflow/build-formstack-form.js`. The
> `field_<NNN>` ids below are the live ids from that build.
>
> **Aligned to the official DSRR template** (`AnyVan_DSRR_Form.docx`). Rows marked **`new`** are
> added by the additive updater `node workflow/build-formstack-form.js --form 6559077`; their
> live ids are assigned when that runs — record them here afterwards.
>
> **MVP:** no Freshdesk custom fields yet — everything lands in **ticket tags + the description**.
> The `cf_*` column is the **later** mapping (add per `docs/freshdesk-custom-fields.md`).

| Form question | Requester types | Formstack field id | Destination (MVP) | Later `cf_*` |
|---|---|---|---|---|
| Intro / about-this-form note (DPM, privacy@anyvan.com, 1-month) | all | `new` (richtext) | — (guidance only) | — |
| Title | all | `new` | description | — |
| Full name / of data subject | all | `197276071` | description | — |
| Email address (data subject) | all | `197276072` | **`requester_email`** (unless Third Party — see below) | — |
| Phone number | all | `197276073` | ticket `phone` + description | — |
| Alternative phone number | all | `197276074` | description | — |
| Postal address | all | `new` | description | — |
| Identity-verification details | Customer, TP | `new` | description | — |
| Identity document (file, copy only) | Customer, TP | `new` | attached / noted in description | — |
| Business type (Sole/Ltd) | TP | `197276081` | → `requester_type` (TP Sole/Ltd) | — |
| Trading name | TP sole | `197276082` | description | — |
| Registered company / partnership name | TP ltd | `197276083` | description | — |
| Transport Partner username | TP | `197276084` | description | `cf_tp_username` |
| Third party — your (acting party's) name | Third Party | `new` | description | — |
| Third party — your email | Third Party | `new` | **`requester_email`** (Third Party) | — |
| Third party — your phone | Third Party | `new` | description | — |
| Authorisation details | Third Party | `197276085` | description | — |
| Proof of authorisation (file) | Third Party | `197276086` | vision-summarised into description | — |
| AnyVan booking reference | all | `197276080` | description (AV-prefixed) | `cf_booking_reference` |
| Account-holder confirmation | Customer, TP | `197276087` | description + `account-holder-confirmed` tag | — |
| Request type (9 options — see below) | all | `197276089` | `dsr_type` + `request_type_tag` + subject | `cf_dsr_type` |
| SAR data categories | SAR | `197276090` | description | — |
| Call recordings — from date | SAR (calls) | `197277114` | description | — |
| Call recordings — to date | SAR (calls) | `197277122` | description | — |
| Chat — from date | SAR (chat) | `197276092` | description | — |
| Chat — to date | SAR (chat) | `197276093` | description | — |
| Chat channels | SAR (chat) | `197276094` | description | — |
| All-data — earliest | SAR (all) | `197276095` | description | — |
| All-data — most recent | SAR (all) | `197276096` | description | — |
| All-data reason | SAR (all) | `197276097` | description | — |
| Deletion scopes | Deletion | `197276099` | description | — |
| Rectification fields | Rectification | `197276100` | description | — |
| Rectification details | Rectification | `197276101` | description | — |
| Restriction guidance note | Restrict Processing | `new` (richtext) | — (specifics via Additional information) | — |
| Objection guidance note | Object to Processing | `new` (richtext) | — (specifics via Additional information) | — |
| Automated decision-making note | Automated Decision-Making | `new` (richtext) | — (specifics via Additional information) | — |
| Withdraw-consent note | Withdraw Consent | `new` (richtext) | — (specifics via Additional information) | — |
| Additional information related to your request | all | `197276106` | description | — |
| Full name (typed signature) | all | `new` | description | — |
| Declaration | all | `197276108` | required to submit | — |
| source (hidden) | admin entry | `197276151` | description ("logged by staff") | — |
| agent (hidden) | admin entry | `197276152` | description | — |

Controllers (for reference): `requester_type` = `197276069`, sections = `197276067` /
`197276070` / `197276088` / `197276107` (+ `new` sections for Identity Verification and Third
Party). New sections created by `--form` are appended — reorder them in the builder.

## Request type — options → `dsr_type` / `request_type_tag`
The `request_type` radio (`197276089`) now carries all 8 statutory rights + Marketing Opt-Out.
The workflow maps the submitted option string per `workflow/config_prompt.md`:

| Option string (Formstack) | `dsr_type` | `request_type_tag` |
|---|---|---|
| Access My Data (SAR) | SAR | `sar` |
| Correct My Data | Rectification | `rectification` |
| Delete My Data | Deletion | `deletion` |
| Restrict Processing | Restriction | `restriction` |
| Data Portability | Portability | `portability` |
| Object to Processing | Objection | `objection` |
| Automated Decision-Making | Automated Decision-Making | `automated-decision` |
| Withdraw Consent | Withdrawal of Consent | `withdraw-consent` |
| Marketing Opt-Out | Marketing Opt-Out | `marketing-opt-out` |

## Derived / meta
| Value | Source | Destination |
|---|---|---|
| `requester_type` | requester-type + business type | subject + `requester_type_tag` (`customer`/`tp`/`third-party`) |
| `requester_email` | data-subject email, **or** the acting party's `tp3_email` when Third Party | ticket requester |
| Reference | Formstack submission id | `DSR-<id>` in subject + confirmation |
| `source` / `agent` | hidden prefill `?field197276151=admin&field197276152=<id>` | description |
| Tags | derived | `privacy`, `dsr`, `<request_type_tag>`, `<requester_type_tag>`, `source:dsr-form` |

## Later (when adding Freshdesk custom fields)
`cf_dsr_type`, `cf_requester_type`, `cf_booking_reference`, `cf_tp_username` — see
`docs/freshdesk-custom-fields.md`; then put `custom_fields` back into `workflow/actions.json`.
Confirm `cf_*` live keys/types via `GET /api/v2/ticket_fields`.
