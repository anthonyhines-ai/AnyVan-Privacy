# SAR Operations Checklist — Monika J Bagińska
## Bookings #9454215 · #9555113 | Deadline: 14 September 2026

> ⚠️ **CONFIDENTIAL — OPERATIONAL GUIDE.**
> This checklist contains references to customer personal data. Access restricted to authorised AnyVan Privacy / Operations staff. Follow all PII redaction rules before final delivery.

| | |
|---|---|
| **Document type** | Operational workflow & task checklist |
| **SAR record** | booking-lookups/2026-08-28-sar-monika-baginska-9454215-9555113.md |
| **Customer** | Monika J Bagińska (07881361498, monibag2000@yahoo.com) |
| **Bookings** | #9454215 (Home Removal), #9555113 (Furniture Delivery) |
| **Request received** | 14 August 2026 |
| **Statutory deadline** | 14 September 2026 (30 days) |
| **Document status** | IN PROGRESS — Task 2 Active |

---

## Timeline & SLA

| Milestone | Deadline | Owner | Status |
|---|---|---|---|
| Identity verification & data discovery | 1 Sep | Privacy Officer | ✅ DONE |
| Call recordings compiled & verified | 3 Sep | Operations | ✅ DONE |
| Payment/account data extracted | 3 Sep | Data team | ✅ DONE |
| Video consultation located (Jiminny) | **10 Sep** | Operations | ⏳ IN PROGRESS |
| Email threads exported (Freshdesk) | **10 Sep** | Freshdesk admin | ⏳ PENDING |
| Shared notes extracted (HubSpot/Freshdesk) | **10 Sep** | Operations | ⏳ PENDING |
| PII redaction review | **11 Sep** | Compliance Officer | ⏳ PENDING |
| Archive creation & encryption | **11 Sep** | Operations | ⏳ PENDING |
| WeTransfer delivery setup | **12 Sep** | Operations | ⏳ PENDING |
| Customer delivery & SMS password | **12 Sep** | DPO/Ops | ⏳ PENDING |
| **GDPR Statutory Deadline** | **14 Sep** | — | ⏳ PENDING |

---

## Section 1: Completed Tasks ✅

### 1.1 Identity Verification (Completed)
- [x] Customer identity confirmed across HubSpot, Snowflake, email channels
- [x] User ID resolved: **1853670**
- [x] HubSpot Contact ID resolved: **524897651**
- [x] Phone normalised: **07881361498** (+447881361498)
- [x] Email addresses confirmed: **monibag2000@yahoo.com** (primary), **monciab74@gmail.com** (secondary)

### 1.2 Booking Data Compiled (Completed)
- [x] Booking #9454215 (Home Removal) — retrieved from MASTER_LISTING with full details
- [x] Booking #9555113 (Furniture Delivery) — retrieved from MASTER_LISTING with full details
- [x] Customer account preferences extracted from CONFORMED layer
- [x] Booking status, volume, dates, property details all documented

### 1.3 Payment Transaction Records (Completed)
- [x] Queried HARMONISED.PRODUCTION.PAYMENT for user_id 1853670
- [x] **7 transactions located:**
  1. £731.00 (Jun 2026) — booking #9454215
  2. £234.00 (Jun 2026) — booking #9555113
  3. Processing fees (authorised 2026-06-08)
  4. Additional transactions (dates Jun–Aug 2026)
- [x] Transaction IDs, authorisation codes, timestamps recorded
- [x] Redaction rule applied: customer card last-4 digits RETAINED; internal processor IDs removed

