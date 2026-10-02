# DSR field mapping (single source of truth)

The contract between the **Formstack form** and the **workflow → Freshdesk** wiring (`workflow/`).
Customer-facing form copy (welcome + submission messages) lives in `docs/dsr-form-copy.md`.

> **Built.** The form exists in the AnyVanforms account — **form id `6559077`**
> (`AnyVan — Data Subject Request (DSR)`), created by `workflow/build-formstack-form.js`. The
> `field_<NNN>` ids below are the live ids from that build.
>
> **Aligned to the official DSRR template** (`AnyVan_DSRR_Form.docx`). The additive updater
> `node workflow/build-formstack-form.js --form 6559077` **applied 2026-10-01**.
>
> **Trimmed back to the DPO-approved baseline (2026-10-01):** the data-subject **Identity
> Verification** section (`199104347/8/9`), **Title** (`199104345`), **intro note** (`199104344`),
> **postal address** (`199104346`), **typed-signature** (`199104359`) and the four **rights-explainer
> notes** (`199104355–358`) are **to be deleted in the builder** — they were unapproved additions and
> are not legally required. **Kept:** the **Third Party / Official Authority** block
> (`199104350/1/2/3`), which also carries law-enforcement requests. That kept delta + the
> request-type scope need a **DPO re-sign-off** before public launch.
>
> **MVP:** everything lands in **ticket tags + the description**, plus **one date custom field**
> `cf_privacy_due_date` (**Privacy Due Date**, already live in Freshdesk — confirm its key via
> `GET /api/v2/ticket_fields`). The `cf_*` column below is the **later** dropdown/text mapping
> (add per `docs/freshdesk-custom-fields.md`); a **Privacy Type** field (`cf_dsr_type`) now exists
> and is the first to wire next.

| Form question | Requester types | Formstack field id | Destination (MVP) | Later `cf_*` |
|---|---|---|---|---|
| Full name / of data subject | all | `197276071` | description | — |
| Email address (data subject) | all | `197276072` | **`requester_email`** (unless Third Party — see below) | — |
| Phone number | all | `197276073` | ticket `phone` + description | — |
| Alternative phone number | all | `197276074` | description | — |
| Business type (Sole/Ltd) | TP | `197276081` | → `requester_type` (TP Sole/Ltd) | — |
| Trading name | TP sole | `197276082` | description | — |
| Registered company / partnership name | TP ltd | `197276083` | description | — |
| Transport Partner username | TP | `197276084` | description | `cf_tp_username` |
| Third party — your (acting party's) name | Third Party | `199104351` | description | — |
| Third party — your email | Third Party | `199104352` | **`requester_email`** (Third Party) | — |
| Third party — your phone | Third Party | `199104353` | description | — |
| Authorisation details | Third Party | `197276085` | description | — |
| Proof of authorisation / signed request form (file) | Third Party / authority | `197276086` | vision-summarised into description | — |
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
| Additional information related to your request (+ specifics for Restriction/Objection/ADM/Withdraw) | all | `197276106` | description | — |
| Declaration | all | `197276108` | required to submit | — |
| source (hidden) | admin entry | `197276151` | description ("logged by staff") | — |
| agent (hidden) | admin entry | `197276152` | description | — |

Controllers (for reference): `requester_type` = `197276069`, sections = `197276067` /
`197276070` / `197276088` / `197276107` (+ Third Party `199104350`, added 2026-10-01). New
sections created by `--form` are appended — reorder them in the builder.

## Request type — options → `dsr_type` / `request_type_tag`
The `request_type` radio (`197276089`) carries the offered rights (**Automated Decision-Making
excluded** — AnyVan makes no solely-automated decisions with significant effect) + Marketing
Opt-Out. The workflow maps the submitted option string per `workflow/config_prompt.md`, which also
sets a best-fit **Freshdesk Privacy Type** (`privacy_type`, advisory until `cf_dsr_type` is wired):

| Option string (Formstack) | `dsr_type` | `request_type_tag` |
|---|---|---|
| Access My Data (SAR) | SAR | `sar` |
| Correct My Data | Rectification | `rectification` |
| Delete My Data | Deletion | `deletion` |
| Restrict Processing | Restriction | `restriction` |
| Data Portability | Portability | `portability` |
| Object to Processing | Objection | `objection` |
| Withdraw Consent | Withdrawal of Consent | `withdraw-consent` |
| Marketing Opt-Out | Marketing Opt-Out | `marketing-opt-out` |

## Derived / meta
| Value | Source | Destination |
|---|---|---|
| `requester_type` | requester-type + business type | subject + `requester_type_tag` (`customer`/`tp`/`third-party`) |
| `requester_email` | data-subject email, **or** the acting party's `tp3_email` when Third Party | ticket requester |
| Reference | Formstack submission id | `DSR-UK-<id>` in subject + confirmation |
| `source` / `agent` | hidden prefill `?field197276151=admin&field197276152=<id>` | description |
| Tags | derived | `privacy`, `dsr`, `<request_type_tag>`, `<requester_type_tag>`, `source:dsr-form` |

## Custom fields
**Live now (wired in the MVP):** `cf_privacy_due_date` (**Privacy Due Date**, date) — the
statutory deadline, set in `workflow/actions.json`.
**Deferred (add later):** `cf_dsr_type`, `cf_requester_type`, `cf_booking_reference`,
`cf_tp_username` — see `docs/freshdesk-custom-fields.md`; then add them to `custom_fields` in
`workflow/actions.json`. `cf_dsr_type` (**Privacy Type**) already exists and is first to wire.
Always confirm `cf_*` live keys/types via `GET /api/v2/ticket_fields` before relying on them.
