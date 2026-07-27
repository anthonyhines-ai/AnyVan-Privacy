# Building the DSR form in Formstack

Recreates the DSR intake form (`dsr-intake-form.html` / `docs/dsr-intake-form-handoff.md`) as a
single Formstack form serving **both** UK customers (public) and staff (internal). One form =
one source of truth for the DSR question logic. Feeds the workflow in `workflow/`.

**Fastest path — run the build script** (creates the form + fields + conditional logic via the
Formstack API and prints the field-id map):
```bash
FORMSTACK_TOKEN=<oauth token> node workflow/build-formstack-form.js   # --dry-run to preview
```
Then finish the builder-only bits below (page breaks, region/retention/reCAPTCHA, theme,
confirmation email). The rest of this doc is the field-by-field spec the script implements — use
it to build by hand instead, or to review/adjust what the script created.

Do this in the Formstack account (needs a Formstack builder login). Record each field's numeric
id in `docs/dsr-field-mapping.md` (the script prints them).

## Pages (mirror the 4 steps)
1. **Requester Type** — single choice: Customer / Transport Partner / Authorised Third Party.
2. **Your Details** — common + type-specific fields (conditional, below).
3. **Your Request** — request type + its detail panels (conditional, below).
4. **Review & Declaration** — Formstack review + the declaration checkbox (required).

## Fields & conditional logic
Use Formstack **Conditional Logic** to show/hide by the Requester Type (page 1) and Request
Type (page 3) selections.

**Common (all requester types), page 2:** Full Name (required), Email (required), Phone
(required), Alternative Phone (optional), AnyVan Booking Reference (optional, placeholder
`AV1234567`).

**Customer:** Account-holder confirmation checkbox (required).

**Transport Partner:** Business Type (required: Sole Trader / Limited Company or Partnership);
if Sole Trader → Trading Name (optional); if Limited → Registered Company / Partnership Name
(required); Transport Partner Username (optional); account-holder confirmation checkbox
(required, wording per business type — see handoff §Step 2).

**Authorised Third Party:** Authorisation Details (required, long text); Proof of Authorisation
**file upload** (required, ≥1 file; accept PDF/JPG/PNG; set the size cap to 10MB/file).

**Request type (page 3, single choice, required):** Access My Data (SAR) / Delete My Data /
Correct My Data / Marketing Opt-Out / Data Portability. Then, conditionally:
- **SAR →** data-category checkboxes (booking, call recordings, chat transcripts, email,
  payment, **all personal data held**). Sub-panels:
  - Call recordings → per-call **date + approx time** (phone optional). Formstack repeatable
    sections are limited — see the repeatable note below.
  - Chat transcripts → date range + channel (WhatsApp / Live Chat / Both).
  - All personal data held → date range (required) + written reason (required, ≥20 chars) +
    the amber "this takes longer / be specific" guidance.
  - Enforce that "all personal data held" is mutually exclusive with the specific categories.
- **Delete →** deletion-scope checkboxes + the red legal-retention note.
- **Correct →** field checkboxes + required "correct information" long text.
- **Marketing Opt-Out →** green confirmation note.
- **Data Portability →** blue info note.
- All types: optional Additional Information long text.

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
