# Call-Recording Retention Gap — Company-Wide Quantification

> ℹ️ **INTERNAL — contains no customer personal data.** Aggregate call-volume statistics only — no
> names, numbers, addresses, account IDs or recording references. Safe to share internally.

| | |
|---|---|
| **Record type** | Retention-gap analysis / governance note |
| **Date created** | 2026-09-16 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Data source** | Snowflake `PRODUCTION` (read-only) — `HARMONISED.PRODUCTION.TWILIO_CALL` |
| **Subject** | Impact of the call-recording retention change (3-month → 12-month, effective **5 May 2026**) on audio availability |

---

## 1. Context

Call-recording **audio** retention changed from **3 months** to **12 months** on **5 May 2026**.
Retention governs the **audio only** — call *metadata* (that a call happened, when, direction,
duration, agent, queue) lives in the warehouse and is not deleted by this policy. This note sizes how
much recorded-call audio is unrecoverable as a result, company-wide.

Prompted by a single-customer call lookup filed under `communication-lookups/` (Freshdesk ticket
`2264362`), where that customer's 30 Jan 2026 quote calls were found already purged.

---

## 2. Mechanism

A recording is purged once it exceeds the window in force, and **a purge cannot be undone**; extending
the window only preserves recordings **still alive at the switch**. So:

- A pre-5-May-2026 recording survives to today only if it was **< 3 months old on 5 May 2026** — i.e.
  the call was on/after **~5 Feb 2026** (the "survivor boundary").
- Anything earlier was already deleted under the 3-month rule before the window extended → **gone**.

The **avoidable** slice — recordings a 12-month policy would still hold *today* but which are gone — is
the window **[today − 12 months, 5 Feb 2026)**. It is **transient**: it shrinks each day and closes
completely on **~5 Feb 2027**, once everything the 12-month policy would keep is stuff we actually
retained.

---

## 3. Quantification (as at 2026-09-16)

**Proxy = connected Twilio call legs** (`STATUS='completed'` AND `DURATION > 0`). There is no
recording-inventory table in the warehouse, so this stands in for "a recording existed." Twilio records
per connected leg, so it is a reasonable **recording-file** proxy — but see caveats (§6): it **over-counts
distinct customer conversations**.

| Bucket | Connected call legs (≈ recordings) | Period |
|---|---|---|
| **B — avoidable loss** (12-mo policy *would still hold today*, but purged before the switch) | **~2.42M** (`2,421,105`) | 16 Sep 2025 → 4 Feb 2026 |
| A — would have aged out under 12 months anyway | ~7.13M (`7,130,418`) | 1 Apr 2021 → 15 Sep 2025 |
| C — retained (survived the switch) | ~5.15M (`5,152,035`) | 5 Feb 2026 → 15 Sep 2026 |

- **Avoidable loss ≈ 2.4M recordings** — the cost of the switch landing on 5 May rather than a year
  earlier.
- **Total unrecoverable pre-survivor-boundary ≈ 9.55M** (A + B), a rolling ~5-year backlog back to
  2021 — but ~7.1M of that (bucket A) would be gone under a 12-month policy regardless, so it is **not**
  attributable to the policy timing.

---

## 4. Monthly shape (connected call legs)

~520k connected legs/month; the avoidable window spans ~4.7 months.

| Month | Legs | | Month | Legs |
|---|---|---|---|---|
| 2025-06 | 420,036 | | 2025-12 | 469,785 |
| 2025-07 | 483,181 | | 2026-01 | 501,658 |
| 2025-08 | 495,034 | | 2026-02 | 532,931 |
| 2025-09 | 539,920 | | 2026-03 | 602,928 |
| 2025-10 | 557,450 | | 2026-04 | 596,755 |
| 2025-11 | 535,175 | | | |

*The avoidable gap (bucket B) runs from mid-Sep 2025 to early Feb 2026 — roughly Oct 2025–Jan 2026 in
full months plus the part-months either side.*

---

