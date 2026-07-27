# DSR field mapping (single source of truth)

The contract between the **Formstack form** (`docs/formstack-dsr-build.md`) and the
**workflow → Freshdesk** wiring (`workflow/`). Fill the `field_<NNN>` column once the Formstack
form is built (fields are referenced by numeric id, not label). "Destination" is where the
value lands on the Freshdesk ticket.

| Form question | Requester types | Formstack field id | Destination |
|---|---|---|---|
| Full Name / Full Name of Data Subject | all | `field____` | ticket requester name + description |
| Email Address | all | `field____` | **`requester_email`** |
| Phone Number | all | `field____` | ticket `phone` + description |
| Alternative Phone Number | all | `field____` | description |
| Business Type (Sole Trader / Limited) | TP | `field____` | derives `requester_type` = `TP Sole Trader` / `TP Limited` |
| Trading Name / Company Name | TP | `field____` | description |
| Transport Partner Username | TP | `field____` | **`cf_tp_username`** |
| Authorisation Details | Third Party | `field____` | description |
| Proof of Authorisation (file upload) | Third Party | `field____` | vision-summarised into description (file stays on the Formstack submission — see open item) |
| AnyVan Booking Reference | all | `field____` | **`cf_booking_reference`** (AV-prefix if digits-only) |
| Account-holder confirmation | Customer, TP | `field____` | description (attestation) |
| Request type | all | `field____` | **`cf_dsr_type`** + `request_type_tag` + description |
| SAR data categories | SAR | `field____` | description |
| Call recording entries (date/time/phone) | SAR (calls) | `field____` | description |
| Chat transcript detail (date range, channels) | SAR (chat) | `field____` | description |
| All-data window + reason | SAR (all data) | `field____` | description |
| Deletion scopes | Deletion | `field____` | description |
| Rectification fields + details | Rectification | `field____` | description |
| Additional Information | all | `field____` | description |
| Declaration | all | `field____` | required to submit (not stored as a field) |

## Derived / meta

| Value | Source | Destination |
|---|---|---|
| `requester_type` | requester-type page + business type | **`cf_requester_type`** (`Customer` / `TP Sole Trader` / `TP Limited` / `Third Party`) + `requester_type_tag` (`customer`/`tp`/`third-party`) |
| Formstack submission id | event payload | **`cf_formstack_id`** + subject reference `DSR-<id>` |
| `source` / `agent` | hidden URL params on the admin entry point (`?source=admin&agent=<id>`) | description ("logged by staff …") |
| Tags | derived | `privacy`, `dsr`, `<request_type_tag>`, `<requester_type_tag>`, `source:dsr-form` |

## Freshdesk dropdown values (must match exactly)
- `cf_dsr_type`: `SAR` · `Deletion` · `Rectification` · `Marketing Opt-Out` · `Portability`
- `cf_requester_type`: `Customer` · `TP Sole Trader` · `TP Limited` · `Third Party`

## Open items to confirm during build
- **`cf_formstack_id` type/key.** Historically a *number* field (and its key was once renamed
  to `cf_formstack_id594255` when its type changed). Confirm the live key + type via
  `GET /api/v2/ticket_fields`; `workflow/actions.json` currently sends it as a typed number.
- **Submission-id path** in the `FORMSTACK_FORM_SUBMITTED` payload (`actions.json` uses the
  placeholder `{event.payload.UniqueID}`) — confirm from a real event / `catalogue`.
- **Attaching the third-party auth file to the ticket.** The file remains on the Formstack
  submission and is vision-summarised; pulling the bytes into a Freshdesk attachment isn't a
  documented action-config path. Decide: (a) reviewers open the Formstack submission, or
  (b) add a step/handler to copy the file across. Defaulting to (a).
