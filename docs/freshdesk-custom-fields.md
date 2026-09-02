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

The dropdown **values must match exactly** (case and spacing) — the workflow prompt
(`workflow/config_prompt.md`) emits these literal strings for `dsr_type` and `requester_type`
(it already produces both, plus the booking reference and TP username, for the description). If
you prefer different display values, update the option strings in that prompt to match.

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

Use each returned `name` (and `type`) as the field's key in the `custom_fields` block of
`workflow/actions.json` — e.g. `"cf_dsr_type": "{dsr_type}"`, `"cf_requester_type":
"{requester_type}"`, `"cf_booking_reference": "{booking_reference}"`, `"cf_tp_username":
"{tp_username}"`. If Freshdesk suffixed a key (or you later change a field's type and its key
changes), update it in `actions.json` and re-create a DRY_RUN workflow version. This is the
same mechanism as the live `cf_privacy_due_date` field (see *Live now*, above).

## Tags (set automatically, no admin action)

The workflow sets these tags on the ticket (in `workflow/actions.json`'s `tags` array) — you do
**not** create them in admin: `privacy`, `dsr`, `<request-type>` (e.g. `sar`), `<requester-type>`
(`customer`, `tp`, or `third-party`), and `source:dsr-form`.
