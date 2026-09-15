-- interaction_hub_call_transcript
-- NEW saved query for the Interaction Hub call-transcript pane (additive; nothing calls it yet).
--
-- Purpose: return the diarised transcript of a single call, one row per spoken utterance,
--          ordered chronologically and labelled AGENT / CUSTOMER, for the "View Transcription"
--          panel in interaction-hub.html.
--
-- Params (bound via AVDashboard.runQuery(..., { parameters: {...} })):
--   :call_sid      the row's INTERACTION_ID (a Twilio 'CA...' worker-leg call sid). Always sent.
--   :recording_id  the row's RECORDING_ID ('RE...') when known — more precise on transferred /
--                  multi-leg calls. Sent as '' when unknown; the WHERE falls back to :call_sid.
--
-- Speaker attribution: SPEAKER is already resolved to AGENT / CUSTOMER upstream in
-- CALL_TRANSCRIPT_SEGMENTS (dual-channel, whisper-large-v3). CALL_DIRECTION_FACT is carried
-- through as the deterministic cross-check requested by Ops:
--   inbound  = customer called AnyVan  -> the caller is the CUSTOMER
--   outbound = AnyVan called customer  -> the caller is the AGENT
--
-- Ordering: order by SEG_START, NOT SEGMENT_INDEX (per the CALL_TRANSCRIPT_SEGMENTS table
-- comment, the source transcript array is not chronological).

SELECT
    s.RECORDING_ID,
    s.CALL_SID,
    s.SEGMENT_INDEX,
    s.SEG_START,
    s.SEG_END,
    s.SPEAKER,                                   -- 'AGENT' | 'CUSTOMER'
    s.SEGMENT_TEXT,
    c.AGENT_NAME,                                -- resolved display name (redaction target for SAR export)
    c.AGENT_EMAIL,
    c.CALL_DIRECTION_FACT   AS CALL_DIRECTION,   -- 'inbound' | 'outbound'
    c.CALL_LANGUAGE,
    c.CALL_DURATION_SEC,
    c.N_SPEAKERS
FROM CONFORMED.PRODUCTION.CALL_TRANSCRIPT_SEGMENTS s
LEFT JOIN CONFORMED.PRODUCTION.CALL_TRANSCRIPT_CLASSIFIED c
       ON c.RECORDING_ID = s.RECORDING_ID
WHERE ( NULLIF(:recording_id, '') IS NOT NULL AND s.RECORDING_ID = :recording_id )
   OR ( NULLIF(:recording_id, '') IS NULL     AND s.CALL_SID     = :call_sid )
ORDER BY s.SEG_START, s.SEGMENT_INDEX
LIMIT 2000
