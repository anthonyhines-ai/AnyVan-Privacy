# DSR Intake Form Handoff — Formstack form, request types & payload convention

> **Purpose:** define the **Formstack privacy-request form** that starts a DSR/SAR, the **request-type taxonomy**, the **JSON payload convention**, and the **Freshdesk custom-field (`cf_`) mapping** the workflow writes to. Companion to [`customer-communications-mapping.md`](customer-communications-mapping.md) and [`SAR-Comms-Lookup-Reference.md`](SAR-Comms-Lookup-Reference.md); the automation that consumes this is in [`dsr-privacy-request-workflow-design.md`](dsr-privacy-request-workflow-design.md).
>
> **⚠️ Status:** a privacy Formstack form / DSR workflow was reportedly built in a previous session, but **no export exists in this repo**. The field list below is the **target spec**; the **numeric `field_<NNN>` IDs are placeholders** — replace them with the live IDs (from `GET` the form or the `formstack_submission` tool output) before wiring the workflow. Same for the Freshdesk `cf_` names (look up via `GET /api/v2/ticket_fields`).

---

## 1. Why Formstack + why these fields

The submission fires `FORMSTACK_FORM_SUBMITTED`, which triggers the workflow. The form must capture enough to (a) **identify** the data subject, (b) **scope** the request (which channels, what dates), and (c) **route/verify** it. **Structured** channel and date fields (choice / date, not free text) keep the AI parse reliable and the audit defensible.

---

## 2. Form fields (target spec)

| # | Field label | Formstack `field_<NNN>` | `value_type` | Required | Notes |
|---|---|---|---|---|---|
| 1 | Full name | `field_AAAAAAA` | `name` | ✅ | Data subject's name |
| 2 | Email address | `field_BBBBBBB` | `text` | ✅ | Primary identifier; also default delivery address |
| 3 | Phone number | `field_CCCCCCC` | `text` | ➖ | Improves call/SMS/WhatsApp matching |
| 4 | Booking ref / listing ID | `field_DDDDDDD` | `text` | ➖ | `AV#######` or bare listing id; scopes to a booking |
| 5 | Request type | `field_EEEEEEE` | `choice` | ✅ | Multiselect — see §3 |
| 6 | Communications requested | `field_FFFFFFF` | `choice` | ✅ | Multiselect — see §4 |
| 7 | Date range — from | `field_GGGGGGG` | `text` (date) | ➖ | ISO `YYYY-MM-DD`; blank = all time |
| 8 | Date range — to | `field_HHHHHHH` | `text` (date) | ➖ | ISO `YYYY-MM-DD`; blank = today |
| 9 | Delivery email (if different) | `field_IIIIIII` | `text` | ➖ | Where the pack is sent; defaults to #2 |
| 10 | Proof of identity (upload) | `field_JJJJJJJ` | (file) | ➖ | For the stronger-verification path (§6); read via `formstack_upload` / `formstack_upload_interpret` |
| 11 | Declaration / consent | `field_KKKKKKK` | `choice` | ✅ | "I am the data subject (or authorised)" checkbox |

> `value_type` values match the `FORMSTACK_SUBMISSION_UPDATE` action's allowed set: `text | name | address | choice`.

---

## 3. Request-type taxonomy (field #5)

| Value | Meaning | v1 handling |
|---|---|---|
| `access` / `sar` | Copies of their personal data / communications | ✅ Automated assembly → officer sign-off → release |
| `portability` | Machine-readable export (CSV/JSON) | ✅ Same pipeline; emit the portability JSON (mapping doc §10) |
| `erasure` | Delete their data | ⚠️ **Higher-risk — no auto-action.** Route to officer; confirm-what-exists only |
| `rectification` | Correct their data | ⚠️ Route to officer; no auto-edit |
| `objection` / `restriction` | Object to / restrict processing | ⚠️ Route to officer; no auto-action |

