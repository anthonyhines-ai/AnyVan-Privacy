"""
Shared field ids/labels and content blocks for the "AnyVan UK - Privacy Requests" Formstack form
(id 6559077), used by both build-formstack-notifications.py (the internal email to
privacy@anyvan.com that raises the Freshdesk ticket) and build-formstack-confirmations.py (the
acknowledgement email to the requester). Keeping the content in one module means the two
audiences never drift apart on field ids, and both share the same visual design: Georgia serif,
an 18px body / 24px bold headline, and <hr> section dividers, matching the format of Ant's
original hand-built notification ("Customer Privacy Request Email [UK]", id 9711486).

Field ids/labels confirmed live via GET /forms/6559077/fields (2026-09-24); keep in sync with
docs/dsr-field-mapping.md.

⚠️ Formstack notification cap discovered live 2026-09-25: this form's plan allows at most 5
notification emails total. There is no such cap on confirmations (16 created in testing with no
error). Notifications are therefore keyed by REQUEST TYPE only (5 total, one per request type,
each showing exactly and only that type's own fields, no blanks) rather than by requester type:
Ant confirmed the request-type detail (dates, categories, deletion scope, etc.) is what needs
precise capture, so that's the axis that gets the full 5-slot budget. Requester-type detail (a
handful of TP/third-party identity fields) is the smaller compromise and is shown unconditionally
in every notification, blank when not applicable. Confirmations keep the full 3x5 = 15-variant
matrix. See docs/dsr-notification-matrix.md.
"""

DUE_DATE = ("197302298", "Privacy Due Date")
REQ_FULLNAME = ("197276071", "Full name [of the Data Subject]")
REQ_EMAIL = ("197276072", "Email Address")
REQ_PHONE = ("197276073", "Phone Number")
REQ_ALT_PHONE = ("197276074", "Alternative phone number")
REQ_BOOKING = ("197276080", "AnyVan Booking Reference/s [If Any]")

TP_BUSINESS_TYPE = ("197276081", "Business type")
TP_TRADING_NAME = ("197276082", "Trading name")
TP_COMPANY_NAME = ("197276083", "Registered Company / Partnership Name")
TP_USERNAME = ("197276084", "Transport Partner Username")

TPARTY_AUTH_DETAILS = ("197276085", "Authorisation details")
TPARTY_PROOF = ("197276086", "Proof of authorisation [PDF/JPG/PNG]")

SAR_CATEGORIES = ("197276090", "What data would you like to access?")
SAR_ALLDATA_FROM = ("197276095", "All Data - Earliest Interaction")
SAR_ALLDATA_TO = ("197276096", "All Data - Most Recent Interaction")
SAR_CHAT_METHOD = ("197276094", "Chat Method Used")
SAR_CHAT_FROM = ("197276092", "Chat Transcripts - From Date")
SAR_CHAT_TO = ("197668331", "Chat Transcripts - To Date")
SAR_EMAIL_FROM = ("197668332", "Email Correspondence - From Date")
SAR_EMAIL_TO = ("197276093", "Email Correspondence  - To Date")  # double space is live-label-exact
SAR_CALL_FROM = ("197277114", "Call/Video Recordings - From Date")
SAR_CALL_TO = ("197277122", "Call/Video Recordings - To Date")
SAR_REASON = ("197276097", "Why are you requesting this Data?")

RECT_WHICH = ("197276100", "Which data needs correcting?")
RECT_CORRECT_INFO = ("197276101", "Please provide the correct information")

DEL_SCOPE = ("197276099", "What data would you like deleted?")

ADDITIONAL_INFO = ("197276106", "Additional Information")

REQUEST_TYPE_RAW = ("197276089", "What would you like us to do?")
REQUESTER_TYPE_RAW = ("197276069", "Are You.......")
SUBMISSION_ID = "{$_submission_id}"

REQUESTER_TYPE_FIELD = "197276069"
REQUEST_TYPE_FIELD = "197276089"

# (internal kind, display label, live Formstack option string)
REQUESTERS = [
    ("customer", "Customer", "A Customer"),
    ("tp", "Transport Partner", "A Transport Partner"),
    ("third_party", "Authorised Third Party", "An Authorised Third Party"),
]

