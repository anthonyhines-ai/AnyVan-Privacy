A DSR Formstack form was submitted (submission id `{event.payload.UniqueID}`).

1. Call `formstack_submission` to read the full submission.
2. If the requester type is "An Authorised Third Party", call `formstack_upload` /
   `formstack_upload_interpret` on the uploaded proof-of-authorisation file(s) and summarise
   what the document is and whether it appears to authorise the requester.
3. Produce the output-contract fields (see the config prompt) to raise the Freshdesk ticket.

Map faithfully from the submission — do not guess. Normalise the booking reference (prepend
`AV` to a digits-only value). Compose the subject as
`DSR-{event.payload.UniqueID} — <dsr_type> (<requester_type>)`.