v1 automates the **access / portability** path end-to-end (up to the human gate). The other types create the ticket + audit note and stop for the officer.

---

## 4. Communications requested (field #6) → sources

| Choice value | Resolves to (see mapping docs) |
|---|---|
| `all` | Every source below |
| `emails_transactional` | Spine + `EVENTS_MESSAGING_MESSAGE` (body 2026-05-19+) |
| `emails_marketing` | `HUBSPOT_EMAIL_CAMPAIGNS` (subject/metadata only) |
| `sms` | `LISTING_COMMUNICATION` `TOKENS.message` |
| `whatsapp` | `TWILIO_MESSAGE` + `TWILIO_CONVERSATION_MESSAGE` |
| `calls` | `AIRCALL_CALL` (recording URL) + Twilio SID → Flex download |
| `live_chat` | `TWILIO_CONVERSATION_MESSAGE` / LiveChat platform |

---

## 5. JSON payload convention

### 5.1 Intake payload (parsed from the submission by the workflow)
```json
{
  "request": {
    "formstack_submission_id": "123456789",
    "received_at": "2026-08-19T09:12:00+01:00",
    "request_types": ["access"],
    "channels": ["all"],
    "date_from": null,
    "date_to": null,
    "sla_due_date": "2026-09-19"
  },
  "data_subject": {
    "full_name": "…", "email": "…", "phone": "…",
    "booking_reference": "AV9541974", "delivery_email": "…"
  }
}
```

### 5.2 Output / portability payload
Emitted by the assembly step — the shape is defined once in [`customer-communications-mapping.md`](customer-communications-mapping.md) §10 (`export` + `data_subjects[].communications[]`, snake_case, ISO-8601). This doc does not duplicate it.

- `sla_due_date` = `received_at` + **1 calendar month** (UK GDPR statutory period).
- All timestamps **ISO-8601**; booking refs `AV#######`.

---

## 6. Identity verification (soft match + human sign-off)

The form's email/phone/listing are **claims, not proof**. The workflow **matches** them to the account (`v4_user_lookup` + identity queries) and records a match result, but **releases nothing automatically** — a privacy officer authorises before release. The optional ID upload (field #10) supports a **stronger** path later (`formstack_upload_interpret` vision-check vs the account). Full logic in the workflow-design doc §"Identity gate".

---

## 7. Freshdesk custom-field (`cf_`) mapping

> **⚠️ `cf_` keys are the lowercase internal names, NOT the labels** — look up real names via `GET /api/v2/ticket_fields`. Changing a field's **type** recreates it with a new `cf_` name. Send a Freshdesk **number** field with the typed form `{"cf_x":{"value":"…","type":"number"}}` (a plain string is rejected).

| Purpose | `cf_` key (placeholder) | Type | Source |
|---|---|---|---|
| Request type(s) | `cf_dsr_request_type` | text | intake `request_types` |
| Channels requested | `cf_dsr_channels` | text | intake `channels` |
| Formstack submission id | `cf_formstack_id` | number (typed) | `formstack_submission_id` |
| Data-subject email | `cf_dsr_subject_email` | text | `data_subject.email` |
| SLA due date | `cf_dsr_sla_due` | date | `sla_due_date` |
| Identity-match status | `cf_dsr_identity_match` | text | workflow match result |

Ticket also gets `tags: ["dsr","sar"]` and (recommended) a dedicated `group_id` for the privacy queue. Real ids/group to be filled at build.

---

## 8. Cross-references
- [`customer-communications-mapping.md`](customer-communications-mapping.md) · [`SAR-Comms-Lookup-Reference.md`](SAR-Comms-Lookup-Reference.md) · [`dsr-privacy-request-workflow-design.md`](dsr-privacy-request-workflow-design.md)

*Target spec drafted 2026-08-19 — replace `field_<NNN>` / `cf_` placeholders with live IDs before wiring the workflow.*
