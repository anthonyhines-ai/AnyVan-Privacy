------------------------------------------------------------------------------
-- sar_messaging  (AV Dashboards named query; param :email)
-- Modern messaging-platform sends for a customer: EMAIL + RCS + WHATSAPP,
-- with rendered subject, body, template, and marketing/transactional consent.
-- One table covers all these channels. Coverage: EMAIL/RCS from 2026-05-19,
-- WHATSAPP from 2026-06-17 (older/other channels: sar_comms_log, sar_whatsapp_twilio).
-- Keyed directly on RESOLVED_USER_EMAIL (no join needed).
-- Target dashboard: operations/sar-data-extract  (tab: Messaging)
-- STATUS: Snowflake-validated (compiles; columns confirmed 2026-09).
------------------------------------------------------------------------------
SELECT
  EVENT_TIMESTAMP,
  CHANNEL,
  EVENT_NAME,
  TEMPLATE_KEY,
  RENDERED_SUBJECT,
  MESSAGE                                   AS BODY,
  CHANNEL_RECIPIENT,
  DELIVERY_MODE,
  CASE WHEN RESOLVED_USER_CONSENT_MARKETING     THEN 'Yes' ELSE 'No' END AS CONSENT_MARKETING,
  CASE WHEN RESOLVED_USER_CONSENT_TRANSACTIONAL THEN 'Yes' ELSE 'No' END AS CONSENT_TRANSACTIONAL,
  REQUEST_METADATA_CONTEXT:listingId::string AS LISTING_ID
FROM HARMONISED.PRODUCTION.EVENTS_MESSAGING_MESSAGE
WHERE LOWER(RESOLVED_USER_EMAIL) = LOWER(:email)
ORDER BY EVENT_TIMESTAMP DESC
LIMIT 5000
