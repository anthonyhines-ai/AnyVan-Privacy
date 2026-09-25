# DSR Formstack notifications: one email per requester type

**INTERNAL (no customer PII).** How the "AnyVan UK - Privacy Requests" form (id `6559077`) actually
raises a Freshdesk ticket. Companion to `docs/dsr-go-live-readiness.md` and
`workflow/build-formstack-notifications.py` (the script that builds this). Written 2026-09-24,
rewritten 2026-09-25 after discovering a hard Formstack plan limit (see below).

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
design used for confirmations. 5 creates succeeded (the Customer requester type, one per request
type); the 6th failed with `{"error": "This form reached the notification emails limit"}`, and
every further create failed the same way. This is a **Formstack plan-level cap**, not a bug: 5
notification emails total, for the whole form, no matter how they're split. There is **no such cap
on confirmations** (16 created in testing with no error), which is why confirmations can be the
full 15-variant matrix while notifications cannot.

## The live design: 3 notifications, one per requester type
Each notification is gated on requester type only (`197276069`) and covers **all 5 request types
inside one email**: every request-type block (SAR, Rectification, Deletion, Data Portability,
Marketing Opt-Out) is concatenated unconditionally. Only the block matching what was actually
selected has populated merge fields; the other 4 render blank (the same "blank means not
applicable" pattern already accepted for SAR's own multi-select categories, extended to the whole
request-type axis because the notification budget doesn't allow splitting further).

| Requester type | Notification | Live id |
|---|---|---|
| Customer | Customer Privacy Request Email [UK] | `9711486` (retargeted from the original) |
| Transport Partner | Transport Partner Privacy Request Email [UK] | `9770031` |
| Authorised Third Party | Authorised Third Party Privacy Request Email [UK] | `9770032` |

This uses 3 of the 5 available slots, leaving 2 spare (e.g. for a future non-DSR notification on
this form, or if Ant later wants a 4th/5th variant).

Each notification, in order:
1. **Headline**: `[UK] New {requester type} Privacy Request | {raw "What would you like us to do?"
   answer, merged} | Privacy Request Due: {computed date}`, then `<hr>`.
2. **Requester & Subject** (always): full name, email, phone, alt phone, booking ref.
3. **Requester-type block**: omitted entirely for Customer; Transport Partner gets business
   type/trading name/company name/username; Authorised Third Party gets authorisation
   details/proof-of-authorisation/the no-acting-party-email flag.
4. **All 5 request-type blocks**, concatenated (SAR, Rectification, Deletion, Data Portability,
   Marketing Opt-Out), plus a small-print line telling the reader that only the block matching the
   headline's request type will have populated fields.
5. **Additional Information** + a Declaration line, always last.

Design matches Ant's original hand-built notification: Georgia serif, 24px bold headline, 18px
body text, `<hr>` section dividers.

## Build script
`workflow/build-formstack-notifications.py`: `--dry-run` prints every payload with no API calls;
`--apply` (with `FORMSTACK_TOKEN` set) PUTs the 3 known ids in place and DELETEs the 2 stray
request-type-specific notifications left over from the abandoned 15-variant attempt. It is
idempotent (PUT, full-payload replace against fixed ids) as long as the 3 ids in
`EXISTING_NOTIFICATION_IDS_TO_REUSE` stay correct; re-verify with
`GET /forms/6559077/notifications` (dedupe by id: the list endpoint echoes each one twice) before
re-running if the live ids might have changed.

The field ids/labels and the shared content blocks live in `workflow/formstack_dsr_content.py`,
shared with `workflow/build-formstack-confirmations.py` so the two audiences never drift apart on
field ids, even though their designs now differ in shape (3 vs 15 variants) because of the cap.

## Sources
`docs/dsr-go-live-readiness.md` (blocker #1) · `docs/dsr-confirmation-emails.md` (the confirmation
side, unaffected by the notification cap) · `docs/dsr-field-mapping.md` · `docs/conventions.md`
(the cap + confirmation payload shape, recorded there for future Formstack work) ·
`workflow/formstack_dsr_content.py` · `workflow/build-formstack-notifications.py`.
