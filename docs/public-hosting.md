# Public / customer-facing hosting (later phase)

The form is deployed today on **AV Dashboards** (`operations/dsr-intake-form`), which
hard-enforces `@anyvan.com` Google OAuth on every page. That makes the current
deployment **internal only** — staff can open it, customers and Transport Partners
cannot. It is therefore suitable for the privacy/CS team to log requests, but not for a
requester to fill in directly.

A customer-facing deployment is **net-new infrastructure**. There is no existing AnyVan
IaC (no Terraform/CloudFormation/SAM in the estate) and no `privacy.anyvan.com` to reuse.
The only public-static precedent found is the `assets.anyvan.com` CDN (used for one
public unauthenticated page). Two options:

## Option A — S3 + CloudFront (recommended for a real public form)

- Static `dsr-intake-form.html` on a private S3 bucket, served via CloudFront (OAC).
- Custom domain e.g. `privacy.anyvan.com` (ACM cert + Route 53).
- Remove the `AVDashboard.ensureAuthenticated()` call and the `INTERNAL TEST MODE` banner
  from the page for the public build.
- Set `CONFIG.API_ENDPOINT` to the API Gateway URL from the backend (see the runbook).
- Lock the backend's `ALLOWED_ORIGIN` to the public domain (not `*`).
- Consider a bot/abuse control on the public endpoint (e.g. CAPTCHA or WAF rate-limiting)
  since it will be unauthenticated and accepts file uploads.

This is an infra/eng task (new IaC + DNS + AWS). It can be added as a second SAM/CDK stack
alongside `backend/template.yaml`.

## Option B — publish under `assets.anyvan.com`

Lighter-weight: publish the static build under the existing public CDN path pattern. Same
form/endpoint changes as Option A, but reuses the existing public-asset mechanism instead
of standing up a new distribution. Fewer moving parts; less control over the domain.

## Identity verification note

Whichever hosting is chosen, the DSR process still requires **identity verification before
data is released** (the form's declaration already states this). A public form lowers the
barrier to submission, so make sure the downstream Freshdesk/verification workflow is ready
for higher volume before opening it to customers.
