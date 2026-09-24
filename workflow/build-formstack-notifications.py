#!/usr/bin/env python3
"""
Build / update the "AnyVan UK - Privacy Requests" Formstack notifications (form 6559077).

A Formstack "notification" is an internal email — distinct from a "confirmation" (sent to the
form submitter; see docs/dsr-confirmation-emails.md, none built yet). Ant built one notification
by hand in the Formstack builder ("Customer Privacy Request Email [UK]", id 9711486): it's sent to
privacy@anyvan.com and is how the Freshdesk ticket actually gets created (via Freshdesk's
email-to-ticket pipe) — this is the "Freshdesk-event" trigger option from
docs/dsr-go-live-readiness.md blocker #1, not the AI-workflow FRESHDESK_TICKET_CREATE action in
workflow/actions.json. See docs/dsr-notification-matrix.md for the full picture and the open
question this raises about workflow/.

This script builds the other 14 requester-type x request-type combinations (3 requester types x
5 request types = 15 total) and re-points the existing Customer/SAR one so it only fires for
Customer + SAR (today it has no request-type check at all, so it fires for every Customer
submission regardless of type). Each notification's body renders only its own requester-type
block and its own one request-type block, per docs/dsr-notification-matrix.md.

Usage:
  # preview every payload — no token, no API calls
  python3 workflow/build-formstack-notifications.py --dry-run

  # apply for real (updates 9711486 in place, creates the other 14)
  FORMSTACK_TOKEN=<fs_pat_...> python3 workflow/build-formstack-notifications.py --apply

Auth: a Formstack V2025 Personal Access Token (fs_pat_...), env var only — never pass on the
command line or commit it. If one is ever pasted into chat/a file, rotate it (docs/conventions.md).
API: https://www.formstack.com/api/v2025 — GET /forms/{id}/notifications lists them (a known
listing quirk can echo the same notification twice; GET /notifications/{id} is the source of
truth for one record). Update is PUT /notifications/{id} with the FULL payload (not a partial
patch — a partial body 400s). Create is POST /forms/{id}/notifications.
"""

import json
import os
import sys
import urllib.request
import urllib.error

FORM_ID = 6559077
BASE = "https://www.formstack.com/api/v2025"
EXISTING_CUSTOMER_SAR_NOTIFICATION_ID = 9711486


def mt(field):
    fid, label = field
    return "{$%s %s}" % (fid, label)


def p(html, size=18):
    return '<p><span style="font-size: %dpx; font-family: Georgia, serif;">%s</span></p>' % (size, html)


def h(text, size=18):
    return '<p><span style="font-size: %dpx; font-family: Georgia, serif;"><strong>%s</strong></span></p>' % (size, text)


HR = "<hr>"

# Field ids/labels confirmed live via GET /forms/6559077/fields (2026-09-24) — keep in sync with
# docs/dsr-field-mapping.md.
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


def build_notification(requester, request_type):
    r_kind, r_label, r_option = requester
    q_kind, q_label, q_option = request_type

    header = (
        '<p><span style="font-family: Georgia, serif; font-size: 24px;"><strong>[UK] New %s Privacy Request | %s | Privacy Request Due: %s</strong></span></p><hr>'
        % (r_label, q_label, mt(DUE_DATE))
    )

    message = (
        header
        + requester_subject_block()
        + requester_type_block(r_kind)
        + request_type_block(q_kind)
        + footer_block()
    )

    subject = "[UK] %s Privacy Data Request — %s for %s [{$_submission_id}]" % (r_label, q_label, mt(REQ_FULLNAME))
    name = "%s Privacy Request Email [UK] - %s" % (r_label, q_label)

    payload = {
        "name": name,
        "fromType": "field",
        "fromValue": "197276072",
        "recipients": "privacy@anyvan.com",
        "subject": subject,
        "type": "fields",
        "hideEmpty": 0,
        "hideHidden": False,
        "showSection": 0,
        "attachLimit": 14336,
        "format": "html",
        "message": message,
        "logic": {
            "action": "show",
            "conditional": "all",
            "checks": [
                {"field": REQUESTER_TYPE_FIELD, "condition": "equals", "option": r_option},
                {"field": REQUEST_TYPE_FIELD, "condition": "equals", "option": q_option},
            ],
        },
    }
    return name, payload


def api(method, path, payload, token):
    req = urllib.request.Request(BASE + path, data=json.dumps(payload).encode(), method=method)
    req.add_header("Authorization", "Bearer " + token)
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        try:
            return e.code, json.loads(body)
        except Exception:
            return e.code, {"raw": body}


def main():
    apply_ = "--apply" in sys.argv
    token = os.environ.get("FORMSTACK_TOKEN", "")
    if apply_ and not token:
        print("FORMSTACK_TOKEN is not set — refusing to --apply.", file=sys.stderr)
        sys.exit(1)
    dry = not apply_

    for requester in REQUESTERS:
        for request_type in REQUEST_TYPES:
            name, payload = build_notification(requester, request_type)
            is_existing = requester[0] == "customer" and request_type[0] == "sar"
            if is_existing:
                if dry:
                    print("WOULD PUT  (update %d):" % EXISTING_CUSTOMER_SAR_NOTIFICATION_ID, name)
                    continue
                status, resp = api("PUT", "/notifications/%d" % EXISTING_CUSTOMER_SAR_NOTIFICATION_ID, payload, token)
                print(name, "-> PUT", status, resp)
            else:
                if dry:
                    print("WOULD POST (create):", name)
                    continue
                status, resp = api("POST", "/forms/%d/notifications" % FORM_ID, payload, token)
                print(name, "-> POST", status, resp)


if __name__ == "__main__":
    main()
