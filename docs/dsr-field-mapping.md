# DSR field mapping (single source of truth)

The contract between the **Formstack form** and the **workflow → Freshdesk** wiring (`workflow/`).

> **Built.** The form exists in the AnyVanforms account — **form id `6559077`**
> (`AnyVan — Data Subject Request (DSR)`), created by `workflow/build-formstack-form.js`. The
> `field_<NNN>` ids below are the live ids from that build.
>
> **MVP:** no Freshdesk custom fields yet — everything lands in **ticket tags + the description**.
> The `cf_*` column is the **later** mapping (add per `docs/freshdesk-custom-fields.md`).

| Form question | Requester types | Formstack field id | Destination (MVP) | Later `cf_*` |
|---|---|---|---|---|
| Full name / of data subject | all | `197276071` | description | — |
| Email address | all | `197276072` | **`requester_email`** | — |
| Phone number | all | `197276073` | ticket `phone` + description | — |
| Alternative phone number | all | `197276074` | description | — |
| Business type (Sole/Ltd) | TP | `197276081` | → `requester_type` (TP Sole/Ltd) | — |
| Trading name | TP sole | `197276082` | description | — |
| Registered company / partnership name | TP ltd | `197276083` | description | — |
| Transport Partner username | TP | `197276084` | description | `cf_tp_username` |
| Authorisation details | Third Party | `197276085` | description | — |
| Proof of authorisation (file) | Third Party | `197276086` | vision-summarised into description | — |
| AnyVan booking reference | all | `197276080` | description (AV-prefixed) | `cf_booking_reference` |
| Account-holder confirmation | Customer, TP | `197276087` | description + `account-holder-confirmed` tag | — |
| Request type | all | `197276089` | `cf_dsr_type` value + `request_type_tag` + subject | `cf_dsr_type` |
| SAR data categories | SAR | `197276090` | description | — |
| Call recording details | SAR (calls) | `197276091` | description | — |
| Chat — from date | SAR (chat) | `197276092` | description | — |
| Chat — to date | SAR (chat) | `197276093` | description | — |
| Chat channels | SAR (chat) | `197276094` | description | — |
| All-data — earliest | SAR (all) | `197276095` | description | — |
| All-data — most recent | SAR (all) | `197276096` | description | — |
| All-data reason | SAR (all) | `197276097` | description | — |
| Deletion scopes | Deletion | `197276099` | description | — |
| Rectification fields | Rectification | `197276100` | description | — |
| Rectification details | Rectification | `197276101` | description | — |
| Additional information | all | `197276106` | description | — |
| Declaration | all | `197276108` | required to submit | — |
| source (hidden) | admin entry | `197276151` | description ("logged by staff") | — |
| agent (hidden) | admin entry | `197276152` | description | — |

Controllers (for reference): `requester_type` = `197276069`, sections = `197276067` /
`197276070` / `197276088` / `197276107`.

## Derived / meta
| Value | Source | Destination |
|---|---|---|
| `requester_type` | requester-type + business type | subject + `requester_type_tag` (`customer`/`tp`/`third-party`) |
| Reference | Formstack submission id | `DSR-<id>` in subject + confirmation |
| `source` / `agent` | hidden prefill `?field197276151=admin&field197276152=<id>` | description |
| Tags | derived | `privacy`, `dsr`, `<request_type_tag>`, `<requester_type_tag>`, `source:dsr-form` |

## Later (when adding Freshdesk custom fields)
`cf_dsr_type`, `cf_requester_type`, `cf_booking_reference`, `cf_tp_username` — see
`docs/freshdesk-custom-fields.md`; then put `custom_fields` back into `workflow/actions.json`.
Confirm `cf_*` live keys/types via `GET /api/v2/ticket_fields`.
