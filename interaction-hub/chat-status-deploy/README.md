# Interaction Hub — Chat Status badge + LiveChat visibility fix (DEPLOY-READY)

> Staged and **validated against Snowflake** on 2026-09-09, but **not yet deployed** —
> the AV Dashboards MCP connector was not authorised in the building session.
> Deploy from a fresh Claude Code session where the connector is authorised.

## What this delivers

1. **Live "Status" indicator** on the **LiveChat** and **WhatsApp** tabs (and in the side drawer)
   showing whether a chat is **🟢 Active** (in progress) or **⚪ Closed** (resolved), driven by
   `HARMONISED.PRODUCTION.TWILIO_CONVERSATION.STATE`.
2. **Fix: LiveChat was hiding all Sophie web-chats.** The query matched `TYPE LIKE '%Sophie%'`
   (case-sensitive), but web-chat events are typed `sophie_webchat` (lowercase), so **754 Sophie
   LiveChat sessions / 7 days were silently dropped**. Changed to `ILIKE '%sophie%'`.

## Validation evidence (Snowflake, 2026-09-09)

- `TWILIO_CONVERSATION.STATE` ∈ {`active`, `closed`} only — clean binary. Median sync lag **2s**
  (worst ~1h), table ~1 min behind live → effectively real-time.
- `TWILIO_CONVERSATION` is **1 row per conversation ID** (17,136 rows = 17,136 distinct IDs) → join is safe, no row fan-out.
- Updated LiveChat query end-to-end: **2,463 rows** (754 Sophie web-chats now included + 1,709 admin),
  all 754 Sophie rows get a status (482 active / 272 closed), no inflation.
- Sophie web-chats: 754 → **100%** have a state, **99.9%** have a transcript.
- Status coverage: Sophie AI (WhatsApp ~99.6%, LiveChat 100%), Admin WhatsApp where the conversation
  resolves. **Admin LiveChat has no conversation SID in the warehouse → shows "Unknown"** (same data
  gap that stops those transcripts loading; separate pipeline fix if wanted).

## Deploy steps

### 1. Update the two queries (AV Dashboards MCP `update_query`)

Replace the SQL of each query with the files in this folder (already include the status join **and**
the `ILIKE` fix):

- `interaction_hub_livechat` ← `interaction_hub_livechat.sql`
- `interaction_hub_whatsapp` ← `interaction_hub_whatsapp.sql`

Both add a `CHAT_STATE` column via:
```sql
LEFT JOIN HARMONISED.PRODUCTION.TWILIO_CONVERSATION tc
  ON tc.ID = c.<CONVO_SID|TRANSCRIPT_SID> AND tc.DELETED_ROW = FALSE
```

### 2. Edit the dashboard HTML (`operations/interaction-hub`)

**Re-fetch the LIVE HTML first** (`get_dashboard_html`) — do not reuse any local scratchpad copy,
it is behind live. Then make four edits:

**(a) Add the Status column** to both `COLS.livechat` and `COLS.whatsapp`, right after the
`INTERACTION_DATETIME` entry:
```js
{ key: 'CHAT_STATE', label: 'Status', w: '95px' },
```

**(b) Add a pill helper + CSS** (near the other render helpers / styles). Match the existing badge
styling/theme (see how `ESCALATED` renders) — reference implementation:
```js
function chatStatusPill(v){
  var s = (v||'').toString().toLowerCase();
  if (s === 'active') return '<span class="cs-pill cs-active">🟢 Active</span>';
  if (s === 'closed') return '<span class="cs-pill cs-closed">⚪ Closed</span>';
  return '<span class="cs-pill cs-unknown">—</span>';
}
```
```css
.cs-pill{display:inline-block;padding:2px 8px;border-radius:10px;font-size:11px;font-weight:600;white-space:nowrap}
.cs-active{background:#e6f4ea;color:#137333}
.cs-closed{background:#eceff1;color:#5f6368}
.cs-unknown{color:#9aa0a6}
:root[data-theme="dark"] .cs-active{background:#0d3a1e;color:#7ee2a8}
:root[data-theme="dark"] .cs-closed{background:#2a2e33;color:#c3c7cb}
```
In the main table cell renderer, special-case the column:
```js
if (col.key === 'CHAT_STATE') { td.innerHTML = chatStatusPill(row.CHAT_STATE); return; } // adapt to the renderer's shape
```

**(c) Fetch the field.** In the data-fetch column list (the `else` branch that pushes
`'ESCALATED','FIELDS_CHANGED','TRANSCRIPT_URL'`), add `'CHAT_STATE'`.

**(d) Drawer meta grid.** Add a Status row (text is fine here):
```js
{ label: 'Status', val: r.CHAT_STATE ? (r.CHAT_STATE==='active' ? 'Active (in progress)' : 'Closed') : 'Unknown' },
```

Optional: a one-line note under the tabs — "Status updates in near-real-time (within ~a minute)."

### 3. Publish

HTML is > 40KB → use the direct-API PUT flow (`get_upload_token` → `PUT .../production/upload`
with `{html, path:'operations/interaction-hub', title, query_ids}`), not `update_dashboard`
(truncates). Every publish auto-versions (rollback available).

### 4. Verify

- `execute_query interaction_hub_livechat` → confirm `CHAT_STATE` present and populated for Sophie rows,
  and that Sophie web-chats now appear (row count ~2.4k vs ~1.7k before).
- `execute_query interaction_hub_whatsapp` → `CHAT_STATE` present.
- Re-fetch HTML, grep for `CHAT_STATE`, `chatStatusPill`, `Status`.
- Spot-check: pick a currently-`active` conversation and confirm the badge reads Active.

## Design decisions (confirmed defaults — change if Ant prefers)

- Labels **Active / Closed** (alt: "In progress / Resolved").
- Admin-LiveChat "Unknown" is shown honestly, not hidden.
