# Hosting the DSR form for customers & admins

## Decision: Formstack (single form, both audiences)

The DSR form goes live as **one Formstack form** serving both UK customers (public) and staff
(internal), feeding the workflow-system → Freshdesk. See `docs/formstack-dsr-build.md` (build)
and `docs/formstack-to-freshdesk-workflow.md` (wiring).

**Why Formstack rather than self-hosting:**
- It's a paved road here — a live **"Damage Claim - UK - Formstack"** workflow already does
  Formstack-submit → workflow-system → Freshdesk, and the workflow-system has native Formstack
  read/vision tools.
- It offloads the parts of a **public, unauthenticated PII form** that are otherwise net-new
  and risky: hosting, SSL, spam/bot protection, accessibility, file handling, and GDPR posture.
- Formstack is **already an approved processor for UK customer PII** (DPA + EU/UK residency), so
  there's no procurement gate — only correct configuration (data region, retention, spam).
- The AV Dashboards platform can't serve customers anyway (it hard-enforces `@anyvan.com`
  Google login), and Freshdesk's native customer portal/forms aren't used anywhere at AnyVan.

## Entry points
- **Customers:** the Formstack hosted public URL (linked from the privacy policy / a
  `anyvan.com/privacy` page, or embedded). No login.
- **Staff:** the same form linked from `/administer`, with hidden `?source=admin&agent=<id>`
  prefill so we capture who logged a staff-entered request. One form, one source of truth.

## Alternative considered and NOT chosen: self-hosted (S3 + CloudFront)
Kept for the record. A static build of `dsr-intake-form.html` on S3 behind CloudFront at
`privacy.anyvan.com` (ACM + Route 53), stripping `AVDashboard.ensureAuthenticated()` and the
test banner, wiring `CONFIG.API_ENDPOINT` to a self-hosted Lambda backend, and adding
WAF/CAPTCHA. Rejected because it makes AnyVan own an unauthenticated PII surface with **no
existing IaC and no WAF/CAPTCHA precedent** — more net-new security to build and maintain than
Formstack, for no offsetting benefit now that Formstack is approved for this data. (The
reference Lambda that would have backed this has since been **removed from the repo**.)

## Interim state
The bugfixed custom form stays live internally on AV Dashboards (`operations/dsr-intake-form`)
as the staff tool until the Formstack form is live and adopted, then it's retired (or kept as
an internal fallback). The reference `backend/` Lambda that this alternative would have used has
been **removed from the repo** — the workflow-system path supersedes it.

## Identity verification (unchanged, both channels)
DSRs still require identity verification **before data is released** (the form's declaration
already states this). A public form lowers the barrier to submission, so make sure the
downstream Freshdesk/verification workflow is resourced for higher volume before opening it up.
