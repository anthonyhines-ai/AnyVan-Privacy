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

## 3. Web Live Chat — customer-centric retrieval (shipped for phone lookup)

Web Live Chat messages **are** in `TWILIO_CONVERSATION_MESSAGE` (≈1,900 conversations/week). The
message *author* is an anonymous `FX…` web id, **but the web user record carries the customer's
identity**: `HARMONISED.PRODUCTION.TWILIO_CONVERSATION_USER.FRIENDLY_NAME` is 100% populated and
~52% are **emails** (the rest names), captured from the pre-chat form. Of the email ones, **~64%
resolve to a known `DIM_USER_CUSTOMER`**.

That gives a customer-centric link even though the **task** can't be linked (the chat task's
`FROMNUMBER`/`TONUMBER` are non-phone fragments — only 6 of 1,614 resolve to a customer, so a
task↔conversation match is a dead end). So we surface web chats **by customer, in the SAR phone
lookup**, not on the Live Chat tab:

```
searched phone (:phone_suffix)
  → DIM_USER_CUSTOMER (PRIMARY/SECONDARY_PHONE_NUMBER) → EMAIL_ADDRESS
  → TWILIO_CONVERSATION_USER.FRIENDLY_NAME = that email → FX web user
  → its web-chat CONVERSATION_ID (CH) → transcript
```

Implemented as the `web_livechat` branch (`cust` + `web_chat` CTEs) in
`interaction_hub_phone_lookup` **v11** — LiveChat rows carrying `TRANSCRIPT_SID = CH`, so the drawer
renders them with no HTML change. Coverage: ~62% of email-bearing web chats are reachable by phone
(~a third of all web chats). Rows sit under the LiveChat channel in phone-lookup results.

**Still not covered:** the Live Chat **tab** (task rows) — those have no usable key at all, so they
still need the Flex `conversationSid` captured against the task: a **Twilio API proxy** route
`TaskSid → attributes.conversationSid` (no data request, recordings-proxy pattern) or source capture.
An agent-plus-time heuristic was rejected — agents run concurrent chats, so it could attach the wrong
customer's transcript to a booking.

## 4. Governance notes

- **Read-only.** All Snowflake access was `SELECT` against `PRODUCTION`; no writes.
- **No PII / secrets committed.** Verification used transient sample suffixes recorded nowhere; this
  note and the dashboard hold only column names, URL templates and SID *patterns*.

## 5. Sources

- Transcript query `interaction_hub_conversation_transcript` (reads `TWILIO_CONVERSATION_MESSAGE`).
- Companion note: [`interaction-hub/2026-09-03-twilio-flex-console-links.md`](2026-09-03-twilio-flex-console-links.md).
