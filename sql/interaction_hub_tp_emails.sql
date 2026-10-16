-- interaction_hub_tp_emails  (v1 — transport-partner data-subject search)
-- Serves a TP's data-subject request: resolve a transport partner, then list every job comm we
-- sent THAT TP across ALL their bookings. Companion to interaction_hub_emails (customer subject).
--
-- Attribution is EXACT, not allocation-window guesswork: HARMONISED.PRODUCTION.LISTING_COMMUNICATION
-- carries RECIPIENT_ID, and for TARGET='provider' rows that is the TP's USER_ID in
-- CONFORMED.PRODUCTION.DIM_USER_TRANSPORTPROVIDER. One listing can involve several TPs over its life
-- (deallocations, route-match offers, final assignment) — RECIPIENT_ID keeps each comm tied to the
-- TP that actually received it.
--
-- Class: TP-Marketing = job offers (route-match / route-match-back, pre-allocation);
--        TP-Transactional = servicing an allocated job (driver-assigned/reminder, job-changed,
--        job-completed, driver-deallocated).
-- Email-only (the Emails tab). Metadata only, no bodies.
-- Params: :mode ('tpid'|'name'|'phone'|'email'), :term_tpid, :term_name, :term_phone10, :term_email, :days
WITH tp AS (
  SELECT USER_ID, FULL_NAME, NICKNAME, EMAIL_ADDRESS
  FROM CONFORMED.PRODUCTION.DIM_USER_TRANSPORTPROVIDER
  WHERE (:mode='tpid'  AND :term_tpid<>''    AND (TO_VARCHAR(USER_ID)=:term_tpid OR ID=:term_tpid))
     OR (:mode='name'  AND :term_name<>''    AND (UPPER(TRIM(FULL_NAME))=:term_name OR UPPER(TRIM(NICKNAME))=:term_name))
     OR (:mode='phone' AND :term_phone10<>'' AND (
            RIGHT(REGEXP_REPLACE(PRIMARY_PHONE_NUMBER  ,'[^0-9]',''),10)=:term_phone10
         OR RIGHT(REGEXP_REPLACE(SECONDARY_PHONE_NUMBER,'[^0-9]',''),10)=:term_phone10))
     OR (:mode='email' AND :term_email<>''   AND LOWER(EMAIL_ADDRESS)=:term_email)
),
ids AS ( SELECT DISTINCT USER_ID FROM tp ),
tp_disp AS (
  SELECT USER_ID, COALESCE(NULLIF(TRIM(FULL_NAME),''), NULLIF(TRIM(NICKNAME),''), EMAIL_ADDRESS, 'TP '||USER_ID) AS disp
  FROM tp
)
SELECT
  CONVERT_TIMEZONE('Europe/London', lc.CREATED_AT)::TIMESTAMP_NTZ AS INTERACTION_DATETIME,
  'LC-' || lc.LISTING_COMMUNICATION_ID::string                    AS INTERACTION_ID,
  CASE WHEN lc.TYPE ILIKE 'route-match%' THEN 'TP-Marketing' ELSE 'TP-Transactional' END AS EMAIL_CLASS,
  INITCAP(REPLACE(lc.TYPE,'-',' '))                               AS EMAIL_TYPE,
  INITCAP(REPLACE(lc.TYPE,'-',' '))                               AS SUBJECT,
  COALESCE(d.disp, 'TP ' || lc.RECIPIENT_ID::string)             AS RECIPIENT,
  UPPER(lc.CHANNEL)                                              AS CHANNEL,
  'Outbound'                                                     AS DIRECTION,
  lc.TYPE                                                        AS CAMPAIGN,
  'transport_partner'                                           AS PARTY,
  lc.LISTING_ID                                                 AS LISTING_ID,
  lc.RECIPIENT_ID                                               AS TP_USER_ID
FROM HARMONISED.PRODUCTION.LISTING_COMMUNICATION lc
JOIN ids i          ON i.USER_ID = lc.RECIPIENT_ID
LEFT JOIN tp_disp d ON d.USER_ID = lc.RECIPIENT_ID
WHERE lc.TARGET='provider' AND lc.CHANNEL='email' AND lc.DELETED_ROW=FALSE
  AND lc.CREATED_AT >= DATEADD('day', -1 * :days, CURRENT_DATE())
ORDER BY INTERACTION_DATETIME DESC
LIMIT 3000
