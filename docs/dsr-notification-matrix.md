# DSR Formstack notifications — the 3x5 requester/request-type matrix

**INTERNAL — no customer PII.** How the "AnyVan UK - Privacy Requests" form (id `6559077`) actually
raises a Freshdesk ticket, and the 15-notification build that makes each ticket show only the
fields relevant to its own requester type and request type. Companion to
`docs/dsr-go-live-readiness.md` and `workflow/build-formstack-notifications.py` (the script that
builds this). Written 2026-09-24.

## This is a different mechanism from `workflow/`
Formstack has two separate kinds of outbound email, easy to conflate:
- **Notification** — an internal email, e.g. to `privacy@anyvan.com`. **This is what raises the
  Freshdesk ticket** — `privacy@anyvan.com` is a Freshdesk-connected mailbox, so an inbound email
  becomes a ticket via Freshdesk's email-to-ticket pipe. Subject → ticket subject, body → ticket
  description, `fromType:"field"` (the data subject's email field) → ticket requester.
- **Confirmation** — sent to the *form submitter* (customer/TP/third party) acknowledging receipt.
  **None exist yet** (`GET /forms/6559077/confirmations` → `{"confirmations":[]}`). This is the
  piece `docs/dsr-confirmation-emails.md` drafted copy for — still to be configured.

Ant built one notification by hand in the Formstack builder: **"Customer Privacy Request Email
[UK]"** (id `9711486`), gated on `197276069 == "A Customer"`, sent to `privacy@anyvan.com`. This
**is** blocker #1's "Freshdesk-event" trigger option from `docs/dsr-go-live-readiness.md` —
Formstack's own Email Output creates the ticket directly; no workflow-system involvement.

**Open question this raises for `workflow/`:** `workflow/config_prompt.md` +
`workflow/actions.json` build an *AI-workflow* path (`FORMSTACK_FORM_SUBMITTED` →
`FRESHDESK_TICKET_CREATE`) — the "Formstack-event" trigger option. If the notification-based path
above is now the live mechanism, the workflow-system build is either (a) redundant and can be
parked, or (b) still wanted as a second pass that *enriches* the ticket the notification already
created (per blocker #1's phrasing: "Freshdesk-event … workflow enriches"). **Ant to confirm which**
— this doc doesn't decide it, it just flags that today's notification work makes the choice live
rather than hypothetical.

## The matrix
The original Customer notification had **no request-type condition** — it fires for every Customer
submission regardless of `dsr_type`, and its body unconditionally includes every SAR-specific
section (Chat/Call/Email date ranges) even for a Deletion or Rectification request, because
Formstack merge fields don't support inline conditionals — an unanswered field just renders blank
inline ("Chat Transcripts From: to "), it doesn't disappear. The only way to keep a ticket scoped to
*its own* request type is one notification per **(requester type, request type)** combination, each
gated by two ANDed conditions and each body containing only that combination's blocks.

3 requester types x 5 request types = **15 notifications**:

| | SAR | Rectification | Deletion | Data Portability | Marketing Opt-Out |
|---|---|---|---|---|---|
| **Customer** | ✅ existing `9711486`, retargeted | new | new | new | new |
| **Transport Partner** | new | new | new | new | new |
| **Authorised Third Party** | new | new | new | new | new |

Each notification:
- **Logic** — `conditional: "all"`, two checks: `197276069` (requester type) equals its option,
  **and** `197276089` (request type) equals its option. This is the fix for the existing
  notification too — retargeting it to also require `dsr_type == "Subject Access Request"` so it
  no longer fires (duplicating the ticket) for e.g. a Customer Deletion request once the new
  Deletion notification exists.
- **Recipients** — `privacy@anyvan.com` (unchanged).
- **From** — `fromType: "field"`, `fromValue: "197276072"` (the data subject's email) — unchanged,
  and the same known gap as before: for an Authorised Third Party submission this is still the data
  subject's email, not the third party's own (no such field exists on the form; flagged inline in
  that block's body).
- **Body** — three parts, always in this order:
  1. **Requester & Subject** (always) — full name, email, phone, alt phone, booking ref.
  2. **Requester-type block** — omitted entirely for Customer; Transport Partner gets business
     type/trading name/company name/username; Authorised Third Party gets authorisation
     details/proof-of-authorisation/the no-acting-party-email flag.
  3. **Request-type block** — exactly one of: SAR (categories, all applicable date ranges, chat
     method, reason), Rectification (which data + correct info), Deletion (scopes), Data
     Portability (standard note), Marketing Opt-Out (standard note).
  Then **Additional Information** + a Declaration line, always last.

## Known residual limitation
Within the SAR block, the date-range/chat-method rows still render for every SAR ticket regardless
of which data categories (`197276090`) were actually ticked — Formstack has no inline "hide if
category X not ticked" for notification bodies. A field the requester left blank just prints blank
inline (e.g. "Chat Transcripts From: to "). Splitting further (SAR x category-combination) would
explode the matrix well past 15 notifications for diminishing value; the ticket-handling agent
reads the ticked-categories line first and treats blank date rows as "not applicable" rather than
"missing". Revisit only if this causes real triage confusion.

## Build script
`workflow/build-formstack-notifications.py` — `--dry-run` prints every payload with no API calls;
`--apply` (with `FORMSTACK_TOKEN` set) updates `9711486` in place and creates the other 14. Rerun
it any time the field ids or block content change — it's idempotent on the existing one (PUT,
full-payload replace) but **not** idempotent on the 14 new ones (each run's `--apply` creates them
again if run twice — check `GET /forms/6559077/notifications` first, or delete stragglers via
`DELETE /notifications/{id}` before re-running).

## Sources
`docs/dsr-go-live-readiness.md` (blocker #1) · `docs/dsr-confirmation-emails.md` (the separate,
not-yet-built confirmation side) · `docs/dsr-field-mapping.md` · `workflow/config_prompt.md` ·
`workflow/build-formstack-notifications.py`.
