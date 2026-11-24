A DSR Formstack form was submitted (submission id `{event.payload.uniqueId}`).

1. Call `formstack_submission` to read the full submission.
2. If the requester type is "Authorised Third Party", call `formstack_upload` /
   `formstack_upload_interpret` on the uploaded proof-of-authorisation file(s) and summarise
   what the document is, who it names, and whether it appears to authorise the requester.
3. Work out what was requested (the request type and, for a SAR, the data categories ticked) and run ONLY the
   lookups that scope needs, as described under "What was requested" in the config prompt, with `snowflake_query`.
4. Write the initial note (`description`: the request table and the Request Verification table) and the private
   update note (`update_note_html`: only what was found, with Authority Verification for third parties first, then one
   section per ticked option; do not repeat the request details from the initial note), then the other output-contract fields.

Map faithfully from the submission — do not guess. Compose the subject as
`[UK] <requester label> Privacy Request [Ref: DSR-UK-{event.payload.uniqueId}]` (no name in the subject)
(requester label = Customer / Transport Partner / Third Party, per the config prompt)
and the description table exactly as specified in the config prompt (only the listed rows).

