# Building the DSR form in Formstack

Recreates the DSR intake form (`dsr-intake-form.html` / `docs/dsr-intake-form-handoff.md`) as a
single Formstack form serving **both** UK customers (public) and staff (internal), **aligned to
AnyVan's official DSRR template** (`AnyVan_DSRR_Form.docx`). One form = one source of truth for
the DSR question logic. Feeds the workflow in `workflow/`.

**Fastest path — run the build script** (creates the form + fields + conditional logic via the
Formstack API and prints the field-id map):
```bash
FORMSTACK_TOKEN=<fs_pat_...> node workflow/build-formstack-form.js   # --dry-run to preview
```

**Already have the live form (6559077)?** Apply the template-alignment additions without
recreating it — the additive updater adds only the new fields and refreshes the request-type
options:
```bash
node workflow/build-formstack-form.js --form 6559077 --dry-run       # preview the additions
FORMSTACK_TOKEN=<fs_pat_...> node workflow/build-formstack-form.js --form 6559077
```
New fields are appended, so afterwards drag them into place in the builder (Identity Verification
after the data-subject details; the Third Party block by the authorisation fields; each rights
note inside the request panel) and record their ids in `docs/dsr-field-mapping.md`.

Then finish the builder-only bits below (page breaks, region/retention/reCAPTCHA, theme,
confirmation email). The rest of this doc is the field-by-field spec the script implements — use
it to build by hand instead, or to review/adjust what the script created.

Do this in the Formstack account (needs a Formstack builder login). Record each field's numeric
id in `docs/dsr-field-mapping.md` (the script prints them).

## Intro (top of the form)
A rich-text **about-this-form** note stating that this is AnyVan's Data Subject Rights Request
form, that requests are handled by the **Data Protection Manager (privacy@anyvan.com)** within
**one calendar month**, that identity is verified before any data is released or changed, and
that any documents must be **copies only — never originals** (mirrors the template's "About this
Form").

## Pages (mirror the 4 steps)
1. **Requester Type** — single choice: Customer / Transport Partner / Authorised Third Party.
2. **Your Details** — common + type-specific fields, Identity Verification, Third Party block
   (all conditional, below).
3. **Your Request** — request type + its detail panels (conditional, below).
4. **Review & Declaration** — Formstack review + typed-signature name + the declaration checkbox
   (required).

## Fields & conditional logic
Use Formstack **Conditional Logic** to show/hide by the Requester Type (page 1) and Request
Type (page 3) selections.

**Common (all requester types), page 2 — the data subject's details:** Title (optional), Full
Name (required), Email (required), Phone (required), Alternative Phone (optional), **Postal
Address (optional)**, AnyVan Booking Reference (optional, placeholder `AV1234567`). If the
requester is acting for someone else, these are the *data subject's* details; the acting party's
own details go in the Third Party block.

**Identity Verification (Customer + Transport Partner):** a section with the "copies only, never
originals, don't include full card numbers" guidance, an optional **free-text** ("information to
help us verify your identity") and an optional **ID document upload** (copy only; PDF/JPG/PNG).
Mirrors the template's Identity Verification section.

**Customer:** Account-holder confirmation checkbox (required).

**Transport Partner:** Business Type (required: Sole Trader / Limited Company or Partnership);
if Sole Trader → Trading Name (optional); if Limited → Registered Company / Partnership Name
(required); Transport Partner Username (optional); account-holder confirmation checkbox
(required, wording per business type — see handoff §Step 2).

**Authorised Third Party:** a Third Party section capturing the acting party's **own** details —
Your Full Name (required), Your Email (required), Your Phone (optional) — plus Authorisation
Details (required, long text) and Proof of Authorisation **file upload** (required, copy only,
≥1 file; accept PDF/JPG/PNG; set the size cap to 10MB/file). Keeping the acting party's contact
details distinct from the data subject's mirrors the template.

**Request type (page 3, single choice, required)** — all **8 statutory rights + Marketing
Opt-Out**: Access My Data (SAR) / Correct My Data / Delete My Data / Restrict Processing / Data
Portability / Object to Processing / Automated Decision-Making / Withdraw Consent / Marketing
Opt-Out. Then, conditionally:
- **SAR →** data-category checkboxes (booking, call recordings, chat transcripts, email,
  **all personal data held**). Sub-panels:
  - Call recordings → date range (from/to). Formstack repeatable sections are limited — see the
    repeatable note below.
  - Chat transcripts → date range + channel (WhatsApp / Live Chat / Both).
  - All personal data held → date range (required) + written reason (required) + the amber
    "this takes longer / be specific" guidance.
  - Enforce that "all personal data held" is mutually exclusive with the specific categories.
- **Correct →** field checkboxes + required "correct information" long text.
- **Delete →** deletion-scope checkboxes + the red legal-retention note.
- **Restrict / Object / Automated Decision-Making / Withdraw Consent →** a short guidance note
  each, directing the requester to give specifics in the shared **Additional information** box
  (matches the template, which uses one "Additional information related to your request" field).
- **Data Portability →** blue info note.
- **Marketing Opt-Out →** green confirmation note.
- All types: optional **Additional information related to your request** long text.

## Declaration
Typed **Full name (acts as your signature)** (required) + a single declaration checkbox
(required) worded to cover both cases — "I am the data subject named above, or a third party
duly authorised to act on their behalf" — with the identity/authority-verification and
one-calendar-month acknowledgement. The submission timestamp is the date. (The template splits
this into two signed variants; a single combined online attestation is equivalent. Split it into
two conditional checkboxes by requester type if you prefer an exact match.)

## Repeatable call entries (validate)
Formstack's repeatable-section support varies by plan. Pick one and note the decision in the
mapping doc: (a) a repeatable section of {date, time, phone} if the plan supports it;
(b) a fixed set of N call rows shown progressively; or (c) a single structured long-text field
("one call per line: date, time, number"). The workflow reads whatever is submitted.

## Two entry points, one form
- **Customers:** the Formstack **hosted public URL** (link it from the privacy policy / a
  `anyvan.com/privacy` page, or embed it). This is the public channel — no `@anyvan.com` login.
- **Staff:** the **same form**, linked from the `/administer` console, with **hidden/prefill
  URL params** `?source=admin&agent=<adminId>` (add hidden fields "source" and "agent" and map
  them from the query string). The workflow records who logged it. No second form to maintain.

## Configuration (Formstack is already an approved UK-PII processor — just configure it)
- **Data region:** set the form/account to the **EU/UK** data centre.
- **Retention:** set Formstack submission retention to the DSR policy's minimum — Freshdesk is
  the record of truth; don't let PII accumulate in Formstack.
- **Spam/bot:** enable Formstack's built-in reCAPTCHA on the public form.
- **Theme:** apply AnyVan branding; run an accessibility (WCAG 2.2 AA) pass on the theme.
- **Confirmation:** enable a submitter confirmation email stating the reference
  (`DSR-<submission id>`) and the one-calendar-month timeline; set the on-screen confirmation
  message likewise.
- **ICO framing:** keep the "friction-by-design" copy as *helping us locate your data*, not as
  a deterrent to exercising rights. For the public channel, lean towards lighter friction than
  the internal tool — a regulator will scrutinise anything that looks like a barrier.

## After building
Record every `field_<NNN>` id in `docs/dsr-field-mapping.md`, then wire the workflow
(`docs/formstack-to-freshdesk-workflow.md`).
