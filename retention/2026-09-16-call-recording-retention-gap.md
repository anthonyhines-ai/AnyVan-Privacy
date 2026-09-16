# Call-recording AUDIO retention gap — connected-call quantification (refined)

> ℹ️ **INTERNAL — COMMERCIAL IN CONFIDENCE. Contains no customer personal data.**
> Aggregate volume analysis only — **no customer PII**: no names, numbers, call/recording SIDs, or
> the Twilio Account SID (redacted as `<TWILIO_ACCOUNT_SID>` throughout — GitHub push protection
> blocks the raw `AC…` value). Figures are counts from read-only Snowflake `PRODUCTION` queries.
> Note that anything committed here persists in git history.

| | |
|---|---|
| **Record type** | Retention / data-loss quantification |
| **Date created** | 2026-09-16 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Data source** | Snowflake `PRODUCTION` (read-only) — `HARMONISED.PRODUCTION.TWILIO_CALL`, `MART_SALES_OPS.PRODUCTION.SOPHIE_CALLS_INCREMENTAL` |
| **Subject** | Volume of call-recording **audio** purged vs retained under the 3→12-month retention change (company-wide, aggregate) |
| **Status** | **Refined** (Snowflake dedup complete). **Twilio purge reconciliation OUTSTANDING** — needs Twilio account access (see §5) |

---

## 1. Summary

AnyVan's call-recording **audio** retention changed from **3 months to 12 months on 5 May 2026**.
A purge is irreversible, and a window extension only preserves recordings **still alive at the
switch**. So audio survives only for calls on/after the **survivor boundary (~5 Feb 2026 =
5 May − 3 months)**; everything earlier was already purged under the old 3-month rule.

This note quantifies the loss. Because there is **no recordings table in the warehouse** for the
affected period (see §5), we use a **proxy**: connected Twilio call legs
(`STATUS='completed' AND TRY_TO_NUMBER(DURATION) > 0`). The refinement below **de-duplicates**
that proxy to a per-conversation grain and reconciles it against Twilio.

**Headline (as at 2026-09-16):**

| Measure | Baseline (connected legs) | Refined (distinct conversations) | Change |
|---|--:|--:|--:|
| **Avoidable loss** — bucket B (a 12-month policy would still hold these) | **2,421,105** | **2,338,378** | **−82,727 (−3.4%)** |
| **Total purged** — buckets A + B (no audio survives) | **9,551,523** | **9,344,448** | **−207,075 (−2.2%)** |
| Retained — bucket C (audio held) | 5,152,035 | 4,928,062 | −223,973 (−4.4%) |

**So what:** parent-SID de-duplication moves the figures by only **2–4%**. The order of magnitude
and the business conclusion are **unchanged** — roughly **2.3–2.4M avoidable recording losses** and
**~9.3–9.5M total purged**. The dedup is small because **~70% of connected legs are single-leg
automated `outbound-api` calls** that never over-counted; only inbound→agent calls carry the
parent+child+transfer structure the dedup collapses. See §4.

**Two caveats that matter more than the dedup** (§5): (a) the proxy counts *legs*, not confirmed
*recording files* — the true file count can't be measured from the warehouse; (b) the purge itself
is **not yet confirmed** against Twilio. Both need Twilio account access to close.

---

## 2. The retention mechanics & the survivor boundary

```
        BUCKET A                         BUCKET B                    │      BUCKET C
  (aged out under 12mo too)         (AVOIDABLE loss)                 │   (audio retained)
◀───────────────────────┼──────────────────────────────────────┼───┼──────────────────▶
   … older calls      2025-09-16                            ~2026-02-05   2026-05-05   2026-09-16
                    12-month horizon                       survivor bdry  policy switch  today
                    (as at today)                          (switch − 3mo) (3mo → 12mo)  (analysis)
```

- **5 May 2026 — policy switch.** Audio retention 3 months → 12 months. Only recordings **still
  present** on this date gain the longer window.
