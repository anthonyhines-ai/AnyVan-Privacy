# CLAUDE.md

## Repository Overview

This repo contains AnyVan operational dashboard HTML files (used with the AV Dashboards platform) and related privacy/data tooling.

## AV Dashboards Platform

- Dashboards are single HTML files that use the `AVDashboard` client library
- Queries run via `AVDashboard.runQuery('query_name', { param: value })` against Snowflake
- Queries are managed separately via the AV Dashboards MCP tools (`mcp__AV_Dashboards__*`)
- Query changes must be **pinned** to the dashboard using `update_query` with both `query_id` and `dashboard_id`
- Dashboard HTML is deployed via `update_dashboard` or `upload_dashboard`

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
