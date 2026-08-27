# DSR Intake Form — Claude Code Handoff

## What This Is

A multi-step Data Subject Request intake form for AnyVan, deployed to AV Dashboards for internal testing. Covers all UK GDPR request types for Customers, Transport Partners (sole traders and limited companies), and Authorised Third Parties.

**Live URL:** `https://dashboards.anyvan.com/operations/dsr-intake-form`
**Dashboard path:** `operations/dsr-intake-form`
**Status:** Deployed, internal test mode. Submissions display structured JSON payload — not yet wired to Freshdesk.

---

## Known Bug To Fix

The account holder confirmation checkbox doesn't work in the deployed HTML version. Root cause: missing space between `checked` attribute and `style` attribute in the template literal, producing `checkedstyle=` as one invalid attribute.

**Fix location:** In `renderStep2()`, the confirm-box checkbox line. Change:

```javascript
${chk?'checked':''}style="margin-top:3px;
```

To:

```javascript
${chk?'checked ':''}style="margin-top:3px;
```

Also add a fallback click handler on the wrapper div in `bindEvents()`:

```javascript
const cbw = document.getElementById('confirm-box-wrap');
if (cbw && ah) cbw.onclick = (e) => {
  if (e.target === ah) return;
  S.accountHolder = !S.accountHolder;
  render();
};
```

The fix is already applied in the local file at `/home/claude/dsr-form.html` but was not pushed to AV Dashboards because MCP tools were evicted during the long session.

**Priority:** Push this fix first before any other changes.

---

## Form Structure (4 Steps)

### Step 1 — Requester Type
Three options:
- **Customer** — "I used AnyVan to arrange a move or delivery"
- **Transport Partner** — "I provide transport services through AnyVan"
- **Authorised Third Party** — "I'm acting on behalf of someone else (e.g. solicitor, family member)"

### Step 2 — Your Details
Common fields (all requester types):
- Your Full Name / Full Name of Data Subject (label changes for third party) — required
- Email Address — required
- Phone Number — required
- Alternative Phone Number — optional
- AnyVan Booking Reference — optional, placeholder `AV1234567`, auto-normalises in review (prepends `AV` if user enters digits only)

**Customer-specific:**
- Account holder confirmation checkbox (required) — "I confirm that the details provided above are registered to my AnyVan customer account and that I am the person authorised to make this request."

**Transport Partner-specific:**
- Business Type selector (required): Sole Trader / Limited Company or Partnership
  - Sole Trader → Trading Name (optional)
  - Limited → Registered Company / Partnership Name (required)
- Transport Partner Username (optional) — "Your login username for the AnyVan partner portal"
- Account holder confirmation checkbox (required) — wording varies:
  - Sole Trader: "I confirm that I am the individual sole trader registered to this Transport Partner account on AnyVan and that the personal data associated with this account relates to me."
  - Limited: "I confirm that I am the registered account holder or an authorised director/officer for this Transport Partner account on the AnyVan platform and that I am authorised to make this request on behalf of the business."

**Third Party-specific:**
- Authorisation Details textarea (required)
- Proof of Authorisation file upload (required, min 1 file) — drag-and-drop or click, accepts PDF/JPG/PNG up to 10MB per file, multiple files supported, each shows with name/size/type icon/remove button

**Asterisk explainer** sits below the "Your Details" heading: "Fields marked with * are required."

### Step 3 — Your Request
Five request types presented as a button grid:
1. **Access My Data (SAR)** — checkbox selection of data categories:
   - Booking & account details
   - Call recordings → expands **Call Recording Details** panel (per-call date + approx time required, phone number optional, "+ Add another call" button, amber retention warning)
   - Chat transcripts → expands **Chat Transcript Details** panel (date range, channel selection: WhatsApp / Live Chat / Both)
   - Email correspondence
   - Payment & transaction records
   - All personal data held → expands **friction panel** (date range required, written reason required min 20 chars, amber warning about manual searches and full calendar month)
   - "All personal data held" is mutually exclusive with individual categories (selecting it disables others, selecting any individual unchecks "all")

2. **Delete My Data** — checkbox selection of deletion scopes (full account, booking history, call recordings, chat transcripts, marketing data) + red legal retention warning

3. **Correct My Data (Rectification)** — checkbox selection of fields to correct (name, email, phone, address, other) + required textarea for correct information

4. **Marketing Opt-Out** — green confirmation note (removes from email, SMS, push; does not affect transactional messages)

5. **Data Portability** — blue info note (CSV or JSON within one calendar month)

All request types show an optional "Additional Information" textarea.

### Step 4 — Review & Declaration
- Summary grid showing all captured data
- Booking ref normalised with AV prefix
- Account Holder shown as "✓ Confirmed" in green
- Auth files listed for third party
- Call entries shown with date/time/phone
- Declaration checkbox (required) with five points:
  1. Information accurate and complete
  2. Data subject or duly authorised
  3. Identity verification required
  4. One calendar month processing (Article 12(3))
  5. No liability for interception after sending

