-- interaction_hub_identity_lookup
-- Unified identity search: resolve a customer from ANY of email / phone / name,
-- fan out to their full identifier set, then match interactions across every channel.
-- Params: :mode ('phone'|'email'|'name'), :term_phone10, :term_email, :term_name, :days
--
-- Design:
--  * cust_seed  = customer rows in DIM matching the searched identifier.
--  * cust       = cust_seed ONLY when it resolves to a single USER_ID — so a shared
--                 phone / duplicate household never bleeds one person's ids into another's.
--  * phones2 / emails2 = the searched value itself (kept even when the customer is NOT
--                 in DIM, so nothing regresses vs the old phone-only lookup) PLUS the
--                 resolved customer's other phones/emails (the cross-channel fan-out).
--  * Phone-keyed channels (voice, WhatsApp, human live chat) match on phones2;
--    web live chat matches on emails2 (the FRIENDLY_NAME email bridge).
--  * MATCH_CONFIDENCE = 'Exact' for phone/email searches, 'Name — verify' for a name
--    search (name resolves a single customer but still wants a human eyeball).
WITH cust_seed AS (
    SELECT USER_ID, EMAIL_ADDRESS, PRIMARY_PHONE_NUMBER, SECONDARY_PHONE_NUMBER, FULL_NAME
    FROM CONFORMED.PRODUCTION.DIM_USER_CUSTOMER
    WHERE
        (:mode = 'phone' AND :term_phone10 <> '' AND (
             RIGHT(REGEXP_REPLACE(PRIMARY_PHONE_NUMBER  ,'[^0-9]',''),10) = :term_phone10
          OR RIGHT(REGEXP_REPLACE(SECONDARY_PHONE_NUMBER,'[^0-9]',''),10) = :term_phone10))
     OR (:mode = 'email' AND :term_email <> '' AND LOWER(EMAIL_ADDRESS) = :term_email)
     OR (:mode = 'name'  AND :term_name  <> '' AND UPPER(TRIM(FULL_NAME)) = :term_name)
),
cust AS (
    SELECT * FROM cust_seed
    WHERE (SELECT COUNT(DISTINCT USER_ID) FROM cust_seed) = 1
),
phones AS (
    SELECT :term_phone10 AS p10 FROM (SELECT 1) WHERE :mode = 'phone' AND LENGTH(:term_phone10) = 10
    UNION
    SELECT RIGHT(REGEXP_REPLACE(PRIMARY_PHONE_NUMBER  ,'[^0-9]',''),10) FROM cust WHERE PRIMARY_PHONE_NUMBER   IS NOT NULL
    UNION
    SELECT RIGHT(REGEXP_REPLACE(SECONDARY_PHONE_NUMBER,'[^0-9]',''),10) FROM cust WHERE SECONDARY_PHONE_NUMBER IS NOT NULL
),
phones2 AS ( SELECT DISTINCT p10 FROM phones WHERE p10 IS NOT NULL AND LENGTH(p10) = 10 ),
emails AS (
    SELECT :term_email AS em FROM (SELECT 1) WHERE :mode = 'email' AND :term_email <> ''
    UNION
    SELECT LOWER(EMAIL_ADDRESS) FROM cust WHERE EMAIL_ADDRESS IS NOT NULL
),
emails2 AS ( SELECT DISTINCT em FROM emails WHERE em IS NOT NULL AND em <> '' ),
cust_phone AS ( SELECT ANY_VALUE(PRIMARY_PHONE_NUMBER) AS phone FROM cust ),
wa_conv AS (
    SELECT
        RIGHT(REGEXP_REPLACE(m.AUTHOR,'[^0-9]',''),10) AS PHONE10,
        m.CONVERSATION_ID,
        MIN(m.CREATED_AT) AS WIN_START,
        MAX(m.CREATED_AT) AS WIN_END
    FROM HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE m
    WHERE m.AUTHOR LIKE 'whatsapp:%'
      AND RIGHT(REGEXP_REPLACE(m.AUTHOR,'[^0-9]',''),10) IN (SELECT p10 FROM phones2)
      AND m.CREATED_AT >= DATEADD('day', -1 * (:days + 3), CURRENT_DATE())
    GROUP BY 1, 2
),
admin_wa_ch AS (
    SELECT c.TASKSID, MAX(w.CONVERSATION_ID) AS CH
    FROM CONFORMED.PRODUCTION.FCT_TWILIO_CALL_METRICS c
    JOIN wa_conv w
      ON w.PHONE10 = RIGHT(REGEXP_REPLACE(CASE WHEN LOWER(c.TASKTYPE)='inbound' THEN c.FROMNUMBER ELSE c.TONUMBER END,'[^0-9]',''),10)
     AND c.EVENTTIMESTAMP BETWEEN DATEADD('hour',-6,w.WIN_START) AND DATEADD('hour',6,w.WIN_END)
    WHERE c.TASKCHANNELNAME = 'whatsapp'
      AND LOWER(NVL(c.WORKEREMAIL,'')) NOT LIKE '%sophie%'
      AND c.WORKEREMAIL IS NOT NULL
      AND c.EVENTTIMESTAMP >= DATEADD('day', -1 * :days, CURRENT_DATE())
      AND (RIGHT(REGEXP_REPLACE(c.FROMNUMBER,'[^0-9]',''),10) IN (SELECT p10 FROM phones2)
           OR RIGHT(REGEXP_REPLACE(c.TONUMBER,'[^0-9]',''),10) IN (SELECT p10 FROM phones2))
    GROUP BY c.TASKSID
    HAVING COUNT(DISTINCT w.CONVERSATION_ID) = 1
),
web_chat AS (
    SELECT m.CONVERSATION_ID, (SELECT phone FROM cust_phone) AS CUSTOMER_PHONE, MIN(m.CREATED_AT) AS FIRST_MSG
    FROM HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE m
    JOIN HARMONISED.PRODUCTION.TWILIO_CONVERSATION_USER u ON u.USER_IDENTITY = m.AUTHOR
    JOIN emails2 e ON e.em = LOWER(u.FRIENDLY_NAME)
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
        NULL::VARCHAR                                                            AS TRANSCRIPT_SID
    FROM MART_SALES_OPS.PRODUCTION.SOPHIE_CALLS_INCREMENTAL sc
    WHERE sc.EVENTTIMESTAMP >= DATEADD('day', -1 * :days, CURRENT_DATE())
      AND RIGHT(REGEXP_REPLACE(sc.CUSTOMERPHONENUMBER, '[^0-9]', ''), 10) IN (SELECT p10 FROM phones2)
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
        NULL::VARCHAR                                                            AS TRANSCRIPT_SID
    FROM CONFORMED.PRODUCTION.FCT_TWILIO_CALL_METRICS c
    WHERE c.TASKCHANNELNAME = 'voice'
      AND LOWER(NVL(c.WORKEREMAIL,'')) NOT LIKE '%sophie%'
      AND LOWER(NVL(c.WORKEREMAIL,'')) NOT LIKE '%amy-sdr%'
      AND c.WORKEREMAIL IS NOT NULL
      AND c.TALKTIME > 0
      AND c.EVENTTIMESTAMP >= DATEADD('day', -1 * :days, CURRENT_DATE())
      AND (
          RIGHT(REGEXP_REPLACE(c.FROMNUMBER, '[^0-9]', ''), 10) IN (SELECT p10 FROM phones2)
          OR RIGHT(REGEXP_REPLACE(c.TONUMBER, '[^0-9]', ''), 10) IN (SELECT p10 FROM phones2)
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
        sc.CALLSID                                                               AS TRANSCRIPT_SID
    FROM MART_SALES_OPS.PRODUCTION.SOPHIE_CHATS_INCREMENTAL sc
    WHERE sc.EVENTTIMESTAMP >= DATEADD('day', -1 * :days, CURRENT_DATE())
      AND sc.CUSTOMERPHONENUMBER LIKE '+%'
      AND RIGHT(REGEXP_REPLACE(sc.CUSTOMERPHONENUMBER, '[^0-9]', ''), 10) IN (SELECT p10 FROM phones2)
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
        aw.CH                                                                    AS TRANSCRIPT_SID
    FROM CONFORMED.PRODUCTION.FCT_TWILIO_CALL_METRICS c
    LEFT JOIN admin_wa_ch aw ON aw.TASKSID = c.TASKSID
    WHERE c.TASKCHANNELNAME = 'whatsapp'
      AND LOWER(NVL(c.WORKEREMAIL,'')) NOT LIKE '%sophie%'
      AND c.WORKEREMAIL IS NOT NULL
      AND c.EVENTTIMESTAMP >= DATEADD('day', -1 * :days, CURRENT_DATE())
      AND (
          RIGHT(REGEXP_REPLACE(c.FROMNUMBER, '[^0-9]', ''), 10) IN (SELECT p10 FROM phones2)
          OR RIGHT(REGEXP_REPLACE(c.TONUMBER, '[^0-9]', ''), 10) IN (SELECT p10 FROM phones2)
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
        sc.CALLSID                                                               AS TRANSCRIPT_SID
    FROM MART_SALES_OPS.PRODUCTION.SOPHIE_CHATS_INCREMENTAL sc
    WHERE sc.EVENTTIMESTAMP >= DATEADD('day', -1 * :days, CURRENT_DATE())
      AND (sc.CUSTOMERPHONENUMBER NOT LIKE '+%' OR sc.CUSTOMERPHONENUMBER IS NULL)
      AND RIGHT(REGEXP_REPLACE(sc.CUSTOMERPHONENUMBER, '[^0-9]', ''), 10) IN (SELECT p10 FROM phones2)
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
        NULL::VARCHAR                                                            AS TRANSCRIPT_SID
    FROM CONFORMED.PRODUCTION.FCT_TWILIO_CALL_METRICS c
    WHERE c.TASKCHANNELNAME = 'chat'
      AND LOWER(NVL(c.WORKEREMAIL,'')) NOT LIKE '%sophie%'
      AND c.WORKEREMAIL IS NOT NULL
      AND c.EVENTTIMESTAMP >= DATEADD('day', -1 * :days, CURRENT_DATE())
      AND (
          RIGHT(REGEXP_REPLACE(c.FROMNUMBER, '[^0-9]', ''), 10) IN (SELECT p10 FROM phones2)
          OR RIGHT(REGEXP_REPLACE(c.TONUMBER, '[^0-9]', ''), 10) IN (SELECT p10 FROM phones2)
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
        wc.CONVERSATION_ID                                                       AS TRANSCRIPT_SID
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
    u.RECORDING_URL,
    u.TRANSCRIPT_URL,
    u.ESCALATED,
    u.FIELDS_CHANGED,
    u.CONVERSATION_ID,
    u.TWILIO_CONSOLE_URL,
    flex.TWILIO_FLEX_URL,
    u.TRANSCRIPT_SID,
    CASE WHEN :mode = 'name' THEN 'Name — verify' ELSE 'Exact' END               AS MATCH_CONFIDENCE
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
ORDER BY u.INTERACTION_DATETIME DESC
LIMIT 5000
