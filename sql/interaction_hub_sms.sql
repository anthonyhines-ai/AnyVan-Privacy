------------------------------------------------------------------------------
-- interaction_hub_sms.sql
--
-- Source-of-truth SQL for the AV Dashboards saved query `interaction_hub_sms`
-- (register/update via the AV_Dashboards MCP). Powers the Interaction Hub SMS tab.
--
-- WHY: the hub had no SMS channel at all — the text messages AnyVan sends a customer
-- (driver-assigned, feedback-request, etc.) were invisible. They live in the
-- LISTING_COMMUNICATION spine (authoritative send log AND authoritative SMS body).
--
-- IDENTITY: same email/phone/name fan-out as interaction_hub_emails, so the front-end
-- passes the identical param set. The spine has no phone/email, so match it by the
-- customer's LISTING_IDs (resolved from user id) OR RECIPIENT_ID (the user id itself).
--
-- ⚠ PLATFORM GOTCHA: use GET(TRY_PARSE_JSON(TOKENS),'message'), NOT the Snowflake path
--    TOKENS:message. The AV Dashboards runQuery layer scans the SQL for ":word" bind
--    params and misreads ":message" (the JSON path) as a missing parameter, failing with
--    "Missing value for parameter :message". GET() avoids the colon-path entirely.
--
-- STATUS is a NUMBER dispatch code (2 = dispatched) — never a delivery/read receipt.
-- CREATED_AT is TIMESTAMP_TZ (UTC); converted to Europe/London for display.
--
-- Params: :mode ('phone'|'email'|'name'), :term_phone10, :term_email, :term_name, :days
--
-- Validated read-only + through the platform runQuery path (2026-09-11) for a live
-- single-listing UK customer: returned both customer SMS with full body text.
------------------------------------------------------------------------------

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
cust AS ( SELECT * FROM cust_seed WHERE (SELECT COUNT(DISTINCT USER_ID) FROM cust_seed) = 1 ),  -- single-customer guard
uids AS ( SELECT DISTINCT USER_ID FROM cust ),
cust_phone AS ( SELECT ANY_VALUE(PRIMARY_PHONE_NUMBER) AS phone FROM cust ),
listings AS (
    SELECT DISTINCT LISTING_ID FROM CONFORMED.PRODUCTION.MASTER_LISTING WHERE LISTING_USER_ID IN (SELECT USER_ID FROM uids)
    UNION
    SELECT DISTINCT LISTING_ID FROM HARMONISED.PRODUCTION.LISTING       WHERE USER_ID         IN (SELECT USER_ID FROM uids)
)
SELECT
    CONVERT_TIMEZONE('Europe/London', lc.CREATED_AT)::TIMESTAMP_NTZ   AS INTERACTION_DATETIME,
    lc.LISTING_COMMUNICATION_ID                                        AS INTERACTION_ID,
    lc.TYPE                                                            AS SMS_TYPE,
    GET(TRY_PARSE_JSON(lc.TOKENS), 'message')::string                 AS BODY,           -- authoritative SMS text
    (SELECT phone FROM cust_phone)                                     AS RECIPIENT,
    lc.LISTING_ID,
    CASE WHEN lc.STATUS = 2 THEN 'dispatched' ELSE 'status ' || lc.STATUS::string END AS DISPATCH_STATUS,
    'Outbound'                                                         AS DIRECTION,
    'https://www.anyvan.com/administer/instant-listings/' || lc.LISTING_ID::string
        || '/listing-communications/' || lc.LISTING_COMMUNICATION_ID::string || '/view'  AS ADMIN_VIEW_URL
FROM HARMONISED.PRODUCTION.LISTING_COMMUNICATION lc
WHERE lc.CHANNEL = 'sms' AND lc.TARGET = 'customer' AND lc.DELETED_ROW = FALSE
  AND ( lc.LISTING_ID IN (SELECT LISTING_ID FROM listings) OR lc.RECIPIENT_ID IN (SELECT USER_ID FROM uids) )
  AND lc.CREATED_AT >= DATEADD('day', -1 * :days, CURRENT_DATE())
ORDER BY lc.CREATED_AT DESC
LIMIT 3000;
