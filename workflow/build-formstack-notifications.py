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

⚠️ Formstack caps this form's plan at 5 notification emails total (discovered live 2026-09-25: a
3 requester type x 5 request type = 15-notification matrix hit "This form reached the notification
emails limit" on the 6th create). So this script builds ONE notification per requester type (3
total, matching Ant's original design), each covering all 5 request types inside one email (every
request-type block concatenated; only the block matching what was actually selected has populated
merge fields, the other 4 render blank). This uses 3 of 5 slots.

Usage:
  # preview every payload; no token, no API calls
  python3 workflow/build-formstack-notifications.py --dry-run

  # apply for real (updates 9711486 in place as Customer; creates/reuses TP and Third Party)
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
    REQUESTER_TYPE_FIELD,
    REQUESTERS,
    REQUEST_TYPE_RAW,
    all_request_type_blocks,
    footer_block,
    h,
    headline,
    mt,
    p,
    requester_subject_block,
    requester_type_block,
    HR,
)

FORM_ID = 6559077

# The 5 notification ids created before this script discovered the plan cap (all currently
# "Customer Privacy Request Email [UK] - <request type>"). Reused here: the first 3 are
# retargeted to the new one-per-requester-type design; the other 2 are deleted as no longer
# needed. Fill in from `GET /forms/6559077/notifications` if this ever needs re-running from a
# different starting state.
EXISTING_NOTIFICATION_IDS_TO_REUSE = {
    "customer": 9711486,
    "tp": 9770031,
    "third_party": 9770032,
}
EXISTING_NOTIFICATION_IDS_TO_DELETE = [9770033, 9770034]


def build_notification(requester):
    r_kind, r_label, r_option = requester

    message = (
        headline(
            "[UK] New %s Privacy Request | %s | Privacy Request Due: %s"
            % (r_label, mt(REQUEST_TYPE_RAW), mt(DUE_DATE))
        )
        + HR
        + requester_subject_block()
        + requester_type_block(r_kind)
        + all_request_type_blocks()
        + p(
            "Only the section above matching the request type shown at the top will have "
            "populated fields; blank rows in the other sections mean not applicable.",
            size=12,
        )
        + footer_block()
    )

    subject = "[UK] %s Privacy Data Request: %s for %s [{$_submission_id}]" % (
        r_label,
        mt(REQUEST_TYPE_RAW),
        mt(REQ_FULLNAME),
    )
    name = "%s Privacy Request Email [UK]" % r_label

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

    for requester in REQUESTERS:
        r_kind = requester[0]
        name, payload = build_notification(requester)
        notif_id = EXISTING_NOTIFICATION_IDS_TO_REUSE[r_kind]
        if dry:
            print("WOULD PUT (retarget %d):" % notif_id, name)
            continue
        status, resp = call("PUT", "/notifications/%d" % notif_id, payload, token)
        print(name, "-> PUT", status, resp if status != 200 else {"id": resp.get("id"), "name": resp.get("name")})

    for stray_id in EXISTING_NOTIFICATION_IDS_TO_DELETE:
        if dry:
            print("WOULD DELETE (no longer needed):", stray_id)
            continue
        status, resp = call("DELETE", "/notifications/%d" % stray_id, None, token)
        print("delete", stray_id, "->", status, resp)


if __name__ == "__main__":
    main()
