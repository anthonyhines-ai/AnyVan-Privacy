-- interaction_hub_emails  (v3 — lifecycle classifier + customer/transport-partner party)
-- Emails tab (customer-scoped). Category is decided by BOOKING LIFECYCLE, not sending platform:
--   customer party:
--     Transactional = sent while a booking is live (listing created -> completed), INCLUDING
--                     agent-generated HubSpot sends that land inside the window (e.g. day-of-move).
--     Marketing     = sent OUTSIDE any live booking (pre-listing quote nurture, or post-completion
--                     win-back). HubSpot only.
--   transport-partner party (comms about the customer's job sent to the allocated driver/TP):
--     TP-Marketing     = job offers (route-match / route-match-back) — pre-allocation.
--     TP-Transactional = servicing an allocated job (driver-assigned/reminder, job-changed,
--                        job-completed, driver-deallocated).
-- Per-booking app comms = LISTING_COMMUNICATION (CHANNEL='email'); HubSpot marketing = EVENTS_EMAIL.
-- Identity fans out across duplicate accounts sharing a phone. Metadata only, no bodies. Freshdesk
-- (inbound/operational) is a manual link, not this query.
-- Params: :mode ('phone'|'email'|'name'), :term_phone10, :term_email, :term_name, :days
WITH seed AS (
    SELECT USER_ID, LOWER(EMAIL_ADDRESS) AS email,
           RIGHT(REGEXP_REPLACE(PRIMARY_PHONE_NUMBER  ,'[^0-9]',''),10) AS p1,
           RIGHT(REGEXP_REPLACE(SECONDARY_PHONE_NUMBER,'[^0-9]',''),10) AS p2
    FROM CONFORMED.PRODUCTION.DIM_USER_CUSTOMER
    WHERE (:mode='phone' AND :term_phone10<>'' AND (
             RIGHT(REGEXP_REPLACE(PRIMARY_PHONE_NUMBER  ,'[^0-9]',''),10)=:term_phone10
          OR RIGHT(REGEXP_REPLACE(SECONDARY_PHONE_NUMBER,'[^0-9]',''),10)=:term_phone10))
       OR (:mode='email' AND :term_email<>'' AND LOWER(EMAIL_ADDRESS)=:term_email)
       OR (:mode='name'  AND :term_name<>''  AND UPPER(TRIM(FULL_NAME))=:term_name)
),
seed_phones AS (
    SELECT p1 AS p10 FROM seed WHERE p1 IS NOT NULL AND LENGTH(p1)=10
    UNION SELECT p2 FROM seed WHERE p2 IS NOT NULL AND LENGTH(p2)=10
    UNION SELECT :term_phone10 FROM (SELECT 1) WHERE :mode='phone' AND LENGTH(:term_phone10)=10
),
linked AS (
    SELECT c.USER_ID, LOWER(c.EMAIL_ADDRESS) AS email,
           RIGHT(REGEXP_REPLACE(c.PRIMARY_PHONE_NUMBER  ,'[^0-9]',''),10) AS p1,
           RIGHT(REGEXP_REPLACE(c.SECONDARY_PHONE_NUMBER,'[^0-9]',''),10) AS p2
    FROM CONFORMED.PRODUCTION.DIM_USER_CUSTOMER c
    WHERE c.USER_ID IN (SELECT USER_ID FROM seed)
       OR RIGHT(REGEXP_REPLACE(c.PRIMARY_PHONE_NUMBER  ,'[^0-9]',''),10) IN (SELECT p10 FROM seed_phones)
       OR RIGHT(REGEXP_REPLACE(c.SECONDARY_PHONE_NUMBER,'[^0-9]',''),10) IN (SELECT p10 FROM seed_phones)
),
ids AS ( SELECT DISTINCT USER_ID FROM linked ),
user_email AS ( SELECT USER_ID, MAX(email) AS email FROM linked GROUP BY USER_ID ),
emails2 AS (
    SELECT DISTINCT em FROM (
        SELECT email AS em FROM linked WHERE email IS NOT NULL AND email<>''
        UNION SELECT :term_email AS em FROM (SELECT 1) WHERE :mode='email' AND :term_email<>''
    )
),
listings AS (
    SELECT DISTINCT ml.LISTING_ID, ml.LISTING_USER_ID
    FROM CONFORMED.PRODUCTION.MASTER_LISTING ml
    WHERE ml.LISTING_USER_ID IN (SELECT USER_ID FROM ids)
),
cust_windows AS (
    SELECT ml.LISTING_CREATED_DATE AS created_at, ml.LISTING_COMPLETED_DATE AS completed_at
    FROM CONFORMED.PRODUCTION.MASTER_LISTING ml
    WHERE ml.LISTING_USER_ID IN (SELECT USER_ID FROM ids)
),
txn AS (
    SELECT
        CONVERT_TIMEZONE('Europe/London', lc.CREATED_AT)::TIMESTAMP_NTZ AS INTERACTION_DATETIME,
        'LC-' || lc.LISTING_COMMUNICATION_ID::string                    AS INTERACTION_ID,
        CASE WHEN lc.TARGET='provider' AND lc.TYPE ILIKE 'route-match%' THEN 'TP-Marketing'
             WHEN lc.TARGET='provider'                                  THEN 'TP-Transactional'
             ELSE 'Transactional' END                                   AS EMAIL_CLASS,
        INITCAP(REPLACE(lc.TYPE,'-',' '))                               AS EMAIL_TYPE,
        INITCAP(REPLACE(lc.TYPE,'-',' '))                               AS SUBJECT,
        CASE WHEN lc.TARGET='provider' THEN '(transport partner)' ELSE ue.email END AS RECIPIENT,
        'EMAIL'                                                         AS CHANNEL,
        'Outbound'                                                      AS DIRECTION,
        lc.TYPE                                                         AS CAMPAIGN,
        CASE WHEN lc.TARGET='provider' THEN 'transport_partner' ELSE 'customer' END AS PARTY
    FROM HARMONISED.PRODUCTION.LISTING_COMMUNICATION lc
    JOIN listings ls        ON ls.LISTING_ID = lc.LISTING_ID
    LEFT JOIN user_email ue ON ue.USER_ID   = ls.LISTING_USER_ID
    WHERE lc.CHANNEL='email' AND lc.DELETED_ROW=FALSE
      AND lc.CREATED_AT >= DATEADD('day', -1 * :days, CURRENT_DATE())
),
mkt AS (
    SELECT
        CONVERT_TIMEZONE('Europe/London', e.EVENT_TIMESTAMP)::TIMESTAMP_NTZ AS INTERACTION_DATETIME,
        e.PAYLOAD:emailEventId::string                                  AS INTERACTION_ID,
        CASE WHEN EXISTS (SELECT 1 FROM cust_windows w
                          WHERE e.EVENT_TIMESTAMP >= w.created_at
                            AND e.EVENT_TIMESTAMP <= COALESCE(w.completed_at, CURRENT_TIMESTAMP()))
             THEN 'Transactional' ELSE 'Marketing' END                 AS EMAIL_CLASS,
        COALESCE(e.PAYLOAD:emailName::string,'(campaign)')              AS EMAIL_TYPE,
        e.EMAIL_SUBJECT                                                 AS SUBJECT,
        e.EMAIL_ADDRESS                                                 AS RECIPIENT,
        'EMAIL'                                                         AS CHANNEL,
        'Outbound'                                                      AS DIRECTION,
        e.PAYLOAD:emailName::string                                     AS CAMPAIGN,
        'customer'                                                      AS PARTY
    FROM HARMONISED.PRODUCTION.EVENTS_EMAIL e
    WHERE e.EMAIL_EVENT_TYPE='sent' AND e.SOURCE='hubspot'
      AND e.EVENT_DATE >= DATEADD('day', -1 * :days, CURRENT_DATE())
      AND LOWER(e.EMAIL_ADDRESS) IN (SELECT em FROM emails2)
)
SELECT * FROM txn
UNION ALL SELECT * FROM mkt
ORDER BY INTERACTION_DATETIME DESC
LIMIT 3000
