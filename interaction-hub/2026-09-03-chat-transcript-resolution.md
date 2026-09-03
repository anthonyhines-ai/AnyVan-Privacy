# Interaction Hub — Live Chat & WhatsApp Transcript Resolution

> ℹ️ **INTERNAL — no customer data.** Documents how the hub links an interaction to its
> Twilio conversation transcript, and the current coverage gap. No phone numbers, names or
> SIDs are recorded here. The live transcripts are customer PII behind AnyVan SSO — handle
> per the data-protection policy.

| | |
|---|---|
| **Record type** | Dashboard / data-lineage note |
| **Date created** | 2026-09-03 |
| **Raised by** | Anthony Hines (anthony.hines@anyvan.com) |
| **Surface** | Interaction Hub — https://dashboards.anyvan.com/operations/interaction-hub |
| **Data source** | `TWILIO_CONVERSATION_MESSAGE`, `FCT_TWILIO_CALL_METRICS`, `TWILIO_EVENTS`, `SOPHIE_CHATS_INCREMENTAL` (read-only, PRODUCTION) |
| **Subject** | Why chat transcripts resolve for some rows but not others, and the WhatsApp fix |

---

## 1. Root cause

The drawer builds a transcript from a **Twilio conversation SID (`CH…`)** — the key of
`HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE.CONVERSATION_ID`. Rows only resolve a
transcript if they carry that `CH`.

- **Sophie AI** chat/WhatsApp rows carry it natively (`TWILIO_EVENTS.CALLSID` / `SOPHIE_CHATS_INCREMENTAL.CALLSID` = `CH`).
- **Human-agent** chat/WhatsApp rows come from `FCT_TWILIO_CALL_METRICS`, where `CUSTOMERCALLSID`
  is **100% NULL** for chat/WhatsApp, so the row's id falls back to the **task SID (`WT…`)** —
  which never matches the message table. Result: no transcript.

So WhatsApp only *looked* healthy because Sophie dominates it; **human-agent WhatsApp and all
human-agent Live Chat were silently blank**. There is **no `WT`→`CH` key anywhere in the
warehouse** — verified across `FCT_TWILIO_CALL_METRICS`, `TWILIO_EVENTS`(+`_TASKROUTER_TASKS`),
`PARENTTASK`, the `TWILIO_CONVERSATION*` tables, the `CS_*_INBOUND_INTERACTIONS` tables, Studio
`TWILIO_EXECUTION`, and a metadata sweep for any table holding a conversation column *and* a task
column (none exists).

## 2. What shipped — WhatsApp (in-warehouse, no data request)

The customer's phone is present in the **message author** (`AUTHOR LIKE 'whatsapp:<phone>'`), which
gives a usable bridge the participant tables don't:

```
human WhatsApp task (customer phone, task time)
  → TWILIO_CONVERSATION_MESSAGE where whatsapp:<phone> author,
    task time within the conversation's message window (±6h)
  → CONVERSATION_ID (CH)  → transcript
```

Implemented as a `TRANSCRIPT_SID` column (`admin_wa_ch` CTE), populated **only when the match is
unambiguous** (`HAVING COUNT(DISTINCT conversation)=1`). Ambiguous matches are all *the same
customer's* number, so the discarded cases risk only right-customer/wrong-session — never a
cross-customer leak — and we drop them anyway rather than guess.

- Coverage: **~99% of human WhatsApp tasks match a conversation; ~43% resolve uniquely** and get a
  transcript today (≈1,500/week that were blank). The rest fall back to no transcript (no regression).
- The drawer reads `TRANSCRIPT_SID || INTERACTION_ID` and shows the transcript only when it's a
  real `CH` — so unresolved rows now hide the panel instead of showing an empty one.
- Queries: `interaction_hub_whatsapp` v7, `interaction_hub_phone_lookup` v10. Also folded the
  **UK-time** fix into `interaction_hub_whatsapp` / `interaction_hub_livechat` (v7), which the
  earlier timezone pass had missed.

## 3. Still open — web Live Chat

Web Live Chat messages **are** in `TWILIO_CONVERSATION_MESSAGE` (≈1,900 conversations/week), but the
customer author is an **anonymous `FX…` web-chat id** — no phone, listing or booking on it — so
there is no safe key from a Live Chat task to its conversation. The phone trick can't help (web-chat
messages carry no phone). Fixing it needs the Flex **`conversationSid` captured against the task**,
via either:

- **Live Twilio API lookup** (no data request): a proxy route `TaskSid → attributes.conversationSid`,
  same pattern as the recordings proxy; the hub then runs the existing transcript query. *(Preferred.)*
- **Source capture**: land the `conversationSid` against the task in the Twilio events pipeline.

An agent-plus-time heuristic was rejected: agents run concurrent chats, so it could attach the wrong
customer's transcript to a booking — unacceptable in a privacy tool.

## 4. Governance notes

- **Read-only.** All Snowflake access was `SELECT` against `PRODUCTION`; no writes.
- **No PII / secrets committed.** Verification used transient sample suffixes recorded nowhere; this
  note and the dashboard hold only column names, URL templates and SID *patterns*.

## 5. Sources

- Transcript query `interaction_hub_conversation_transcript` (reads `TWILIO_CONVERSATION_MESSAGE`).
- Companion note: [`interaction-hub/2026-09-03-twilio-flex-console-links.md`](2026-09-03-twilio-flex-console-links.md).
