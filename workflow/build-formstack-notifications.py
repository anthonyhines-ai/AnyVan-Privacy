#!/usr/bin/env python3
"""
Build / update the "AnyVan UK - Privacy Requests" Formstack notifications (form 6559077).

A Formstack "notification" is an internal email, distinct from a "confirmation" (sent to the
form submitter; see build-formstack-confirmations.py / docs/dsr-confirmation-emails.md). Ant built
one notification by hand in the Formstack builder ("Customer Privacy Request Email [UK]", id
9711486): it's sent to privacy@anyvan.com and is how the Freshdesk ticket actually gets created
(via Freshdesk's email-to-ticket pipe); this is the "Freshdesk-event" trigger option from
docs/dsr-go-live-readiness.md blocker #1, not the AI-workflow FRESHDESK_TICKET_CREATE action in
workflow/actions.json. See docs/dsr-notification-matrix.md for the full picture.

⚠️ Formstack caps this form's plan at 5 notification emails total (discovered live 2026-09-25).
Ant confirmed the priority: he wants the notification to show precisely and only the data/path the
submitter actually took for their request type (dates, categories, deletion scope, etc.), not a
superset with blank rows. So this script builds ONE notification per REQUEST TYPE (5 total: SAR,
Rectification, Deletion, Data Portability, Marketing Opt-Out) rather than per requester type -
each shows exactly that one request-type's own fields, with no other request type's fields present
at all. Requester-type detail (TP/third-party identity fields) is the smaller compromise: it's
shown unconditionally in every notification, blank when not applicable, since only 5 slots exist
total and request-type precision was the stated priority.

Usage:
  # preview every payload; no token, no API calls
  python3 workflow/build-formstack-notifications.py --dry-run

  # apply for real (PUTs all 5 known ids in place; idempotent)
  FORMSTACK_TOKEN=<fs_pat_...> python3 workflow/build-formstack-notifications.py --apply

API notes: GET /forms/{id}/notifications lists them (a known listing quirk can echo the same
notification twice; GET /notifications/{id} is the source of truth for one record). Update is
PUT /notifications/{id} with the FULL payload (not a partial patch; a partial body 400s). Create
is POST /forms/{id}/notifications, and is capped at 5 per form on this plan.
"""

import os
import sys

from formstack_api import call
from formstack_dsr_content import (
    DUE_DATE,
    REQ_FULLNAME,
    REQUEST_TYPE_FIELD,
    REQUESTER_TYPE_RAW,
    REQUEST_TYPES,
    all_requester_type_blocks,
    footer_block,
    headline,
    mt,
    p,
    request_type_block,
    requester_subject_block,
    HR,
)

FORM_ID = 6559077

# All 5 request types now have a live notification id (the first 3 were reused from the earlier,
# abandoned requester-type-keyed design; the last 2 were freshly created alongside this design).
# Re-running --apply PUTs all 5 in place rather than creating, so this stays idempotent and never
# risks hitting the 5-notification cap on a re-run. Re-verify against
# `GET /forms/6559077/notifications` if the live ids ever change (dedupe by id: the list endpoint
# echoes each one twice).
EXISTING_NOTIFICATION_IDS_TO_REUSE = {
    "sar": 9711486,
    "rectification": 9770031,
    "deletion": 9770032,
    "portability": 9770051,
    "marketing": 9770052,
}


def build_notification(request_type):
    q_kind, q_label, q_option = request_type

    message = (
        headline(
            "[UK] New %s Privacy Request | Requester Type: %s | Privacy Request Due: %s"
            % (q_label, mt(REQUESTER_TYPE_RAW), mt(DUE_DATE))
        )
        + HR
        + requester_subject_block()
        + all_requester_type_blocks()
        + request_type_block(q_kind)
        + footer_block()
    )

    subject = "[UK] %s Privacy Data Request for %s [{$_submission_id}]" % (q_label, mt(REQ_FULLNAME))
    name = "%s Privacy Request Email [UK]" % q_label

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
                {"field": REQUEST_TYPE_FIELD, "condition": "equals", "option": q_option},
            ],
        },
    }
    return name, payload


def main():
    apply_ = "--apply" in sys.argv
    token = os.environ.get("FORMSTACK_TOKEN", "")
    if apply_ and not token:
        print("FORMSTACK_TOKEN is not set; refusing to --apply.", file=sys.stderr)
        sys.exit(1)
    dry = not apply_

    for request_type in REQUEST_TYPES:
        q_kind = request_type[0]
        name, payload = build_notification(request_type)
        reuse_id = EXISTING_NOTIFICATION_IDS_TO_REUSE.get(q_kind)
        if dry:
            if reuse_id:
                print("WOULD PUT (retarget %d):" % reuse_id, name)
            else:
                print("WOULD POST (create):", name)
            continue
        if reuse_id:
            status, resp = call("PUT", "/notifications/%d" % reuse_id, payload, token)
        else:
            status, resp = call("POST", "/forms/%d/notifications" % FORM_ID, payload, token)
        print(name, "->", "PUT" if reuse_id else "POST", status, resp if status != 200 else {"id": resp.get("id"), "name": resp.get("name")})


if __name__ == "__main__":
    main()
