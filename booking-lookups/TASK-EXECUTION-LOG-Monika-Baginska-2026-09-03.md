# Task Execution Log — Monika J Bagińska SAR Operations
## Booking #9454215 · #9555113 | Date: 2026-09-03 | Deadline: 2026-09-14

> **STATUS:** Task 1 (Jiminny Video Lookup) — INITIATING  
> **DEADLINE:** 10 September 2026 (7 days remaining)

---

## Quick Reference

| Item | Value |
|---|---|
| **Customer** | Monika J Bagińska |
| **Email** | monibag2000@yahoo.com (primary) · monciab74@gmail.com (secondary) |
| **Phone** | 07881361498 · +447881361498 |
| **Bookings** | #9454215 (Home Removal) · #9555113 (Furniture Delivery) |
| **Video Date/Time** | 17 June 2026 ~14:30 UTC |
| **Statutory Deadline** | 14 September 2026 |
| **SLA Milestones** | Video: 10 Sep | Emails/Notes: 10 Sep | Redaction: 11 Sep | Archive: 11 Sep | Delivery: 12 Sep |

---

## TASK 1: Jiminny Video Consultation Lookup

**Status:** ⏳ INITIATING  
**Owner:** Operations team  
**Deadline:** 10 September 2026 (7 days)

### Summary
Locate and retrieve the video consultation recording from **17 June 2026 (~2:30 PM)** where Monika's flat was assessed for the Home Removal booking (#9454215).

### Critical Points

✅ **VALIDATED METHOD:** Jiminny UI email search  
✓ Ground truth: Booking #9615866 (video found via email search in Jiminny UI, recorded by agent Alex York)  
✓ This is the ONLY reliable method — Snowflake has NO Jiminny data

❌ **DO NOT:** Try Snowflake queries, assume data is in any data warehouse, or search by internal IDs first

### Step-by-Step Execution

#### Phase 1: Access Jiminny (Today — 2026-09-03)

1. **Log in to Jiminny platform**
   - URL: [Internal Jiminny platform]
   - Credentials: AnyVan staff login
   - Navigate to: **Calls**, **Recordings**, or **Search** section

2. **Initial Search**
   - Click **Search** or **Filter** in Calls/Recordings view
   - Enter customer email: **monibag2000@yahoo.com**
   - Press Search (do NOT filter by date yet)
   - Review full list of all calls/videos for this email

3. **Locate Target Video**
   - Look for entry matching these criteria:
     - ✓ Date: **17 June 2026** (or very close, ±1 day acceptable)
     - ✓ Time: **~14:30 UTC** (±15 minutes acceptable window: 14:15–14:45)
     - ✓ Type: **"Video"** (NOT "Voice Call", "Audio", or "Phone")
     - ✓ Call type/subtype: Should show "Assessment", "Consultation", "Video Tour", or similar
     - ✓ Duration: **15–60 minutes** (typical flat assessment)
     - ✓ Status: **"Completed"** or **"Finished"** (not in-progress or failed)

4. **Verify Correct Call**
   - Click on the matching entry to view full details
   - Confirm:
     - ✓ Customer name: **Monika J Bagińska**
     - ✓ Customer email: **monibag2000@yahoo.com** (or monciab74@gmail.com)
     - ✓ Date/time: **17 June 2026 ~14:30 UTC**
     - ✓ Type: **Video** (clearly marked as video, not audio)
     - ✓ Duration: Reasonable for assessment (check exact length)
   - Check call notes/summary for: "flat", "assessment", "property tour", "inventory", "removal quote"

#### Phase 2: Download Video File (2026-09-04 to 2026-09-05)

5. **Initiate Download**
   - Click **Download** or **Export** button on the verified call
   - Choose file format:
     - **Recommended:** MP4 (most widely compatible)
     - Alternative: MOV (Apple format)
     - Last resort: Jiminny default format (proprietary)
   - Start download

6. **Save to Secure Location**
   - Save to **password-protected company network folder** (NOT personal device, NOT public cloud)
   - File name: `Jiminny-Assessment-Monika-2026-06-17.mp4` (or appropriate extension)
   - Document full file path: `___________________________`
   - Record file size: `______________ MB`
   - Record exact duration: `__m __s` (from Jiminny metadata)

