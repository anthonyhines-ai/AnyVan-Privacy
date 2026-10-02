# DSR Formstack internal notification templates (preserved)

> **INTERNAL** — no customer data (these are merge-field templates, not submissions).
> The internal "to `privacy@anyvan.com`" notification emails from Formstack form `6559077`,
> captured 2026-10-02. **Preserved here because these become the internal comms the
> WORKFLOW will send** (via the Freshdesk ticket) once the native Formstack notifications are
> **disabled**. Customer-facing comms (on-screen confirmation + confirmation email) stay ON.
> Merge codes: `{$<fieldId> label}` = that form field value; `{$_submission_id}` = Formstack
> submission id.
>
> **Coverage gap:** templates exist for **5 of the 8** request types below. There is **no** internal
> template for **Restrict Processing**, **Object to Processing**, or **Withdraw Consent** — the
> workflow must cover those from the shared skeleton.

---

## SAR Privacy Request Email [UK]

- Formstack notification id: `9711486`
- Shows when `request_type` = **Access My Data (SAR)**
- Recipient: `privacy@anyvan.com` · From field: `197276072`

**Subject:** `[UK] SAR Privacy Data Request | Requester Type: {$197276069 Are You.......} [{$_submission_id}]`

**Message (verbatim HTML):**

```html
<p><span style="font-family: Georgia, serif; font-size: 24px;"><strong>[UK] New SAR Privacy Request | Requester Type: {$197276069 Are You.......} | Privacy Request Due: {$197302298 Privacy Due Date}</strong></span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Requester &amp; Subject</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Full Name: {$197276071 Full name [of the Data Subject]}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Email Address: {$197276072 Email Address}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Primary Phone Number: {$197276073 Phone Number} | Alternative Phone Number: {$197276074 Alternative phone number}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">AnyVan Booking Reference: {$197276080 AnyVan Booking Reference/s [If Any]}</span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Transport Partner Details</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Business Type: {$197276081 Business type}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Trading Name: {$197276082 Trading name}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Registered Company / Partnership Name: {$197276083 Registered Company / Partnership Name}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Transport Partner Username: {$197276084 Transport Partner Username}</span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Authorised Third Party Details</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Authorisation Details: {$197276085 Authorisation details}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Proof of Authorisation: {$197276086 Proof of authorisation [PDF/JPG/PNG]}</span></p><p><span style="font-size: 14px; font-family: Georgia, serif;"><em>No acting-party contact email is captured on this form; the requester email above is the data subject's. Verify authorisation before proceeding.</em></span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Subject Access Request Details</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Data Categories Requested: {$197276090 What data would you like to access?}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">All Data From: {$197276095 All Data - Earliest Interaction} to {$197276096 All Data - Most Recent Interaction}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Chat Method Used: {$197276094 Chat Method Used}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Chat Transcripts From: {$197276092 Chat Transcripts - From Date} to {$197668331 Chat Transcripts - To Date}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Email Correspondence From: {$197668332 Email Correspondence - From Date} to {$197276093 Email Correspondence  - To Date}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Call/Video Recordings From: {$197277114 Call/Video Recordings - From Date} to {$197277122 Call/Video Recordings - To Date}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Reason For Request: {$197276097 Why are you requesting this Data?}</span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Additional Information</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Additional Information: {$197276106 Additional Information}</span></p><p><span style="font-size: 14px; font-family: Georgia, serif;">Declaration confirmed by requester (UK GDPR Art. 12(3)).</span></p>
```

---

## Rectification Privacy Request Email [UK]

- Formstack notification id: `9770031`
- Shows when `request_type` = **Correct My Data**
- Recipient: `privacy@anyvan.com` · From field: `197276072`

**Subject:** `[UK] Rectification Privacy Data Request | Requester Type: {$197276069 Are You.......} [{$_submission_id}]`

**Message (verbatim HTML):**

