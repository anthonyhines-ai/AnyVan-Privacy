------------------------------------------------------------------------------
-- sar_consent_history  (AV Dashboards named query; param :email)
-- Marketing / consent property-change history from HubSpot for this customer.
-- Resolves email -> HubSpot CONTACT_ID, then returns the consent/marketing
-- property changes over time (a proper opt-in/opt-out audit trail for a SAR).
-- Target dashboard: operations/sar-data-extract  (tab: Consent)
-- STATUS: authored from confirmed schema; validate in Snowflake before deploy
--         (confirm the NAME filter covers the live consent property keys).
------------------------------------------------------------------------------
WITH c AS (
  SELECT ID AS CONTACT_ID
  FROM HARMONISED.PRODUCTION.HUBSPOT_CONTACT
  WHERE LOWER(PROPERTY_EMAIL) = LOWER(:email)
    AND COALESCE(DELETED_ROW, FALSE) = FALSE
)
SELECT
  h.TIMESTAMP  AS CHANGED_AT,
  h.NAME       AS PROPERTY,
  h.VALUE,
  h.SOURCE,
  h.SOURCE_ID
FROM HARMONISED.PRODUCTION.HUBSPOT_CONTACT_PROPERTY_HISTORY h
JOIN c ON c.CONTACT_ID = h.CONTACT_ID
WHERE h.NAME ILIKE 'hs_marketable%'
   OR h.NAME ILIKE '%consent%'
   OR h.NAME ILIKE '%opt_out%'
   OR h.NAME ILIKE '%opt_in%'
   OR h.NAME ILIKE '%subscri%'
   OR h.NAME ILIKE '%marketing%'
ORDER BY h.TIMESTAMP DESC
LIMIT 5000
