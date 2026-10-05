A DSR Formstack form was submitted (submission id `{event.payload.uniqueId}`).

1. Call `formstack_submission` to read the full submission.
2. If the requester type is "Authorised Third Party", call `formstack_upload` /
   `formstack_upload_interpret` on the uploaded proof-of-authorisation file(s) and summarise
   what the document is and whether it appears to authorise the requester.
3. Produce the output-contract fields (see the config prompt) to raise the Freshdesk ticket.

Map faithfully from the submission — do not guess. Produce every output-contract field exactly
as the config prompt specifies (subject, description, tags, privacy_type, privacy_due_date). The
subject follows the config prompt's `[UK] <Type> Privacy Data Request | Requester Type:
<requester> [<submission id>]` format; the submission id is `{event.payload.uniqueId}`. Normalise
the booking reference (prepend `AV` to a digits-only value).
