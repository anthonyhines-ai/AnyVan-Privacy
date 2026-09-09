WITH wa_conv AS (
    SELECT
        RIGHT(REGEXP_REPLACE(m.AUTHOR,'[^0-9]',''),10)                           AS PHONE10,
        m.CONVERSATION_ID,
        MIN(m.CREATED_AT)                                                        AS WIN_START,
        MAX(m.CREATED_AT)                                                        AS WIN_END
    FROM HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE m
    WHERE m.AUTHOR LIKE 'whatsapp:%'
      AND m.CREATED_AT >= DATEADD('day', -10, CURRENT_DATE())
    GROUP BY 1, 2
),
admin_wa_ch AS (
    -- Resolve the human-agent WhatsApp task to its Twilio conversation via the customer's
    -- phone in the message author, bracketed by the task time. Keep only unambiguous matches
    -- (exactly one conversation) so we never show the wrong session's transcript.
    SELECT c.TASKSID, MAX(w.CONVERSATION_ID) AS CH
    FROM CONFORMED.PRODUCTION.FCT_TWILIO_CALL_METRICS c
    JOIN wa_conv w
      ON w.PHONE10 = RIGHT(REGEXP_REPLACE(CASE WHEN LOWER(c.TASKTYPE)='inbound' THEN c.FROMNUMBER ELSE c.TONUMBER END,'[^0-9]',''),10)
     AND c.EVENTTIMESTAMP BETWEEN DATEADD('hour',-6,w.WIN_START) AND DATEADD('hour',6,w.WIN_END)
    WHERE c.TASKCHANNELNAME='whatsapp'
      AND LOWER(NVL(c.WORKEREMAIL,'')) NOT LIKE '%sophie%'
      AND c.WORKEREMAIL IS NOT NULL
      AND c.EVENTTIMESTAMP >= DATEADD('day', -7, CURRENT_DATE())
    GROUP BY c.TASKSID
    HAVING COUNT(DISTINCT w.CONVERSATION_ID) = 1
),
ai_whatsapp AS (
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
        'https://av-public-2653.s3.eu-west-1.amazonaws.com/twilio-message-viewer.html?conversationId=' || te.CALLSID AS TRANSCRIPT_URL,
        COALESCE(sc.SOPHIE_ESCALATED, FALSE)                                    AS ESCALATED,
        sc.FIELDS_CHANGED,
        te.CALLSID                                                               AS TRANSCRIPT_SID
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
    LEFT JOIN MART_SALES_OPS.PRODUCTION.SOPHIE_CHATS_INCREMENTAL sc ON te.CALLSID = sc.CALLSID
    WHERE te.EVENTTYPE = 'task.created'
      AND te.TYPE ILIKE '%sophie%'   -- case-insensitive, for consistency (WhatsApp still gated to '+' phone below)
      AND te.CALLSID LIKE 'CH%'
      AND te.CUSTOMERPHONENUMBER LIKE '+%'
      AND te.EVENTTIMESTAMP >= DATEADD('day', -7, CURRENT_DATE())
    QUALIFY ROW_NUMBER() OVER (PARTITION BY te.CALLSID ORDER BY te.EVENTTIMESTAMP) = 1
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
        CASE WHEN c.CUSTOMERCALLSID IS NOT NULL
             THEN 'https://av-public-2653.s3.eu-west-1.amazonaws.com/twilio-message-viewer.html?conversationId=' || c.CUSTOMERCALLSID
             ELSE NULL END                                                       AS TRANSCRIPT_URL,
        FALSE::BOOLEAN                                                           AS ESCALATED,
        NULL::VARCHAR                                                            AS FIELDS_CHANGED,
        aw.CH                                                                    AS TRANSCRIPT_SID
    FROM CONFORMED.PRODUCTION.FCT_TWILIO_CALL_METRICS c
    LEFT JOIN admin_wa_ch aw ON aw.TASKSID = c.TASKSID
    WHERE c.TASKCHANNELNAME = 'whatsapp'
      AND LOWER(NVL(c.WORKEREMAIL,'')) NOT LIKE '%sophie%'
      AND c.WORKEREMAIL IS NOT NULL
      AND c.EVENTTIMESTAMP >= DATEADD('day', -7, CURRENT_DATE())
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
    'WhatsApp'                                                                   AS CHANNEL,
    c.TRANSCRIPT_URL,
    c.ESCALATED,
    c.FIELDS_CHANGED,
    c.TRANSCRIPT_SID,
    tc.STATE                                                                     AS CHAT_STATE
FROM (SELECT * FROM ai_whatsapp UNION ALL SELECT * FROM admin_whatsapp) c
LEFT JOIN MART_ENTERPRISE.PRODUCTION.ENTERPRISE_LISTING_EXTRACT ele
    ON c.LISTING_ID = ele.LISTING_ID
LEFT JOIN HARMONISED.PRODUCTION.TWILIO_CONVERSATION tc
    ON tc.ID = c.TRANSCRIPT_SID AND tc.DELETED_ROW = FALSE
ORDER BY c.INTERACTION_DATETIME DESC
LIMIT 5000
