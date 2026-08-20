# Secure delivery of customer call recordings — options appraisal (WeTransfer alternatives)

> ℹ️ **INTERNAL — COMMERCIAL IN CONFIDENCE. Contains no customer personal data.**
> This is a process/vendor options appraisal to inform a decision on how AnyVan delivers
> phone call recordings to customers. It holds **no customer PII** — only tooling analysis.
> Pricing and third-party feature claims are from desk research (dates below) and are
> **indicative**; confirm current figures/terms and clear any chosen tool with the DPO before
> adoption. Note that anything committed here persists in git history.

| | |
|---|---|
| **Record type** | Options appraisal / vendor evaluation |
| **Date created** | 2026-08-20 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Data source** | Desk research (web, Aug 2026) + `AnyVan-Privacy` repo context |
| **Subject** | Secure storage & delivery of customer phone call recordings (SAR/DSAR & customer requests) |
| **Status** | Draft for review — no decision taken |

---

## 1. Context & the problem to solve

When AnyVan provides customers with large files — typically **phone call recordings**, usually in
response to a customer request or a **Subject Access Request (SAR/DSAR)** under UK GDPR — we currently
send them via the **free tier of WeTransfer**. It is free and gives the customer a **3-day** window to
download.

Ant asked us to explore whether better alternatives exist for **secure storage and delivery**, ideally
giving customers a **longer / configurable access window** than three days.

Desk research surfaced **three material problems** with the status quo for personal-data delivery:

1. **No Data Processing Agreement (Art. 28) on the free tier.** We are routing customers' own personal
   data — recordings can contain payment details or vulnerability/health disclosures (potentially
   **special-category** data) — through a processor with **no DPA in place**. This is the single biggest
   gap: a DPA is a legal requirement where a processor handles personal data on our behalf.
2. **The 3-day window is fixed** — not configurable, not extendable, and **not revocable**. It is
   simultaneously *too short* for some customers to action in time, and offers *no ability to pull a link
   back* if something is sent in error.
3. **Trust, capacity & audit gaps.** WeTransfer is now owned by Bending Spoons and had a **July-2025
   controversy** over broad AI/content-licence terms (since rolled back). The free tier is capped at
   **~3 GB / 10 transfers per rolling 30 days**, and provides only a **download-notification email**, not
   a proper audit trail for accountability.

**Scope note:** AnyVan is **Google Workspace only** (no Microsoft 365), so the "already-owned" analysis
below centres on Google. This paper is an appraisal to inform a decision — **no change should be made to
any live process until a direction is chosen with the DPO.**

---

## 2. What "good" looks like — evaluation criteria (UK GDPR / ICO)

Call recordings are **clearly personal data**. When sending them to a customer via a file link, the ICO's
SAR and encryption guidance points to the following controls. These are the criteria used to score the
options in §5.

| # | Criterion | Why it matters |
|---|---|---|
| 1 | **Encryption in transit *and* at rest** (ideally **end-to-end**) | Protects the file if intercepted or if the host is compromised. |
| 2 | **Password / access code, sent via a *separate* channel** | ICO SAR advice: send *"a password-protected file with the password sent to the person in a separate email"*, or *"an encrypted format and send a secure code to access the encrypted information separately."* A bare "anyone-with-the-link" URL is weak. |
| 3 | **Recipient verification** | Sending a SAR response to the wrong person is itself a personal-data breach. ICO: *"double- or triple-check the person's address before you send it."* |
| 4 | **Configurable expiry + revocation** | Supports **storage limitation** and limits exposure; lets us set a window that suits the customer and pull it back if needed. |
| 5 | **UK / EU data residency** | Keep data in-region, or have a documented transfer mechanism/SCCs. |
| 6 | **Data Processing Agreement (Art. 28)** | Legally required where a processor handles our customers' personal data. |
| 7 | **Audit trail** | Evidence of what was sent, to whom, when, and when accessed — accountability. |
| 8 | **Data minimisation & retention** | Send only the specific recording(s) requested; shortest workable expiry; delete after collection. |

> ⚠️ The ICO wording above is quoted from the ICO's SAR-advice and encryption-guidance pages as surfaced
> in research; the ICO site blocks automated fetching, so **confirm the exact wording on the live ICO
> pages** (links in §9) before quoting in any formal internal paper or customer-facing process.

---

## 3. Current tool assessment — WeTransfer

