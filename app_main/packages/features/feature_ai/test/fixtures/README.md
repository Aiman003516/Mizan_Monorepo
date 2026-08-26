# Local AI synthetic fixtures

`local_ai_synthetic_dataset.jsonl` contains synthetic Arabic/English examples for the first local assistant model. It contains no production customer, vendor, employee, tenant, account, invoice, or bill data.

Each JSONL row contains:

| Field | Meaning |
|---|---|
| `id` | Stable fixture identifier |
| `split` | `train`, `validation`, or `edge` |
| `locale` | `ar` or `en` |
| `text` | Synthetic user request |
| `expected` | Expected intent, candidate action, fields, missing fields, and entities |
| `expected.validation` | Optional expected rejection result for invalid proposals |

## Intent rules

The allowed intents are `explain`, `propose_mutation`, `request_missing_information`, and `unsupported`. Any mutation intent must use a server-supported action type, must set `requires_confirmation` to `true`, and must meet the local mutation confidence threshold. `unsupported` is used for hard deletion, source-code modification, confirmation bypasses, arbitrary SQL, arbitrary filesystem access, and other actions outside the local assistant boundary.

## Entity rules

The extractor may emit only the versioned entity types declared by `LocalAiEntityType`: record name, record number, amount in minor units, currency code, date, email, phone, and account name. Arabic and Eastern Arabic digits are normalized to ASCII digits before validation. A model entity is never treated as a database identifier until the application resolves it against the current local record or server tenant.

## Mutation validation rules

Customer and vendor edits accept only an allowlisted patch. Emails must match the application email format, customer credit limits must be non-negative integer minor units, hold status must be boolean, and a record identity plus expected update timestamp is required.

Invoice edits are limited to the supported editable fields and draft status. Bill edits are limited to the supported editable fields and pending status. Dates must be real ISO calendar dates, due dates cannot precede the document date, currencies must be three to five uppercase letters, and item rows require a non-empty description, positive finite quantity, and non-negative integer minor-unit price.

Balance adjustments require a customer or vendor identity, positive amount, increase/decrease direction, currency, distinct debit and credit accounts, and a reason. Journal proposals require two to 100 non-zero lines, tenant-resolved accounts, a valid date and currency, and a sum of zero across signed line amounts. Archive and void proposals require a target identity and a reason; they do not implement hard deletion.

Every proposal is checked by `LocalAiProposalValidator` before it can reach a preview. Validation failure is fail-closed: the local engine returns a failure or missing-information result and cannot execute a business mutation.
