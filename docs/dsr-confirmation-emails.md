# DSR confirmation emails: the requester-facing matrix

**INTERNAL (no customer PII).** The acknowledgement email sent to the *requester* (customer / TP /
authorised third party) on the "AnyVan UK - Privacy Requests" Formstack form (id `6559077`), as
opposed to the internal notification that raises the Freshdesk ticket (`docs/dsr-notification-matrix.md`).
**Live as of 2026-09-25** (all 15 created). Companion to `docs/dsr-go-live-readiness.md` (blocker #2)
and `workflow/build-formstack-confirmations.py` (generates all 15 from
`workflow/formstack_dsr_content.py`).

## The matrix
Same two axes, both mutually-exclusive radios on the live form: 3 requester types x 5 request
types = **15 confirmations**. Unlike notifications (capped at 5 per form on this plan; see
`docs/dsr-notification-matrix.md`), confirmations have no such cap (16 created in testing with no
error), so this matrix stays fully granular.

| | SAR | Rectification | Deletion | Data Portability | Marketing Opt-Out |
|---|---|---|---|---|---|
| **Customer** | `3186402` | `3186403` | `3186404` | `3186405` | `3186406` |
| **Transport Partner** | `3186407` | `3186408` | `3186409` | `3186410` | `3186411` |
| **Authorised Third Party** | `3186412` | `3186413` | `3186414` | `3186415` | `3186416` |

Each cell is generated from shared pieces (`workflow/formstack_dsr_content.py`):
- **Headline + opening line** (by requester type only, `CONFIRMATION_HEADLINE` +
  `REQUESTER_CONFIRMATION_OPENING`).
- **Reference + timeline** (`CONFIRMATION_REQUEST_LINE` + `CONFIRMATION_TIMELINE_LINE`) merges in
  the raw "What would you like us to do?" answer rather than picking a per-request-type paragraph
  (see "Why one generic line" below).
- **Verification paragraph** (by requester type only, omitted entirely for Customer,
  `REQUESTER_CONFIRMATION_VERIFICATION`).
- **Footer small print** (same on all 15, `CONFIRMATION_FOOTER_SMALL_PRINT`): "Our business days
  are Monday to Friday." Confirmed by Ant 2026-09-25, added mainly to support the Marketing
  Opt-Out "5 working days" line but stated on every variant for consistency.

Logic gates each on `conditional: "all"`: `197276069` (requester type) equals its option **and**
`197276089` (request type) equals its option, exactly like the notifications.

## Design
Georgia serif, 24px bold headline, 18px body, `<hr>` section dividers, matching the notifications
and Ant's original hand-built example. 12px footer small print.

## Why one generic reference/timeline line, not five
The request-type detail is a single merged sentence ("We've received your request (`{request-type
answer}`) and logged it...") rather than five separate per-type paragraphs. Two reasons:
1. **Consistency with the notification redesign.** Once the request-type axis had to collapse to
   "blank if not applicable" for notifications (forced by the 5-email cap), giving confirmations
   five fully bespoke per-type paragraphs while notifications don't have the equivalent detail
   would create an odd asymmetry, and the generic line already reads correctly for any of the 5
   options via the raw merge.
2. **SAR's own sub-categories still don't split further.** "Call recording", "chat transcript",
   "email correspondence" etc. are options inside one **checkbox** field (`197276090`), not a
   radio; a requester can tick several at once. Splitting on that axis too would need up to 2⁶=64
   variants per requester type, and Formstack's conditional logic can't express "contains one of"
   cleanly anyway. A generic confirmation avoids ever needing to try.

The one exception: the Marketing Opt-Out timeline (5 working days, 30-day statutory caveat) is
folded into the single `CONFIRMATION_TIMELINE_LINE` as an "if you asked for X" clause, so it reads
correctly whether or not that's what was actually requested.

## Payload shape (confirmed live 2026-09-25)
`POST /forms/{id}/confirmations`: `{name, subject, message, format, toField, senderEmail, logic}`.
`toField` is the recipient field id (`197276072`, the data subject's Email Address); `senderEmail`
is the visible From address (`privacy@anyvan.com`). Both required; discovered by adding one field
at a time against successive 400s naming the missing key. See `docs/conventions.md` for the fuller
API note, including the list-endpoint duplicate-echo quirk (each of the 15 appears twice in
`GET /forms/6559077/confirmations`, 30 rows, 15 distinct ids; dedupe by id).

## Notes
- These are acknowledgement emails only: never confirm identity, never release data, never state a
  calculated due date (Formstack can't replicate the weekend/bank-holiday roll-forward the workflow
  computes for `cf_privacy_due_date`; "one calendar month" is the correct statutory wording for the
  requester, and the exact computed date lives on the Freshdesk ticket for staff).
- `{$_submission_id}` in the subject matches the same value used for `DSR-<submission id>` in the
  Freshdesk ticket subject, so the requester's reference and the ticket's reference are the same
  number.
- Test one submission per requester type x request type and confirm the right confirmation fires
  with the right content, then flip `docs/dsr-go-live-readiness.md` blocker #2 to done.

## Sources
`docs/dsr-field-mapping.md` · `docs/dsr-go-live-readiness.md` · `docs/dsr-notification-matrix.md` ·
`docs/conventions.md` · `workflow/formstack_dsr_content.py` ·
`workflow/build-formstack-confirmations.py`.