### 1.4 Call Recording Metadata (Completed)
- [x] Queried FCT_VOICE_INTERACTIONS for user_id 1853670 (date range 10 Jun–28 Aug 2026)
- [x] **11 Twilio recordings located** with Flex URLs (https://flex.twilio.com/recordings/{RECORDING_ID})
- [x] All metadata extracted: date, time, duration, agent name, recording ID
- [x] Twilio Account SID replaced with placeholder: **<TWILIO_ACCOUNT_SID>** (recoverable from HubSpot engagement)
- [x] URL format validated: `/recordings/{CA xxxxxxxxxxxxxxxxxxxxxxx}` (32-hex ID)

### 1.5 Account Preferences & Settings (Completed)
- [x] Communication preferences extracted (SMS, email, WhatsApp consent)
- [x] Marketing opt-in/opt-out status documented
- [x] Account notification settings recorded

### 1.6 Data Processing Purposes Documented (Completed)
- [x] **6 processing categories** identified and documented with GDPR Article 6 lawful basis:
  1. Contract performance (Article 6(1)(b)) — booking fulfillment
  2. Legitimate interest (Article 6(1)(f)) — fraud prevention, analytics
  3. Consent (Article 6(1)(a)) — marketing communications
  4. Legal obligation (Article 6(1)(c)) — tax, audit, retention
  5. Legal claim (Article 6(1)(e)) — dispute resolution
  6. Vital interests (not applicable)
- [x] Retention period for each category documented

### 1.7 Data Recipients & Third-Party Processors (Completed)
- [x] **6 third-party recipients identified** with DPA/SCC confirmation:
  1. Jiminny (call recording platform) — DPA confirmed
  2. Twilio Flex (recording service) — DPA confirmed
  3. Freshdesk (support ticketing) — DPA confirmed
  4. HubSpot (CRM) — DPA confirmed
  5. Payment processor (Stripe/Square) — DPA + PCI-DSS
  6. Google Drive (file sharing) — DPA via Google Workspace
- [x] Transfer mechanism documented (intra-EU/UK, no international transfers)

---

## Section 2: Pending Tasks ⏳

### 2.1 Jiminny Video Consultation Lookup
**Status:** IN PROGRESS  
**Deadline:** 10 September 2026  
**Owner:** Operations team

#### Objective
Locate and retrieve the video consultation recording from 17 June 2026 (~2:30 PM) where Monika's flat was assessed for the Home Removal booking.

#### Search Method (Validated ✅)
**Primary method:** Jiminny UI email search — **confirmed working** via booking #9615866 ground-truth test

#### Step-by-Step Instructions

1. **Access Jiminny Platform**
   - Navigate to internal Jiminny call recording system
   - Log in with AnyVan staff credentials
   - Go to **Calls**, **Recordings**, or **Search** section

2. **Search by Customer Email** (PRIMARY METHOD)
   - Click **Search** or **Filter** in Calls/Recordings list
   - Enter customer email: **monibag2000@yahoo.com**
   - If no results, try secondary email: **monciab74@gmail.com**
   - **Do NOT filter by date first** — let Jiminny show all calls
   - Review full list of recordings

3. **Identify Correct Video**
   - Look for entry with these characteristics:
     - **Date:** 17 June 2026 (or very close)
     - **Time:** ~14:30 UTC (±15 minutes acceptable)
     - **Type:** "Video", "Assessment", "Consultation" (NOT "Voice Call" or "Audio")
     - **Duration:** 15–45 minutes (typical flat assessment)
     - **Status:** "Completed" or "Finished"

4. **Verify It's the Correct Call**
   - Click entry to view details
   - Confirm:
     - ✓ Customer name: Monika J Bagińska
     - ✓ Customer email: monibag2000@yahoo.com
     - ✓ Date/time: 17 June 2026 ~14:30
     - ✓ Type: Video (not audio)
     - ✓ Duration: 15–60 minutes
   - Check call summary/notes for: "flat", "assessment", "property tour", "inventory", "removal quote"

5. **Download Video File**
   - Click **Download** or **Export** button
   - Choose format:
     - **MP4** (most compatible — recommended)
     - MOV (Apple format)
   - Save to secure, password-protected location:
     - Company network secure folder
     - NOT public cloud
     - Document file path in Section 5 below

6. **Verify Playback**
   - Open video in media player (VLC, QuickTime)
   - Check:
     - ✓ Video plays without errors
     - ✓ Audio is clear and audible
     - ✓ Shows property/flat tour or assessment context
     - ✓ Customer and agent identifiable (agent will be redacted)
     - ✓ File size and duration match Jiminny entry

#### Alternative Search Methods (if Step 2 returns no results)

**Method B: Search by Phone**
- Enter customer phone: **07881361498** or **+447881361498**
- Review all recordings for this number
- Look for 17 June ~14:30 entry

**Method C: Search by Booking Reference**
- Search for: **9454215** (Home Removal booking ID)
- Filter date range: 1 June – 30 June 2026
- Look for "Video", "Assessment", or "Consultation" type

**Method D: Browse by Agent** (if agent name is known from booking notes)
- Go to **Team** or **Agent** view in Jiminny
- Select likely agent from HubSpot booking notes
- Filter by date: 17 June 2026
- Look for video calls during business hours (09:00–17:00)

#### Fallback: If Video NOT Found in Jiminny
Escalate to:
- **Interaction Hub team** — AnyVan's internal assessment platform (may store videos separately)
- **Google Drive / Shared Folder** — Search "Monika" OR "9454215" OR "07881361498" (June 2026)
  - Look under: "Customer Assessments", "Property Surveys", "Video Consultations"
- **WeTransfer / Secure Share** — Check AnyVan-sent emails for WeTransfer links from June 2026
- **Third-party Assessment Tool** — Check booking #9454215 notes in HubSpot for tool name (Robinhood, Tradify, etc.)

#### Jiminny MCP Transcript (Optional)
**After locating the video**, if you also need the transcript:

```
MCP Tool: mcp__AnyVan_MCP__get_conversation_transcript
Input: dealId = 60955982356 (Home Removal booking #9454215)
Output: Full conversation transcript (agent + customer dialogue)
Use case: Provide both video AND transcript in SAR if needed
```

#### Data Handling — Video File
Once video is located:

**File Verification**
- [ ] **File saved:** Confirm in secure, password-protected location
- [ ] **Format verified:** MP4/MOV plays without errors in media player
- [ ] **Audio quality:** Customer/agent audio is clear and audible
- [ ] **Duration recorded:** Note exact length (e.g., 23m 45s)
- [ ] **File size noted:** Record size in MB (typical: 200–500 MB for 20–45 min video)

**Metadata & Documentation**
- [ ] **Source recorded:** "Jiminny call recording, booking #9454215"
- [ ] **Agent name recorded:** From Jiminny UI (e.g., "Alex York") — **WILL BE REDACTED AS [AGENT]**
- [ ] **Timestamp:** Date and time recorded (2026-06-17 ~14:30 UTC)
- [ ] **Call duration:** Exact length of recording
- [ ] **Storage location:** Secure path where file is stored (for audit trail)

---

### 2.2 Freshdesk Email Export
**Status:** PENDING  
**Deadline:** 10 September 2026  
**Owner:** Freshdesk admin

#### Objective
Export all customer-facing email threads from Freshdesk relating to bookings #9454215 and #9555113, date range 1 June – 28 August 2026.

#### Search Criteria
- **Customer email:** monibag2000@yahoo.com (primary) or monciab74@gmail.com (secondary)
- **Booking references:** AV9454215, AV9555113
- **Phone number:** 07881361498 or +447881361498
- **Date range:** 1 June 2026 – 28 August 2026
- **Include:** Customer-facing threads (agent ↔ customer)
- **Exclude:** Internal emails, staff-only notes, private Freshdesk notes

#### Export Format
- Format: **Text export (plaintext) or HTML** with timestamps, sender, recipient, subject, body
- Include: Email header (Date, From, To, Subject)
- Exclude: Internal metadata (ticket IDs, internal routing, staff private notes)
- PII redaction: Agent email addresses → [REDACTED]; agent names → [AGENT]; customer data → retain

#### Delivery
- Save to secure, password-protected location
- File name format: `Freshdesk-Emails-Monika-Baginska-2026-06-01-2026-08-28.txt`
- Verify export completeness: count of threads/emails
- Document in Section 5 below

---

### 2.3 HubSpot Shared Notes Extraction
**Status:** PENDING  
**Deadline:** 10 September 2026  
**Owner:** Operations / HubSpot admin

#### Objective
Export shared (customer-relevant) notes from HubSpot DEALs relating to bookings #9454215 and #9555113.

#### DEAL Records in Scope
| Deal Type | HubSpot Deal ID | Booking ID | Scope |
|---|---|---|---|
| Home Removal | 60955982356 | 9454215 | Extract shared notes only |
| Furniture Delivery | 14842423123 | 9555113 | Extract shared notes only |

#### Content Rules
**INCLUDE (shared/customer-relevant notes):**
- [ ] Booking status updates
- [ ] Customer service interactions
- [ ] Service requests and accommodations
- [ ] Issue resolution logs
- [ ] Delivery/pickup notes visible to customer

**EXCLUDE (internal/private notes):**
- [ ] Private staff assessments
- [ ] Performance reviews or internal evaluations
- [ ] Sensitive internal decision logs
- [ ] Staff-only troubleshooting notes

#### Export Format
- Format: **Text or CSV** with timestamp, note author (redacted to [AGENT]), note text
- Include: Deal ID, creation date, note body
- Exclude: Author ID, internal metadata, version history
- Redaction: Agent names → [AGENT]; agent emails → [REDACTED]

#### Delivery
- Save to secure location
- File name: `HubSpot-Notes-Deals-60955982356-14842423123-2026-09-03.txt`
- Verify note count and content completeness
- Document in Section 5 below

---

### 2.4 Freshdesk Ticket Shared Notes
**Status:** PENDING  
**Deadline:** 10 September 2026  
**Owner:** Freshdesk admin

#### Objective
Export shared notes from any Freshdesk support tickets for this customer, date range 1 June – 28 August 2026.

#### Search Criteria
- Customer email: monibag2000@yahoo.com or monciab74@gmail.com
- Booking references: AV9454215, AV9555113
- Date range: 1 June 2026 – 28 August 2026
- Type: Support tickets with shared customer-visible notes

#### Content Rules
**INCLUDE:**
- [ ] Customer service interactions
- [ ] Resolution updates
- [ ] Booking accommodations

**EXCLUDE:**
- [ ] Private Freshdesk notes (staff-internal only)
- [ ] Internal troubleshooting logs
- [ ] Internal decision notes

#### Export Format
- Format: **Text export** with timestamp, ticket ID, note text
- Redaction: Staff names → [AGENT]; staff emails → [REDACTED]
- Include: Note creation date, note body

#### Delivery
- File name: `Freshdesk-Notes-Monika-Baginska-2026-09-03.txt`
- Verify against Freshdesk records
- Document in Section 5 below

---

### 2.5 PII Redaction Review
**Status:** PENDING  
**Deadline:** 11 September 2026  
**Owner:** Compliance Officer (Anthony Hines)

#### Objective
Review all manual data exports and apply PII redaction rules before final archive creation.

#### PII Redaction Rules

**RETAIN (Customer data — keep as-is):**
- [x] Customer name: **Monika J Bagińska** (full, as per records)
- [x] Customer email addresses: **monibag2000@yahoo.com**, **monciab74@gmail.com**
- [x] Customer phone number: **07881361498** (normalised)
- [x] Booking references: **AV9454215**, **AV9555113**
- [x] Property details: addresses, flat assessments, inventory lists
- [x] Payment information: transaction dates, amounts, card last-4 digits
- [x] Personal data about customer: preferences, communication history

**REDACT (Staff / Internal data — remove before delivery):**
- [ ] Agent names: e.g., "Alex York" → **[AGENT]**
- [ ] Staff email addresses: e.g., "jessica.g@anyvan.com" → **[REDACTED]**
- [ ] Internal employee IDs: e.g., "agent_jg_001" → **[REDACTED]**
- [ ] Driver names: from delivery notes → **[DRIVER]**
- [ ] Private assessments: internal property surveys → **[REDACTED]**
- [ ] Staff phone numbers: internal contact info → **[REDACTED]**
- [ ] Internal routing codes: ticket IDs, internal only → **[REDACTED]**

#### Redaction Examples

**Email Header:**
```
FROM: jessica.g@anyvan.com → FROM: [REDACTED]
TO: monibag2000@yahoo.com → TO: monibag2000@yahoo.com ✓ KEEP
SUBJECT: Assessment for Monika's flat → SUBJECT: Assessment for Monika's flat ✓ KEEP
```

**Call Recording Metadata:**
```
Agent: Alex York → Agent: [AGENT]
Agent Email: alex.y@anyvan.com → Agent Email: [REDACTED]
Recording ID: CA11263fdaaab499a5e2eefb18d67329af → [Redirect to Jiminny download link] ✓ KEEP (if necessary)
```

**Freshdesk Note:**
```
ORIGINAL:
"Jessica G reviewed the flat assessment on 2026-06-17. The property is 45m² with moderate clutter. 
We estimate 4 hours for removal. Spoke to Monika about schedule conflicts."

REDACTED:
"[AGENT] reviewed the flat assessment on 2026-06-17. The property is 45m² with moderate clutter. 
We estimate 4 hours for removal. Spoke to Monika about schedule conflicts."
```

#### Redaction Checklist

- [ ] All **email exports** reviewed:
  - Agent names: [AGENT]
  - Staff emails: [REDACTED]
  - Customer data: RETAINED
  
- [ ] All **Freshdesk notes** reviewed:
  - Staff names: [AGENT]
  - Staff emails: [REDACTED]
  - Internal routing: [REDACTED]
  - Customer data: RETAINED
  
- [ ] All **HubSpot notes** reviewed:
  - Agent names: [AGENT]
  - Agent emails: [REDACTED]
  - Customer data: RETAINED
  
- [ ] All **call recordings** metadata reviewed:
  - Agent names in metadata: [AGENT]
  - Agent IDs: [REDACTED]
  - Recording IDs: Include with disclaimer (Jiminny download link)
  
- [ ] **Video file** reviewed:
  - Filename: `Jiminny-Assessment-2026-06-17.mp4` (no PII in filename)
  - File metadata: Check no internal paths/IDs
  - Video content: Agent name [AGENT] when visible
  
- [ ] All **payment data** verified:
  - Amounts: RETAINED ✓
  - Dates: RETAINED ✓
  - Card last-4: RETAINED ✓
  - Processor IDs: [REDACTED]
  - Internal transaction IDs: [REDACTED]

#### Sign-Off
- [ ] Compliance Officer reviewed all files
- [ ] All redactions applied per rules above
- [ ] Signature: _________________________ Date: _________

---

### 2.6 Archive Creation & Encryption
**Status:** PENDING  
**Deadline:** 11 September 2026  
**Owner:** Operations team

#### Objective
Compile all redacted data into a secure encrypted archive ready for WeTransfer delivery.

#### Files to Include
- [ ] SAR cover letter (customer-facing introduction)
- [ ] Expanded SAR document (42 KB with all 13 sections)
- [ ] Call recordings metadata + Jiminny download instructions
- [ ] Freshdesk email export (plaintext)
- [ ] Freshdesk ticket notes (plaintext)
- [ ] HubSpot DEAL shared notes (plaintext)
- [ ] Payment transaction records (CSV/plaintext)
- [ ] Account preferences (plaintext)
- [ ] GDPR Article 15 Rights Notice (customer education)
- [ ] Video consultation file (MP4) — post-download from Jiminny
- [ ] README with file index and access instructions

#### Archive Format
- **Type:** ZIP archive
- **Encryption:** AES-256 (industry standard)
- **Compression:** ZIP (no additional compression needed for already-compressed media)
- **File name:** `SAR-Monika-Baginska-2026-09-14.zip` (include deadline date)
- **Size estimate:** ~500 MB – 1 GB (video file will dominate)

#### Tools
- **macOS:** `zip -e` command (AES-256 by default on modern systems)
- **Linux:** `7z a -tzip -mem=AES256` or `zip -e`
- **Windows:** Windows Defender or 7-Zip (AES-256 option)

#### Encryption Process
```bash
# Linux/macOS example:
zip -e SAR-Monika-Baginska-2026-09-14.zip \
  SAR-Cover-Letter.docx \
  SAR-Full-Document.docx \
  Call-Recordings-Metadata.txt \
  Freshdesk-Emails.txt \
  Freshdesk-Notes.txt \
  HubSpot-Notes.txt \
  Payments.csv \
  Account-Preferences.txt \
  GDPR-Article-15-Rights.pdf \
  Jiminny-Assessment-2026-06-17.mp4 \
  README.txt

# Prompt: Enter password (twice)
# Result: SAR-Monika-Baginska-2026-09-14.zip (encrypted, AES-256)
```

#### Password Requirements
- **Length:** Minimum 16 characters
- **Complexity:** Mix of uppercase, lowercase, digits, special characters
- **Format:** e.g., `Moni-SAR!2026-Sept14`
- **Storage:** Keep in secure location (password will be sent via SMS separately)
- **Expiry:** Valid until 14 September 2026; revoke if not used

#### Archive Verification
- [ ] File size reasonable (not 0 bytes)
- [ ] Test extraction with correct password
- [ ] Test extraction with wrong password (should fail)
- [ ] All files present in extracted archive
- [ ] File integrity check: HASH value recorded

#### Checklist
- [ ] Archive created and encrypted
- [ ] Password set and recorded securely
- [ ] Archive extracted and verified
- [ ] All files present and readable
- [ ] File hashes recorded (SHA-256)
- [ ] Ready for WeTransfer upload

---

### 2.7 WeTransfer Delivery Setup
**Status:** PENDING  
**Deadline:** 12 September 2026  
**Owner:** Operations team

#### WeTransfer Plus Configuration
- **Service:** WeTransfer Plus (secure, no free account sharing)
- **Encryption:** AES-256 (on top of archive encryption — defense in depth)
- **Expiry:** 7 days (automatic deletion post-expiry)
- **Download limit:** 5 downloads (sufficient for customer + backup)
- **Feature:** Custom download page with company branding (optional)

#### Upload Process
1. Log in to WeTransfer Plus account
2. Select file: **SAR-Monika-Baginska-2026-09-14.zip**
3. **Don't set password here** — use SMS for password delivery (separate from link)
4. Set expiry: 7 days from upload date
5. Set download limit: 5 downloads
6. Recipient: monibag2000@yahoo.com (primary) or monciab74@gmail.com (secondary)
7. Message: Standard SAR delivery message (see template below)
8. Upload and generate link

#### Message Template
```
Dear Monika,

Your Subject Access Request has been processed and is ready for download.

Link: [GENERATED_WEBTRANSFER_LINK]
Expiry: 7 days from today
Downloads: 5 permitted

Your password will be sent separately by SMS to 07881361498.

The archive contains:
- Full SAR document (42 pages)
- Call recordings (11 Twilio audio files)
- Video consultation (property assessment, 17 June 2026)
- Email correspondence (Freshdesk export)
- Payment records & account data
- GDPR Article 15 Rights Notice

This data is provided under UK GDPR Article 15 (Right of Access).

Best regards,
AnyVan Privacy & Compliance Team
```

#### Delivery Checklist
- [ ] Archive uploaded to WeTransfer Plus
- [ ] Link generated successfully
- [ ] Expiry set to 7 days
- [ ] Download limit set to 5
- [ ] Recipient email entered
- [ ] Custom message added (if required)
- [ ] Link tested in incognito/private browser window
- [ ] Link URL recorded (for SMS delivery)

---

### 2.8 Customer Delivery via SMS
**Status:** PENDING  
**Deadline:** 12 September 2026  
**Owner:** DPO / Compliance Officer (Anthony Hines)

#### SMS Password Delivery
- **Recipient:** 07881361498 (Monika's confirmed phone)
- **Content:** Download link + password, nothing else
- **Tone:** Professional, no PII in SMS body (password already in SMS)
- **Send time:** Business hours (09:00–17:00 UTC)

#### SMS Template
```
AnyVan Privacy: Your SAR is ready. 

Download: [WEBTRANSFER_LINK]
Password: [ARCHIVE_PASSWORD]

Expires in 7 days. Questions? Reply to this number.
```

#### Alternative: Customer Email Delivery
If SMS fails:
- Send email to monibag2000@yahoo.com (primary) or monciab74@gmail.com (secondary)
- Subject: **"Your AnyVan Subject Access Request — Download Ready"**
- Body: Link + password as above
- Cc: DPO / Compliance team for audit trail

#### Delivery Confirmation
- [ ] SMS sent successfully (delivery confirmation)
- [ ] Timestamp recorded
- [ ] Password acknowledged by customer (optional follow-up call)
- [ ] Request for download confirmation email (customer to confirm receipt)

---

## Section 3: PII Redaction Rules (Reference)

See **Section 2.5** above for detailed redaction instructions and examples.

---

## Section 4: Delivery & Verification Checklist

### Final 12-Point Verification

Before sending to customer, verify ALL of the following:

- [ ] **1. All files redacted** per PII rules (Section 2.5)
- [ ] **2. Archive encrypted** with AES-256
- [ ] **3. Archive password** set and recorded securely
- [ ] **4. WeTransfer link** generated and tested
- [ ] **5. Link expiry** set to 7 days
- [ ] **6. Download limit** set to 5 downloads
- [ ] **7. SMS password** ready to send (not in link, sent separately)
- [ ] **8. Video file** successfully downloaded from Jiminny and included
- [ ] **9. All call recordings** included (11 Twilio audio files)
- [ ] **10. Email threads** complete (Freshdesk export)
- [ ] **11. Shared notes** included (HubSpot + Freshdesk)
- [ ] **12. Compliance Officer sign-off** obtained (PII redaction review)

### Sign-Off
- [ ] Archive verified and ready for delivery
- [ ] Prepared by: _________________________ Date: _________
- [ ] Reviewed by: _________________________ Date: _________
- [ ] Approved by: _________________________ Date: _________

---

## Section 5: Timeline Summary & Key Contacts

### SLA Dates
| Date | Milestone | Owner | Status |
|---|---|---|---|
| **6 Sep** | Jiminny video lookup attempt | Operations | ⏳ |
| **7 Sep** | Video downloaded & verified | Operations | ⏳ |
| **8 Sep** | Freshdesk + HubSpot exports complete | Data teams | ⏳ |
| **9 Sep** | PII redaction review | Compliance | ⏳ |
| **10 Sep** | Archive created & encrypted | Operations | ⏳ |
| **11 Sep** | WeTransfer delivery setup | Operations | ⏳ |
| **12 Sep** | SMS password sent to customer | DPO | ⏳ |
| **14 Sep** | **GDPR Statutory Deadline** | — | ⏳ |

### Key Contacts

| Role | Contact | Purpose |
|---|---|---|
| **Privacy Officer / DPO** | Anthony Hines (anthony.hines@anyvan.com) | Overall SAR coordination, compliance approval, final sign-off |
| **Jiminny Admin** | [Internal IT / Jiminny account manager] | Platform access, video download support |
| **Freshdesk Admin** | [Support team lead] | Email & ticket export, shared notes retrieval |
| **HubSpot Admin** | [CRM team lead] | DEAL record access, shared notes extraction |
| **Operations Lead** | [Operations manager] | Archive creation, encryption, delivery coordination |
| **Compliance Lead** | Anthony Hines (anthony.hines@anyvan.com) | PII redaction review, final content approval |

---

## Governance Notes

**Record status:** This checklist is a living document for the in-flight SAR. Update Section 2 task status as each milestone completes. 

**Confidentiality:** Contains references to customer personal data (Monika's booking details, contact info, payment records). Access restricted to authorised AnyVan Privacy / Operations staff only. Commit only if absolutely necessary for knowledge transfer; prefer shared document in secure internal folder.

**Retention:** Keep in repository until SAR is delivered (14 September 2026). Post-delivery, retain in secure archive for 3 months (until mid-December 2026) per AnyVan's data retention policy, then securely delete.

**Related documents:**
- SAR record: `booking-lookups/2026-08-28-sar-monika-baginska-9454215-9555113.md`
- Jiminny lookup guide: `docs/conventions.md` (Section: Jiminny Video Lookup)
- SAR methodology: `booking-lookups/METHODOLOGY-communication-history.md`
- Privacy process: `docs/conventions.md` (all sections)

---

**Document version:** 1.0  
**Date created:** 2026-09-03  
**Last updated:** 2026-09-03  
**Prepared by:** Anthony Hines (anthony.hines@anyvan.com)  
**Status:** IN PROGRESS — Task 2.1 (Jiminny video lookup) currently active

---