7. **Verify File Integrity**
   - Open in media player (VLC, QuickTime, Windows Media Player)
   - Confirm:
     - ✓ Video plays without errors
     - ✓ Audio is clear and audible (customer + agent identifiable)
     - ✓ Content shows property/flat tour or assessment context
     - ✓ Duration matches Jiminny entry
     - ✓ File size is reasonable (typically 200–500 MB for 20–45 min video)

#### Phase 3: Metadata Documentation (2026-09-05)

8. **Record Video Metadata**
   - [ ] Jiminny Agent Name: _______________________ (e.g., "Alex York")
   - [ ] Date Recorded: **2026-06-17**
   - [ ] Time Recorded: **~14:30 UTC** (approx. from Jiminny)
   - [ ] Call Type: **Video**
   - [ ] Duration (exact): **__m __s**
   - [ ] File Format: **MP4 / MOV / [other]**
   - [ ] File Size: **____ MB**
   - [ ] Storage Location: **[Secure folder path]**
   - [ ] Download Status: ✓ Completed
   - [ ] Playback Verified: ✓ Yes / ❌ No (if no, describe issue)
   - [ ] Audio Quality: ✓ Clear / ❌ Unclear (if unclear, describe)
   - [ ] Content Context: ✓ Property assessment visible / ❌ Not visible

### If Video NOT Found in Jiminny

**Escalation Path (in order):**

1. **Alternative Jiminny Search (2026-09-04)**
   - Try search by phone: **07881361498** or **+447881361498**
   - Try search by booking reference: **9454215**
   - Try browse by agent name (if known from HubSpot booking notes)

2. **If Still Not Found (2026-09-05)**
   - Contact: **Jiminny Admin** [internal contact]
   - Question: "Do you have a video consultation recorded for customer Monika J Bagińska (07881361498) on 17 June 2026 ~14:30?"
   - Provide booking reference: **AV9454215**

3. **Fallback Locations (2026-09-06)**
   - [ ] **Interaction Hub** — Contact Operations/Assessments lead
     - Question: Is there a video assessment for booking #9454215 in Interaction Hub?
   - [ ] **Google Drive** — Search for: "Monika" OR "9454215" OR "07881361498" (date: June 2026)
     - Look under: "Customer Assessments", "Property Surveys", "Video Consultations"
   - [ ] **WeTransfer / Secure Share** — Check AnyVan emails from June 2026
     - Look for: WeTransfer links sent from AnyVan to customer
   - [ ] **Third-party Assessment Tool** — Check HubSpot booking #9454215 notes
     - Look for: Tool name (Robinhood, Tradify, etc.)
     - Contact tool provider for export

### Success Criteria

Video lookup is **COMPLETE** when:

- [x] Video file is downloaded to secure location
- [x] File plays without errors
- [x] Date, time, and content match expected assessment (flat tour, property discussion)
- [x] Audio is clear (customer and agent identifiable)
- [x] Duration is reasonable for assessment (15–60 minutes)
- [x] Metadata fully logged (agent name, timestamp, file size, storage path)
- [x] PII redaction plan documented (agent name will be redacted as [AGENT])
- [x] File ready for encryption and WeTransfer delivery

### Sign-Off

- [ ] Video located: ✓ Yes / ❌ No (date: __________)
- [ ] File downloaded: ✓ Yes / ❌ No (date: __________)
- [ ] File verified: ✓ Yes / ❌ No (date: __________)
- [ ] Metadata recorded: ✓ Yes / ❌ No
- **Responsible team member:** _________________________ **Date:** __________
- **Reviewed by:** _________________________ **Date:** __________

---

## TASK 2: Freshdesk Email Export

**Status:** ⏳ PENDING (Start: 2026-09-04)  
**Owner:** Freshdesk admin  
**Deadline:** 10 September 2026 (7 days)

### Quick Summary
Export all customer-facing email threads from Freshdesk for bookings #9454215 and #9555113, date range 1 June – 28 August 2026.

