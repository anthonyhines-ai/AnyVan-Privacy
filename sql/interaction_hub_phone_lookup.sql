-- interaction_hub_phone_lookup  (REVISED — transcript parity for phone-lookup mode)
-- Query ID: 3FWzBkT0qCZzI4X6N2kEDg317ZS  (engine snowflake, public)
-- Additive changes only (supersedes interaction_hub_phone_lookup.PATCH.md):
--   * new rec CTE (call_sid -> recording_id)
--   * CALL_DIRECTION added to every UNION arm (calls: LOWER(TASKTYPE); else NULL)
--   * final SELECT adds RECORDING_ID, TRANSCRIPT_AVAILABLE, CALL_DIRECTION and back-fills
--     the admin RECORDING_URL; LEFT JOIN rec ON rec.CALL_SID = u.INTERACTION_ID
WITH rec AS (
    SELECT CALL_SID, MAX(RECORDING_ID) AS RECORDING_ID
    FROM CONFORMED.PRODUCTION.CALL_TRANSCRIPT_CALLS
    WHERE RECORDING_ID LIKE 'RE%'
    GROUP BY CALL_SID
),
wa_conv AS (
    SELECT
        RIGHT(REGEXP_REPLACE(m.AUTHOR,'[^0-9]',''),10)                           AS PHONE10,
        m.CONVERSATION_ID,
        MIN(m.CREATED_AT)                                                        AS WIN_START,
        MAX(m.CREATED_AT)                                                        AS WIN_END
    FROM HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE m
    WHERE m.AUTHOR LIKE 'whatsapp:%'
      AND RIGHT(REGEXP_REPLACE(m.AUTHOR,'[^0-9]',''),10) = :phone_suffix
      AND m.CREATED_AT >= DATEADD('day', -1 * (:days + 3), CURRENT_DATE())
    GROUP BY 1, 2
),
admin_wa_ch AS (
    SELECT c.TASKSID, MAX(w.CONVERSATION_ID) AS CH
    FROM CONFORMED.PRODUCTION.FCT_TWILIO_CALL_METRICS c
    JOIN wa_conv w
      ON w.PHONE10 = RIGHT(REGEXP_REPLACE(CASE WHEN LOWER(c.TASKTYPE)='inbound' THEN c.FROMNUMBER ELSE c.TONUMBER END,'[^0-9]',''),10)
     AND c.EVENTTIMESTAMP BETWEEN DATEADD('hour',-6,w.WIN_START) AND DATEADD('hour',6,w.WIN_END)
    WHERE c.TASKCHANNELNAME='whatsapp'
      AND LOWER(NVL(c.WORKEREMAIL,'')) NOT LIKE '%sophie%'
      AND c.WORKEREMAIL IS NOT NULL
      AND c.EVENTTIMESTAMP >= DATEADD('day', -1 * :days, CURRENT_DATE())
      AND (RIGHT(REGEXP_REPLACE(c.FROMNUMBER,'[^0-9]',''),10) = :phone_suffix
           OR RIGHT(REGEXP_REPLACE(c.TONUMBER,'[^0-9]',''),10) = :phone_suffix)
    GROUP BY c.TASKSID
    HAVING COUNT(DISTINCT w.CONVERSATION_ID) = 1
),
cust AS (
    SELECT DISTINCT LOWER(EMAIL_ADDRESS) AS email, PRIMARY_PHONE_NUMBER AS phone
    FROM CONFORMED.PRODUCTION.DIM_USER_CUSTOMER
    WHERE EMAIL_ADDRESS IS NOT NULL
      AND (RIGHT(REGEXP_REPLACE(PRIMARY_PHONE_NUMBER,'[^0-9]',''),10) = :phone_suffix
           OR RIGHT(REGEXP_REPLACE(SECONDARY_PHONE_NUMBER,'[^0-9]',''),10) = :phone_suffix)
),
web_chat AS (
    SELECT m.CONVERSATION_ID, ANY_VALUE(cust.phone) AS CUSTOMER_PHONE, MIN(m.CREATED_AT) AS FIRST_MSG
    FROM HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE m
    JOIN HARMONISED.PRODUCTION.TWILIO_CONVERSATION_USER u ON u.USER_IDENTITY = m.AUTHOR
    JOIN cust ON cust.email = LOWER(u.FRIENDLY_NAME)
    WHERE m.AUTHOR LIKE 'FX%'
      AND m.CREATED_AT >= DATEADD('day', -1 * :days, CURRENT_DATE())
    GROUP BY 1
),
ai_calls AS (
    SELECT
        CONVERT_TIMEZONE('UTC','Europe/London', sc.EVENTTIMESTAMP)               AS INTERACTION_DATETIME,
        sc.CALLSID                                                               AS INTERACTION_ID,
        'Sophie AI'                                                              AS AGENT_NAME,
        'sophie-ai@anyvan.com'                                                   AS AGENT_EMAIL,
        'AI'                                                                     AS AGENT_TYPE,
        sc.CUSTOMERPHONENUMBER                                                   AS CUSTOMER_PHONE,
        sc.LISTING_ID,
        sc.SENTIMENT,
        sc.SENTIMENT_SUMMARY,
        sc.INTERACTION_TYPE,
        sc.CALL_DURATION_SECONDS                                                 AS DURATION_SECONDS,
        CASE WHEN sc.RECORDINGSID IS NOT NULL
             THEN 'https://twilio-recordings.anyvan.com/recordings/' || sc.RECORDINGSID
             ELSE NULL END                                                       AS RECORDING_URL,
        NULL::VARCHAR                                                            AS TRANSCRIPT_URL,
        NULL::BOOLEAN                                                            AS ESCALATED,
        NULL::VARCHAR                                                            AS FIELDS_CHANGED,
        'Call'                                                                   AS CHANNEL,
        NULL::VARCHAR                                                            AS CONVERSATION_ID,
        CASE WHEN sc.CALLSID ILIKE 'CA%'
             THEN 'https://console.twilio.com/us1/monitor/logs/calls/' || sc.CALLSID
             ELSE NULL END                                                       AS TWILIO_CONSOLE_URL,
        NULL::VARCHAR                                                            AS TRANSCRIPT_SID,
        NULL::VARCHAR                                                            AS CALL_DIRECTION
    FROM MART_SALES_OPS.PRODUCTION.SOPHIE_CALLS_INCREMENTAL sc
    WHERE sc.EVENTTIMESTAMP >= DATEADD('day', -1 * :days, CURRENT_DATE())
      AND RIGHT(REGEXP_REPLACE(sc.CUSTOMERPHONENUMBER, '[^0-9]', ''), 10) = :phone_suffix
),
admin_calls AS (
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
        NULL::VARCHAR                                                            AS TRANSCRIPT_URL,
        FALSE::BOOLEAN                                                           AS ESCALATED,
        NULL::VARCHAR                                                            AS FIELDS_CHANGED,
        'Call'                                                                   AS CHANNEL,
        c.CONFERENCESID                                                          AS CONVERSATION_ID,
        CASE WHEN c.CUSTOMERCALLSID ILIKE 'CA%'
             THEN 'https://console.twilio.com/us1/monitor/logs/calls/' || c.CUSTOMERCALLSID
             ELSE NULL END                                                       AS TWILIO_CONSOLE_URL,
        NULL::VARCHAR                                                            AS TRANSCRIPT_SID,
        LOWER(c.TASKTYPE)                                                        AS CALL_DIRECTION
    FROM CONFORMED.PRODUCTION.FCT_TWILIO_CALL_METRICS c
    WHERE c.TASKCHANNELNAME = 'voice'
      AND LOWER(NVL(c.WORKEREMAIL,'')) NOT LIKE '%sophie%'
      AND LOWER(NVL(c.WORKEREMAIL,'')) NOT LIKE '%amy-sdr%'
      AND c.WORKEREMAIL IS NOT NULL
      AND c.TALKTIME > 0
      AND c.EVENTTIMESTAMP >= DATEADD('day', -1 * :days, CURRENT_DATE())
      AND (
          RIGHT(REGEXP_REPLACE(c.FROMNUMBER, '[^0-9]', ''), 10) = :phone_suffix
          OR RIGHT(REGEXP_REPLACE(c.TONUMBER, '[^0-9]', ''), 10) = :phone_suffix
      )
),
ai_whatsapp AS (
    SELECT
        CONVERT_TIMEZONE('UTC','Europe/London', sc.EVENTTIMESTAMP)               AS INTERACTION_DATETIME,
        sc.CALLSID                                                               AS INTERACTION_ID,
        'Sophie AI'                                                              AS AGENT_NAME,
        'sophie-ai@anyvan.com'                                                   AS AGENT_EMAIL,
        'AI'                                                                     AS AGENT_TYPE,
        sc.CUSTOMERPHONENUMBER                                                   AS CUSTOMER_PHONE,
        sc.LISTING_ID,
        sc.SENTIMENT,
        sc.SENTIMENT_SUMMARY,
        sc.INTERACTION_TYPE,
        NULL::NUMBER                                                             AS DURATION_SECONDS,
        NULL::VARCHAR                                                            AS RECORDING_URL,
        'https://av-public-2653.s3.eu-west-1.amazonaws.com/twilio-message-viewer.html?conversationId=' || sc.CALLSID AS TRANSCRIPT_URL,
        COALESCE(sc.SOPHIE_ESCALATED, FALSE)                                    AS ESCALATED,
        sc.FIELDS_CHANGED,
        'WhatsApp'                                                               AS CHANNEL,
        NULL::VARCHAR                                                            AS CONVERSATION_ID,
        NULL::VARCHAR                                                            AS TWILIO_CONSOLE_URL,
        sc.CALLSID                                                               AS TRANSCRIPT_SID,
        NULL::VARCHAR                                                            AS CALL_DIRECTION
    FROM MART_SALES_OPS.PRODUCTION.SOPHIE_CHATS_INCREMENTAL sc
    WHERE sc.EVENTTIMESTAMP >= DATEADD('day', -1 * :days, CURRENT_DATE())
      AND sc.CUSTOMERPHONENUMBER LIKE '+%'
      AND RIGHT(REGEXP_REPLACE(sc.CUSTOMERPHONENUMBER, '[^0-9]', ''), 10) = :phone_suffix
),
admin_whatsapp AS (
    SELECT
        CONVERT_TIMEZONE('UTC','Europe/London', c.EVENTTIMESTAMP::TIMESTAMP_NTZ) AS INTERACTION_DATETIME,
        COALESCE(c.CUSTOMERCALLSID, c.TASKSID)                                  AS INTERACTION_ID,
        INITCAP(REPLACE(SPLIT_PART(LOWER(NVL(c.WORKEREMAIL,'')), '@', 1), '.', ' ')) AS AGENT_NAME,
        LOWER(c.WORKEREMAIL)                                                     AS AGENT_EMAIL,
        'Admin'                                                                  AS AGENT_TYPE,
        CASE WHEN LOWER(c.TASKTYPE) = 'inbound' THEN c.FROMNUMBER ELSE c.TONUMBER END AS CUSTOMER_PHONE,
        TRY_TO_NUMBER(c.V4LISTINGID)                                             AS LISTING_ID,
        NULL::VARCHAR                                                            AS SENTIMENT,
        NULL::VARCHAR                                                            AS SENTIMENT_SUMMARY,
        NULL::VARCHAR                                                            AS INTERACTION_TYPE,
        NULL::NUMBER                                                             AS DURATION_SECONDS,
        NULL::VARCHAR                                                            AS RECORDING_URL,
        CASE WHEN c.CUSTOMERCALLSID IS NOT NULL
             THEN 'https://av-public-2653.s3.eu-west-1.amazonaws.com/twilio-message-viewer.html?conversationId=' || c.CUSTOMERCALLSID
             ELSE NULL END                                                       AS TRANSCRIPT_URL,
        FALSE::BOOLEAN                                                           AS ESCALATED,
        NULL::VARCHAR                                                            AS FIELDS_CHANGED,
        'WhatsApp'                                                               AS CHANNEL,
        NULL::VARCHAR                                                            AS CONVERSATION_ID,
        NULL::VARCHAR                                                            AS TWILIO_CONSOLE_URL,
        aw.CH                                                                    AS TRANSCRIPT_SID,
        NULL::VARCHAR                                                            AS CALL_DIRECTION
    FROM CONFORMED.PRODUCTION.FCT_TWILIO_CALL_METRICS c
    LEFT JOIN admin_wa_ch aw ON aw.TASKSID = c.TASKSID
    WHERE c.TASKCHANNELNAME = 'whatsapp'
      AND LOWER(NVL(c.WORKEREMAIL,'')) NOT LIKE '%sophie%'
      AND c.WORKEREMAIL IS NOT NULL
      AND c.EVENTTIMESTAMP >= DATEADD('day', -1 * :days, CURRENT_DATE())
      AND (
          RIGHT(REGEXP_REPLACE(c.FROMNUMBER, '[^0-9]', ''), 10) = :phone_suffix
          OR RIGHT(REGEXP_REPLACE(c.TONUMBER, '[^0-9]', ''), 10) = :phone_suffix
      )
),
ai_livechat AS (
    SELECT
        CONVERT_TIMEZONE('UTC','Europe/London', sc.EVENTTIMESTAMP)               AS INTERACTION_DATETIME,
        sc.CALLSID                                                               AS INTERACTION_ID,
        'Sophie AI'                                                              AS AGENT_NAME,
        'sophie-ai@anyvan.com'                                                   AS AGENT_EMAIL,
        'AI'                                                                     AS AGENT_TYPE,
        sc.CUSTOMERPHONENUMBER                                                   AS CUSTOMER_PHONE,
        sc.LISTING_ID,
        sc.SENTIMENT,
        sc.SENTIMENT_SUMMARY,
        sc.INTERACTION_TYPE,
        NULL::NUMBER                                                             AS DURATION_SECONDS,
        NULL::VARCHAR                                                            AS RECORDING_URL,
        'https://av-public-2653.s3.eu-west-1.amazonaws.com/twilio-message-viewer.html?conversationId=' || sc.CALLSID AS TRANSCRIPT_URL,
        COALESCE(sc.SOPHIE_ESCALATED, FALSE)                                    AS ESCALATED,
        sc.FIELDS_CHANGED,
        'LiveChat'                                                               AS CHANNEL,
        NULL::VARCHAR                                                            AS CONVERSATION_ID,
        NULL::VARCHAR                                                            AS TWILIO_CONSOLE_URL,
        sc.CALLSID                                                               AS TRANSCRIPT_SID,
        NULL::VARCHAR                                                            AS CALL_DIRECTION
    FROM MART_SALES_OPS.PRODUCTION.SOPHIE_CHATS_INCREMENTAL sc
    WHERE sc.EVENTTIMESTAMP >= DATEADD('day', -1 * :days, CURRENT_DATE())
      AND (sc.CUSTOMERPHONENUMBER NOT LIKE '+%' OR sc.CUSTOMERPHONENUMBER IS NULL)
      AND RIGHT(REGEXP_REPLACE(sc.CUSTOMERPHONENUMBER, '[^0-9]', ''), 10) = :phone_suffix
),
admin_livechat AS (
    SELECT
        CONVERT_TIMEZONE('UTC','Europe/London', c.EVENTTIMESTAMP::TIMESTAMP_NTZ) AS INTERACTION_DATETIME,
        COALESCE(c.CUSTOMERCALLSID, c.TASKSID)                                  AS INTERACTION_ID,
        INITCAP(REPLACE(SPLIT_PART(LOWER(NVL(c.WORKEREMAIL,'')), '@', 1), '.', ' ')) AS AGENT_NAME,
        LOWER(c.WORKEREMAIL)                                                     AS AGENT_EMAIL,
        'Admin'                                                                  AS AGENT_TYPE,
        CASE WHEN LOWER(c.TASKTYPE) = 'inbound' THEN c.FROMNUMBER ELSE c.TONUMBER END AS CUSTOMER_PHONE,
        TRY_TO_NUMBER(c.V4LISTINGID)                                             AS LISTING_ID,
        NULL::VARCHAR                                                            AS SENTIMENT,
        NULL::VARCHAR                                                            AS SENTIMENT_SUMMARY,
        NULL::VARCHAR                                                            AS INTERACTION_TYPE,
        NULL::NUMBER                                                             AS DURATION_SECONDS,
        NULL::VARCHAR                                                            AS RECORDING_URL,
        CASE WHEN c.CUSTOMERCALLSID IS NOT NULL
             THEN 'https://av-public-2653.s3.eu-west-1.amazonaws.com/twilio-message-viewer.html?conversationId=' || c.CUSTOMERCALLSID
             ELSE NULL END                                                       AS TRANSCRIPT_URL,
        FALSE::BOOLEAN                                                           AS ESCALATED,
        NULL::VARCHAR                                                            AS FIELDS_CHANGED,
        'LiveChat'                                                               AS CHANNEL,
        NULL::VARCHAR                                                            AS CONVERSATION_ID,
        NULL::VARCHAR                                                            AS TWILIO_CONSOLE_URL,
        NULL::VARCHAR                                                            AS TRANSCRIPT_SID,
        NULL::VARCHAR                                                            AS CALL_DIRECTION
    FROM CONFORMED.PRODUCTION.FCT_TWILIO_CALL_METRICS c
    WHERE c.TASKCHANNELNAME = 'chat'
      AND LOWER(NVL(c.WORKEREMAIL,'')) NOT LIKE '%sophie%'
      AND c.WORKEREMAIL IS NOT NULL
      AND c.EVENTTIMESTAMP >= DATEADD('day', -1 * :days, CURRENT_DATE())
      AND (
          RIGHT(REGEXP_REPLACE(c.FROMNUMBER, '[^0-9]', ''), 10) = :phone_suffix
          OR RIGHT(REGEXP_REPLACE(c.TONUMBER, '[^0-9]', ''), 10) = :phone_suffix
      )
),
web_livechat AS (
    SELECT
        CONVERT_TIMEZONE('UTC','Europe/London', wc.FIRST_MSG::TIMESTAMP_NTZ)     AS INTERACTION_DATETIME,
        wc.CONVERSATION_ID                                                       AS INTERACTION_ID,
        'Web Live Chat'                                                          AS AGENT_NAME,
        NULL::VARCHAR                                                            AS AGENT_EMAIL,
        'Admin'                                                                  AS AGENT_TYPE,
        wc.CUSTOMER_PHONE                                                        AS CUSTOMER_PHONE,
        NULL::NUMBER                                                             AS LISTING_ID,
        NULL::VARCHAR                                                            AS SENTIMENT,
        NULL::VARCHAR                                                            AS SENTIMENT_SUMMARY,
        NULL::VARCHAR                                                            AS INTERACTION_TYPE,
        NULL::NUMBER                                                             AS DURATION_SECONDS,
        NULL::VARCHAR                                                            AS RECORDING_URL,
        NULL::VARCHAR                                                            AS TRANSCRIPT_URL,
        FALSE::BOOLEAN                                                           AS ESCALATED,
        NULL::VARCHAR                                                            AS FIELDS_CHANGED,
        'LiveChat'                                                               AS CHANNEL,
        NULL::VARCHAR                                                            AS CONVERSATION_ID,
        NULL::VARCHAR                                                            AS TWILIO_CONSOLE_URL,
        wc.CONVERSATION_ID                                                       AS TRANSCRIPT_SID,
        NULL::VARCHAR                                                            AS CALL_DIRECTION
    FROM web_chat wc
)
SELECT
    u.INTERACTION_DATETIME,
    u.INTERACTION_ID,
    u.AGENT_NAME,
    u.AGENT_EMAIL,
    u.AGENT_TYPE,
    u.CUSTOMER_PHONE,
    u.LISTING_ID,
    ele.LISTING_JOB_CLASSIFICATION_REGION                                        AS COUNTRY,
    ele.LISTING_CATEGORY_NAME,
    ele.LISTING_PICK_UP_DATE                                                     AS PICKUP_DATE,
    ele.LISTING_STATUS,
    u.SENTIMENT,
    u.SENTIMENT_SUMMARY,
    u.INTERACTION_TYPE,
    u.CHANNEL,
    u.DURATION_SECONDS,
    COALESCE(
        u.RECORDING_URL,
        CASE WHEN rec.RECORDING_ID IS NOT NULL
             THEN 'https://twilio-recordings.anyvan.com/recordings/' || rec.RECORDING_ID END
    )                                                                            AS RECORDING_URL,
    rec.RECORDING_ID,
    IFF(rec.RECORDING_ID IS NOT NULL, TRUE, FALSE)                               AS TRANSCRIPT_AVAILABLE,
    u.CALL_DIRECTION,
    u.TRANSCRIPT_URL,
    u.ESCALATED,
    u.FIELDS_CHANGED,
    u.CONVERSATION_ID,
    u.TWILIO_CONSOLE_URL,
    flex.TWILIO_FLEX_URL,
    u.TRANSCRIPT_SID
FROM (
    SELECT * FROM ai_calls
    UNION ALL SELECT * FROM admin_calls
    UNION ALL SELECT * FROM ai_whatsapp
    UNION ALL SELECT * FROM admin_whatsapp
    UNION ALL SELECT * FROM ai_livechat
    UNION ALL SELECT * FROM admin_livechat
    UNION ALL SELECT * FROM web_livechat
) u
LEFT JOIN MART_ENTERPRISE.PRODUCTION.ENTERPRISE_LISTING_EXTRACT ele
    ON u.LISTING_ID = ele.LISTING_ID
LEFT JOIN (
    SELECT CONVERSATION_ATTRIBUTE_4 AS conf, ANY_VALUE(CONVERSATION) AS TWILIO_FLEX_URL
    FROM HARMONISED.PRODUCTION.TWILIO_FLEX_INSIGHTS_BI_TWILIO_TELEPHONY
    WHERE CONVERSATION_ATTRIBUTE_4 ILIKE 'CF%'
    GROUP BY 1
) flex ON flex.conf = u.CONVERSATION_ID
LEFT JOIN rec ON rec.CALL_SID = u.INTERACTION_ID
ORDER BY u.INTERACTION_DATETIME DESC
LIMIT 5000