---

## Friction-by-Design Philosophy

The form is deliberately structured so that broad, speculative SARs ("all personal data held") require significantly more effort than targeted requests. This is ICO-compliant — every additional field exists to "help locate data" — while naturally steering requestors toward specific, manageable requests.

Friction layers:
- Call recordings: per-call date/time entry
- Chat transcripts: date range + channel selection
- All data held: date range + written justification (min 20 chars) + amber warnings about delays
- Third-party requests: written authorisation + file upload

Targeted requests (specific call, specific booking data, marketing opt-out) are kept straightforward.

---

## Test Mode Payload Structure

On submit, the form generates and displays a JSON payload. Example:

```json
{
  "dsr_reference": "DSR-XXXXXXXXX",
  "submitted_at": "2026-06-16T09:30:00.000Z",
  "requester_type": "CUSTOMER",
  "full_name": "Jane Smith",
  "email": "jane@example.com",
  "phone": "+447123456789",
  "alt_phone": "+447987654321",
  "booking_reference": "AV1234567",
  "account_holder_confirmed": true,
  "request_type": "SAR",
  "sar_data_types": ["call_recordings", "chat_transcripts"],
  "call_entries": [
    { "date": "2026-05-15", "time": "14:30", "phone": "+447123456789" },
    { "date": "2026-05-20", "time": "10:00", "phone": "" }
  ],
  "chat_request": {
    "date_from": "2026-05-01",
    "date_to": "2026-05-31",
    "channels": ["WhatsApp"]
  },
  "freshdesk_tags": ["privacy", "dsr", "sar", "customer", "source:dsr-form", "account-holder-confirmed"]
}
```

TP example adds: `tp_business_type`, `company_name`, `tp_username`
Third party example adds: `third_party_auth`, `auth_files` (array of `{name, size, type}`)
Deletion example adds: `deletion_scopes` array
Rectification example adds: `rectification_fields` array + `rectification_details`
All-data SAR adds: `all_data_request` with `date_from`, `date_to`, `reason`

---

## What Needs Building Next

### 1. Push the checkbox bugfix
Update `operations/dsr-intake-form` on AV Dashboards. Use `get_upload_token` → `PUT` to the upload API with the fixed HTML.

### 2. Freshdesk custom fields
Create in Freshdesk admin before wiring the backend:
- `cf_dsr_type` — dropdown: SAR, Deletion, Rectification, Marketing Opt-Out, Portability
- `cf_requester_type` — dropdown: Customer, TP Sole Trader, TP Limited, Third Party
- `cf_booking_reference` — text
- `cf_tp_username` — text

### 3. Lambda backend (Node.js, AWS Lambda-compatible)
Receives the JSON payload from the form, then:
- Creates a Freshdesk ticket with custom fields, tags, and a structured private note
- Attaches uploaded files to the ticket (base64 pass-through from form → Freshdesk attachment API)
- Fires the existing webhook classifier
- Returns the DSR reference to the form

Freshdesk API patterns (from existing SAR automation):
- Basic auth: API key as username, `"X"` as password (base64 encoded)
- Create ticket: `POST /api/v2/tickets` with `{subject, description, email, phone, custom_fields, tags}`
- Add private note: `POST /api/v2/tickets/{id}/notes` with `{body: html, private: true}`
- Rate limit: sleep 1.5–2s between calls; on HTTP 429, read `Retry-After` header

### 4. S3 + CloudFront hosting
For external (customer/TP-facing) deployment:
- Static site on S3 behind CloudFront
- Subdomain e.g. `privacy.anyvan.com` or path on main site
- Remove the test banner and AV Dashboards auth
- Wire form submission to the Lambda via API Gateway

---

## Technical Notes

- The form is vanilla HTML/JS/CSS — no build step, no React dependency
- State is managed in a single `S` object, re-rendered on every state change
- All form HTML is generated by JavaScript functions (`renderStep1()` through `renderStep4()`)
- Event binding happens in `bindEvents()` after each render
- Google Fonts: DM Sans (weights 300, 400, 500, 600, 700)
- AV Dashboards auth: `AVDashboard.ensureAuthenticated()` on load
- Tracking: `av-track-source="dsr-intake-form"`

### AV Dashboards deployment pattern
1. `get_upload_token` → returns JWT (5 min expiry) + upload URL
2. Build JSON payload: `{"html": "...", "path": "operations/dsr-intake-form", "title": "..."}`
3. `PUT` to `https://63g6ly45b0.execute-api.eu-west-1.amazonaws.com/production/upload` with `Authorization: Bearer {token}` and `Content-Type: application/json`
4. Use `PUT` (not `POST`) because the dashboard already exists

---

## Files

- **Deployed HTML:** Fetch current version via `get_dashboard_html` with path `operations/dsr-intake-form`
- **React mockup:** Available as `data-subject-request-form.jsx` (used for iteration, not deployed)
- **Local fixed HTML:** Was at `/home/claude/dsr-form.html` in the consumer app session (contains the checkbox bugfix)
