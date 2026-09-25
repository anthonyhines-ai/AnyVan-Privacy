------------------------------------------------------------------------------
-- sar_messages_all  (AV Dashboards named query; param :phone_suffix)
-- CONSOLIDATED "Messages" tab for the SAR extract dashboard. One row per
-- message, tagged with a TYPE column, across every non-voice channel we hold:
--   WhatsApp/SMS -> HARMONISED.PRODUCTION.TWILIO_MESSAGE                  ('whatsapp:' prefix => WhatsApp)
--   2-way chat   -> HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE     (+ _PARTICIPANT; incl. AnyVan.com live chat, ~2026-05+)
--   Platform     -> HARMONISED.PRODUCTION.EVENTS_MESSAGING_MESSAGE        (CHANNEL<>'EMAIL': WhatsApp/RCS/Push/SMS; 2026-05-19+)
--   System log   -> HARMONISED.PRODUCTION.LISTING_COMMUNICATION           (CHANNEL sms / whats-app send-log; 2022+)
-- Replaces the per-source queries: sar_sms, sar_whatsapp_twilio,
-- sar_twilio_conversations, sar_messaging (non-email rows), and the SMS/WhatsApp
-- slice of sar_listing_comms / sar_comms_log.
-- Matched on the last 10 phone digits (:phone_suffix). The send-log arm resolves
-- the phone to USER_ID via DIM_USER_CUSTOMER (RECIPIENT_ID = USER_ID).
-- Live-chat bodies before ~Apr-2026 are not in Snowflake (known gap).
-- Text columns cast ::string and timestamps ::TIMESTAMP_NTZ so the UNION arms
-- share one type per column.
-- Shared column contract: OCCURRED_AT, TYPE, SUBJECT, STATUS, BODY, REFERENCE, DETAIL.
-- STATUS: Snowflake-validated (compiles; dummy :phone_suffix -> 0 rows, no PII).
------------------------------------------------------------------------------
WITH u AS (
  SELECT DISTINCT USER_ID
  FROM CONFORMED.PRODUCTION.DIM_USER_CUSTOMER
  WHERE RIGHT(REGEXP_REPLACE(COALESCE(PRIMARY_PHONE_NUMBER,   ''), '[^0-9]', ''), 10) = :phone_suffix
     OR RIGHT(REGEXP_REPLACE(COALESCE(SECONDARY_PHONE_NUMBER, ''), '[^0-9]', ''), 10) = :phone_suffix
)
SELECT * FROM (
  -- Twilio SMS / one-way WhatsApp
  SELECT
    tm.DATE_SENT::TIMESTAMP_NTZ                              AS OCCURRED_AT,
    CASE WHEN tm."FROM" ILIKE 'whatsapp:%' OR tm."TO" ILIKE 'whatsapp:%'
         THEN 'WhatsApp' ELSE 'SMS' END                     AS TYPE,
    CAST(NULL AS VARCHAR)                                    AS SUBJECT,
    tm.DIRECTION::string                                     AS STATUS,
    tm.BODY::string                                          AS BODY,
    tm.ID::string                                           AS REFERENCE,
    ('From ' || COALESCE(tm."FROM", '') || ' To ' || COALESCE(tm."TO", ''))::string AS DETAIL
  FROM HARMONISED.PRODUCTION.TWILIO_MESSAGE tm
  WHERE RIGHT(REGEXP_REPLACE(COALESCE(tm."FROM", ''), '[^0-9]', ''), 10) = :phone_suffix
     OR RIGHT(REGEXP_REPLACE(COALESCE(tm."TO",   ''), '[^0-9]', ''), 10) = :phone_suffix

  UNION ALL
  -- Two-way conversational chat (WhatsApp / AnyVan.com live chat)
  SELECT
    cm.CREATED_AT::TIMESTAMP_NTZ,
    '2-way chat',
    CAST(NULL AS VARCHAR),
    CAST(NULL AS VARCHAR),
    cm.BODY::string,
    cm.CONVERSATION_ID::string,
    cm.AUTHOR::string
  FROM HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE cm
  JOIN (
    SELECT DISTINCT CONVERSATION_ID
    FROM HARMONISED.PRODUCTION.TWILIO_CONVERSATION_PARTICIPANT
    WHERE RIGHT(REGEXP_REPLACE(COALESCE(PARTICIPANT_IDENTITY, ''), '[^0-9]', ''), 10) = :phone_suffix
  ) p ON p.CONVERSATION_ID = cm.CONVERSATION_ID

  UNION ALL
  -- Messaging platform, non-email channels (WhatsApp / RCS / Push / SMS)
  SELECT
    mm.EVENT_TIMESTAMP::TIMESTAMP_NTZ,
    mm.CHANNEL::string,
    mm.RENDERED_SUBJECT::string,
    mm.EVENT_NAME::string,
    mm.MESSAGE::string,
    mm.REQUEST_METADATA_CONTEXT:listingId::string,
    ('template=' || COALESCE(mm.TEMPLATE_KEY, ''))::string
  FROM HARMONISED.PRODUCTION.EVENTS_MESSAGING_MESSAGE mm
  WHERE mm.CHANNEL <> 'EMAIL'
    AND RIGHT(REGEXP_REPLACE(COALESCE(mm.RESOLVED_USER_PHONE, ''), '[^0-9]', ''), 10) = :phone_suffix

  UNION ALL
  -- System send-log, SMS / WhatsApp channels
  SELECT
    lc.CREATED_AT::TIMESTAMP_NTZ,
    'System log',
    TRY_PARSE_JSON(lc.TOKENS):subject::string,
    lc.STATUS::string,
    lc.DETAILS::string,
    lc.LISTING_ID::string,
    lc.CHANNEL::string
  FROM HARMONISED.PRODUCTION.LISTING_COMMUNICATION lc
  JOIN u ON u.USER_ID = lc.RECIPIENT_ID
  WHERE COALESCE(lc.DELETED_ROW, FALSE) = FALSE
    AND (lc.CHANNEL ILIKE 'sms' OR lc.CHANNEL ILIKE 'whats-app')
)
ORDER BY OCCURRED_AT DESC
LIMIT 5000