```html
<p><span style="font-family: Georgia, serif; font-size: 24px;"><strong>[UK] New Rectification Privacy Request | Requester Type: {$197276069 Are You.......} | Privacy Request Due: {$197302298 Privacy Due Date}</strong></span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Requester &amp; Subject</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Full Name: {$197276071 Full name [of the Data Subject]}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Email Address: {$197276072 Email Address}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Primary Phone Number: {$197276073 Phone Number} | Alternative Phone Number: {$197276074 Alternative phone number}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">AnyVan Booking Reference: {$197276080 AnyVan Booking Reference/s [If Any]}</span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Transport Partner Details</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Business Type: {$197276081 Business type}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Trading Name: {$197276082 Trading name}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Registered Company / Partnership Name: {$197276083 Registered Company / Partnership Name}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Transport Partner Username: {$197276084 Transport Partner Username}</span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Authorised Third Party Details</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Authorisation Details: {$197276085 Authorisation details}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Proof of Authorisation: {$197276086 Proof of authorisation [PDF/JPG/PNG]}</span></p><p><span style="font-size: 14px; font-family: Georgia, serif;"><em>No acting-party contact email is captured on this form; the requester email above is the data subject's. Verify authorisation before proceeding.</em></span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Rectification Details</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Which Data Needs Correcting: {$197276100 Which data needs correcting?}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Correct Information Supplied: {$197276101 Please provide the correct information}</span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Additional Information</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Additional Information: {$197276106 Additional Information}</span></p><p><span style="font-size: 14px; font-family: Georgia, serif;">Declaration confirmed by requester (UK GDPR Art. 12(3)).</span></p>
```

---

## Deletion Privacy Request Email [UK]

- Formstack notification id: `9770032`
- Shows when `request_type` = **Delete My Data**
- Recipient: `privacy@anyvan.com` · From field: `197276072`

**Subject:** `[UK] Deletion Privacy Data Request | Requester Type: {$197276069 Are You.......} [{$_submission_id}]`

**Message (verbatim HTML):**

```html
<p><span style="font-family: Georgia, serif; font-size: 24px;"><strong>[UK] New Deletion Privacy Request | Requester Type: {$197276069 Are You.......} | Privacy Request Due: {$197302298 Privacy Due Date}</strong></span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Requester &amp; Subject</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Full Name: {$197276071 Full name [of the Data Subject]}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Email Address: {$197276072 Email Address}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Primary Phone Number: {$197276073 Phone Number} | Alternative Phone Number: {$197276074 Alternative phone number}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">AnyVan Booking Reference: {$197276080 AnyVan Booking Reference/s [If Any]}</span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Transport Partner Details</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Business Type: {$197276081 Business type}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Trading Name: {$197276082 Trading name}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Registered Company / Partnership Name: {$197276083 Registered Company / Partnership Name}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Transport Partner Username: {$197276084 Transport Partner Username}</span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Authorised Third Party Details</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Authorisation Details: {$197276085 Authorisation details}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Proof of Authorisation: {$197276086 Proof of authorisation [PDF/JPG/PNG]}</span></p><p><span style="font-size: 14px; font-family: Georgia, serif;"><em>No acting-party contact email is captured on this form; the requester email above is the data subject's. Verify authorisation before proceeding.</em></span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Deletion Details</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Deletion Scope Requested: {$197276099 What data would you like deleted?}</span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Additional Information</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Additional Information: {$197276106 Additional Information}</span></p><p><span style="font-size: 14px; font-family: Georgia, serif;">Declaration confirmed by requester (UK GDPR Art. 12(3)).</span></p>
```

---

## Data Portability Privacy Request Email [UK]

- Formstack notification id: `9770051`
- Shows when `request_type` = **Data Portability**
- Recipient: `privacy@anyvan.com` · From field: `197276072`

**Subject:** `[UK] Data Portability Privacy Data Request | Requester Type: {$197276069 Are You.......} [{$_submission_id}]`