## 5. Two ways to read it

| Framing | Figure | Meaning |
|---|---|---|
| **Avoidable loss** (policy-timing cost) | **~2.4M** | Recordings a 12-month policy would still hold today; lost to the late switch. Heals ~5 Feb 2027. |
| **Operational blind spot** | **~9.5M** | We cannot produce audio for **any** call before ~5 Feb 2026 — a ~5-year backlog. Relevant to any historical SAR / dispute / legal-hold landing now. |

---

## 6. Caveats

- **Legs ≠ conversations.** Transfers and parent/child dial legs inflate the count; the reference
  lookup was 36 legs ≈ 30 recordings ≈ far fewer actual conversations. Treat 2.4M / 9.5M as a
  **recording-file upper bound** — distinct affected customers/conversations are materially lower. A
  parent-SID dedup would give the true figure (see §8, and the queued task).
- **Transient.** The 2.4M avoidable figure is a point-in-time snapshot; it shrinks daily and reaches
  **zero ~5 Feb 2027**.
- **Not reconciled against Twilio.** Derived from call records, not from Twilio's actual stored-recording
  inventory. The Twilio tooling available in-session is docs/API-schema search, not a live recordings
  client; confirmation that the purge ran as the policy implies needs a Flex/console (or Twilio API)
  reconciliation.
- **Proxy filter.** `completed` + `DURATION > 0` counts connected legs; it may include very short
  connects and excludes ring-only/no-answer legs (which were never recorded anyway).

---

## 7. SQL (reusable)

```sql
-- Buckets by retention logic. Today = 2026-09-16; 12-mo lookback = 2025-09-16; survivor boundary ~2026-02-05.
SELECT
  CASE
    WHEN START_TIME < '2025-09-16' THEN 'A_aged_out_anyway'
    WHEN START_TIME < '2026-02-05' THEN 'B_avoidable_gap'
    ELSE 'C_retained'
  END AS bucket,
  COUNT(*) AS connected_call_legs,
  MIN(START_TIME)::date AS first_call, MAX(START_TIME)::date AS last_call
FROM HARMONISED.PRODUCTION.TWILIO_CALL
WHERE STATUS='completed' AND TRY_TO_NUMBER(DURATION) > 0
GROUP BY 1 ORDER BY 1;

-- Monthly shape
SELECT DATE_TRUNC('month', START_TIME)::date AS mth, COUNT(*) AS connected_call_legs
FROM HARMONISED.PRODUCTION.TWILIO_CALL
WHERE STATUS='completed' AND TRY_TO_NUMBER(DURATION) > 0
  AND START_TIME >= '2025-06-01' AND START_TIME < '2026-05-01'
GROUP BY 1 ORDER BY 1;
```

---

## 8. Recommendations

1. **Refine the number with a parent-SID dedup** — collapse child dial/transfer legs to distinct
   conversations/recording files for a true count (queued as a follow-up task).
2. **Reconcile against Twilio.** Confirm the purge actually ran to the policy (survivor boundary
   ~5 Feb 2026) via the Flex/console or Twilio API, rather than inferring from call records.
3. **SAR / legal risk.** Document that audio for **any call before ~5 Feb 2026 is unrecoverable**;
   for any open dispute/SAR/legal-hold, export the retained audio now (it ages out at call-date + 12
   months) rather than relying on a HubSpot recording link, which persists after the file is purged.
4. **Retention-change checklist for next time.** A policy extension does not retro-rescue already-purged
   media; if future changes need historical coverage, pair them with a one-off export *before* the
   change. (Moot for this change — the pre-5-Feb-2026 media is already gone.)

---

## 9. Governance notes

- All Snowflake queries were **read-only** against `PRODUCTION`.
- This note contains **no customer personal data** — aggregate counts only.
- Figures are a warehouse-derived estimate (connected-leg proxy), pending the §8 dedup and Twilio
  reconciliation; treat as order-of-magnitude, not a reconciled recording ledger.
