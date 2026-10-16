-- interaction_hub_jiminny_transcript
-- NEW saved query: diarised transcript of one Jiminny SALES call, for the hub transcript pane.
--
-- Param: :event_id  (JIMINNY_CALL_METADATA / JIMINNY_CALL_TRANSCRIPT EVENT_ID; the hub row's
--                    INTERACTION_ID for a Jiminny row).
--
-- Output shape is identical to interaction_hub_call_transcript so the hub's renderTranscriptPanel
-- renders it with no branching. Speaker is deterministic upstream:
--   ISORGANIZER = TRUE  -> AnyVan agent  -> 'AGENT'
--   ISORGANIZER = FALSE -> customer      -> 'CUSTOMER'
-- Order by STARTSAT (chronological).

SELECT
    t.EVENT_ID                                    AS RECORDING_ID,
    t.EVENT_ID                                    AS CALL_SID,
    ROW_NUMBER() OVER (ORDER BY t.STARTSAT)        AS SEGMENT_INDEX,
    t.STARTSAT                                     AS SEG_START,
    t.ENDSAT                                       AS SEG_END,
    CASE WHEN t.ISORGANIZER THEN 'AGENT' ELSE 'CUSTOMER' END AS SPEAKER,
    t.TRANSCRIPT                                   AS SEGMENT_TEXT,
    m.ANYVAN_USER_NAME                             AS AGENT_NAME,
    LOWER(m.ANYVAN_USER_EMAIL)                     AS AGENT_EMAIL,
    CASE WHEN m.ANYVAN_USER_TEAMNAME ILIKE '%inbound%'  THEN 'inbound'
         WHEN m.ANYVAN_USER_TEAMNAME ILIKE '%outbound%' THEN 'outbound' END AS CALL_DIRECTION,
    NULL::VARCHAR                                  AS CALL_LANGUAGE,
    m.DURATION_SECONDS                             AS CALL_DURATION_SEC,
    m.PARTICIPANTS_COUNT                           AS N_SPEAKERS
FROM HARMONISED.PRODUCTION.JIMINNY_CALL_TRANSCRIPT t
LEFT JOIN HARMONISED.PRODUCTION.JIMINNY_CALL_METADATA m ON m.EVENT_ID = t.EVENT_ID
WHERE t.EVENT_ID = :event_id
ORDER BY t.STARTSAT
LIMIT 5000