REQUEST_TYPES = [
    ("sar", "SAR", "Subject Access Request"),
    ("rectification", "Rectification", "Correct My Data"),
    ("deletion", "Deletion", "Delete My Data"),
    ("portability", "Data Portability", "Data Portability"),
    ("marketing", "Marketing Opt-Out", "Marketing Opt-Out"),
]


def mt(field):
    fid, label = field
    return "{$%s %s}" % (fid, label)


# ---------------------------------------------------------------------------
# Shared visual design: Georgia serif, 18px body / 24px bold headline, <hr> dividers.
# Matches Ant's original hand-built notification ("Customer Privacy Request Email [UK]").
# ---------------------------------------------------------------------------

def p(html, size=18):
    return '<p><span style="font-size: %dpx; font-family: Georgia, serif;">%s</span></p>' % (size, html)


def h(text, size=18):
    return '<p><span style="font-size: %dpx; font-family: Georgia, serif;"><strong>%s</strong></span></p>' % (size, text)


def headline(text):
    return '<p><span style="font-family: Georgia, serif; font-size: 24px;"><strong>%s</strong></span></p>' % text


HR = "<hr>"


# ---------------------------------------------------------------------------
# Blocks shared by both notifications and confirmations
# ---------------------------------------------------------------------------

def requester_subject_block():
    return (
        h("Requester &amp; Subject")
        + p("Full Name: %s" % mt(REQ_FULLNAME))
        + p("Email Address: %s" % mt(REQ_EMAIL))
        + p("Primary Phone Number: %s | Alternative Phone Number: %s" % (mt(REQ_PHONE), mt(REQ_ALT_PHONE)))
        + p("AnyVan Booking Reference: %s" % mt(REQ_BOOKING))
        + HR
    )


def requester_type_block(kind):
    if kind == "customer":
        return ""
    if kind == "tp":
        return (
            h("Transport Partner Details")
            + p("Business Type: %s" % mt(TP_BUSINESS_TYPE))
            + p("Trading Name: %s" % mt(TP_TRADING_NAME))
            + p("Registered Company / Partnership Name: %s" % mt(TP_COMPANY_NAME))
            + p("Transport Partner Username: %s" % mt(TP_USERNAME))
            + HR
        )
    if kind == "third_party":
        return (
            h("Authorised Third Party Details")
            + p("Authorisation Details: %s" % mt(TPARTY_AUTH_DETAILS))
            + p("Proof of Authorisation: %s" % mt(TPARTY_PROOF))
            + p(
                "<em>No acting-party contact email is captured on this form; the requester email "
                "above is the data subject's. Verify authorisation before proceeding.</em>",
                size=14,
            )
            + HR
        )
    raise ValueError(kind)


def request_type_block(kind):
    if kind == "sar":
        return (
            h("Subject Access Request Details")
            + p("Data Categories Requested: %s" % mt(SAR_CATEGORIES))
            + p("All Data From: %s to %s" % (mt(SAR_ALLDATA_FROM), mt(SAR_ALLDATA_TO)))
            + p("Chat Method Used: %s" % mt(SAR_CHAT_METHOD))
            + p("Chat Transcripts From: %s to %s" % (mt(SAR_CHAT_FROM), mt(SAR_CHAT_TO)))
            + p("Email Correspondence From: %s to %s" % (mt(SAR_EMAIL_FROM), mt(SAR_EMAIL_TO)))
            + p("Call/Video Recordings From: %s to %s" % (mt(SAR_CALL_FROM), mt(SAR_CALL_TO)))
            + p("Reason For Request: %s" % mt(SAR_REASON))
            + HR
        )
    if kind == "rectification":
        return (
            h("Rectification Details")
            + p("Which Data Needs Correcting: %s" % mt(RECT_WHICH))
            + p("Correct Information Supplied: %s" % mt(RECT_CORRECT_INFO))
            + HR
        )
    if kind == "deletion":
        return h("Deletion Details") + p("Deletion Scope Requested: %s" % mt(DEL_SCOPE)) + HR
    if kind == "portability":
        return (
            h("Data Portability")
            + p("No extra input is captured for this request type on the form. Fulfil per the standard CSV/JSON export within 30 days.")
            + HR
        )
    if kind == "marketing":
        return (
            h("Marketing Opt-Out")
            + p("No extra input is captured for this request type on the form. Action per the standard opt-out process.")
            + HR
        )
    raise ValueError(kind)


