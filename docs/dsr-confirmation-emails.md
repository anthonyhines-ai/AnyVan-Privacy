# DSR confirmation emails — the requester-facing matrix

**INTERNAL — no customer PII.** The acknowledgement email sent to the *requester* (customer / TP /
authorised third party) on the "AnyVan UK - Privacy Requests" Formstack form (id `6559077`) — as
opposed to the internal notification that raises the Freshdesk ticket (`docs/dsr-notification-matrix.md`).
Companion to `docs/dsr-go-live-readiness.md` (blocker #2) and `workflow/build-formstack-confirmations.py`
(generates all 15 from `workflow/formstack_dsr_content.py`). Rewritten 2026-09-25 — supersedes the
earlier 3-template version (this repo's git history has that version if you need it).

## The matrix
Same two axes as the notification matrix, both mutually-exclusive radios on the live form: 3
requester types x 5 request types = **15 confirmations**.

| | SAR | Rectification | Deletion | Data Portability | Marketing Opt-Out |
|---|---|---|---|---|---|
| **Customer** | new | new | new | new | new |
| **Transport Partner** | new | new | new | new | new |
| **Authorised Third Party** | new | new | new | new | new |

Each cell is generated from three independent pieces (`workflow/formstack_dsr_content.py`), so
requester-type framing and request-type framing never have to be re-written 15 times by hand:
- **Opening line** — by requester type only (`REQUESTER_CONFIRMATION_OPENING`).
- **Reference + what we understood the request to be** — by request type only
  (`REQUEST_TYPE_CONFIRMATION_LINE` + `REQUEST_TYPE_TIMELINE_LINE`).
- **Verification paragraph** — by requester type only, omitted entirely for Customer
  (`REQUESTER_CONFIRMATION_VERIFICATION`).

## Why SAR isn't split further by data category
"Call recording", "chat transcript", "email correspondence" etc. are options inside one **checkbox**
field (`197276090`), not a radio — a requester can tick several at once. Splitting SAR into a
template per category (or combination) would need up to 2⁶=64 variants per requester type, and
Formstack's conditional logic can't express "contains one of" cleanly anyway (only exact-match
checks). Instead, the single SAR confirmation **merges in whichever categories were actually
ticked** — `{$197276090 What data would you like to access?}` renders as plain text wherever it's
inserted, so a call-recording request and a chat-transcript request read differently from the same
one template without needing to be separate templates.

## Open decision — Marketing Opt-Out timeline
The `marketing` cell currently commits to **5 working days** (statutory backstop: one calendar
month) — a placeholder judgement call, not a decided SLA. Opt-outs are typically actioned far
faster than a subject-access-style request in most teams' processes; a flat one-month promise on
an opt-out probably undersells what actually happens. **Ant to confirm or override** the 5-working-day
figure in `workflow/formstack_dsr_content.py`'s `REQUEST_TYPE_TIMELINE_LINE["marketing"]` before this
goes live — deliberately kept as clean, shippable copy in that file (no bracketed editorial notes
inside a string that gets POSTed straight into a live email).

## Setup — conditional confirmations
Each of the 15 is gated the same way as its notification counterpart: `conditional: "all"`, two
checks — `197276069` (requester type) equals its option **and** `197276089` (request type) equals
its option. If the Formstack plan doesn't support 15 separate confirmations, fall back to one
combined template with the request-type line as the only variable part (lower fidelity, but still
better than a single generic ack).

## ⚠️ Unverified: the confirmation API payload shape
No confirmation has ever existed on this form (`GET /forms/6559077/confirmations` → `{"confirmations":[]}`,
checked live 2026-09-24/25) — unlike notifications, which had one live example to confirm the
shape against. `workflow/build-formstack-confirmations.py`'s payload is a best-effort mirror of the
confirmed notification shape, minus notification-only fields (`fromType`/`fromValue`/`recipients` —
a confirmation goes to whoever submitted the form, not a fixed address). **Before running it for all
15**, create one with `--apply --only customer:sar`, then re-list `/forms/6559077/confirmations` to
see what Formstack actually stored, and fold any correction into `docs/conventions.md` (the same way
the notification-endpoint quirks were recorded) and into the script.

## Notes
- These are acknowledgement emails only — never confirm identity, never release data, never state a
  calculated due date (Formstack can't replicate the weekend/bank-holiday roll-forward the workflow
  computes for `cf_privacy_due_date` — "one calendar month" is the correct statutory wording for the
  requester; the exact computed date lives on the Freshdesk ticket for staff).
- `{$_submission_id}` in the subject must match the same value used for `DSR-<submission id>` in the
  Freshdesk ticket subject, so the requester's reference and the ticket's reference are the same
  number — confirmed as the correct live merge token from the existing notification's subject line.
- Once configured, add a Formstack test submission per requester type x request type to
  `docs/dsr-go-live-readiness.md` blocker #2's evidence and flip it to done.

## Sources
`docs/dsr-field-mapping.md` · `docs/dsr-go-live-readiness.md` · `docs/dsr-notification-matrix.md` ·
`docs/go-live-guide.md` (Stage 2) · `workflow/config_prompt.md` · `workflow/formstack_dsr_content.py` ·
`workflow/build-formstack-confirmations.py`.