### Search Criteria
- **Customer email:** monibag2000@yahoo.com (primary) or monciab74@gmail.com (secondary)
- **Booking references:** AV9454215, AV9555113
- **Phone number:** 07881361498 or +447881361498
- **Date range:** 1 June 2026 – 28 August 2026
- **Include:** Customer-facing threads (agent ↔ customer dialogue)
- **Exclude:** Internal emails, staff-only notes, private Freshdesk notes

### Execution Checklist
- [ ] Access Freshdesk admin panel
- [ ] Search by primary email: **monibag2000@yahoo.com**
- [ ] Search by secondary email: **monciab74@gmail.com**
- [ ] Search by booking refs: **AV9454215**, **AV9555113**
- [ ] Apply date filter: **1 June 2026 – 28 August 2026**
- [ ] Export format: **Plaintext or HTML** with timestamps, sender, recipient, subject, body
- [ ] Remove: Agent emails (→ [REDACTED]), agent names (→ [AGENT])
- [ ] Keep: Customer data (names, phone, email)
- [ ] Save to secure location
- [ ] File name: `Freshdesk-Emails-Monika-Baginska-2026-06-01-2026-08-28.txt`
- [ ] Verify: Count of email threads exported
- [ ] Document: Number of emails and key dates in Section 5 below

---

## TASK 3: HubSpot Shared Notes Extraction

**Status:** ⏳ PENDING (Start: 2026-09-04)  
**Owner:** Operations / HubSpot admin  
**Deadline:** 10 September 2026 (7 days)

### Scope: DEAL Records Only

| Deal Type | HubSpot Deal ID | Booking ID |
|---|---|---|
| Home Removal | 60955982356 | 9454215 |
| Furniture Delivery | 14842423123 | 9555113 |

### Content Rules

**INCLUDE (shared/customer-relevant):**
- ✓ Booking status updates
- ✓ Customer service interactions
- ✓ Service requests and accommodations
- ✓ Issue resolution logs
- ✓ Delivery/pickup notes visible to customer

**EXCLUDE (internal/private):**
- ✗ Private staff assessments
- ✗ Performance reviews or internal evaluations
- ✗ Sensitive internal decision logs
- ✗ Staff-only troubleshooting notes

### Execution Checklist
- [ ] Access HubSpot → Deals section
- [ ] Open Deal ID: **60955982356** (Home Removal)
- [ ] Extract shared notes only (filter out private notes)
- [ ] Open Deal ID: **14842423123** (Furniture Delivery)
- [ ] Extract shared notes only (filter out private notes)
- [ ] Export format: **Text or CSV** with timestamp, note author (redact), note text
- [ ] Redaction: Agent names → [AGENT], agent emails → [REDACTED]
- [ ] Save to secure location
- [ ] File name: `HubSpot-Notes-Deals-60955982356-14842423123-2026-09-03.txt`
- [ ] Verify: Note count and completeness

---

## TASK 4: Freshdesk Ticket Shared Notes

**Status:** ⏳ PENDING (Start: 2026-09-04)  
**Owner:** Freshdesk admin  
**Deadline:** 10 September 2026 (7 days)

### Execution Checklist
- [ ] Access Freshdesk admin panel
- [ ] Search for tickets by customer email: **monibag2000@yahoo.com**
- [ ] Search by booking refs: **AV9454215**, **AV9555113**
- [ ] Date range: **1 June 2026 – 28 August 2026**
- [ ] Extract: Shared (customer-visible) notes only
- [ ] Exclude: Private Freshdesk-internal notes
- [ ] Export format: **Text** with timestamp, ticket ID, note text
- [ ] Redaction: Staff names → [AGENT], staff emails → [REDACTED]
- [ ] Save to secure location
- [ ] File name: `Freshdesk-Notes-Monika-Baginska-2026-09-03.txt`
- [ ] Verify: Ticket count and note completeness

---

## TASK 5: PII Redaction Review

**Status:** ⏳ PENDING (Start: 2026-09-09)  
**Owner:** Compliance Officer (Anthony Hines)  
**Deadline:** 11 September 2026 (8 days)

### PII Redaction Rules (Reference)

**RETAIN (Customer data):**
- ✓ Customer name: Monika J Bagińska
- ✓ Customer emails: monibag2000@yahoo.com, monciab74@gmail.com
- ✓ Customer phone: 07881361498
- ✓ Booking refs: AV9454215, AV9555113
- ✓ Property details: addresses, flat assessments, inventory
- ✓ Payment info: amounts, dates, card last-4