**Message (verbatim HTML):**

```html
<p><span style="font-family: Georgia, serif; font-size: 24px;"><strong>[UK] New Data Portability Privacy Request | Requester Type: {$197276069 Are You.......} | Privacy Request Due: {$197302298 Privacy Due Date}</strong></span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Requester &amp; Subject</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Full Name: {$197276071 Full name [of the Data Subject]}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Email Address: {$197276072 Email Address}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Primary Phone Number: {$197276073 Phone Number} | Alternative Phone Number: {$197276074 Alternative phone number}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">AnyVan Booking Reference: {$197276080 AnyVan Booking Reference/s [If Any]}</span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Transport Partner Details</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Business Type: {$197276081 Business type}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Trading Name: {$197276082 Trading name}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Registered Company / Partnership Name: {$197276083 Registered Company / Partnership Name}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Transport Partner Username: {$197276084 Transport Partner Username}</span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Authorised Third Party Details</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Authorisation Details: {$197276085 Authorisation details}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Proof of Authorisation: {$197276086 Proof of authorisation [PDF/JPG/PNG]}</span></p><p><span style="font-size: 14px; font-family: Georgia, serif;"><em>No acting-party contact email is captured on this form; the requester email above is the data subject's. Verify authorisation before proceeding.</em></span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Data Portability</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">No extra input is captured for this request type on the form. Fulfil per the standard CSV/JSON export within 30 days.</span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Additional Information</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Additional Information: {$197276106 Additional Information}</span></p><p><span style="font-size: 14px; font-family: Georgia, serif;">Declaration confirmed by requester (UK GDPR Art. 12(3)).</span></p>
```

---

## Marketing Opt-Out Privacy Request Email [UK]

- Formstack notification id: `9770052`
- Shows when `request_type` = **Marketing Opt-Out**
- Recipient: `privacy@anyvan.com` · From field: `197276072`

**Subject:** `[UK] Marketing Opt-Out Privacy Data Request | Requester Type: {$197276069 Are You.......} [{$_submission_id}]`

**Message (verbatim HTML):**

```html
<p><span style="font-family: Georgia, serif; font-size: 24px;"><strong>[UK] New Marketing Opt-Out Privacy Request | Requester Type: {$197276069 Are You.......} | Privacy Request Due: {$197302298 Privacy Due Date}</strong></span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Requester &amp; Subject</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Full Name: {$197276071 Full name [of the Data Subject]}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Email Address: {$197276072 Email Address}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Primary Phone Number: {$197276073 Phone Number} | Alternative Phone Number: {$197276074 Alternative phone number}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">AnyVan Booking Reference: {$197276080 AnyVan Booking Reference/s [If Any]}</span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Transport Partner Details</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Business Type: {$197276081 Business type}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Trading Name: {$197276082 Trading name}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Registered Company / Partnership Name: {$197276083 Registered Company / Partnership Name}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Transport Partner Username: {$197276084 Transport Partner Username}</span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Authorised Third Party Details</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Authorisation Details: {$197276085 Authorisation details}</span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Proof of Authorisation: {$197276086 Proof of authorisation [PDF/JPG/PNG]}</span></p><p><span style="font-size: 14px; font-family: Georgia, serif;"><em>No acting-party contact email is captured on this form; the requester email above is the data subject's. Verify authorisation before proceeding.</em></span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Marketing Opt-Out</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">No extra input is captured for this request type on the form. Action per the standard opt-out process.</span></p><hr><p><span style="font-size: 18px; font-family: Georgia, serif;"><strong>Additional Information</strong></span></p><p><span style="font-size: 18px; font-family: Georgia, serif;">Additional Information: {$197276106 Additional Information}</span></p><p><span style="font-size: 14px; font-family: Georgia, serif;">Declaration confirmed by requester (UK GDPR Art. 12(3)).</span></p>
```

