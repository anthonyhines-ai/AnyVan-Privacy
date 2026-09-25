"""
Shared field ids/labels and per-(requester type, request type) content blocks for the
"AnyVan UK - Privacy Requests" Formstack form (id 6559077).

Used by both build-formstack-notifications.py (the internal email to privacy@anyvan.com that
raises the Freshdesk ticket) and build-formstack-confirmations.py (the acknowledgement email to
the requester). Keeping the content in one module means the two audiences never drift apart on
field ids or on which requester/request-type combination gets which facts.

Field ids/labels confirmed live via GET /forms/6559077/fields (2026-09-24) — keep in sync with
docs/dsr-field-mapping.md.
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
# Confirmation-email (to the requester) content, keyed by kind
# ---------------------------------------------------------------------------

# What the requester is told we've received, per request type. SAR deliberately doesn't split by
# data category (Call Recording/s, Chat Transcript/s, ... are a multi-select checkbox, not a
# radio — up to 2^6 combinations, and Formstack's logic can't express "contains one of" cleanly).
# Instead the SAR line merges in whichever categories were actually ticked, so a call-recording
# request and a chat-transcript request read differently from the same one template.
REQUEST_TYPE_CONFIRMATION_LINE = {
    "sar": (
        "We've received your <strong>Subject Access Request</strong> and logged it under "
        "reference <strong>DSR-{$_submission_id}</strong>. You asked us to provide: %s."
    )
    % mt(SAR_CATEGORIES),
    "rectification": (
        "We've received your request to <strong>correct</strong> the following and logged it "
        "under reference <strong>DSR-{$_submission_id}</strong>: %s."
    )
    % mt(RECT_WHICH),
    "deletion": (
        "We've received your request to <strong>delete</strong> the following and logged it "
        "under reference <strong>DSR-{$_submission_id}</strong>: %s."
    )
    % mt(DEL_SCOPE),
    "portability": (
        "We've received your <strong>data portability</strong> request and logged it under "
        "reference <strong>DSR-{$_submission_id}</strong>. We'll provide your data in a "
        "commonly used, machine-readable format (CSV/JSON) within 30 days."
    ),
    "marketing": (
        "We've received your <strong>marketing opt-out</strong> request and logged it under "
        "reference <strong>DSR-{$_submission_id}</strong>."
    ),
}

# Timeline commitment, per request type. Marketing opt-outs are operationally actioned far faster
# than a subject-access-style request, so that one leads with the working SLA and states the
# statutory 30-day allowance as a caveat rather than the headline (confirmed by Ant 2026-09-25).
REQUEST_TYPE_TIMELINE_LINE = {
    "sar": (
        "Under UK GDPR, we aim to respond within <strong>one calendar month</strong> of receiving "
        "your request. If your request is complex, or you've raised more than one, we may need to "
        "extend this by a further two months &mdash; we'll tell you if that happens and explain why."
    ),
    "rectification": (
        "Under UK GDPR, we aim to respond within <strong>one calendar month</strong> of receiving "
        "your request."
    ),
    "deletion": (
        "Under UK GDPR, we aim to respond within <strong>one calendar month</strong> of receiving "
        "your request."
    ),
    "portability": (
        "Under UK GDPR, we aim to respond within <strong>one calendar month</strong> of receiving "
        "your request."
    ),
    "marketing": (
        "We aim to update your marketing preferences within <strong>5 working days</strong>. Please "
        "note that, in line with UK GDPR regulations, we have up to <strong>30 days</strong> to "
        "action this request."
    ),
}

# Requester-type framing: the opening line, and the verification paragraph that follows the
# reference/timeline. Customer gets no extra verification paragraph.
REQUESTER_CONFIRMATION_OPENING = {
    "customer": "Thank you for contacting AnyVan about your personal data.",
    "tp": "Thank you for contacting AnyVan about your personal data as one of our Transport Partners.",
    "third_party": "Thank you for contacting AnyVan on behalf of another person about their personal data.",
}

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
        "statutory response period does not start until we've confirmed your authorisation</strong> "
        "&mdash; we'll write to confirm once it has been verified, or let you know if we need more "
        "information first."
    ),
}

CONFIRMATION_SUBJECT = {
    "customer": "Your AnyVan Privacy Request &mdash; Reference DSR-{$_submission_id}",
    "tp": "Your AnyVan Privacy Request &mdash; Reference DSR-{$_submission_id}",
    "third_party": (
        "Your AnyVan Privacy Request on Behalf of Another Person &mdash; Reference "
        "DSR-{$_submission_id}"
    ),
}


# ---------------------------------------------------------------------------
# Notification-email (to privacy@anyvan.com) content blocks, keyed by kind
# ---------------------------------------------------------------------------

def p(html, size=18):
    return '<p><span style="font-size: %dpx; font-family: Georgia, serif;">%s</span></p>' % (size, html)


def h(text, size=18):
    return '<p><span style="font-size: %dpx; font-family: Georgia, serif;"><strong>%s</strong></span></p>' % (size, text)


HR = "<hr>"


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
                "<em>No acting-party contact email is captured on this form &mdash; the requester email "
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


def footer_block():
    return (
        h("Additional Information")
        + p("Additional Information: %s" % mt(ADDITIONAL_INFO))
        + p("Declaration confirmed by requester (UK GDPR Art. 12(3)).", size=14)
    )
