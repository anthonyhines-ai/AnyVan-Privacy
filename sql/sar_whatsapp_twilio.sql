------------------------------------------------------------------------------
-- sar_whatsapp_twilio  (AV Dashboards named query; param :phone_suffix)
-- One-way automated WhatsApp + SMS bodies from Twilio, matched on the last 10
-- phone digits (handles 0.../44.../+44.../whatsapp:+44... via digit strip).
-- Target dashboard: operations/sar-data-extract  (tab: WhatsApp/SMS)
-- STATUS: authored from confirmed schema; validate in Snowflake before deploy.
------------------------------------------------------------------------------
SELECT
  DATE_SENT              AS SENT_AT,
  DIRECTION,
  "FROM"                 AS FROM_NUMBER,
  "TO"                   AS TO_NUMBER,
  BODY,
  STATUS,
  NUM_MEDIA
FROM HARMONISED.PRODUCTION.TWILIO_MESSAGE
WHERE RIGHT(REGEXP_REPLACE(COALESCE("TO",''),   '[^0-9]', ''), 10) = :phone_suffix
   OR RIGHT(REGEXP_REPLACE(COALESCE("FROM",''), '[^0-9]', ''), 10) = :phone_suffix
ORDER BY DATE_SENT DESC
LIMIT 5000
