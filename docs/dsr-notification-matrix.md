# DSR Formstack notifications: one email per request type

**INTERNAL (no customer PII).** How the "AnyVan UK - Privacy Requests" form (id `6559077`) actually
raises a Freshdesk ticket. Companion to `docs/dsr-go-live-readiness.md` and
`workflow/build-formstack-notifications.py` (the script that builds this). Written 2026-09-24,
rewritten 2026-09-25 twice: first after discovering a hard Formstack plan limit, then again after
Ant clarified the priority (see below).

## This is a different mechanism from `workflow/`
Formstack has two separate kinds of outbound email, easy to conflate:
- **Notification**: an internal email, e.g. to `privacy@anyvan.com`. **This is what raises the
  Freshdesk ticket**: `privacy@anyvan.com` is a Freshdesk-connected mailbox, so an inbound email
  becomes a ticket via Freshdesk's email-to-ticket pipe. Subject → ticket subject, body → ticket
  description, `fromType:"field"` (the data subject's email field) → ticket requester.
- **Confirmation**: sent to the *form submitter* (customer/TP/third party) acknowledging receipt.
  Live as the full 3x5 matrix; see `docs/dsr-confirmation-emails.md`.

Ant built one notification by hand in the Formstack builder: **"Customer Privacy Request Email
[UK]"** (id `9711486`), gated on `197276069 == "A Customer"`, sent to `privacy@anyvan.com`. This
**is** blocker #1's "Freshdesk-event" trigger option from `docs/dsr-go-live-readiness.md`:
Formstack's own Email Output creates the ticket directly; no workflow-system involvement.

**Open question this raises for `workflow/`:** `workflow/config_prompt.md` +
`workflow/actions.json` build an *AI-workflow* path (`FORMSTACK_FORM_SUBMITTED` →
`FRESHDESK_TICKET_CREATE`); the "Formstack-event" trigger option. If the notification-based path
above is now the live mechanism, the workflow-system build is either (a) redundant and can be
parked, or (b) still wanted as a second pass that *enriches* the ticket the notification already
created (per blocker #1's phrasing: "Freshdesk-event … workflow enriches"). **Ant to confirm which**;
this doc doesn't decide it, it just flags that today's notification work makes the choice live
rather than hypothetical.

## ⚠️ Hard limit discovered live 2026-09-25: 5 notification emails per form
The first build of this matrix tried the same 3 requester types x 5 request types = 15-notification
design used for confirmations. 5 creates succeeded; the 6th failed with `{"error": "This form
reached the notification emails limit"}`, and every further create failed the same way. This is a
**Formstack plan-level cap**, not a bug: 5 notification emails total, for the whole form, no matter
how they're split. There is **no such cap on confirmations** (16 created in testing with no error),
which is why confirmations can be the full 15-variant matrix while notifications cannot.

## Which axis gets the 5 slots: request type, not requester type
The first fix split by **requester type** (3 notifications, one per Customer/TP/Third Party, each
covering all 5 request types inside one email with 4 of the 5 request-type blocks always blank).
Ant corrected this: **he wants the notification to show precisely and only the data/path the
submitter actually took**, not a superset with blank rows. Request-type detail (SAR's dates and
categories, the deletion scope, the rectification specifics, etc.) is the bulk of what a ticket
needs and the thing that most needed exact capture, so that's the axis that gets the full 5-slot
budget: **one notification per request type**, each showing exactly and only that type's own
fields, with no other request type's fields present anywhere in the email.

Requester-type detail (Transport Partner business/username fields, Authorised Third Party
authorisation fields) is the smaller compromise this forces: since only 5 slots exist and they're
now spent on request type, requester-type fields are shown **unconditionally in every notification,
blank when not applicable** (the same "blank means not applicable" pattern already accepted for
SAR's own multi-select data categories, now applied to this smaller axis instead of the larger one).

| Request type | Notification | Live id |
|---|---|---|
| SAR | SAR Privacy Request Email [UK] | `9711486` (retargeted from the original) |
| Rectification | Rectification Privacy Request Email [UK] | `9770031` |
| Deletion | Deletion Privacy Request Email [UK] | `9770032` |
| Data Portability | Data Portability Privacy Request Email [UK] | `9770051` |
| Marketing Opt-Out | Marketing Opt-Out Privacy Request Email [UK] | `9770052` |

This uses all 5 available slots; there is no headroom left on this plan for further notification
splitting without a plan upgrade.

Each notification, in order:
1. **Headline**: `[UK] New {request type} Privacy Request | Requester Type: {raw "Are You......."
   answer, merged} | Privacy Request Due: {computed date}`, then `<hr>`.
2. **Requester & Subject** (always): full name, email, phone, alt phone, booking ref.
3. **Transport Partner Details** and **Authorised Third Party Details** blocks, both always present
   (blank fields when the submission wasn't that requester type).
4. **This notification's own request-type block only**: exactly the fields for SAR, or
   Rectification, or Deletion, or Data Portability, or Marketing Opt-Out; never any other type's
   fields.
5. **Additional Information** + a Declaration line, always last.

Design matches Ant's original hand-built notification: Georgia serif, 24px bold headline, 18px
body text, `<hr>` section dividers.

## Build script
`workflow/build-formstack-notifications.py`: `--dry-run` prints every payload with no API calls;
`--apply` (with `FORMSTACK_TOKEN` set) PUTs all 5 known live ids in place, so it's idempotent to
re-run whenever the field ids or block content change. Re-verify against
`GET /forms/6559077/notifications` if the live ids in `EXISTING_NOTIFICATION_IDS_TO_REUSE` ever
stop matching reality (dedupe by id: the list endpoint echoes each one twice).

The field ids/labels and the shared content blocks live in `workflow/formstack_dsr_content.py`,
shared with `workflow/build-formstack-confirmations.py` so the two audiences never drift apart on
field ids, even though their designs differ in shape (5 vs 15 variants, and different axes) because
of the cap.

## Sources
`docs/dsr-go-live-readiness.md` (blocker #1) · `docs/dsr-confirmation-emails.md` (the confirmation
side, unaffected by the notification cap) · `docs/dsr-field-mapping.md` · `docs/conventions.md`
(the cap + confirmation payload shape, recorded there for future Formstack work) ·
`workflow/formstack_dsr_content.py` · `workflow/build-formstack-notifications.py`.
