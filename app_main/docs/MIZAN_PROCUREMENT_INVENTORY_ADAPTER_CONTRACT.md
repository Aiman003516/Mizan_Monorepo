# Mizan Procurement-to-Inventory Adapter Contract

## Scope

This contract defines the explicit bridge between posted procurement receiving/return evidence and the existing inventory accounting bridge. Procurement remains the owner of purchase receipts and returns. Inventory remains the owner of on-hand quantity and average cost. Accounting remains the owner of journal drafts and journal posting.

The adapter does not silently turn procurement evidence into stock. It creates one inventory receipt or inventory return accounting draft per posted procurement line, records an immutable link, and leaves final stock mutation to the existing governed journal-posting trigger.

## Command boundaries

| Command | Preconditions | Effect | Does not do |
|---|---|---|---|
| `post_purchase_receipt_to_inventory` | Authenticated tenant member, branch access, posted procurement receipt, product-backed lines, active account IDs, required permissions | Creates inventory receipt drafts and one link per procurement receipt line | Does not post journals or update `inventory_balances` directly |
| `post_purchase_return_to_inventory` | Authenticated tenant member, branch access, posted procurement return, product-backed lines, active account IDs, required permissions | Creates inventory return drafts and one link per procurement return line | Does not post journals or permit negative stock |
| Existing journal-posting command | Governed accounting permission, valid open period, balanced draft | Posts the linked inventory journal and invokes the inventory trigger | Does not change procurement document status |

The adapter requires the combined procurement, inventory, accounting, and settings permissions because it creates accounting drafts. Account ownership, account type, tenant scope, branch access, product activity, and quantity constraints are rechecked on the server. The caller supplies a trimmed journal prefix of at most 55 characters; the server adds a source-document suffix and line number to avoid collisions.

## Idempotency and atomicity

Each procurement source line has at most one adapter link. A complete retry returns `already_linked` and the existing links without creating new drafts. A partially linked source is treated as an invariant violation rather than silently completing an unknown state. The adapter function runs in one database transaction; if draft creation or link insertion fails, its changes roll back.

The adapter is intentionally line-granular so a source document can be reconciled to its generated inventory drafts. The source procurement receipt or return is locked during adaptation. The generated accounting entry carries `source_type` and `source_id` for audit and reconciliation.

## Return and stock safety

A procurement return may not exceed posted receipt quantity after earlier posted returns. The inventory return draft may not post unless the warehouse/product balance contains sufficient quantity. The existing inventory posting trigger performs the guarded decrement and raises an error if stock changed before posting. Corrections use void/reversal workflows; no client receives direct write access to inventory balances or adapter links.

## Explicit v1 limitations

The adapter requires a product identifier on each procurement line and does not infer products from descriptions. It uses the purchase-order currency and unit cost retained on procurement evidence. Tax allocation, landed cost, serial/lot tracking, multi-warehouse transfer routing, and automatic bill posting remain separate future contracts. No production migration application is performed by repository verification.
