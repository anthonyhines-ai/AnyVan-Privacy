# Personal-data incident assessment — Corrin Stansbie — `Listing 9593885 / Account 3609439`

> ⚠️ **CONFIDENTIAL — CONTAINS CUSTOMER PERSONAL DATA (PII).**
> This record contains customer names, phone numbers, email addresses, account and listing IDs, and a
> summary of an outbound message. Access is restricted to authorised AnyVan Privacy / Operations staff
> and must be handled in line with AnyVan's data protection policy and UK GDPR. Do not share outside
> the business. Anything committed here persists in git history — detail is deliberately minimised and
> the underlying investigation is held in the record cited in §7.

| | |
|---|---|
| **Record type** | Personal-data incident assessment (feeds the DPO breach-assessment form / register) |
| **Date created** | 2026-09-07 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Data source** | Prior investigation record (§7) · Snowflake `PRODUCTION` (read-only) · DPO determination (N. Scott, 2026-09-02) |
| **Subject** | Corrin Stansbie — AnyVan account `3609439` (`edwinastansbie@gmail.com`, current phone `07545703175`) |
| **Status** | **Reopened 2026-09-07** — customer rejected the response and **referred the matter to the ICO**. DPO to re-assess the not-a-breach determination against the customer's contentions (see §10) before any further response. |

---

## 1. Incident summary

On **21 Aug 2026**, an automated WhatsApp booking confirmation for Corrin Stansbie's home removal
(listing `9593885`) — including a link to view and manage the booking — was delivered to mobile number
`07736348212`. That number belongs to the customer's **son** and had been stored on the AnyVan account
as the contact number since **14 Oct 2018**. The customer reported this as a data breach, escalating on
24 Aug to a formal UK GDPR complaint alleging a security vulnerability ("password-free magic link"),
exposure of sensitive data, financial risk, and requesting a vulnerability statement and compensation,
with an intention to escalate to the ICO.

The **DPO has determined this is a data *incident*, not a personal-data breach** (see §5–§6): the
information was sent to a number the customer had herself previously provided as her contact number, no
processing/security control failed, and there is no residual risk now the account number is corrected.

---

## 2. Personal data involved & individuals affected

| | |
|---|---|
| **Categories of data** | Customer name; collection & delivery addresses; move date; item/inventory summary; booking reference; a link to view/manage the booking |
| **Special-category data** | None |
| **Payment data** | None disclosed — the manage-booking link does not reveal the account password or full stored card number |
| **Individuals affected** | **1** data subject (Corrin Stansbie) |
| **Recipient** | The customer's **son** — a family member the customer had previously nominated as the account contact number, **not an unknown third party** |
| **Volume / scale** | Single account, single message; not a systemic or multi-customer event |

---

## 3. Cause / root cause

- Outbound customer comms resolve the recipient from the **account-profile phone number**, not the
  number entered on the individual booking. Every booking artefact (quote, checkout, collection/delivery
  contact) held the **correct** number `07545703175`; the stale **2018 profile number** (`07736348212`)
  was used because that is what the profile carried.
- The 21 Aug booking was placed **signed out**, so it could not write back to the account profile. A
  later booking the same evening, placed **signed in**, updated the profile to `07545703175` — after the
  confirmation had already been sent.
- **Contributing factor (preventability):** in **March 2025** the son replied on WhatsApp that this was
  the wrong number and supplied the correct one. The account number was **not** updated at that point, so
  the August 2026 mis-send to the same number was foreseeable. See §8.

---

## 4. Containment & recovery

- Account primary contact number **corrected to `07545703175`** on 21 Aug 2026 (21:17 UTC), via the
  customer's own signed-in booking — no ongoing mis-routing from this cause.
- **No unauthorised change occurred.** The move completed as booked and the only edits ever made to
  listing `9593885` were the account holder's own (see §5, evidence).
- **Outstanding hardening (recommended, §8):** the son's legacy number is still linked to the account —
  retire/unlink it so it cannot be reused for comms.

---

## 5. Risk assessment (likelihood & severity of harm to the individual)

Evidence from Snowflake (read-only), listing `9593885`:

| Check | Result |
|---|---|
| Listing status | **Completed Paid** — completed 26 Aug 2026 11:59; provider allocated 24 Aug |
| Cancelled / frozen | No |
| Edits to the booking | **2 only**, both 23 Aug, both by **Corrin Stansbie** (account holder) — a volume/item change. No third-party, admin, date or address change |
| Net effect on the move | **None** — went ahead as scheduled |

| Dimension | Assessment |
|---|---|
| **Confidentiality** | Booking/move details seen by a **family member the customer had nominated** as her contact — low severity; not disclosure to an unknown party |
| **Integrity** | No unauthorised changes — evidenced above |
| **Availability** | No loss — move completed as booked |
| **Distress** | Customer reports anxiety/distress; acknowledged. No financial loss or service disruption crystallised |
| **Overall risk to rights & freedoms** | **Low** |

---

## 6. Notifiability decision