- **~5 Feb 2026 — survivor boundary.** Under the old 3-month rule, anything older than 3 months on
  the switch date was already deleted. `5 May − 3 months ≈ 5 Feb 2026`. Calls **on/after** this date
  survived into the new regime; **earlier calls were already gone.** (Exact day depends on the purge
  job's cadence — treat as ~5 Feb.)
- **Bucket split (snapshot as at 2026-09-16):**

| Bucket | Call date window | Meaning |
|---|---|---|
| **A** | before **2025-09-16** | Purged, but **would age out under the 12-month policy anyway** — unavoidable. |
| **B** | **2025-09-16 → 2026-02-04** | Purged, but **within the 12-month window today** → a 12-month policy from the start would still hold these. **This is the avoidable loss.** |
| **C** | **2026-02-05** onward | After the survivor boundary → **audio retained.** |

This is a **moving snapshot**: as time passes the 12-month horizon rolls forward, so bucket A grows
and bucket B shrinks. The counts are fixed as at the analysis date.

---

## 3. The proxy and the three buckets (baseline)

**Proxy:** one connected call leg = one stand-in for a recording. A leg is "connected" when
`STATUS = 'completed'` and `TRY_TO_NUMBER(DURATION) > 0`. Bucketed on `START_TIME`.

| Bucket | Connected legs |
|---|--:|
| A — before 2025-09-16 | 7,130,418 |
| B — 2025-09-16 → 2026-02-04 (**avoidable**) | 2,421,105 |
| C — from 2026-02-05 (retained) | 5,152,035 |
| **Total purged (A+B)** | **9,551,523** |

These reproduce the original note's ~7.13M / ~2.42M / ~5.15M exactly, so the refinement below builds
on the same definition.

---

## 4. Addendum — dedup & Twilio reconciliation (part 1: parent-SID dedup)

### 4.1 Why connected legs over-count

One inbound customer call fans out into several legs — the inbound parent, each dial-to-agent child,
and each transfer — and every leg is a separate `TWILIO_CALL` row. Illustrative connected call
(11 Feb 2026): **1 inbound parent (1,384s) + 4 `outbound-dial` children** → 5 legs, **1 conversation**.

### 4.2 The dedup key

`TWILIO_CALL` columns inspected via `INFORMATION_SCHEMA` (read-only). Two candidate keys:

- **`PARENT_CALL_ID`** — the Twilio parent Call SID. Child legs carry it; a root leg has it `NULL`.
  → **conversation key = `COALESCE(PARENT_CALL_ID, ID)`.** *(Used.)*
- **`GROUP_ID`** — **empty in every bucket** (0 distinct values). Unusable. *(Rejected.)*

There is **no recording-SID column** on `TWILIO_CALL`, so a *distinct-recording-file* count cannot be
taken directly (see 4.4).

### 4.3 Buckets at distinct-conversation grain

`COUNT(DISTINCT COALESCE(PARENT_CALL_ID, ID))` over the connected-leg set:

| Bucket | Connected legs | Distinct conversations | Δ | Δ% |
|---|--:|--:|--:|--:|
| A | 7,130,418 | 7,006,070 | −124,348 | −1.7% |
| B — **avoidable** | 2,421,105 | 2,338,378 | −82,727 | **−3.4%** |
| C — retained | 5,152,035 | 4,928,062 | −223,973 | −4.4% |
| **Purged (A+B)** | **9,551,523** | **9,344,448** | **−207,075** | **−2.2%** |

### 4.4 Why the dedup is so small — leg composition

The over-count only exists on inbound→agent calls, and those are a minority of total volume. The bulk
is single-leg automated outbound (`outbound-api`), which is already 1 leg = 1 conversation:

| Bucket | Connected legs | `inbound` | `outbound-api` (single-leg) | `outbound-dial` (child) | child % |
|---|--:|--:|--:|--:|--:|
| A | 7,130,418 | 2,035,144 (28.5%) | 4,970,925 (**69.7%**) | 124,349 | 1.7% |
| B | 2,421,105 | 604,732 (25.0%) | 1,733,646 (**71.6%**) | 82,727 | 3.4% |
| C | 5,152,035 | 1,210,399 (23.5%) | 3,717,663 (**72.2%**) | 223,973 | 4.4% |

`outbound-dial` (the dial-to-agent/transfer child legs) is the *only* population the parent-SID dedup
removes — 1.7–4.4% of each bucket. Everything else is already at conversation grain.

### 4.5 Distinct-recording-**file** grain — bounded, not measured

The warehouse holds **no RecordingSids** for the purged period (§5), so the file count can only be
**bounded**, not counted:

- **Lower bound = distinct conversations** (one recording per conversation).
- **Upper bound = connected legs** (every connected leg separately recorded).
- **Central estimate ≈ conversations**, because multi-recording conversations (transfers, per-leg
  recording) are the same small `outbound-dial` minority (1.7–4.4%).

| Measure | Recording-file estimate (conversations … legs) |
|---|---|
| **Avoidable (B)** | **~2.34M – 2.42M** |
| **Total purged (A+B)** | **~9.34M – 9.55M** |

**Verdict on job 1:** the dedup is real but immaterial (2–4%). Report the avoidable loss as
**~2.34–2.42M** and the total as **~9.34–9.55M**. Distinct conversations (2,338,378 / 9,344,448) is
the best single point estimate.

---

## 5. Addendum (part 2: Twilio reconciliation) — **OUTSTANDING**

**Goal:** confirm the purge *actually ran to policy* — i.e. audio for pre-5-Feb-2026 connected calls
is **gone**, and audio for post-5-Feb-2026 calls **exists** — rather than inferring it from call
records. **Metadata ≠ content:** a `TWILIO_CALL` row persisting says nothing about whether its audio
survives (confirmed: the reference pre-boundary cohort — Freshdesk 2264362, 30 Jan 2026 — still shows
**2 connected legs in metadata** today, with **8–9 Feb 2026** legs as the retained control; the rows
persist regardless of the audio).

### 5.1 Why it could not be completed in-session

Every live-verification path was attempted and is blocked in this environment:

| Path | Result |
|---|---|
| In-session **Twilio MCP** | **Docs/API-schema search only** — cannot execute account calls (`retrieve` returns specs, `search` returns docs). |
| **Twilio REST API** (auth token / API key) | **No Twilio credential** present in the environment. |
| **S3** recording store (`s3://anyvan-twilio-recordings/…`) via env AWS creds | **Blocked** — STS `InvalidClientTokenId`; `head_object` → `403`. The ambient AWS creds are not scoped to the recordings bucket. |
| **Warehouse** RecordingSids for a pre-boundary sample | **None exist.** `SOPHIE_CALLS_INCREMENTAL` recording coverage starts **2026-06-11**; human-agent calls never carried RecordingSids in the warehouse (see `interaction-hub/2026-08-26-call-recording-playback-diagnosis.md`). No pre-boundary RecordingSid is obtainable without Twilio. |

So the **pre-boundary "is it actually gone?" check is impossible without Twilio account access.**

### 5.2 Runbook to close it (for whoever holds Twilio Console / API access)

Account: `<TWILIO_ACCOUNT_SID>` (the single `AC…` in `TWILIO_CALL.ACCOUNT_ID`; recoverable from the
Twilio Console / Flex Insights link — never commit the raw value).

1. **Pre-boundary cohort → expect PURGED.** Resolve the connected legs for the reference cohort
   (Freshdesk 2264362, **30 Jan 2026**; 2 legs confirmed in `TWILIO_CALL`). For each Call SID:
   `GET /2010-04-01/Accounts/<TWILIO_ACCOUNT_SID>/Calls/{CallSid}/Recordings.json`
   → **expect an empty list** (or the recording resource returns `404` / "deleted"). Console call log
   → recording panel should read *deleted*.
2. **Post-boundary cohort → expect RETAINED.** Same for the **8–9 Feb 2026** legs (2/day), **or** a
   recent Sophie RecordingSid from `SOPHIE_CALLS_INCREMENTAL` (≥ 11 Jun 2026):
   `GET .../Recordings/{RecordingSid}.json` → **expect `status=completed`**, media downloadable.
3. **Storage cross-check (optional).** Recordings live at
   `s3://anyvan-twilio-recordings/<TWILIO_ACCOUNT_SID>/{RecordingSid}`. `head-object` → pre-boundary
   **404**, post-boundary **200 `audio/x-wav`**.
4. **Record the AGGREGATE result here only** (e.g. "5/5 pre-boundary absent; 5/5 post-boundary
   present"). **Do not commit** RecordingSids, Call SIDs, the customer number, or the Account SID.

**Expected outcome if the purge ran to policy:** every pre-5-Feb sample **absent**, every post-5-Feb
sample **present** — which would validate the survivor-boundary model and the bucket split above. Any
pre-boundary sample that is *still present* would be a **finding** (purge did not run as expected).

---

## 6. What this means / recommended next steps

1. **The dedup does not change the decision.** Avoidable loss ≈ **2.34–2.42M**, total purged ≈
   **9.34–9.55M**. Use distinct conversations (2.34M / 9.34M) as the headline; the leg figure is a
   ≤4% over-count.
2. **The real unknowns are recording *coverage* and *purge confirmation*, not leg double-counting.**
   The warehouse cannot say which legs were actually recorded, nor prove the audio is gone. Close §5
   before treating any figure as audited.
3. **Structural fix (removes the guesswork permanently):** land RecordingSid↔CallSid into Snowflake
   (`HARMONISED.PRODUCTION.TWILIO_RECORDING_COMPLETED`, per the 26 Aug diagnosis). Then recording-file
   counts and purge status become directly queryable and this proxy retires.

---

## 7. Governance notes

- All queries were **read-only** `SELECT` against Snowflake `PRODUCTION` (`HARMONISED`,
  `MART_SALES_OPS`, `INFORMATION_SCHEMA`). No writes; no dev/staging.
- Contains **no customer PII** and **no secrets**. The Twilio Account SID is redacted
  (`<TWILIO_ACCOUNT_SID>`); no RecordingSids, Call SIDs, phone numbers, or names are committed.
- This repo captures the **analysis**; the data-protection **policy** and retention schedule live in
  AnyVan's internal policy systems — reference them, don't restate as fact.
- Figures are a **snapshot as at 2026-09-16** and shift as the 12-month horizon rolls forward.

---

## 8. Appendix — reproducible queries (read-only)

```sql
-- Baseline (connected legs) vs deduped (distinct conversations) per bucket
WITH c AS (
  SELECT COALESCE(PARENT_CALL_ID, ID) AS conv_key, START_TIME
  FROM HARMONISED.PRODUCTION.TWILIO_CALL
  WHERE STATUS = 'completed' AND TRY_TO_NUMBER(DURATION) > 0
)
SELECT
  CASE WHEN START_TIME < TIMESTAMP '2025-09-16' THEN 'A_pre16Sep2025'
       WHEN START_TIME < TIMESTAMP '2026-02-05' THEN 'B_avoidable'
       ELSE 'C_retained' END AS bucket,
  COUNT(*)                         AS connected_legs,
  COUNT(DISTINCT conv_key)         AS distinct_conversations
FROM c GROUP BY 1 ORDER BY 1;

-- Leg composition (why the dedup is small): direction split + child (outbound-dial) share
WITH c AS (
  SELECT PARENT_CALL_ID, DIRECTION, START_TIME
  FROM HARMONISED.PRODUCTION.TWILIO_CALL
  WHERE STATUS = 'completed' AND TRY_TO_NUMBER(DURATION) > 0
)
SELECT
  CASE WHEN START_TIME < TIMESTAMP '2025-09-16' THEN 'A'
       WHEN START_TIME < TIMESTAMP '2026-02-05' THEN 'B' ELSE 'C' END AS bucket,
  COUNT(*)                                                          AS connected_legs,
  SUM(IFF(DIRECTION='inbound',1,0))                                AS inbound_legs,
  SUM(IFF(DIRECTION='outbound-api',1,0))                           AS outbound_api_legs,
  SUM(IFF(PARENT_CALL_ID IS NOT NULL,1,0))                         AS child_legs
FROM c GROUP BY 1 ORDER BY 1;

-- GROUP_ID is empty (returns 0), so it cannot be a dedup key:
--   SELECT COUNT(DISTINCT GROUP_ID) FROM HARMONISED.PRODUCTION.TWILIO_CALL;  -- → 0

-- Sophie recording coverage window (why no pre-boundary RecordingSid is available):
SELECT MIN(EVENTTIMESTAMP) AS min_recsid_ts, MAX(EVENTTIMESTAMP) AS max_ts,
       COUNT(*) AS rows_total, COUNT(CASE WHEN RECORDINGSID ILIKE 'RE%' THEN 1 END) AS with_recsid
FROM MART_SALES_OPS.PRODUCTION.SOPHIE_CALLS_INCREMENTAL;   -- → coverage starts 2026-06-11
```

**Sources:** Snowflake `PRODUCTION` (read-only), queried 2026-09-16 —
`HARMONISED.PRODUCTION.TWILIO_CALL`, `MART_SALES_OPS.PRODUCTION.SOPHIE_CALLS_INCREMENTAL`,
`*.INFORMATION_SCHEMA`. Recording-storage mechanics per
`interaction-hub/2026-08-26-call-recording-playback-diagnosis.md` and
`docs/twilio-listing-call-lookup.md`.
