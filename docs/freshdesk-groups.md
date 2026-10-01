# Freshdesk ticket groups — id reference

> **INTERNAL** — no customer data. AnyVan Freshdesk (`anyvan.freshdesk.com`) ticket-group names
> and numeric ids, for wiring `group_id` into workflow actions (DSR intake and others).
> Resolve/refresh with:
> `curl -s -u "$FRESHDESK_API_KEY:X" "https://anyvan.freshdesk.com/api/v2/groups?per_page=100" | jq '.[] | {name, id}'`

## Groups relevant to the DSR / privacy pipeline
| Purpose | Group | `group_id` |
|---|---|---|
| **DSR test sandbox** (used in `workflow/actions.test.json`) | `Privacy [Ant Automation Testing]` | `31000119185` |
| **Live privacy queue** (go-live target for `workflow/actions.json`) | `Privacy` | `31000116264` |
| France privacy | `France Privacy` | `31000119023` |
| Germany privacy | `Germany Privacy` | `31000119027` |
| Data-breach intake | `Data Breach - Emails` | `31000117724` |

## Full list (captured 2026-10-01; appears A–S, may be truncated)
| Group | `group_id` |
|---|---|
| 'Contact Us' External Customer Enquiries | 31000114316 |
| Account Management | 31000118815 |
| Accounts | 31000115569 |
| Allocation - Frozen Jobs at risk of cancelling | 31000118678 |
| Allocations | 31000114241 |
| AnyVan Protection + Claims | 31000118989 |
| Auto close (DO NOT USE) | 31000118978 |
| AVB - Billing | 31000118198 |
| AVB - Complaints | 31000118199 |
| AVB - OTD | 31000118197 |
| AVB - Quotes (London) | 31000118208 |
| AVB Automotive | 31000118065 |
| AVB Bookings | 31000116918 |
| AVB Operations | 31000116579 |
| AVB Quotes (Newcastle) | 31000117181 |
| AVB Sales | 31000116593 |
| AVB Test (Do not use) | 31000118118 |
| AVB Transport | 31000117564 |
| Bespoke Quotes | 31000116744 |
| Bookings | 31000115006 |
| Complaints inbox | 31000116272 |
| Court Claims / Printer | 31000119171 |
| Customer Care | 31000114240 |
| Customer Care - Vinted | 31000118977 |
| Customer Complaints | 31000118995 |
| Damage - TP Comms (ES) | 31000119182 |
| Damage Claim Reports | 31000118731 |
| Damage Claims | 31000115152 |
| Damage Claims - Transport Partners | 31000119137 |
| Damage Escalations & Storage Claims | 31000118888 |
| Damage Ops Support | 31000118074 |
| Damage refunds | 31000117405 |
| Data Breach - Emails | 31000117724 |
| Declined Invoice Submissions (Do not assign to this group) | 31000118795 |
| Disputes & Chargebacks | 31000118993 |
| Driver Support | 31000114690 |
| Driver Support - Deallocation Appeals | 31000119072 |
| Driver Support External Enquiries | 31000114767 |
| Driver Support Reports | 31000116465 |
| Edward Newman (formerly Edward Graham) | 31000116985 |
| ES WhatsApp Complaints | 31000119011 |
| ES_CS_Payment_Alerts | 31000119115 |
| External Emails | 31000118174 |
| Failed Removals Payments | 31000118444 |
| Formal Complaint | 31000114594 |
| France Allocations | 31000119021 |
| France Bookings | 31000119020 |
| France Branding Validations | 31000119110 |
| France Customer Service | 31000119000 |
| France Damage Claims | 31000119025 |
| France Formal Complaints | 31000119024 |
| France OTD Payment Failures | 31000119148 |
| France Privacy | 31000119023 |
| France Transport | 31000118999 |
| France Transport Invoices | 31000119022 |
| France Transport Onboarding | 31000119018 |
| France V2 Quotes | 31000119006 |
| Fraudulent Payments Review | 31000118799 |
| Freight | 31000118026 |
| Germany - Business | 31000117895 |
| Germany Bookings | 31000119001 |
| Germany Customer Service | 31000119002 |
| Germany Privacy | 31000119027 |
| Germany Transport | 31000119004 |
| Germany Transport Onboarding | 31000119019 |
| Germany V2 Quotes | 31000119007 |
| Incident Management | 31000118992 |
| International Bookings | 31000119034 |
| International Transport | 31000119032 |
| International V2 Removal Quotes | 31000119008 |
| Invalid Tickets | 31000115989 |
| Ireland Bookings | 31000119033 |
| Ireland Info | 31000119065 |
| Ireland Transport | 31000119005 |
| Ireland V2 Quotes | 31000119009 |
| IT Support | 31000114786 |
| Italy Bookings | 31000119098 |
| Italy Customer Care | 31000119099 |
| Italy Transport | 31000119044 |
| Journey | 31000116236 |
| LC Support | 31000118443 |
| Letter Before Action / Court | 31000119153 |
| Listing Issues | 31000118804 |
| Live Control | 31000118331 |
| Low Feedback - Spain | 31000118991 |
| Low Feedback QR | 31000118440 |
| Low Feedback Score | 31000116522 |
| Management Escalations | 31000115732 |
| Newbid Bookings | 31000119127 |
| NOT IN USE | 31000117095 |
| On the day issues | 31000115889 |
| Ops Support | 31000118586 |
| Partnerships | 31000118462 |
| Privacy | 31000116264 |
| Privacy [Ant Automation Testing] | 31000119185 |
| Quality and Resolutions | 31000118170 |
| Removals Quote Emails (DH) (External) | 31000116268 |
| Retail Support | 31000118772 |
| Rocio Casas (Spain Sales) | 31000118911 |
| Sandra White | 31000116986 |

_List captured from `GET /api/v2/groups?per_page=100` on 2026-10-01. It ends at "Sandra White"
(alphabetical, letters A–S) so it may be truncated — re-run the command above and append any
later groups (Spain/Transport/UK-suffixed) when needed._