**REDACT (Staff/Internal data):**
- ✗ Agent names: e.g., "Alex York" → **[AGENT]**
- ✗ Staff emails: e.g., "jessica.g@anyvan.com" → **[REDACTED]**
- ✗ Employee IDs: e.g., "agent_jg_001" → **[REDACTED]**
- ✗ Driver names: → **[DRIVER]**
- ✗ Private assessments: → **[REDACTED]**
- ✗ Staff phone numbers: → **[REDACTED]**

### Execution Checklist
- [ ] Review email export: Redact agent names/emails
- [ ] Review Freshdesk notes: Redact staff personal info
- [ ] Review HubSpot notes: Redact agent names/emails
- [ ] Review payment data: Confirm card last-4 retained
- [ ] Review video metadata: Agent name will be redacted in archive
- [ ] Final review: All redactions applied consistently
- **Sign-off:** _________________________ **Date:** __________

---

## TASK 6: Archive Creation & Encryption

**Status:** ⏳ PENDING (Start: 2026-09-10)  
**Owner:** Operations team  
**Deadline:** 11 September 2026 (8 days)

### Files to Include
- [ ] SAR cover letter (customer-facing intro)
- [ ] Expanded SAR document (13 sections, ~42 KB)
- [ ] Call recordings metadata
- [ ] Video consultation file (MP4 from Jiminny)
- [ ] Freshdesk email export
- [ ] Freshdesk ticket notes
- [ ] HubSpot DEAL shared notes
- [ ] Payment transaction records
- [ ] Account preferences
- [ ] GDPR Article 15 Rights Notice
- [ ] README with file index

### Archive Specification
- **Type:** ZIP archive
- **Encryption:** AES-256 (industry standard)
- **File name:** `SAR-Monika-Baginska-2026-09-14.zip`
- **Size estimate:** 500 MB – 1 GB (video-dependent)
- **Password:** [Secure, 16+ chars, mix case/digits/symbols]

### Execution Checklist
- [ ] All files redacted per PII rules
- [ ] Archive created and encrypted with AES-256
- [ ] Password set and recorded securely
- [ ] Archive tested: Extract with correct password ✓
- [ ] Archive tested: Extract with wrong password fails ✓
- [ ] All files present in extracted archive
- [ ] File integrity verified (SHA-256 hash recorded)
- **Ready for delivery:** _________________________ **Date:** __________

---

## TASK 7: WeTransfer Delivery Setup

**Status:** ⏳ PENDING (Start: 2026-09-11)  
**Owner:** Operations team  
**Deadline:** 12 September 2026 (9 days)

### WeTransfer Plus Configuration
- **Service:** WeTransfer Plus (secure, no free account)
- **Encryption:** AES-256 (on top of archive encryption)
- **Expiry:** 7 days (auto-delete post-expiry)
- **Download limit:** 5 downloads
- **Recipient:** monibag2000@yahoo.com

### Execution Checklist
- [ ] Log in to WeTransfer Plus account
- [ ] Select file: `SAR-Monika-Baginska-2026-09-14.zip`
- [ ] Set recipient: monibag2000@yahoo.com
- [ ] Set expiry: 7 days
- [ ] Set download limit: 5 downloads
- [ ] Do NOT set password in WeTransfer (will send via SMS separately)
- [ ] Upload file
- [ ] Generate download link
- [ ] Test link in private/incognito browser
- [ ] Record link URL: _________________________________
- **Ready for SMS delivery:** _________________________ **Date:** __________

---

## TASK 8: Customer Delivery (SMS Password)

**Status:** ⏳ PENDING (Start: 2026-09-12)  
**Owner:** DPO / Compliance Officer  
**Deadline:** 12 September 2026 (9 days)

### SMS Template
```
AnyVan Privacy: Your SAR is ready. 

Download: [WEBTRANSFER_LINK]
Password: [ARCHIVE_PASSWORD]

Expires in 7 days. Questions? Reply.
```

