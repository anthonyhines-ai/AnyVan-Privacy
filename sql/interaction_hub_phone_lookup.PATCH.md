# Patch — `interaction_hub_phone_lookup` (transcript parity for phone-lookup mode)

**Query ID:** `3FWzBkT0qCZzI4X6N2kEDg317ZS` · engine snowflake · public

The Calls tab (`interaction_hub_calls`) is fully revised in `interaction_hub_calls.sql`.
Phone-lookup mode shares the same expand renderer, so the phone lookup query needs the
**same three additive columns** for the transcript pane and admin "Listen" button to work
there too. Until this patch lands, transcript rows in phone-lookup mode show
"Transcription unavailable" (the HTML degrades gracefully).

All changes are additive — no existing column or filter changes.

### 1. Add a `rec` CTE (anywhere before the final `SELECT`)
```sql
rec AS (
    SELECT CALL_SID, MAX(RECORDING_ID) AS RECORDING_ID
    FROM CONFORMED.PRODUCTION.CALL_TRANSCRIPT_CALLS
    WHERE RECORDING_ID LIKE 'RE%'
    GROUP BY CALL_SID
),
```

### 2. `ai_calls` and `admin_calls` CTEs — add a direction column
Add as the final column of **both** CTEs (keeps the UNION column lists aligned):
- `admin_calls`: `LOWER(c.TASKTYPE) AS CALL_DIRECTION`
- `ai_calls`:    `NULL::VARCHAR   AS CALL_DIRECTION`

(The four non-call CTEs — `ai_whatsapp`, `admin_whatsapp`, `ai_livechat`, `admin_livechat`,
`web_livechat` — must add `NULL::VARCHAR AS CALL_DIRECTION` too, so every UNION arm matches.)

### 3. Final projection — add transcript columns + back-fill admin RECORDING_URL
Replace `u.RECORDING_URL,` in the outer `SELECT` with:
```sql
    COALESCE(
        u.RECORDING_URL,
        CASE WHEN rec.RECORDING_ID IS NOT NULL
             THEN 'https://twilio-recordings.anyvan.com/recordings/' || rec.RECORDING_ID END
    )                                                             AS RECORDING_URL,
    rec.RECORDING_ID,
    IFF(rec.RECORDING_ID IS NOT NULL, TRUE, FALSE)               AS TRANSCRIPT_AVAILABLE,
    u.CALL_DIRECTION,
```

### 4. Final `FROM` — join the rollup on the call's interaction id
```sql
LEFT JOIN rec ON rec.CALL_SID = u.INTERACTION_ID
```

> The transcript rollup only matches voice rows (WhatsApp/LiveChat interaction ids are
> conversation sids, not `CA...` call sids), so `TRANSCRIPT_AVAILABLE` is naturally FALSE
> for non-call channels — correct behaviour.
