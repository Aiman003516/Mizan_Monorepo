# Mizan Procure-to-Pay Contract

## Purpose

This contract defines the first procure-to-pay slice for Mizan. It introduces purchase requisitions, purchase orders, receipts and returns, and a server-enforced three-way matching evidence contract that compares purchase-order commitments, received quantities, and vendor-bill quantities. The `assert_purchase_bill_match(uuid)` RPC provides strict match evidence, while `assert_purchase_bill_posting_eligibility(uuid)` provides the server-side eligibility result consumed by future bill approval/posting commands.

The design intentionally keeps procurement separate from accounting, inventory, and CRM. Procurement owns commercial intent and receiving evidence. Accounting owns vendor bills, journal drafts, approvals, and period controls. Inventory owns on-hand balances and stock posting. CRM owns the vendor master. Cross-context behavior is exposed through typed `core_data` contracts and server RPCs rather than direct feature-internal imports.

## Bounded contexts and dependency direction

| Context | Owns | May consume | Must not own |
|---|---|---|---|
| Procurement | Requisitions, purchase orders, PO lines, receipt/return evidence, matching evidence | Vendor identity, product identity, branch membership, approval request contract | Vendor master edits, stock truth, journal posting |
| Accounting | Bills, settlement drafts, journals, periods, tax, approval decisions | Procurement matching result and source IDs | Procurement state mutation outside RPCs |
| Inventory | On-hand balances, stock receipts, returns, costing | Posted receiving commands and product IDs | Purchase approval decisions |
| CRM | Vendors and contacts | None from procurement internals | Purchase-order workflow |
| Governance | Permissions, branches, approval requests, immutable audit events | Typed action metadata from contexts | Business-specific duplicate schemas |

The dependency direction is `feature_procurement -> core_data contracts`; procurement must not import `feature_contacts`, `feature_transactions`, or `feature_products` internals. Vendor, product, accounting, and approval identifiers remain opaque IDs in procurement records. Any future foreign-key strengthening must be additive and must preserve tenant scope. The existing dashboard package is an app-shell composer; its import of the public `feature_procurement` barrel is an intentional composition edge, not a procurement bounded-context dependency. The boundary diagnostic therefore records one additional shell edge while procurement itself remains independently editable.

## Lifecycle model

A requisition progresses through `draft`, `pending_approval`, `approved`, `rejected`, `cancelled`, or `converted`.
A purchase order progresses through `draft`, `pending_approval`, `approved`, `partially_received`, `received`, `closed`, or `cancelled`. Receipts and returns progress through `draft`, `posted`, or `void`. Posted evidence is append-only for financial and stock purposes; corrections use returns, voids, or reversals rather than silent edits.

All mutable commands derive `tenant_id` from the authenticated session, validate branch scope, enforce permission checks, and record the actor. Approval-required purchase orders create a typed governance request with a frozen payload. The approval request is not the purchase order itself and cannot be bypassed by hiding or disabling a UI control.

## Three-way matching contract

The matching RPC accepts a tenant-scoped vendor bill identifier and returns one result per bill line. It compares:

1. **Purchase order quantity and unit price** for the linked product or description.
2. **Posted receipt quantity less posted return quantity** for the same purchase-order line.
3. **Vendor-bill quantity and unit price** for the matching bill line.

For v1, the price tolerance is **exactly zero minor units**; no tenant-configured tolerance source is consumed yet. A line is `matched` only when the cumulative non-void billed quantity for the linked PO line is no greater than the posted receipt quantity less posted returns, the cumulative billed quantity is no greater than the ordered quantity, the net received quantity is no greater than the ordered quantity, and the current billed unit price equals the PO unit price. A line is `blocked` when there is no PO linkage, the PO-line association is inconsistent, there is insufficient receipt quantity, a quantity exceeds the ordered quantity, the exact price check fails, the currency differs, or a source record is invalid. Partial receipts remain valid evidence but do not permit billing beyond the net received quantity.

The implementation exposes line-level evidence and blocking reasons. `assert_purchase_bill_match(uuid)` rejects a bill when any line is blocked. A blocked bill may submit a reason through `request_purchase_bill_match_exception(uuid, text, text)`, which creates a maker-checker `bill` approval request. After an authorized approval decision, `assert_purchase_bill_posting_eligibility(uuid)` can return `approved_exception`. These commands do not automatically post vendor bills or mutate inventory; the final bill-posting command must call the eligibility gate server-side.

## Validation contract

| Field | Rule |
|---|---|
| Requisition/PO number | Required, trimmed, tenant-unique, bounded length. |
| Vendor ID | Required, tenant-scoped, active and not deleted. |
| Product ID | Optional opaque identifier in v1; when supplied, it is non-empty and retained for a future product/inventory contract adapter. Cross-context product validation is not claimed by this slice. |
| Quantity | Finite and strictly positive; fractional quantities are accepted because the existing inventory schema uses numeric quantities. |
| Unit price | Integer minor units, non-negative. |
| Currency | Uppercase supported ISO-like code; all lines in one document must use the document currency. |
| Dates | Required and ordered; receipt date cannot precede the PO date. |
| Reason/description | Required where the schema declares it; trimmed and bounded. |
| Approval payload | Frozen target, vendor, lines, totals, currency, and branch inputs; v1 uses an explicit zero-price-variance policy and approval replay is idempotent. |

The Flutter layer validates before submission. The repository and RPC validate again. Financial values remain integer minor units; quantity remains a finite decimal; display formatting never becomes an accounting input.

## Security and audit rules

Tenant and branch scope are derived on the server. Direct table insert/update/delete grants are revoked for workflow tables where commands exist. Read access is tenant-scoped through RLS. Sensitive actions require explicit permissions such as procurement creation, procurement approval, receiving, and matching review. Approval requesters cannot approve their own requests. Every create, submit, approve, reject, receive, return, and exception decision has an audit trail; matching is a read/evidence query and is not itself a posted financial fact.

## Vertical-slice completion gates

A procurement foundation slice is not complete until its additive migration, registry entry, staging SQL regression tests, typed `core_data` models/repository, localized UI, strict validators, approval/error states, boundary checks, and deployment notes are present. The current bounded wave includes usable requisition, PO, receipt, return, match-evidence, strict bill eligibility, approved-variance exception, and inventory-draft-adapter paths. Final procure-to-pay completion still requires a governed bill-posting command, tax/landed-cost policy, and verified staging execution. No production SQL is applied automatically. Static tests cannot prove authenticated Supabase behavior, realtime delivery, physical Android layout, device RTL, or provider integrations.