| Test | Determination |
|---|---|
| Is it a personal-data breach (Art. 4(12))? | **No** — DPO determination: a data *incident* (anomaly), not a security/processing failure |
| ICO notification (Art. 33 — risk to rights & freedoms)? | **No** — low risk; not notifiable |
| Data-subject notification (Art. 34 — high risk)? | **No** — not high risk (and the customer is already aware) |
| Logged on the incident register for accountability? | **Yes** — this record + the DPO breach-assessment form |

> **DPO determination (Neil Scott, 2026-09-02):** *"This is a data incident, it is not a data breach.
> We provided information to a number she previously provided as her contact number… merely an anomaly
> and not a processing / security issue… there is no residual risk now the phone number on the account
> has been updated."* Complete the breach-assessment form for audit/accountability and return for
> sign-off.

---

## 7. Response & remedy

- **Customer response:** **issued via Freshdesk on 2026-09-07** — a factual explanation of what
  happened (anomaly, not a breach/security issue), confirmation the account contact number has since
  been amended and the move completed with no unauthorised changes, and thanks for continued custom.
- **Goodwill:** **£25.00 account credit** (Operations Director decision — a credit, not a booking
  discount). Optional per the DPO; applied by way of goodwill for inconvenience, without admission of
  liability.
- **Underlying investigation** (identity resolution, full comms trace, number-provenance analysis):
  `communication-lookups/2026-08-24-comms-lookup-jonathanjamesstansbie-and-07736348212.md`.

---

## 8. Corrective actions / lessons

| # | Action | Owner | Type |
|---|---|---|---|
| 1 | **Act on inbound "wrong number" flags.** The number should have been corrected when the son flagged it in March 2025; don't rely solely on the customer re-saving via a signed-in booking | Operations / CS process | Data quality |
| 2 | **Retire/unlink the son's legacy number** from account `3609439` so it cannot be reused for comms | Operations | Containment |
| 3 | **Raise for review:** whether signed-out bookings should resolve comms from the **booking-entered** number rather than a stale profile number (the design point the customer raised) | Privacy by Design / Product | Design (to assess, not committed) |

---

## 9. Governance notes

- All Snowflake queries were **read-only** against `PRODUCTION`.
- This document contains PII — retain only as long as required for the incident/accountability record
  and dispose of / redact per policy when no longer needed.
- This repo captures the **record and decision**; the personal-data-breach register and retention
  schedule are the authoritative systems and live outside this repo. The DPO breach-assessment form is
  the sign-off artefact — this record supplies its content.

---

## 10. Addendum (2026-09-07) — customer rejection & ICO referral

The customer rejected the response and confirmed she has **referred the matter to the ICO**. The
assessment is **reopened** for DPO re-review. Her contentions, and how they bear on the not-a-breach
determination:

| # | Customer contention | Our position / what it changes |
|---|---|---|
| 1 | The booking captured her **correct** number (shown on the booking-confirmation **email**, sent without signing in); the actionable WhatsApp link was nonetheless routed to the **legacy** number | **Consistent with our data** — booking artefacts held `07545703175`; outbound comms resolved the recipient from the stale account-profile number. Strengthens her point that an actionable link went to the wrong number while the right one was on the booking |
| 2 | Disputes the legacy number was ever her account-holder contact; states `…3175` has always been hers as booker/account holder and `…8212` belonged to the person moved in 2018 | **Conflicts with `USER_PHONE_NUMBER`**, which records `…8212` as `IS_CONTACT` from 2018-10-14 and `…3175` added 2026-08-21. To be **reconciled**, not conceded |
| 3 | Concedes the link did **not** expose her password, but states it **permitted amendments to the booking capable of charging her card**; argues the risk existed even though no unauthorised change occurred | **Load-bearing and unverified.** If the manage-booking link permits chargeable amendments / discloses address + inventory to whoever holds it without re-authentication, this is an **unauthorised-disclosure** argument (Art. 4(12)) that the "no risk / not a breach" line does not fully answer. **Verify the link's actual capabilities.** |
| 4 | Privacy-by-design / safeguarding: an actionable link containing current address, destination address and inventory, sent to a stale/wrong number, could in a **domestic-abuse** scenario disclose a victim's new address to an abuser | **The strongest point.** A general design risk to rights & freedoms; the "no harm here" answer does not address it. Likely to weigh with the ICO |

**Implications**
- The **incident-not-breach** determination is now **contestable on confidentiality-disclosure grounds** (her personal data was made accessible to a third party via an actionable link). Defensible, but not safe — the ICO may take a different view.
- **DPO (Neil Scott) to re-assess** in light of §10 before any further response. Route the next response through the **ICO process**; no further direct rebuttal to the complainant pending DPO / Legal steer.

**Open verification (blocks the risk assessment)**
- Confirm exactly what the booking-management ("magic") link permits without re-authentication: view scope (address, destination, inventory), ability to make **chargeable** amendments, and cancellation. This determines whether a confidentiality/integrity breach is arguable.
