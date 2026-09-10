WITH ai_livechat AS (
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
        te.CALLSID                                                               AS CONVO_SID
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
      AND te.TYPE ILIKE '%sophie%'   -- case-insensitive: also captures 'sophie_webchat' (web LiveChat)
      AND te.CALLSID LIKE 'CH%'
      AND (te.CUSTOMERPHONENUMBER NOT LIKE '+%' OR te.CUSTOMERPHONENUMBER IS NULL)
      AND te.EVENTTIMESTAMP >= DATEADD('day', -7, CURRENT_DATE())
    QUALIFY ROW_NUMBER() OVER (PARTITION BY te.CALLSID ORDER BY te.EVENTTIMESTAMP) = 1
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
        CASE WHEN c.CUSTOMERCALLSID IS NOT NULL
             THEN 'https://av-public-2653.s3.eu-west-1.amazonaws.com/twilio-message-viewer.html?conversationId=' || c.CUSTOMERCALLSID
             ELSE NULL END                                                       AS TRANSCRIPT_URL,
        FALSE::BOOLEAN                                                           AS ESCALATED,
        NULL::VARCHAR                                                            AS FIELDS_CHANGED,
        c.CUSTOMERCALLSID                                                        AS CONVO_SID
    FROM CONFORMED.PRODUCTION.FCT_TWILIO_CALL_METRICS c
    WHERE c.TASKCHANNELNAME = 'chat'
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
    'LiveChat'                                                                   AS CHANNEL,
    c.TRANSCRIPT_URL,
    c.ESCALATED,
    c.FIELDS_CHANGED,
    tc.STATE                                                                     AS CHAT_STATE
FROM (SELECT * FROM ai_livechat UNION ALL SELECT * FROM admin_livechat) c
LEFT JOIN MART_ENTERPRISE.PRODUCTION.ENTERPRISE_LISTING_EXTRACT ele
    ON c.LISTING_ID = ele.LISTING_ID
LEFT JOIN HARMONISED.PRODUCTION.TWILIO_CONVERSATION tc
    ON tc.ID = c.CONVO_SID AND tc.DELETED_ROW = FALSE
ORDER BY c.INTERACTION_DATETIME DESC
LIMIT 5000
