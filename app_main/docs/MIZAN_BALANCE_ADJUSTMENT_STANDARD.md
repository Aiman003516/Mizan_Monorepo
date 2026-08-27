# Mizan Manual Balance-Adjustment Standard

**Status:** Implemented in the current worktree; production database deployment remains pending explicit approval.

## Executive assessment

The former customer and supplier controls were two separate modal flows that directly changed a denormalized contact balance and created local ledger rows. The customer charge path incorrectly credited cash instead of revenue, supplier and customer dialogs used different validation contracts, the reason was optional on one side, there was no durable adjustment register, and authenticated cloud mode did not have a server-authoritative manual-adjustment workflow.

The enhanced workflow now treats a manual adjustment as an accounting event rather than a balance overwrite. A successful adjustment records one positive minor-unit amount, a signed direction, a mandatory reason, an optional reference, an effective date, two distinct ledger accounts, a linked journal entry, the operator, and a status. The customer and supplier pages use the same confirmation-first dialog and display the same adjustment history section.

> A manual adjustment is not a payment, invoice, bill, or arbitrary balance edit. It is a controlled, auditable journal posting that changes the contact’s outstanding position for a documented reason.

## Control matrix

| Control | Customer | Supplier | Enforcement |
|---|---|---|---|
| Positive amount | Required | Required | Flutter validator, repository guard, SQL check |
| Signed direction | Increase receivable or decrease receivable | Increase payable or decrease payable | Shared dialog and typed repository contract |
| Mandatory reason | Minimum 3 characters, maximum 500 | Minimum 3 characters, maximum 500 | Form validator, repository guard, SQL check |
| Optional reference | Maximum 120 characters | Maximum 120 characters | Form limit and SQL check |
| Effective date | Date picker with bounded date range | Same | Dialog plus accounting-period check in SQL |
| Non-negative resulting balance | Enforced | Enforced | Preview, repository guard, SQL row lock and check |
| Double-entry posting | Charge: debit receivable, credit revenue; decrease: debit cash, credit receivable | Increase: debit expense/cost of sales, credit payable; decrease: debit payable, credit cash | Local repository and server RPC |
| Account separation | Debit and credit must differ | Debit and credit must differ | Repository and SQL check |
| Base currency | Uses selected local currency; cloud server requires tenant base currency | Same | Server RPC; local ledger uses project’s existing currency representation |
| Period lock | N/A in current local-only ledger | N/A in current local-only ledger | Cloud RPC rejects locked/closed periods |
| Idempotency | Server-generated deterministic retry key | Same | Unique tenant/key constraint and RPC replay check |
| Audit trail | Local transaction plus adjustment register; cloud audit trigger plus journal source | Same | Drift register, Supabase `audit_row_change`, journal source ID |
| Direct table writes | Not permitted in cloud | Not permitted in cloud | RLS, revoked table writes, RPC-only posting |

## Workflow

The user selects **Increase** or **Decrease**, enters a positive amount, supplies a reason, optionally supplies a reference, and selects the effective date. The dialog previews the resulting balance and requires a second confirmation. The operation then runs through the appropriate repository.

Guest/local mode commits the journal transaction, two balanced transaction entries, adjustment-register row, and updated contact balance inside one Drift transaction. Authenticated cloud mode calls `post_manual_balance_adjustment`, which derives the tenant from the authenticated membership, validates permission and base currency, locks the contact row, checks the accounting period, validates tenant-owned accounts, posts the canonical journal entry and lines, writes the adjustment register, updates the contact, and returns the committed balance. The client writes the returned result into its local cache for immediate display.

The detail page subscribes to a reactive adjustment-history stream. In cloud mode it uses the Supabase Realtime stream with a Drift fallback; in local mode it uses a Drift watch. This removes the prior dependence on a one-time provider invalidation and makes the history visible after the operation and on other subscribed devices once the migration is deployed.

## Accounting corrections

Customer increases now debit Accounts Receivable and credit a revenue account. They do not credit cash, because an unbilled charge is not a receipt. Customer decreases debit cash and credit Accounts Receivable. Supplier increases debit expense or cost of sales and credit Accounts Payable. Supplier decreases debit Accounts Payable and credit cash.

Invoice and bill balance recalculation now includes posted manual adjustments, so a later invoice, bill, payment, or status update cannot silently overwrite a registered correction. New local opening balances are also registered as opening adjustments linked to their opening journal transaction.

## Database changes

The canonical application migration directory contains the new migration:

```text
app_main/supabase/migrations/20260827293000_manual_balance_adjustment_workflow.sql
```

It creates `public.balance_adjustments`, indexes party/date and journal lookups, enables RLS, permits authenticated history reads only for tenant members, adds timestamp and audit hooks, adds the Realtime publication entry, and creates the authenticated RPC:

```text
public.post_manual_balance_adjustment(
  text, uuid, bigint, text, text, text, text, date, uuid, uuid, text
)
```

Direct table inserts and updates are not granted to authenticated clients. The RPC is the only cloud posting entry point. It writes `journal_entries` and `journal_lines`, not the obsolete `synced_*` tables used by an older AI-only contract.

The local Drift database is now schema version **33** and includes `BalanceAdjustments`. Existing local databases create the new table during the `from < 33` upgrade path.

## Regression coverage

The following tests cover the new local behavior:

| Test | Coverage |
|---|---|
| `core_data/test/ar_quick_adjustment_test.dart` | Customer revenue/cash directions, balanced entries, register history, and negative-result rejection |
| `core_data/test/ap_quick_adjustment_test.dart` | Supplier directions, balanced entries, register history, and negative-result rejection |
| `supabase/tests/manual_balance_adjustment_workflow.sql` | Table/RPC existence, RLS, privileges, indexes, audit/timestamp triggers, canonical journal usage, negative-balance rule, base-currency rule, idempotency support, and Realtime publication |

## Deployment sequence

Apply the canonical migrations in order. The balance consistency migration and CRM edit wrapper migration precede the manual-adjustment workflow migration:

```text
20260827291000_repair_crm_balance_consistency.sql
20260827292000_crm_edit_rpc_wrappers.sql
20260827293000_manual_balance_adjustment_workflow.sql
```

After deployment, run both SQL regression files in a disposable or project test database. Then test with two authenticated users from separate tenants, a permitted operator, an unauthorized operator, a locked period, an incorrect currency, a duplicate idempotency key, a negative-result attempt, and a repeated network retry. No production migration was applied by this task.

## Remaining limitations

Static analysis and local tests do not prove physical-device layout, Arabic RTL rendering, keyboard behavior, authenticated Supabase execution, Realtime availability, or period-policy configuration in the target project. Cloud mode also requires the new SQL migration to be deployed before the client’s manual-adjustment path can succeed. The owner approval setting exists in the current local settings contract but is not yet a server-enforced approval queue; if the business requires maker-checker approval for every or threshold-based adjustment, that should be implemented as a separate pending-approval RPC and workflow before enabling the policy for production.