def all_requester_type_blocks():
    """TP + Third Party blocks concatenated (Customer's block is empty, so it isn't needed here),
    for the notification design forced by the 5-notification-per-form cap: notifications are keyed
    by request type, so the actual requester type isn't known until the reader sees which block
    has populated fields (the other one renders blank). This is the smaller of the two possible
    compromises: requester-type detail is a handful of identity fields, versus the full
    request-type detail (dates, categories, deletion scope) that stays exact per notification.
    See the module docstring."""
    return requester_type_block("tp") + requester_type_block("third_party")


def footer_block():
    return (
        h("Additional Information")
        + p("Additional Information: %s" % mt(ADDITIONAL_INFO))
        + p("Declaration confirmed by requester (UK GDPR Art. 12(3)).", size=14)
    )


# ---------------------------------------------------------------------------
# Confirmation-email (to the requester) content, keyed by requester type only
# ---------------------------------------------------------------------------

REQUESTER_CONFIRMATION_OPENING = {
    "customer": "Thank you for contacting AnyVan about your personal data.",
    "tp": "Thank you for contacting AnyVan about your personal data as one of our Transport Partners.",
    "third_party": "Thank you for contacting AnyVan on behalf of another person about their personal data.",
}

# One generic reference/timeline pair covering all 5 request types (the confirmation isn't gated
# on request type, so it merges in the raw selection rather than picking a per-type paragraph;
# see docs/dsr-confirmation-emails.md for why this reads fine for any of the 5 options).
CONFIRMATION_REQUEST_LINE = (
    "We've received your request (%s) and logged it under reference <strong>DSR-%s</strong>. "
    "Please quote this reference in any further correspondence."
) % (mt(REQUEST_TYPE_RAW), SUBMISSION_ID)

CONFIRMATION_TIMELINE_LINE = (
    "Under UK GDPR, we aim to respond within <strong>one calendar month</strong> of receiving "
    "your request. If you've asked us to update your marketing preferences, this is normally "
    "actioned much sooner, within <strong>5 working days</strong>; the statutory allowance for "
    "that is <strong>30 days</strong>."
)

REQUESTER_CONFIRMATION_VERIFICATION = {
    "customer": "",
    "tp": (
        "We may need to verify your identity against your AnyVan Transport Partner account before "
        "we can act on your request, and may contact you via your registered TP details to do so."
    ),
    "third_party": (
        "Before we can proceed, we need to check that you're authorised to act on the data "
        "subject's behalf. We'll review the proof of authorisation you provided and may contact "
        "you and/or the data subject directly to confirm this. <strong>The one-calendar-month "
        "statutory response period does not start until we've confirmed your authorisation</strong>; "
        "we'll write to confirm once it has been verified, or let you know if we need more "
        "information first."
    ),
}

CONFIRMATION_SUBJECT = {
    "customer": "Your AnyVan Privacy Request: Reference DSR-{$_submission_id}",
    "tp": "Your AnyVan Privacy Request: Reference DSR-{$_submission_id}",
    "third_party": (
        "Your AnyVan Privacy Request on Behalf of Another Person: Reference "
        "DSR-{$_submission_id}"
    ),
}

CONFIRMATION_HEADLINE = {
    "customer": "Your AnyVan Privacy Request",
    "tp": "Your AnyVan Privacy Request",
    "third_party": "Your AnyVan Privacy Request on Behalf of Another Person",
}

# Small-print footer line, same on all confirmations, clarifying what a "working day" means
# (relevant to the Marketing Opt-Out timeline, but stated generally). Confirmed by Ant 2026-09-25.
CONFIRMATION_FOOTER_SMALL_PRINT = "Our business days are Monday to Friday."
