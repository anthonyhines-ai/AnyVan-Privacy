# Editing the Interaction Hub dashboard — read this first

**Dashboard:** https://dashboards.anyvan.com/operations/interaction-hub (path `operations/interaction-hub`)
**Stack:** a single static HTML page on S3 that renders Snowflake query results via the AV Dashboards platform (`AVDashboard.runQuery`). Edited through the **AV Dashboards MCP**.

## ⚠️ The one rule: always edit from the LIVE version

Before making any change, fetch the current live HTML and edit **that**:

```
get_dashboard_html("operations/interaction-hub")
```

**Never rebuild the page from an older or local copy.** This dashboard changes often, and a rebuild from a stale base silently drops whatever was added since. This has already bitten us once: a rebuild between ~10–15 Sep 2026 dropped the LiveChat/WhatsApp **Status** badges (the query still returned the data; the render was just gone). If you start from the live HTML every time, features stay intact.

## Publish flow (the HTML is >40KB)

`update_dashboard` truncates payloads over ~40KB — **do not use it.** Publish via the direct Upload API:

1. `get_upload_token` → short-lived JWT (valid 5 min).
2. `PUT https://63g6ly45b0.execute-api.eu-west-1.amazonaws.com/production/upload`
   with `Authorization: Bearer <jwt>`, `Content-Type: application/json`, body:
   `{ "html": "...", "path": "operations/interaction-hub", "title": "AnyVan | Interaction Hub", "query_ids": [ ... ] }`
3. **Re-enumerate `query_ids` from the live HTML every time** (grep `runQuery('...')` + the tab-query map) so you never drop a tab's query access. Missing a query id breaks that tab.

Every publish is auto-versioned, so any change is one rollback away.

## Where feature logic lives

- **Query data** (per-dashboard pinned SQL) is edited with `update_query(query_id, sql_text, dashboard_id="operations/interaction-hub", change_summary=...)`. This pins the dashboard to the new SQL version; other dashboards sharing the query are unaffected.
- **Rendering** lives in the HTML/JS. A feature usually = a query change (data) **+** an HTML change (render). Losing one half silently degrades the feature.

## Current features a rebuild must preserve

- Tabs: **Calls · LiveChat · WhatsApp · Emails · SMS**, plus the customer **identity lookup**.
- **Emails** tab categories: All · Marketing · Transactional · **Operational (Freshdesk)**. Operational is a live, customer-scoped Freshdesk **ticket list** (`interaction_hub_freshdesk`), scoped by the customer's listings.
- **LiveChat & WhatsApp Status badge** — 🟢 Active / ⚪ Closed / — Unknown, from `CHAT_STATE` (a `TWILIO_CONVERSATION.STATE` join in the pinned query). The LiveChat/WhatsApp queries also use a **case-insensitive** Sophie filter (`TYPE ILIKE '%sophie%'`) so `sophie_webchat` LiveChats are not dropped.
- Redacted, customer-ready transcript export; native in-drawer transcripts; per-row deep links (Admin listing, Freshdesk ticket, Twilio/Flex).

## The 11 queries this dashboard uses (as of 15 Sep 2026)

`interaction_hub_calls`, `interaction_hub_livechat`, `interaction_hub_whatsapp`,
`interaction_hub_identity_lookup`, `interaction_hub_identity_profile`,
`interaction_hub_conversation_transcript`, `interaction_hub_email_kpis`,
`interaction_hub_emails`, `interaction_hub_email_body`, `interaction_hub_sms`,
`interaction_hub_freshdesk`.

> Tip: after any publish, re-fetch the live HTML and `grep` for your change's markers to confirm it took. A quick JS syntax check (compile each inline `<script>`) before publishing avoids shipping a broken page.
