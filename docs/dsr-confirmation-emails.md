# DSR confirmation emails — content for Formstack Email Output

**INTERNAL — no customer PII.** Ready-to-paste copy for the "AnyVan UK - Privacy Requests"
Formstack form (id `6559077`). Companion to `docs/dsr-field-mapping.md` (field ids) and
`docs/dsr-go-live-readiness.md` (blocker #2 — "Configure the Email Output"). This is the *content*;
configuring it live in the Formstack builder still needs a Formstack builder login + a freshly
rotated `FORMSTACK_TOKEN`/UI access, and is not done by this doc.

## Why three templates, not one
The confirmation email is the data subject's (or third party's) first contact-point acknowledgement
under **UK GDPR Art. 12(3)** — it must give a reference, state the statutory timeline, and give a
contact address. But the three requester types on the live form (`197276069`) need materially
different wording:
- **A Customer** — standard acknowledgement, clock starts on submission.
- **A Transport Partner** — same acknowledgement, but note we may verify against their TP account.
- **An Authorised Third Party** — must **not** promise the same clock start, because the request
  can't be actioned until we've checked the proof of authorisation (`197276086`); ICO guidance is
  that the one-month clock only starts once identity/authorisation is confirmed.

## Setup — preferred: three conditional confirmations
If the Formstack plan's Email Output supports **conditional logic on the confirmation/notification
email** (send a different confirmation based on an answer), configure three, each triggered on
`197276069` ("Are You……."):

| Confirmation | Condition |
|---|---|
| Template A — Customer | `197276069` is `A Customer` |
| Template B — Transport Partner | `197276069` is `A Transport Partner` |
| Template C — Authorised Third Party | `197276069` is `An Authorised Third Party` |

Build each subject/body by selecting the fields from Formstack's own "Insert Field" merge picker
in the email editor (don't hand-type field-id merge syntax — the picker inserts whatever tag format
that Formstack account uses). The picker fields you need: **Full name** (`197276071`), **What would
you like us to do?** (`197276089`), and Formstack's built-in **Submission ID** / **Unique ID**
merge variable (also from the picker, not a form field).

## Setup — fallback: one confirmation, conditional text block
If the plan only allows a single confirmation email, use **Template A** as the base and manually
toggle in the bracketed `[if Transport Partner: …]` / `[if Third Party: …]` paragraph from Templates
B/C in place of the marked line, matching whichever requester types the form is live for at the
time. Not ideal (it's a manual toggle per go-live, not automatic per submission) — prefer the
conditional setup above if it's available.

---

## Template A — Customer

**Subject:** Your AnyVan Privacy Request — Reference DSR-{{Submission ID}}

> Dear {{Full name}},
>
> Thank you for contacting AnyVan about your personal data.
>
> We've received your **{{What would you like us to do?}}** request and logged it under reference
> **DSR-{{Submission ID}}**. Please quote this reference in any further correspondence.
>
> Under UK GDPR, we aim to respond within **one calendar month** of receiving your request. If your
> request is complex, or you've raised more than one, we may need to extend this by a further two
> months — we'll tell you if that happens and explain why.
>
> We may contact you to verify your identity, or to ask for more detail, before we can act on your
> request.
>
> If you have any questions in the meantime, email us at **privacy@anyvan.com** and quote your
> reference number.
>
> Kind regards,
> AnyVan Privacy Team

## Template B — Transport Partner

**Subject:** Your AnyVan Privacy Request — Reference DSR-{{Submission ID}}

> Dear {{Full name}},
>
> Thank you for contacting AnyVan about your personal data as one of our Transport Partners.
>
> We've received your **{{What would you like us to do?}}** request and logged it under reference
> **DSR-{{Submission ID}}**. Please quote this reference in any further correspondence.
>
> Under UK GDPR, we aim to respond within **one calendar month** of receiving your request. If your
> request is complex, or you've raised more than one, we may need to extend this by a further two
> months — we'll tell you if that happens and explain why.
>
> We may need to verify your identity against your AnyVan Transport Partner account before we can
> act on your request, and may contact you via your registered TP details to do so.
>
> If you have any questions in the meantime, email us at **privacy@anyvan.com** and quote your
> reference number.
>
> Kind regards,
> AnyVan Privacy Team

## Template C — Authorised Third Party

**Subject:** Your AnyVan Privacy Request on Behalf of Another Person — Reference DSR-{{Submission ID}}

> Dear {{Full name}},
>
> Thank you for contacting AnyVan on behalf of another person about their personal data.
>
> We've received your **{{What would you like us to do?}}** request, submitted on behalf of the
> data subject named in your request, and logged it under reference **DSR-{{Submission ID}}**.
> Please quote this reference in any further correspondence.
>
> Before we can proceed, we need to check that you're authorised to act on the data subject's
> behalf. We'll review the proof of authorisation you provided and may contact you and/or the data
> subject directly to confirm this. **The one-calendar-month statutory response period does not
> start until we've confirmed your authorisation** — we'll write to confirm once it has been
> verified, or let you know if we need more information first.
>
> If you have any questions in the meantime, email us at **privacy@anyvan.com** and quote your
> reference number.
>
> Kind regards,
> AnyVan Privacy Team

---

## Notes
- These are acknowledgement emails only — they never confirm identity, release data, or state a
  calculated due date (Formstack can't replicate the weekend/bank-holiday roll-forward the
  workflow computes for `cf_privacy_due_date`; "one calendar month" is the correct statutory
  wording to give the requester, the exact date lives on the Freshdesk ticket for staff).
- `{{Submission ID}}` must match the same value the workflow uses for `DSR-<submission id>` in the
  Freshdesk ticket subject (`workflow/config_prompt.md`), so the requester's reference and the
  ticket's reference are the same number.
- Once configured, add a Formstack test submission per requester type to `docs/dsr-go-live-readiness.md`
  blocker #2's evidence and flip it to done.

## Sources
`docs/dsr-field-mapping.md` · `docs/dsr-go-live-readiness.md` · `docs/go-live-guide.md` (Stage 2) ·
`workflow/config_prompt.md`.
