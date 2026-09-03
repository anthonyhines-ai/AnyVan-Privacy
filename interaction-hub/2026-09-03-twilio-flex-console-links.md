# Interaction Hub — Conversation ID + Twilio Flex & Console Deep-Links

> ℹ️ **INTERNAL — no customer data.** This note documents a dashboard build and its
> data lineage. It contains no phone numbers, names, or Twilio SIDs. The live dashboard
> shows personal data (numbers, conference/call SIDs) behind AnyVan SSO — handle per the
> data-protection policy; never paste real SIDs or the Twilio Account SID into this repo.

| | |
|---|---|
| **Record type** | Dashboard build / data-lineage note |
| **Date created** | 2026-09-03 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Surface** | Interaction Hub — https://dashboards.anyvan.com/operations/interaction-hub |
| **Data source** | `FCT_TWILIO_CALL_METRICS`, `TWILIO_EVENTS`, `TWILIO_FLEX_INSIGHTS_BI_TWILIO_TELEPHONY` (read-only, PRODUCTION) |
| **Subject** | Add the Conversation ID and Twilio Flex + Console links to the call detail |

---

## 1. What changed

In the call detail drawer (Calls tab **and** phone-lookup mode), each voice call now shows:

- **Conversation ID** — the Twilio **conference SID** (`CF…`) for the call.
- **▶️ Twilio Flex** — opens the call in **Flex Insights** (the conversation drill-down /
  playback), the "Copy link" reviewers use.
- **🖥️ Twilio Console** — opens the call in the **Twilio Console** call log.

Both are deep-links to *that* call. They render only for voice interactions and only when the
underlying id resolves, so WhatsApp/Live Chat rows and un-matched calls simply don't show them.

This replaces the previous behaviour where the **Interaction ID** field was itself a bare
hyperlink to the Console — the two links are now explicit, labelled buttons and the Conversation
ID is surfaced as its own value.

---

## 2. Data lineage (where each link comes from)

| Element | Admin (human-agent) calls | Sophie AI calls |
|---|---|---|
| Console link (`CA…` call SID) | `FCT_TWILIO_CALL_METRICS.CUSTOMERCALLSID` | `TWILIO_EVENTS.CALLSID` |
| Conversation ID (`CF…` conference SID) | `FCT_TWILIO_CALL_METRICS.CONFERENCESID` | — (not a Flex conference) |
| Flex Insights link | `TWILIO_FLEX_INSIGHTS_BI_TWILIO_TELEPHONY.CONVERSATION`, joined on `CONVERSATION_ATTRIBUTE_4 = CONFERENCESID` | — |

URL templates (built in SQL, so no secrets ship in the dashboard HTML):

```
Console : https://console.twilio.com/us1/monitor/logs/calls/{CALL_SID}
Flex    : read wholesale from the CONVERSATION column (already a full flex-insights-drilldown URL)
```

> **Why the Flex URL is read from the warehouse, not built.** The Flex drill-down URL embeds the
> Twilio **Account SID** (`AC…`), which GitHub push-protection blocks and which must never be
> committed. The warehouse already stores the complete URL in `CONVERSATION`, so the query returns
> it as data at run time and the HTML never constructs it.

The two hub queries were updated (additively) to emit three new columns —
`CONVERSATION_ID`, `TWILIO_CONSOLE_URL`, `TWILIO_FLEX_URL`:

- `interaction_hub_calls` → SQL v7
- `interaction_hub_phone_lookup` → SQL v8

The Flex link is a `LEFT JOIN` on the conference SID (deduped one row per conference via
`ANY_VALUE`), so it is 1:1 and cannot drop or fan out call rows.

---

## 3. Coverage & caveats

- **Flex Insights is a rolling ~7-week export** (verified 2026-07-15 → today). The 7-day Calls tab
  is fully covered; in phone-lookup mode, calls older than the window resolve a **Console** link
  but **no Flex** link. This is expected — degrade gracefully, don't treat as a fault.
- **Console link uses the customer leg** (`CUSTOMERCALLSID`) where present; the drawer falls back
  to the Interaction ID (worker leg) if the query value is absent, so the link keeps working.
- **AI (Sophie) calls** aren't Flex conferences — they carry a Console call SID but no conference
  SID and don't appear in Flex Insights, so only the Console button shows for them.
- **Transfers** are multi-leg: one customer call can span several conference legs. The link opens
  the leg tied to the row; other legs appear as their own rows.
- Verified populations (7-day window): Console ~99.98% of calls; Conversation ID ~100% of admin
  calls; Flex link ~98–99% of admin calls.

---

## 4. Governance notes

- **Read-only.** All Snowflake access for this build was `SELECT` against `PRODUCTION`; no writes.
- **No PII committed.** Verification used transient sample SIDs/suffixes that are recorded nowhere;
  this note and the dashboard HTML contain only URL templates and column names.
- **No secrets.** The Twilio Account SID is never hardcoded — the Flex URL comes from the
  `CONVERSATION` column at run time. Recordings/links stay behind AnyVan SSO.

## 5. Sources

- Reference build for the link patterns: [`sql/listing_calls_with_twilio_links.sql`](../sql/listing_calls_with_twilio_links.sql)
  and [`docs/twilio-listing-call-lookup.md`](../docs/twilio-listing-call-lookup.md).
- Prior hub diagnosis: [`interaction-hub/2026-08-26-call-recording-playback-diagnosis.md`](2026-08-26-call-recording-playback-diagnosis.md).
- AV Dashboards queries `interaction_hub_calls` (v7) and `interaction_hub_phone_lookup` (v8).
