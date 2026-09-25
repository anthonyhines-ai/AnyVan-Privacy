------------------------------------------------------------------------------
-- sar_twilio_conversations  (AV Dashboards named query; param :phone_suffix)
-- Two-way conversational WhatsApp / chat message bodies (Twilio Conversations).
-- No phone column on the message; join via the participant's identity, matched
-- on the last 10 phone digits. Coverage from ~2026-05-01.
-- Target dashboard: operations/sar-data-extract  (tab: Chat 2-way)
-- STATUS: authored from confirmed schema; validate in Snowflake before deploy.
------------------------------------------------------------------------------
WITH parts AS (
  SELECT DISTINCT CONVERSATION_ID
  FROM HARMONISED.PRODUCTION.TWILIO_CONVERSATION_PARTICIPANT
  WHERE RIGHT(REGEXP_REPLACE(COALESCE(PARTICIPANT_IDENTITY,''), '[^0-9]', ''), 10) = :phone_suffix
)
SELECT
  m.CREATED_AT     AS SENT_AT,
  m.AUTHOR,
  m.BODY,
  m.CONVERSATION_ID
FROM HARMONISED.PRODUCTION.TWILIO_CONVERSATION_MESSAGE m
JOIN parts p ON p.CONVERSATION_ID = m.CONVERSATION_ID
ORDER BY m.CREATED_AT DESC
LIMIT 5000
