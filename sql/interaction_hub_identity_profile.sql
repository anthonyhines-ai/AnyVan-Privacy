-- interaction_hub_identity_profile
-- Companion to interaction_hub_identity_lookup. Resolves a customer from email/phone/name
-- and returns the fanned-out identity set (all user_ids, names, emails, primary+secondary
-- phones) plus a resolution flag (unique/ambiguous/none) so the Interaction Hub can render
-- an "identity card" for cross-checking. Ambiguous matches are surfaced as a count only —
-- the UI never merges several people's identifiers into one card.
-- Params: :mode ('phone'|'email'|'name'), :term_phone10, :term_email, :term_name
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
agg AS (
    SELECT
        COUNT(DISTINCT USER_ID)                                         AS seed_customers,
        LISTAGG(DISTINCT TO_VARCHAR(USER_ID), ', ')                     AS user_ids,
        LISTAGG(DISTINCT NULLIF(TRIM(FULL_NAME),''), ', ')              AS names,
        LISTAGG(DISTINCT LOWER(EMAIL_ADDRESS), ', ')                    AS emails,
        LISTAGG(DISTINCT NULLIF(TRIM(PRIMARY_PHONE_NUMBER),''), ', ')   AS primary_phones,
        LISTAGG(DISTINCT NULLIF(TRIM(SECONDARY_PHONE_NUMBER),''), ', ') AS secondary_phones
    FROM cust_seed
)
SELECT
    seed_customers, user_ids, names, emails, primary_phones, secondary_phones,
    CASE WHEN seed_customers = 1 THEN 'unique'
         WHEN seed_customers = 0 THEN 'none'
         ELSE 'ambiguous' END AS resolution
FROM agg
