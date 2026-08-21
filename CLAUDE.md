# CLAUDE.md

## Repository Overview

This repo contains AnyVan operational dashboard HTML files (used with the AV Dashboards platform) and related privacy/data tooling.

## AV Dashboards Platform

- Dashboards are single HTML files that use the `AVDashboard` client library (`https://assets.anyvan.com/av-dashboards/av-dashboard.js`)
- Queries are managed separately via the AV Dashboards MCP tools (`mcp__AV_Dashboards__*`)
- Query changes must be **pinned** to the dashboard using `update_query` with both `query_id` and `dashboard_id`
- Dashboard HTML is deployed via `update_dashboard` (existing) or `upload_dashboard` (new) — the **full HTML must be passed inline**; there is no file-path option

### `runQuery` — the parameter contract (READ THIS FIRST)

The client signature is `AVDashboard.runQuery(query_name, options)`. **Bind parameters MUST be nested under `options.parameters`** — the library only reads `options.parameters` (confirmed in `av-dashboard.js`: `o.parameters && (n.parameters = o.parameters)`).

```javascript
// ✅ CORRECT — params bind to :email / :phone_suffix server-side
await AVDashboard.runQuery('sar_customer_profile', { parameters: { email: x } });
await AVDashboard.runQuery('interaction_hub_phone_lookup', { parameters: { phone_suffix: s, days: 30 } });

// ❌ WRONG — a flat object is IGNORED; :email is never bound; Snowflake returns
//    HTTP 500 "Query execution failed" for EVERY parameterised query.
await AVDashboard.runQuery('sar_customer_profile', { email: x });
```

Other `options`: `freshness` (cache TTL seconds), `dashboardId` (defaults to the page path).

Auth + init (call once, before any `runQuery`):
```javascript
await AVDashboard.ensureAuthenticated();
await AVDashboard.init();
```

### Query pinning / `query_ids` — what actually matters

- `runQuery` auto-derives `dashboard_id` from the page path, so **query pinning is automatic** — the dashboard runs its pinned SQL version. You do **not** need to pass `query_ids` to `update_dashboard` for queries to execute (it is not the fix for a 500).
- `update_query` only records a new version / re-pins when the **SQL text actually changes** — passing identical SQL is a silent no-op.
- Pass `dashboard_id` to `update_query` so the edit pins to that dashboard and shows in its version history.

### Debugging "Query execution failed" / HTTP 500 — checklist

1. **Split test first:** do param-LESS queries succeed while every parameterised one fails? → it's the `{ parameters: {} }` envelope (see above), not auth, cold-start, or `query_ids`.
2. **MCP is not the browser.** `mcp__AV_Dashboards__execute_query` takes params its own way and often returns cached rows (`Cached: Yes`) — a green MCP result does **not** prove the browser path works. Force a real execution with a **novel parameter value** (e.g. a fake email) to bust the cache and see the true server error.
3. Read the actual client source (`av-dashboard.js`) and the 500 response body before theorising — it's ~23KB and settles most questions in minutes.

### Call recordings (Twilio)