| Attribute | WeTransfer **Free** (current) | WeTransfer **Starter** (~$8/mo) | WeTransfer **Ultimate** (~$23/mo) |
|---|---|---|---|
| Volume | 3 GB **total** / 10 transfers per 30 days | 300 GB / 30 days (10-transfer cap) | Unlimited transfers, up to **1 TB** each |
| **Access window** | **Fixed 3 days**, no config, no revoke | **Still 3 days** | **Custom / unlimited** + recovery |
| Password on link | Yes (now all tiers) | Yes | Yes + **Access Control** |
| Encryption | TLS in transit + AES-256 at rest; **not E2E**; EU (AWS Ireland) | same | same |
| **DPA (Art. 28)** | **None on Free** ❌ | On business/Teams plans | On business/Teams plans |
| Audit | Download-notification email only | Basic | Basic |

**Key finding:** the only way to get a longer/configurable window on WeTransfer is **Ultimate** — the
cheaper **Starter tier keeps the 3-day cap**. So "just upgrade WeTransfer" effectively means jumping to
Ultimate (~$23/mo) or a Teams plan (for a DPA). Even then, the E2E-encryption gap and the recent
ownership/trust flags remain. WeTransfer paid is therefore a **low-change stopgap**, not the strongest
destination.

---

## 4. Options appraisal

Per Ant's steer, the two shortlisted options are the **best already-owned** route and the **best
purpose-built paid** route, presented side by side, with honourable mentions after.

### Option A — Google Workspace / Google Drive (already owned, ~£0 incremental)

**We already pay for this** (Business Starter ≈ £5.90/user/mo, Standard ≈ £11.80/user/mo annual, +VAT).

- **Strengths:** DPA already in place; EU data-region option; **strong Drive audit logs** (View / Edit /
  Download / share-change events, ~6 months retention, exportable); no new spend or vendor onboarding.
- **Limitations (stated honestly):**
  - **No native password on share links.** Google Drive has no password gate on a link.
  - **Link expiry only works on named-person ("specific people") shares** (feature added Nov 2025) —
    **not** on "anyone with the link". So the secure, expiring mode requires the customer to
    **authenticate with a Google account**, which many customers won't have or want.
- **Two workable compliant patterns:**
  1. **Named-email + expiry:** share restricted to the **customer's specific email**, set an expiry,
     rely on Workspace audit logs. Clean audit; needs the customer to have/verify a Google identity.
  2. **Encrypted archive over Drive:** put the recording in a **password-protected archive**
     (e.g. 7-Zip / AES-256), upload to Drive, share the link, and **send the archive password by a
     separate channel** (SMS or phone). Works for customers with no Google account and satisfies the
     ICO "encrypted file + separate code" model — but expiry on an open link isn't native, so you must
     **manually revoke/delete** at the end of the window (the honest operational overhead of the
     Google-only route).

### Option B — Tresorit / Tresorit Send (purpose-built paid, indicative ~$14.50/user/mo)

Swiss + EU, end-to-end encrypted file sharing built for exactly this kind of sensitive delivery.

- **Strengths:** **True end-to-end (zero-knowledge) encryption** — Tresorit cannot read the files;
  **password + custom expiry + download limits + revocation**; **no recipient account required**
  (customer opens a secure browser link); **DPA** available; **Swiss jurisdiction + EU data centres**,
  ISO 27001/27017/27018. This is the closest match to the ICO's "encrypted file + code sent separately"
  model, with the **least customer friction**.
- **Tresorit Send** is a lighter, WeTransfer-style drop-in (send up to ~5 GB, still E2E + expiry +
  password) if a full per-seat rollout isn't wanted initially.
- **Cost (indicative):** Business Standard **~$14.50/user/mo** (≈ **£11–12**), **minimum 3 users**,
  billed annually; higher Business Plus / Enterprise tiers exist. **Confirm GBP pricing and that the DPA
  is included on the specific tier** before committing.
- **Trade-off:** a new vendor to onboard and a modest per-seat cost — but it is purpose-built for the job.

### Honourable mentions / other routes (brief)

- **WeTransfer Teams/Ultimate** — lowest-change stopgap; closes the DPA + window gaps but keeps the E2E
  gap and trust flags.
- **Dropbox (paid)** — password + expiring links, no recipient account; **US-default residency** is the
  GDPR question mark (EU residency is a plan/add-on) — verify.
- **Egnyte** — EU datacentre, expiry **by date or click-count**, preview-only links; capable but priced
  as a full content platform (~$22/user/mo+).
