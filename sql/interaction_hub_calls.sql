-- interaction_hub_calls  (REVISED — call transcript + admin recording playback)
-- Query ID: 3FMEoLMS0TRU0niESsyKpb5dUln  (engine: snowflake, visibility: public)
--
-- Changes vs live version (all additive — existing columns/behaviour unchanged):
--   1. admin_voice + ai_voice now emit CALL_DIRECTION (admin: LOWER(TASKTYPE); ai: NULL).
--   2. Final SELECT LEFT JOINs a per-call transcript rollup (rec) keyed on
--      WORKERCALLSID (= INTERACTION_ID) and adds:
--        - RECORDING_ID          the Twilio 'RE...' sid landed by the transcription pipeline
--        - TRANSCRIPT_AVAILABLE  boolean gate for the hub's available/unavailable state
--      and back-fills RECORDING_URL for admin calls (previously hard-NULL) so the
--      "Listen to Recording" button works for human-agent calls too — same proxy URL
--      pattern Sophie AI calls already use.
--
-- Join note: rec is keyed on CALL_SID = the agent leg. Verified (7d) that the worker-call-sid
-- carries 100% of matchable transcripts; the customer-call-sid adds nothing. Coverage is a
-- pipeline/queue matter, not a join defect — see interaction-hub/2026-09-15-call-transcript-
-- matching-and-coverage.md.