- Recording URLs look like `https://twilio-recordings.anyvan.com/recordings/{RECORDINGSID}` (built in-query from `SOPHIE_CALLS_INCREMENTAL.RECORDINGSID`; `interaction_hub_calls`/`interaction_hub_phone_lookup` expose it as `RECORDING_URL`, `sophie_calls_v5` as `TASK_URL`).
- That proxy is **Flex-scoped**: it returns `Access-Control-Allow-Origin: https://flex.twilio.com` and demands HTTP Basic auth (`www-authenticate: Basic`). So from a dashboard it prompts for login.
- **Working pattern:** open the recording in a **new tab** (`<a target="_blank" rel="noopener">` or `window.open`). The user authenticates the proxy once and the browser caches it for the session. This is what the Sophie review dashboard does.
- **Do NOT** render an inline `<audio src=RECORDING_URL>` from a dashboard — it silently 401s (can't send the auth header; CORS blocks the origin), showing a broken player.
- **Never** hardcode Twilio/Basic credentials in dashboard HTML — it's public and committed to git.
- Inline playback or a clean (no-login) download requires a backend change: either widen the proxy (allow `dashboards.anyvan.com` origin + accept the AV Dashboards token or issue signed URLs), or add a `/recordings/{sid}` route on the AV Dashboards API that streams from Twilio server-side.

### Parameterised time-window pattern

For per-record history that could otherwise scan huge tables, parameterise the window and default it small:
```sql
WHERE EVENTTIMESTAMP >= DATEADD('day', -1 * :days, CURRENT_DATE())
```
Client: default to a short window (e.g. 30 days), let the user expand it in steps up to the retention limit (12 months / 365 days), and reuse already-loaded larger windows instead of re-querying. Add retry-with-backoff on transient `execution failed`/timeout/5xx (Snowflake warehouse cold-start).

## Phone Number Formats in Snowflake

UK phone numbers are stored inconsistently across tables. **Never do exact-match lookups on raw user input.**

### Storage formats by table

| Table | Column(s) | Example for 07521 016537 |
|-------|-----------|--------------------------|
| `CONFORMED.PRODUCTION.FCT_VOICE_INTERACTIONS` | `FROM_NUMBER`, `TO_NUMBER` | `447521016537` (no `+`) |
| `CONFORMED.PRODUCTION.FCT_TWILIO_CALL_METRICS` | `FROMNUMBER`, `TONUMBER` | `447521016537` (no `+`) |
| `MART_SALES_OPS.PRODUCTION.FACT_VOICE_ACTIVITY` | `CUSTOMERPHONENUMBER` | `+447521016537` (with `+`) |
| `MART_SALES_OPS.PRODUCTION.CS_INTERACTIONS` | `CUSTOMER_PHONE` | `447521016537` (no `+`) |
| `MART_SALES_OPS.PRODUCTION.SOPHIE_CALLS_INCREMENTAL` | `CUSTOMERPHONENUMBER` | `+447521016537` (with `+`) |
| `MART_SALES_OPS.PRODUCTION.SOPHIE_CHATS_INCREMENTAL` | `CUSTOMERPHONENUMBER` | `+447521016537` (with `+`) |
| `HARMONISED.PRODUCTION.CS_INBOUND_INTERACTIONS` | `CUSTOMER_PHONE` | `+447521016537` (with `+`) |

### User input formats

Users enter phone numbers in many ways:
- `07521 016537` (UK local with spaces)
- `07521016537` (UK local, no spaces)
- `+447521016537` (E.164 with +)
- `447521016537` (E.164 without +)
- `+44 7521 016537` (E.164 with spaces)

### Recommended normalisation pattern

**Client-side (JavaScript):**
```javascript
function normPhone(raw) {
    var digits = raw.replace(/\D/g, '');
    if (digits.startsWith('0')) digits = '44' + digits.substring(1);
    return digits;
}
// Then use last 10 digits as suffix: digits.slice(-10)
```

**Server-side (Snowflake SQL) — suffix matching:**
```sql
RIGHT(REGEXP_REPLACE(phone_column, '[^0-9]', ''), 10) = :phone_suffix
```

This approach handles all formats by comparing the last 10 digits (subscriber number without country code prefix), which is consistent regardless of whether the stored value has `+`, `44`, or `0` prefix.

### Important: avoid unfiltered large queries

Snowflake tables like `FCT_TWILIO_CALL_METRICS` contain millions of rows per year. Always filter server-side with parameterised queries rather than fetching all rows and filtering client-side. A `LIMIT 5000` on an unfiltered 3M-row table only covers ~14 hours of data.

## International Numbers

AnyVan operates in UK, Spain, and France. Phone prefixes:
- UK: `44` (local prefix `0`)
- Spain: `34` (no local prefix)
- France: `33` (local prefix `0`)

The suffix-matching approach (last 10 digits) works across all territories.
