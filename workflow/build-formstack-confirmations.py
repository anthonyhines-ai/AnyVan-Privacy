#!/usr/bin/env python3
"""
Build the "AnyVan UK - Privacy Requests" Formstack CONFIRMATIONS (form 6559077): the
acknowledgement email sent to the requester (customer/TP/third party), as opposed to
build-formstack-notifications.py's internal email to privacy@anyvan.com that raises the ticket.

Payload shape confirmed live 2026-09-25 (create one, inspect the 200 response):
  {name, subject, message, format, toField, senderEmail, logic}
`toField` is the field id (bare string, no `field_` prefix) whose answer is the recipient address;
`senderEmail` is the visible From address. Unlike notifications, confirmations on this plan have
no email-count cap (16 created in testing with no error), so the full 3 requester types x 5
request types = 15-variant matrix stands here even though notifications had to be consolidated
to 3 (one per requester type) to fit that cap; see docs/dsr-notification-matrix.md.

Visual design matches the notifications and Ant's original hand-built example: Georgia serif,
24px bold headline, 18px body, <hr> section dividers.

Usage:
  python3 workflow/build-formstack-confirmations.py --dry-run
  FORMSTACK_TOKEN=<fs_pat_...> python3 workflow/build-formstack-confirmations.py --apply
  FORMSTACK_TOKEN=<fs_pat_...> python3 workflow/build-formstack-confirmations.py --apply --only customer:sar
"""

import os
import sys

from formstack_api import call
from formstack_dsr_content import (
    CONFIRMATION_FOOTER_SMALL_PRINT,
    CONFIRMATION_HEADLINE,
    CONFIRMATION_REQUEST_LINE,
    CONFIRMATION_SUBJECT,
    CONFIRMATION_TIMELINE_LINE,
    REQUEST_TYPE_FIELD,
    REQUESTER_CONFIRMATION_OPENING,
    REQUESTER_CONFIRMATION_VERIFICATION,
    REQUESTER_TYPE_FIELD,
    REQUEST_TYPES,
    REQUESTERS,
    HR,
    h,
    headline,
    p,
)

FORM_ID = 6559077


def build_confirmation(requester, request_type):
    r_kind, r_label, r_option = requester
    q_kind, q_label, q_option = request_type

    verification = REQUESTER_CONFIRMATION_VERIFICATION[r_kind]

    message = (
        headline(CONFIRMATION_HEADLINE[r_kind])
        + HR
        + p(REQUESTER_CONFIRMATION_OPENING[r_kind])
        + p(CONFIRMATION_REQUEST_LINE)
        + p(CONFIRMATION_TIMELINE_LINE)
        + (p(verification) if verification else "")
        + HR
        + p(
            "If you have any questions in the meantime, email us at "
            "<strong>privacy@anyvan.com</strong> and quote your reference number."
        )
        + p("Kind regards,<br>AnyVan Privacy Team")
        + p(CONFIRMATION_FOOTER_SMALL_PRINT, size=12)
    )

    subject = CONFIRMATION_SUBJECT[r_kind]
    name = "%s Confirmation Email [UK] - %s" % (r_label, q_label)

    payload = {
        "name": name,
        "subject": subject,
        "message": message,
        "format": "html",
        "toField": "197276072",
        "senderEmail": "privacy@anyvan.com",
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
            print(name, "-> POST", status, resp if status != 200 else {"id": resp.get("id"), "name": resp.get("name")})


if __name__ == "__main__":
    main()
