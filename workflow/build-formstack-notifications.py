#!/usr/bin/env python3
"""
Build / update the "AnyVan UK - Privacy Requests" Formstack notifications (form 6559077).

A Formstack "notification" is an internal email — distinct from a "confirmation" (sent to the
form submitter; see build-formstack-confirmations.py / docs/dsr-confirmation-emails.md). Ant built
one notification by hand in the Formstack builder ("Customer Privacy Request Email [UK]", id
9711486): it's sent to privacy@anyvan.com and is how the Freshdesk ticket actually gets created
(via Freshdesk's email-to-ticket pipe) — this is the "Freshdesk-event" trigger option from
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

API notes: GET /forms/{id}/notifications lists them (a known listing quirk can echo the same
notification twice; GET /notifications/{id} is the source of truth for one record). Update is
PUT /notifications/{id} with the FULL payload (not a partial patch — a partial body 400s). Create
is POST /forms/{id}/notifications.
"""

import os
import sys

from formstack_api import call
from formstack_dsr_content import (
    DUE_DATE,
    REQ_FULLNAME,
    REQUEST_TYPE_FIELD,
    REQUESTER_TYPE_FIELD,
    REQUEST_TYPES,
    REQUESTERS,
    footer_block,
    mt,
    request_type_block,
    requester_subject_block,
    requester_type_block,
)

FORM_ID = 6559077
EXISTING_CUSTOMER_SAR_NOTIFICATION_ID = 9711486


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
                status, resp = call("PUT", "/notifications/%d" % EXISTING_CUSTOMER_SAR_NOTIFICATION_ID, payload, token)
                print(name, "-> PUT", status, resp)
            else:
                if dry:
                    print("WOULD POST (create):", name)
                    continue
                status, resp = call("POST", "/forms/%d/notifications" % FORM_ID, payload, token)
                print(name, "-> POST", status, resp)


if __name__ == "__main__":
    main()