WITH ai_voice AS (
    SELECT
        CONVERT_TIMEZONE('UTC','Europe/London', te.EVENTTIMESTAMP)               AS INTERACTION_DATETIME,
        te.CALLSID                                                               AS INTERACTION_ID,
        'Sophie AI'                                                              AS AGENT_NAME,
        'sophie-ai@anyvan.com'                                                   AS AGENT_EMAIL,
        'AI'                                                                     AS AGENT_TYPE,
        te.CUSTOMERPHONENUMBER                                                   AS CUSTOMER_PHONE,
        COALESCE(te.V4LISTINGID, snl.LISTING_ID)                                AS LISTING_ID,
        sc.SENTIMENT,
        sc.SENTIMENT_SUMMARY,
        sc.INTERACTION_TYPE,
        sc.CALL_DURATION_SECONDS                                                 AS DURATION_SECONDS,
        CASE WHEN sc.RECORDINGSID IS NOT NULL
             THEN 'https://twilio-recordings.anyvan.com/recordings/' || sc.RECORDINGSID
             ELSE NULL END                                                       AS RECORDING_URL,
        NULL::VARCHAR                                                            AS CONVERSATION_ID,
        CASE WHEN te.CALLSID ILIKE 'CA%'
             THEN 'https://console.twilio.com/us1/monitor/logs/calls/' || te.CALLSID
             ELSE NULL END                                                       AS TWILIO_CONSOLE_URL,
        NULL::VARCHAR                                                            AS CALL_DIRECTION
    FROM HARMONISED.PRODUCTION.TWILIO_EVENTS te
    LEFT JOIN (
        SELECT DISTINCT LISTING_ID, CREATED_AT
        FROM HARMONISED.PRODUCTION.ADMIN_LISTING_NOTES
        WHERE USER_ID = 5822926
          AND CREATED_AT >= DATEADD('day', -8, CURRENT_DATE())
          AND DELETED_ROW = FALSE AND LISTING_ID IS NOT NULL
    ) snl
        ON snl.CREATED_AT BETWEEN te.EVENTTIMESTAMP AND DATEADD('minute', 30, te.EVENTTIMESTAMP)
       AND (te.V4LISTINGID IS NULL OR te.V4LISTINGID = snl.LISTING_ID)
    LEFT JOIN MART_SALES_OPS.PRODUCTION.SOPHIE_CALLS_INCREMENTAL sc ON te.CALLSID = sc.CALLSID
    WHERE te.EVENTTYPE = 'task.created'
      AND te.TYPE LIKE '%Sophie%'
      AND te.CALLSID NOT LIKE 'CH%'
      AND te.EVENTTIMESTAMP >= DATEADD('day', -7, CURRENT_DATE())
    QUALIFY ROW_NUMBER() OVER (PARTITION BY te.CALLSID ORDER BY te.EVENTTIMESTAMP) = 1
),
admin_voice AS (
    SELECT
        CONVERT_TIMEZONE('UTC','Europe/London', c.EVENTTIMESTAMP::TIMESTAMP_NTZ) AS INTERACTION_DATETIME,
        COALESCE(c.WORKERCALLSID, c.TASKSID)                                    AS INTERACTION_ID,
        INITCAP(REPLACE(SPLIT_PART(LOWER(NVL(c.WORKEREMAIL,'')), '@', 1), '.', ' ')) AS AGENT_NAME,
        LOWER(c.WORKEREMAIL)                                                     AS AGENT_EMAIL,
        'Admin'                                                                  AS AGENT_TYPE,
        CASE WHEN LOWER(c.TASKTYPE) = 'inbound' THEN c.FROMNUMBER ELSE c.TONUMBER END AS CUSTOMER_PHONE,
        TRY_TO_NUMBER(c.V4LISTINGID)                                             AS LISTING_ID,
        NULL::VARCHAR                                                            AS SENTIMENT,
        NULL::VARCHAR                                                            AS SENTIMENT_SUMMARY,
        NULL::VARCHAR                                                            AS INTERACTION_TYPE,
        c.TALKTIME                                                               AS DURATION_SECONDS,
        NULL::VARCHAR                                                            AS RECORDING_URL,
        c.CONFERENCESID                                                          AS CONVERSATION_ID,
        CASE WHEN c.CUSTOMERCALLSID ILIKE 'CA%'
             THEN 'https://console.twilio.com/us1/monitor/logs/calls/' || c.CUSTOMERCALLSID
             ELSE NULL END                                                       AS TWILIO_CONSOLE_URL,
        LOWER(c.TASKTYPE)                                                        AS CALL_DIRECTION
    FROM CONFORMED.PRODUCTION.FCT_TWILIO_CALL_METRICS c
    WHERE c.TASKCHANNELNAME = 'voice'
      AND LOWER(NVL(c.WORKEREMAIL,'')) NOT LIKE '%sophie%'
      AND LOWER(NVL(c.WORKEREMAIL,'')) NOT LIKE '%amy-sdr%'
      AND c.WORKEREMAIL IS NOT NULL
      AND c.TALKTIME > 0
      AND c.EVENTTIMESTAMP >= DATEADD('day', -7, CURRENT_DATE())
),
rec AS (
    -- One recording sid per agent-leg call sid (transcription pipeline output).
    SELECT CALL_SID, MAX(RECORDING_ID) AS RECORDING_ID
    FROM CONFORMED.PRODUCTION.CALL_TRANSCRIPT_CALLS
    WHERE RECORDING_ID LIKE 'RE%'
    GROUP BY CALL_SID
)
SELECT
    c.INTERACTION_DATETIME,
    c.INTERACTION_ID,
    c.AGENT_NAME,
    c.AGENT_EMAIL,
    c.AGENT_TYPE,
    c.CUSTOMER_PHONE,
    c.LISTING_ID,
    ele.LISTING_JOB_CLASSIFICATION_REGION                                        AS COUNTRY,
    ele.LISTING_CATEGORY_NAME,
    ele.LISTING_PICK_UP_DATE                                                     AS PICKUP_DATE,
    ele.LISTING_STATUS,
    c.SENTIMENT,
    c.SENTIMENT_SUMMARY,
    c.INTERACTION_TYPE,
    'Call'                                                                       AS CHANNEL,
    c.DURATION_SECONDS,
    COALESCE(
        c.RECORDING_URL,
        CASE WHEN rec.RECORDING_ID IS NOT NULL
             THEN 'https://twilio-recordings.anyvan.com/recordings/' || rec.RECORDING_ID END
    )                                                                            AS RECORDING_URL,
    rec.RECORDING_ID,
    IFF(rec.RECORDING_ID IS NOT NULL, TRUE, FALSE)                               AS TRANSCRIPT_AVAILABLE,
    c.CALL_DIRECTION,
    c.CONVERSATION_ID,
    c.TWILIO_CONSOLE_URL,
    flex.TWILIO_FLEX_URL
FROM (SELECT * FROM ai_voice UNION ALL SELECT * FROM admin_voice) c
LEFT JOIN MART_ENTERPRISE.PRODUCTION.ENTERPRISE_LISTING_EXTRACT ele
    ON c.LISTING_ID = ele.LISTING_ID
LEFT JOIN (
    SELECT CONVERSATION_ATTRIBUTE_4 AS conf, ANY_VALUE(CONVERSATION) AS TWILIO_FLEX_URL
    FROM HARMONISED.PRODUCTION.TWILIO_FLEX_INSIGHTS_BI_TWILIO_TELEPHONY
    WHERE CONVERSATION_ATTRIBUTE_4 ILIKE 'CF%'
    GROUP BY 1
) flex ON flex.conf = c.CONVERSATION_ID
LEFT JOIN rec ON rec.CALL_SID = c.INTERACTION_ID
ORDER BY c.INTERACTION_DATETIME DESC
LIMIT 5000