### Execution Checklist
- [ ] Compose SMS with WeTransfer link + archive password
- [ ] Send to: **07881361498** (Monika's confirmed phone)
- [ ] Send time: Business hours (09:00–17:00 UTC)
- [ ] Record: Delivery timestamp
- [ ] Request: Customer reply confirming receipt (optional follow-up call)
- **Sent:** _________________________ **Date/Time:** __________

---

## Section 5: Daily Progress Log

| Date | Task | Owner | Status | Notes |
|---|---|---|---|---|
| **2026-09-03** | 1. Jiminny video lookup — INITIATING | Ops | ⏳ START | Instructions provided; searching Jiminny UI by email |
| | | | | |
| **2026-09-04** | 1. Jiminny video — Search & download | Ops | ⏳ | Follow Phase 1–2 steps; save file to secure location |
| | 2. Freshdesk email export — START | Freshdesk | ⏳ | Search by email/booking ref; apply date filter 1 Jun–28 Aug |
| | 3. HubSpot notes — START | HubSpot | ⏳ | Extract Deal IDs 60955982356 & 14842423123 (shared notes only) |
| | | | | |
| **2026-09-05** | 1. Jiminny video — Verify file | Ops | ⏳ | Confirm playback, audio quality, duration matches |
| | 1. Jiminny video — Document metadata | Ops | ⏳ | Record agent name, timestamp, file size, storage path |
| | 2. Freshdesk — Complete export | Freshdesk | ⏳ | Finalize email export; apply redaction rules (agent emails → [REDACTED]) |
| | | | | |
| **2026-09-06** | 3. HubSpot notes — Complete export | HubSpot | ⏳ | Finalize shared notes extraction; redact agent names/emails |
| | 4. Freshdesk ticket notes — START | Freshdesk | ⏳ | Search by customer email; extract shared notes only (exclude private) |
| | | | | |
| **2026-09-08** | 4. Freshdesk ticket notes — Complete | Freshdesk | ⏳ | Finalize ticket notes export; apply redaction |
| | | | | |
| **2026-09-09** | 5. PII Redaction Review — START | Compliance | ⏳ | Review all exports; apply redaction rules consistently |
| | | | | |
| **2026-09-10** | 5. PII Redaction Review — COMPLETE | Compliance | ⏳ | Final sign-off; all PII redacted per rules |
| | 6. Archive Creation — START | Ops | ⏳ | Create ZIP with AES-256 encryption; set password |
| | 6. Archive Creation — COMPLETE | Ops | ⏳ | Test extraction; verify all files present; record hash |
| | | | | |
| **2026-09-11** | 7. WeTransfer Delivery — SETUP | Ops | ⏳ | Upload archive; generate link; test link in incognito window |
| | | | | |
| **2026-09-12** | 8. Customer Delivery — SMS Password | DPO | ⏳ | Send SMS with link + password to 07881361498 |
| | | | | |
| **2026-09-14** | **GDPR STATUTORY DEADLINE** | — | ⏳ | Confirmation of customer receipt expected by this date |

---

## Key Contacts

| Role | Name / Team | Contact |
|---|---|---|
| **Privacy Officer / DPO** | Anthony Hines | anthony.hines@anyvan.com |
| **Jiminny Admin** | [Internal IT] | [internal contact] |
| **Freshdesk Admin** | [Support team lead] | [internal contact] |
| **HubSpot Admin** | [CRM team lead] | [internal contact] |
| **Operations Lead** | [Operations manager] | [internal contact] |
| **Compliance** | Anthony Hines | anthony.hines@anyvan.com |

---

## Governance & Retention

**Record status:** Living task execution log for in-flight SAR (2026-09-03 to 2026-09-14).

**Confidentiality:** Contains references to customer personal data (Monika's contact info, booking details). Access restricted to authorised AnyVan Privacy / Operations staff only.

**Retention:** Keep until SAR is delivered (14 September 2026). Post-delivery, retain in secure archive for 3 months, then securely delete.

---

**Document version:** 1.0  
**Date created:** 2026-09-03  
**Last updated:** 2026-09-03  
**Prepared by:** Anthony Hines (anthony.hines@anyvan.com)  
**Status:** IN PROGRESS — Task 1 (Jiminny video lookup) actively executing

---
