# DSR form copy (welcome + submission messages)

> **INTERNAL** — no customer data. The customer-facing copy for the UK DSR intake form
> (Formstack form `6559077`). Source of truth for the wording; keep this and the live form in
> step. **House style: no em dashes in any customer-facing copy.**
>
> Placeholders: `{reference}` = Formstack submission-ID merge field prefixed with `DSR-UK-`
> (so it matches the ticket subject the workflow builds). `[WhatsApp link]` = the Privacy team's
> WhatsApp contact link.

## Welcome message (top of form)

> **AnyVan — Data Privacy Request**
> Use this form to exercise your data protection rights, for example to access, correct, or delete
> your data. Our Privacy team will respond within **one calendar month**, and may first need to
> verify your identity.
>
> **This form is for data protection requests only.** The Privacy team does not handle bookings,
> quotes, moves, payments, or general enquiries.
> • **To unsubscribe from AnyVan marketing emails** you do not need us: just click **Unsubscribe**
>   at the bottom of any AnyVan email, or update your preferences in your account.
> • **For anything else**, please message us on WhatsApp: **[WhatsApp link]**

## Submission messages (shown after submit, by requester type)

### Customer
> Thank you. We've received your privacy request, and a confirmation email is on its way to the
> address you provided. Your reference is **DSR-UK-{reference}**. Please quote it in any
> correspondence.
>
> We'll respond within one calendar month. To keep your information safe, we may need to verify
> your identity before we release or change any data.
>
> Our Privacy team handles data protection requests only. For anything else, please message us on
> WhatsApp: **[WhatsApp link]**.

### Transport Partner
> Thank you. We've received your privacy request, and a confirmation email is on its way to the
> address you provided. Your reference is **DSR-UK-{reference}**. Please quote it in any
> correspondence.
>
> We'll respond within one calendar month. To keep your information safe, we may first need to
> verify your identity and your Transport Partner account before we release or change any data.
>
> Our Privacy team handles data protection requests only. For Transport Partner account, payments
> or allocation matters, please use your usual TP support channels, or message us on WhatsApp:
> **[WhatsApp link]**.

### Authorised Third Party
> Thank you. We've received your submission, and a confirmation email is on its way to the address
> you provided. Your reference is **DSR-UK-{reference}**. Please quote it in any correspondence.
>
> We'll respond within one calendar month. As you're acting on someone else's behalf, we'll first
> verify the data subject's identity and your authority to act, using the details and document you
> provided, before we release or change any data.
>
> Our Privacy team handles data protection requests only. For anything else, please message us on
> WhatsApp: **[WhatsApp link]**.

## Data Portability — optional field (shown when request = Data Portability)

> **Which data would you like provided, and in what format?** (optional)
> We provide portable data in CSV or JSON. Portability covers data you gave us that we process by
> automated means, and we'll confirm what's in scope.

## Notes
- The Welcome message deflects marketing opt-outs to self-serve (email footer Unsubscribe) and all
  non-privacy queries to WhatsApp, so the Privacy queue stays scoped to privacy work.
- Keep `{reference}` as the same submission-ID merge field the workflow keys on, so the number the
  requester sees matches the Freshdesk ticket subject (`DSR-UK-<id> — <dsr_type> (<requester_type>)`).
