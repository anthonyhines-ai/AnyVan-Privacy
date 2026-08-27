------------------------------------------------------------------------------
-- listing_calls_with_twilio_links.sql
--
-- Given an AnyVan listing/booking ID, return every associated voice call with:
--   * Flex Insights "Copy link" (drill-down URL)
--   * Twilio Console call-log link
--
-- Calls are matched by listing_id OR by ANY of the booking's phone numbers
-- (booking customer + collection contact + delivery contact), because
-- FCT_VOICE_INTERACTIONS.TWILIO_LISTING_ID is admin-entered and often NULL/wrong.
-- The caller is frequently the collection/delivery contact, not the lead customer.
--
-- Companion doc: docs/twilio-listing-call-lookup.md
-- Recording download links are NOT built here: the Recording SID must be fetched
-- live from the Twilio Recordings API (by Conference SID / Call SID) and the S3
-- link is a short-lived presign — see the doc, Step 4C.
------------------------------------------------------------------------------

-- Set the target listing (run this first, or substitute inline below).
SET listing_id = 9540980;

WITH listing AS (
    SELECT LISTING_ID, USER_ID, PICKUP_ADDRESS, DELIVERY_ADDRESS
    FROM HARMONISED.PRODUCTION.LISTING
    WHERE LISTING_ID = $listing_id
),

-- All phone numbers on the booking, reduced to digits only.
booking_numbers AS (
    SELECT DISTINCT REGEXP_REPLACE(num, '[^0-9]', '') AS digits
    FROM (
        SELECT PRIMARY_PHONE_NUMBER   AS num FROM CONFORMED.PRODUCTION.DIM_USER_CUSTOMER WHERE USER_ID = (SELECT USER_ID FROM listing)
        UNION ALL
        SELECT SECONDARY_PHONE_NUMBER AS num FROM CONFORMED.PRODUCTION.DIM_USER_CUSTOMER WHERE USER_ID = (SELECT USER_ID FROM listing)
        UNION ALL
        SELECT PHONE_NUMBER           AS num FROM HARMONISED.PRODUCTION.ADDRESS
            WHERE ADDRESS_ID IN (SELECT PICKUP_ADDRESS FROM listing UNION SELECT DELIVERY_ADDRESS FROM listing)
        UNION ALL
        SELECT MOBILE_PHONE_NUMBER    AS num FROM HARMONISED.PRODUCTION.ADDRESS
            WHERE ADDRESS_ID IN (SELECT PICKUP_ADDRESS FROM listing UNION SELECT DELIVERY_ADDRESS FROM listing)
    )
    WHERE num IS NOT NULL AND num <> ''
),

-- Calls matched to the booking by listing id OR by phone number.
-- Match uses the last 10 significant digits (drops country code / leading 0);
-- tune the length per market if needed.
calls AS (
    SELECT DISTINCT
        vi.CONFERENCE_ID,
        vi.CALL_DATE_TIME,
        vi.CALL_DIRECTION,
        vi.FROM_NUMBER,
        vi.TO_NUMBER,
        vi.CALLER_ROLE,
        vi.QUEUE_NAME,
        vi.WORKER_FULL_NAME,
        vi.TALK_TIME_SECS,
        vi.CUSTOMER_CALL_ID,
        vi.WORKER_CALL_ID,
        vi.TWILIO_LISTING_ID
    FROM CONFORMED.PRODUCTION.FCT_VOICE_INTERACTIONS vi
    WHERE vi.TWILIO_LISTING_ID = $listing_id
       OR EXISTS (
            SELECT 1
            FROM booking_numbers b
            WHERE LENGTH(b.digits) >= 7
              AND ( REGEXP_REPLACE(COALESCE(vi.FROM_NUMBER, ''), '[^0-9]', '') LIKE '%' || RIGHT(b.digits, 10) || '%'
                 OR REGEXP_REPLACE(COALESCE(vi.TO_NUMBER,   ''), '[^0-9]', '') LIKE '%' || RIGHT(b.digits, 10) || '%' )
          )
),

-- Flex Insights drill-down link per conference (the "Copy link").
flex AS (
    SELECT
        CONVERSATION_ATTRIBUTE_4 AS conference_sid,
        ANY_VALUE(CONVERSATION)  AS flex_insights_copy_link
    FROM HARMONISED.PRODUCTION.TWILIO_FLEX_INSIGHTS_BI_TWILIO_TELEPHONY
    WHERE CONVERSATION_ATTRIBUTE_4 ILIKE 'CF%'
    GROUP BY 1
)

SELECT
    c.CALL_DATE_TIME,                                   -- UTC (UK = +1 in BST)
    c.CALL_DIRECTION,
    c.FROM_NUMBER,
    c.TO_NUMBER,
    c.CALLER_ROLE,
    c.QUEUE_NAME,
    c.WORKER_FULL_NAME,
    c.TALK_TIME_SECS,
    c.CONFERENCE_ID,
    f.flex_insights_copy_link,
    'https://console.twilio.com/us1/monitor/logs/calls/' || c.CUSTOMER_CALL_ID AS twilio_console_link,
    c.CUSTOMER_CALL_ID,
    c.WORKER_CALL_ID,
    c.TWILIO_LISTING_ID
FROM calls c
LEFT JOIN flex f ON f.conference_sid = c.CONFERENCE_ID
ORDER BY c.CALL_DATE_TIME;
