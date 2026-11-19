**INTERNAL — no customer personal data in this document itself** (methodology/schema reference
only; any example identifiers below are illustrative).

# Methodology — Phone number provenance / "I'm getting someone else's texts" (reusable)

How to investigate a complaint that a phone number is receiving communications meant for a
different AnyVan customer. Companion to `2026-08-18-phone-number-lookup-07497-700277.md` (finds
*bookings* for a number) and `METHODOLOGY-communication-history.md` (finds *all comms* for a
customer) — this one is specifically for **diagnosing how a number ended up on the wrong
account**, not just confirming it has. Distilled from the Paula Brown / `07495514972` lookup
(2026-11-17, `2026-11-17-phone-number-cross-contact-07495-514972.md`).

> Handle per the PII + secret-redaction rules in `/CLAUDE.md`. All Snowflake access is read-only.

---

## 0. The question to settle first

Before anything else: **is this one account with a stale number, or two accounts genuinely
colliding on the same number?** The complaint will usually be framed as the latter ("you're
sending me other customers' data") — don't assume that framing is correct. These have different
causes and different fixes, and `DIM_USER_CUSTOMER` **cannot tell you which one you've got** — it
only shows each user's *current* primary/secondary number, not history.

1. Find the `PHONE_NUMBER_ID` for the number:
   ```sql
   SELECT PHONE_NUMBER_ID, FULL_NUMBER, NATIONAL_NUMBER, CREATED_AT, DELETED_ROW
   FROM HARMONISED.PRODUCTION.PHONE_NUMBER
   WHERE FULL_NUMBER ILIKE '%7495514972%' OR NATIONAL_NUMBER ILIKE '%7495514972%';
   ```
2. Join to `USER_PHONE_NUMBER` on that `PHONE_NUMBER_ID` (not the other way via
   `DIM_USER_CUSTOMER`) to see **every** account it has ever been linked to:
   ```sql
   SELECT u.USER_ID, u.IS_CONTACT, u.IS_ALTERNATIVE, u.IS_SMS, u.CREATED_AT, u.DELETED_ROW
   FROM HARMONISED.PRODUCTION.USER_PHONE_NUMBER u
   WHERE u.PHONE_NUMBER_ID = <id>;
   ```
   **One row, one `USER_ID`, ever** → one account, stale/mis-linked number (go to §1).
   **Multiple distinct `USER_ID`s** → genuine cross-account collision — a different
   investigation (check whether the number was recycled by the telecom and both registrations are
   "real" at different times, or whether one customer mistyped another's live number).

---

## 1. One account, stale number — find out when and how it was set

1. `PRE_LISTING_PHONE_NUMBER` joined on the same `PHONE_NUMBER_ID` gives the `ADMIN_ID` and
   timestamp of every time it was captured/reused:
   ```sql
   SELECT PRE_LISTING_ID, ADMIN_ID, CREATED_AT, TYPE
   FROM HARMONISED.PRODUCTION.PRE_LISTING_PHONE_NUMBER
   WHERE PHONE_NUMBER_ID = <id> ORDER BY CREATED_AT;
   ```
   Admin-entered within the same minute(s) as account creation, reused by several admins over the
   following days = normal pattern for a phone/chat enquiry that converted. **Check what *other*
   `PHONE_NUMBER_ID` was captured in the same narrow time window** (same pre-listing/admin,
   created within minutes) — a second number captured at the same time that never got promoted to
   `USER_PHONE_NUMBER` is the strongest signal of "two numbers given, wrong one flagged as
   primary."
2. Pull the **booking's own address-level contact number** — this is a different field from the
   account's contact number and can (and did, in the worked example) carry a different, more
   current number than the account record:
   ```sql
   SELECT ADDRESS_ID, USER_ID, FIRSTNAME, LASTNAME, PHONE_NUMBER, MOBILE_PHONE_NUMBER,
          MOBILE_PHONE_NUMBER_ID, PHONE_NUMBER_ID
   FROM HARMONISED.PRODUCTION.ADDRESS
   WHERE ADDRESS_ID IN (<pickup_address_id>, <delivery_address_id>);
   ```
3. Cross-check **both** candidate numbers against real usage, all-time, no date filter:
   ```sql
   -- calls (combined Twilio + Aircall, all directions)
   SELECT CALL_DATE_TIME, CALL_DIRECTION, TO_NUMBER, FROM_NUMBER, CALLER_ROLE, WORKER_FULL_NAME
   FROM CONFORMED.PRODUCTION.FCT_VOICE_INTERACTIONS
   WHERE RIGHT(REGEXP_REPLACE(TO_NUMBER,'[^0-9]',''),10) = '<number>'
      OR RIGHT(REGEXP_REPLACE(FROM_NUMBER,'[^0-9]',''),10) = '<number>'
   ORDER BY CALL_DATE_TIME;

   -- WhatsApp
   SELECT LISTING_ID, DIRECTION, DATE, WORKERFULLNAME
   FROM MART_SALES_OPS.PRODUCTION.FACT_WHATSAPP_ACTIVITY
   WHERE RIGHT(REGEXP_REPLACE(CUSTOMERPHONENUMBER,'[^0-9]',''),10) = '<number>'
   ORDER BY DATE DESC;
   ```
   The number with real call/WhatsApp history is almost certainly the customer's actual number;
   the one with zero activity ever, despite being flagged `IS_SMS`/`IS_CONTACT` on the account, is
   the stale one firing transactional SMS to the wrong person.

---

## 2. The gotcha: a booking can be correct and the account still wrong

Don't stop once you've found the customer *did* log in at some point (checking `LAST_LOGIN_DATE`,
or a self-service row in `MART_SALES_OPS.PRODUCTION.FCT_LISTING_EDITS_ALL` with `IS_CUSTOMER = 1`)
— that only proves they *could* authenticate, not that the booking which captured the new/correct
number was created inside an authenticated session for that account.

**Check the specific pre-listing behind the booking, at its own creation:**
```sql
SELECT PRE_LISTING_ID, USER_ID, USER_EMAIL, STAGE_LAST, STAGE_MAX, CREATED_AT
FROM HARMONISED.PRODUCTION.PRE_LISTING
WHERE LISTING_ID = <listing_id>
ORDER BY CREATED_AT;
```
A **blank `USER_ID`** on the earliest row (identified only by email) means that booking started
as an **anonymous quote**. It can still convert into a listing under an existing account weeks or
months later — but that reconciliation happens by **matching the email address**, not by an
authenticated profile action, and an email-match reconciliation does not write back to the
account's own `USER_PHONE_NUMBER` record. That's the mechanism that lets a customer give AnyVan
their correct, current number on a new booking while their account's stored contact number stays
wrong indefinitely — and it doesn't require the customer to have "never logged in" in any general
sense, only that *this particular booking* didn't start as one.

Also check `FCT_LISTING_EDITS_ALL` for the listing — it tracks dates/volume/floor/special
instructions/address lat-lng, but **has no phone/contact-number column at all**. You will not find
a "customer tried to update their number" edit there even if one happened; its absence proves
nothing either way.

---

## 3. Validating a specific alleged contact ("I phoned to ask for it to be removed")

Search `FCT_VOICE_INTERACTIONS` with **no date filter first**, both `TO_NUMBER` and `FROM_NUMBER`.
Zero rows ever (not just zero in the period the complainant mentioned) is a materially different,
stronger finding than "none in the last 3 months" — report which one you actually found, and say
plainly that absence of a record doesn't prove the contact didn't happen (it may have gone through
a channel not wired into this warehouse, or not been logged).

---

## 4. Caveats (learned)

- `DIM_USER_CUSTOMER.PRIMARY_PHONE_NUMBER` / `SECONDARY_PHONE_NUMBER` are **point-in-time
  snapshots** of the "most recent" `IS_CONTACT`/`IS_ALTERNATIVE` phone — they do not show history
  and cannot distinguish one-account-stale-number from two-account-collision. Always go via
  `USER_PHONE_NUMBER` joined on `PHONE_NUMBER_ID`.
- `PHONE_NUMBER.LAST_SMS` / `LAST_RECEIVED` / `LAST_CALLED` were blank even for a number that
  demonstrably did receive SMS (per the customer's own evidence) — don't rely on these fields to
  prove or disprove delivery; they're not a reliable message log. For a SAR asking for "a copy of
  every text sent," this warehouse does not hold that log — it has to be sourced from the
  SMS/Twilio send-side system directly.
- `FCT_LISTING_EDITS_ALL` and `ADMIN_LISTING_NOTES` are good for corroborating *when* a customer
  was genuinely engaging (dates, WA note timestamps) but neither captures phone/contact-number
  changes — don't expect either to show an "attempted number update."
- As elsewhere in this repo: normalise phone numbers to last-10-digits before any match; `"FROM"`
  / `"TO"` are reserved words; `LISTING_TERRORITY` is an intentional typo.

---

## 5. Record structure (what to write)

One dated record under `booking-lookups/`, following the house style, with (at minimum):
1. **Request** — verbatim, plus the specific sub-questions asked (e.g. "did they call," "how did
   the number get added," "who were the bookings for," "were they logged in").
2. **One-account-or-two** finding (§0) stated explicitly, first.
3. **Provenance** — when/how the number was captured, by whom, and what the other candidate
   number(s) from the same capture event were.
4. **Live-number cross-check** (§1.3) — a short table, both numbers, calls/WA, all-time.
5. **Login/anonymous-booking finding** (§2) if relevant — don't conflate "ever logged in" with
   "this booking was authenticated."
6. **Observations** — root cause stated plainly, and whether the complainant's own account of
   events matches the data (say so even where it doesn't — it affects how the response is worded).
7. **Governance** — read-only confirmation, retention note, and an explicit owner + date for any
   outstanding fix (account correction, consent withdrawal) — never "flag for review" with no
   owner.