- **Citrix ShareFile** — strong client-portal/PII posture, EU (Ireland) if enabled; sales-led/premium and
  likely over-scoped for occasional SAR delivery.
- **AWS S3 pre-signed URLs** — cheap, fully EU-controllable (London region), **7-day max** window suits
  DSARs, CloudTrail logging; **no password layer** (the URL is the secret) and it's an **engineering
  build**, not a product. Viable if we ever want an in-house option.
- **MASV / Filemail** — for very large files with selectable EU region; more than we need for single
  recordings.

---

## 5. Comparison table

Scored for the **"send a call recording to a customer"** use case. Costs are **indicative** (mostly USD
list; confirm GBP). ✅ good · ⚠️ partial/with caveats · ❌ gap.

| Option | Access-window control | Password on link | Encryption (transit / rest / **E2E**) | DPA & residency | Audit log | Recipient needs account? | Indicative cost | Overall fit |
|---|---|---|---|---|---|---|---|---|
| **WeTransfer Free** (current) | ❌ fixed 3 days, no revoke | ✅ | ✅ / ✅ / ❌ ; EU | ❌ **no DPA on Free** | ⚠️ email only | No | £0 | **Weak** |
| **WeTransfer Ultimate** | ✅ custom | ✅ + Access Control | ✅ / ✅ / ❌ | ⚠️ DPA on business/Teams; EU | ⚠️ basic | No | ~$23/mo | OK (pricey) |
| **Google Workspace** (owned) | ⚠️ only on named-person shares | ❌ native (use encrypted archive) | ✅ / ✅ / ❌ ; EU region | ✅ DPA; EU | ✅ strong | ⚠️ Yes for secure/expiring mode | **~£0 incremental** | **Good, with friction** |
| **Tresorit** | ✅ custom + download limits + revoke | ✅ | ✅ / ✅ / **✅ E2E** ; CH+EU | ✅ DPA; Swiss/EU | ✅ | **No** | ~$14.50/user/mo (min 3) | **Strongest privacy fit** |
| **Dropbox (paid)** | ✅ password + expiry | ✅ | ✅ / ✅ / ❌ | ⚠️ DPA; **US default** | ⚠️ team audit | No | ~$16.58/mo+ | Good (check residency) |
| **AWS S3 pre-signed URL** | ✅ 1 min–7 days | ❌ (URL is the secret) | ✅ / ✅ / ❌ ; **London** | ✅ AWS DPA; EU | ✅ CloudTrail | No | pennies + **build** | Good if engineered |

---

## 6. Recommendation

**Do now (interim quick win):** stop using **WeTransfer Free** for personal-data delivery. Its **lack of a
DPA** is a live compliance gap regardless of anything else. If we can't switch tools immediately, the
minimum stopgap is a WeTransfer **Teams** plan (which carries a DPA) — but treat that as a bridge, not the
destination.

Then choose between two clear routes (both give a **configurable window longer than 3 days**):

- **Route 1 — zero extra cost (Google Workspace).** Best when budget is the priority and we can either
  (a) rely on customers authenticating with a named Google email, or (b) adopt the **encrypted-archive +
  separately-sent password** pattern. Closes the DPA gap at **~£0**, at the cost of some customer
  friction and **manual delete/revoke** overhead.
- **Route 2 — best privacy fit (Tresorit).** Best when we want the strongest GDPR posture and the lowest
  customer friction: **end-to-end encryption, password, custom expiry, download limits, revocation, EU/CH
  residency, DPA, and no customer account needed** — for a modest per-seat cost (~£11–12/user/mo, min 3
  users). This is the recommendation if a small spend is acceptable.

**Access window:** recommend a **configurable default of ~14 days** (policy range **7–30 days**). Longer
is more convenient for customers but weaker on storage limitation — 14 days balances the two and is well
inside every shortlisted tool's capability. Whatever is chosen, **delete after collection**.

**One-line steer:** *if a modest budget is acceptable, Tresorit is the cleanest answer; if it must be £0,
Google Workspace with the encrypted-archive pattern works but carries manual overhead — either way, move
off WeTransfer Free because it has no DPA.*

---

## 7. Controls to apply regardless of the tool chosen (reusable mini-runbook)

Whichever option is adopted, apply these every time a recording is sent — this is the ICO checklist made
operational:

1. **Encrypt** the file (tool-native E2E, or a password-protected archive).
2. **Password/access code sent via a *separate* channel** from the link (e.g. link by email, password by
   SMS/phone) — never in the same email.
3. **Verify the recipient** — confirm the identity and the delivery address/email before sending;
   double-check to avoid a wrong-recipient breach.
4. **Set the shortest workable expiry** (proposed default 14 days) and **revoke/delete after collection**.
5. **Send only what was requested** — the specific recording(s), nothing extra (data minimisation).
6. **Log the send** — what was sent, to whom, when, and (where the tool supports it) when it was accessed.

---

## 8. Open questions / decisions for Ant & the DPO

- **Do customers reliably have Google accounts?** If yes, Google named-email sharing is clean; if not, the
  Google route means the encrypted-archive pattern with its manual overhead.
- **Is a modest per-seat spend acceptable?** If yes, Tresorit is the strongest fit.
- **What access window do we want as policy?** (Proposed: 14 days; range 7–30.)
- **Who owns the send process** — Privacy, Ops, or Customer Service — and where is it documented?
- **Confirm before adopting:** exact GBP pricing; that a DPA is included on the specific tier; and the
  current ICO wording (§2 caveat).

---

## 9. Governance notes & sources

- This document contains **no customer PII** — it is a vendor/process appraisal. Retain as a decision
  record; it may be shared internally (commercial-in-confidence).
- All third-party feature/price claims are **desk research (Aug 2026)** and **indicative** — verify before
  any procurement or process change. No live customer recordings were handled in producing it.
- No change to any live sending process is implied until a direction is agreed with the DPO.

**Sources (accessed Aug 2026):**

- WeTransfer: [plan limits](https://wetransfer.com/help-center/subscriptions/plan-limits) ·
  [password protection](https://wetransfer.com/resources/password-protected-file-transfer/how-to-password-protect-file-sharing) ·
  [pricing analysis](https://goodsign.io/blog/wetransfer-pricing) ·
  [Trust Center](https://trust.wetransfer.com/) ·
  [2026 limits overview](https://www.transfernow.net/en/wetransfer/limits)
- WeTransfer 2025 AI-terms episode:
  [The Next Web](https://thenextweb.com/news/how-wetransfer-reignited-fears-about-training-ai-on-user-data) ·
  [TechTimes](https://www.techtimes.com/articles/311360/20250716/wetransfer-clarifies-ai-policy-after-backlash-over-terms-service-update.htm)
- Google Workspace: [UK pricing (Refractiv)](https://refractiv.co.uk/news/google-workspace-cost-uk-pricing/) ·
  [sharing-expiration feature, Nov 2025](https://workspaceupdates.googleblog.com/2025/11/set-sharing-expirations-files-and-folders.html) ·
  [Drive log events / audit](https://knowledge.workspace.google.com/admin/reports/drive-log-events) ·
  [no native link passwords](https://www.multcloud.com/tutorials/google-drive-share-file-with-password.html)
- Tresorit: [secure file sharing](https://tresorit.com/product/secure-file-sharing) ·
  [access-control KB](https://support.tresorit.com/hc/en-us/articles/12176560096018-How-to-control-access-to-your-shared-files) ·
  [business pricing](https://tresorit.com/pricing/business) ·
  [pricing review](https://dupple.com/reviews/tresorit)
- Dropbox: [password protection](https://www.dropbox.com/features/share/password-protection) ·
  [link permissions/expiry](https://help.dropbox.com/share/set-link-permissions)
- Egnyte: [secure-links KB](https://helpdesk.egnyte.com/hc/en-us/articles/201637554-How-Do-I-Make-File-and-Folder-Links-More-Secure) ·
  [GDPR](https://www.egnyte.com/gdpr/solutions)
- Citrix ShareFile: [GDPR](https://www.simpleanalytics.com/is-gdpr-compliant/sharefile)
- AWS S3 pre-signed URLs: [user guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-presigned-url.html) ·
  [security best practice](https://aws.amazon.com/blogs/security/how-to-securely-transfer-files-with-presigned-urls/)
- ICO (confirm wording on live pages):
  [SAR advice](https://ico.org.uk/for-organisations/advice-for-small-organisations/subject-access-requests-sar/subject-access-request-advice/) ·
  [supplying information to the requester](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/individual-rights/right-of-access/how-can-we-supply-information-to-the-requester/) ·
  [encryption guidance (PDF)](https://ico.org.uk/media2/bi0bcdxr/encryption-guidance.pdf)
