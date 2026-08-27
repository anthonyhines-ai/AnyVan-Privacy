# Freshdesk custom fields for DSR tickets

> **Deferred for the MVP launch.** The initial go-live maps everything into ticket **tags + a
> structured HTML description** (no custom fields). Everything still routes. Add these fields
> later when you want structured filtering/reporting (SLA views, ICO metrics) — the workflow's
> prompt already emits the values, so enabling them is a small follow-up (add the fields, then
> put `custom_fields` back into `workflow/actions.json`). The rest of this doc is that follow-up.

## Live now: Privacy Due Date (date field)
Already created in Freshdesk (label **Privacy Due Date**, hidden from customers). Internal key
**`cf_privacy_due_date`** — confirm via `GET /api/v2/ticket_fields` and adjust
`workflow/actions.json` if Freshdesk suffixed it. The workflow sets it to the statutory deadline
(submission date + one calendar month, rolled to the next working day), formatted `YYYY-MM-DD`,
via `custom_fields`. This is the one custom field wired in the MVP.

## Deferred: dropdown/text fields
These four custom fields go on the **ticket** object in Freshdesk. Create them in
**Admin → Ticket Fields** (requires Freshdesk admin).

| Label (what admins see) | Internal key (`cf_*`) | Type | Values |
|---|---|---|---|
| DSR Type | `cf_dsr_type` | Dropdown | `SAR`, `Deletion`, `Rectification`, `Marketing Opt-Out`, `Portability` |
| Requester Type | `cf_requester_type` | Dropdown | `Customer`, `TP Sole Trader`, `TP Limited`, `Third Party` |
| Booking Reference | `cf_booking_reference` | Text (single line) | — |
| TP Username | `cf_tp_username` | Text (single line) | — |

The dropdown **values must match exactly** (case and spacing) — the backend sends these
literal strings. If you prefer different display values, update the maps in
`backend/handler.js` (`DSR_TYPE_LABELS`, `requesterTypeLabel`) to match.

## ⚠️ Confirm the live `cf_*` keys before deploying

Freshdesk's internal `cf_*` key is derived from the label **at creation time**, and it
**changes if you later change the field's type** (e.g. a number field renamed to
`cf_booking_reference594255`). A stale key makes the ticket-create call fail with
`invalid_field`.

Confirm the actual keys with:

```bash
curl -s -u "$FRESHDESK_API_KEY:X" \
  "https://<domain>.freshdesk.com/api/v2/ticket_fields" \
  | jq '.[] | select(.name|test("dsr|requester|booking|tp_username")) | {label:.label, name:.name, type:.type}'
```

If any returned `name` differs from the defaults above, set the matching environment
variable on the Lambda so no code change is needed:

| If the live key is… | set env var |
|---|---|
| DSR type field | `CF_DSR_TYPE` |
| Requester type field | `CF_REQUESTER_TYPE` |
| Booking reference field | `CF_BOOKING_REFERENCE` |
| TP username field | `CF_TP_USERNAME` |

## Tags (set automatically, no admin action)

The backend derives tags from the payload — you do **not** create these in admin:
`privacy`, `dsr`, `<request-type>` (e.g. `sar`), `<requester-type>` (e.g. `customer`,
`tp`, `third-party`), `source:dsr-form`, and `account-holder-confirmed` (only when the
requester confirmed they are the account holder).
