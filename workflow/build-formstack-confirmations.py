#!/usr/bin/env python3
"""
Build the "AnyVan UK - Privacy Requests" Formstack CONFIRMATIONS (form 6559077): the
acknowledgement email sent to the requester (customer/TP/third party), as opposed to
build-formstack-notifications.py's internal email to privacy@anyvan.com that raises the ticket.

⚠️ UNVERIFIED PAYLOAD SHAPE. Unlike notifications (confirmed live via GET /forms/6559077/
notifications on 2026-09-24), no confirmation has ever been created on this form;
GET /forms/6559077/confirmations returned {"confirmations":[]}. This script's payload shape is a
best-effort mirror of the confirmed notification shape (Formstack's own help centre documents
"Confirmations & Notifications" as one feature family), minus the notification-only fields
(fromType/fromValue/recipients: a confirmation goes to whoever submitted the form, not to a
fixed address). Before running this for all 15, create ONE (comment out the others, or run with
--apply --only customer:sar) and GET /notifications/{id}-equivalent, i.e. re-list
/forms/6559077/confirmations, to see what Formstack actually stored, then fold any correction
back into docs/conventions.md the way the notification quirks were, and adjust this script.

Content mirrors build-formstack-notifications.py's requester/request-type matrix but for a
customer-facing tone: reference number, statutory timeline (Art. 12(3)), and a requester-type
verification paragraph (none for Customer, account-check for TP, authorisation-gate for Third
Party). See docs/dsr-confirmation-emails.md for the full drafted copy and rationale, including the
open question on the Marketing Opt-Out timeline commitment.

Usage:
  python3 workflow/build-formstack-confirmations.py --dry-run
  FORMSTACK_TOKEN=<fs_pat_...> python3 workflow/build-formstack-confirmations.py --apply
  FORMSTACK_TOKEN=<fs_pat_...> python3 workflow/build-formstack-confirmations.py --apply --only customer:sar
"""

import os
import sys

from formstack_api import call
from formstack_dsr_content import (
    CONFIRMATION_SUBJECT,
    REQUEST_TYPE_CONFIRMATION_LINE,
    REQUEST_TYPE_TIMELINE_LINE,
    REQUEST_TYPE_FIELD,
    REQUESTER_CONFIRMATION_OPENING,
    REQUESTER_CONFIRMATION_VERIFICATION,
    REQUESTER_TYPE_FIELD,
    REQUEST_TYPES,
    REQUESTERS,
)

FORM_ID = 6559077


def build_confirmation(requester, request_type):
    r_kind, r_label, r_option = requester
    q_kind, q_label, q_option = request_type

    paragraphs = [
        REQUESTER_CONFIRMATION_OPENING[r_kind],
        REQUEST_TYPE_CONFIRMATION_LINE[q_kind],
        "Please quote this reference in any further correspondence.",
        REQUEST_TYPE_TIMELINE_LINE[q_kind],
    ]
    verification = REQUESTER_CONFIRMATION_VERIFICATION[r_kind]
    if verification:
        paragraphs.append(verification)
    paragraphs.append(
        "If you have any questions in the meantime, email us at <strong>privacy@anyvan.com</strong> "
        "and quote your reference number."
    )

    body_html = "".join('<p><span style="font-size: 15px;">%s</span></p>' % para for para in paragraphs)
    message = (
        body_html
        + '<p><span style="font-size: 15px;">Kind regards,<br>AnyVan Privacy Team</span></p>'
    )

    subject = CONFIRMATION_SUBJECT[r_kind]
    name = "%s Confirmation Email [UK] - %s" % (r_label, q_label)

    payload = {
        "name": name,
        "subject": subject,
        "message": message,
        "format": "html",
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


def main():
    apply_ = "--apply" in sys.argv
    only = None
    if "--only" in sys.argv:
        only = sys.argv[sys.argv.index("--only") + 1]  # e.g. "customer:sar"
    token = os.environ.get("FORMSTACK_TOKEN", "")
    if apply_ and not token:
        print("FORMSTACK_TOKEN is not set; refusing to --apply.", file=sys.stderr)
        sys.exit(1)
    dry = not apply_

    for requester in REQUESTERS:
        for request_type in REQUEST_TYPES:
            if only and only != "%s:%s" % (requester[0], request_type[0]):
                continue
            name, payload = build_confirmation(requester, request_type)
            if dry:
                print("WOULD POST (create):", name)
                continue
            status, resp = call("POST", "/forms/%d/confirmations" % FORM_ID, payload, token)
            print(name, "-> POST", status, resp)


if __name__ == "__main__":
    main()
