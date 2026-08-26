# Mizan Owner Control Center Roadmap

## Purpose

The Owner Control Center gives the company owner or authorized administrator one governed place to configure company-wide behavior. Personal preferences remain separate. Every company-level setting is validated, persisted locally for guest mode, and designed for synchronized tenant storage after the additive Supabase migration is reviewed and applied.

Critical accounting rules remain application- and database-authoritative. Settings cannot bypass double-entry balancing, tenant isolation, permissions, audit logging, confirmation gates, or concurrency checks.

## Phase plan and implementation status

| Phase | Scope | Implementation status |
|---:|---|---|
| 1 | Repository, schema, route, settings, and feature audit | Completed. Existing modules and gaps were inventoried before implementation. |
| 2 | Versioned Owner Control Center contract and local-first repository | Completed. Settings sections use `mizan.owner-settings/v1`, strict section/key allowlists, revisioning, and bounded privacy-preserving local audit entries. |
| 3 | Company profile, branches, setup wizard, localization, and owner dashboard foundations | Completed. The setup wizard covers identity, industry, address, tax number, base currency, fiscal year, branch, tax defaults, payment methods, proof-review policy, and a pending first-employee onboarding email. The control-center header shows configuration, branch, approval, and audit activity. |
| 4 | Accounting, currencies, tax defaults, document numbering, and fiscal governance | Completed in the owner settings UI. Base currency, enabled currencies, exchange-rate policy, rounding, fiscal-period behavior, tax settings, and document-numbering defaults are persisted with validation. Historical-affecting changes remain policy-controlled. |
| 5 | Employees, invitations, roles, branches, and security | Completed in the owner UI. Employee-governance settings include invitation expiry, staff limits, MFA requirement, self-service profile editing, and default branch assignment. Existing searchable/bulk staff and role screens remain the execution surface. Branch management supports local creation, editing, activation, and safe deletion. |
| 6 | Approvals, audit, and period governance | Completed as a safe foundation. The approval center has a versioned local request contract, pending/approved/rejected transitions, and explicit guest-mode limitations. Local settings changes are audited without recording sensitive values. The additive Supabase migration adds tenant-scoped approval requests and server audit triggers for authenticated deployment. |
| 7 | CRM configuration | Completed in the owner UI. Owners can configure lead stages, pipeline stages, interaction types, follow-up days, customer categories, default credit limits, and duplicate-matching fields. Existing CRM records and interactions remain separate from accounting logic. |
| 8 | Products, categories, units, warehouses, purchasing, and stock policy | Completed as owner configuration plus local warehouse management. Stock valuation method, negative-stock policy, reorder point, low-stock alerts, barcode policy, default warehouse, and local Drift warehouse creation/listing are available. Existing product and stock-movement workflows remain the transaction surface. |
| 9 | POS, cash control, and payments | Completed in dedicated owner screens. POS terminals, cash drawers, opening-balance requirement, shift-close approval, refund approval, discount limit, suspended sales, receipt template, and default payment method are configurable. Yemen-focused payment settings support cash, bank transfer, Jaib, Al Kuraimi, Yemen Wallet, card, credit terms, merchant instructions, and manual proof review. No payment-provider secret is stored in these settings. |
| 10 | Expenses, reimbursements, banking, and reconciliation | Completed in dedicated owner finance-operations settings. Owners can configure default expense account, categories, receipt requirement, reimbursement approval, mileage, bank account identifiers, statement format, banking currencies, owner reconciliation approval, and matching behavior. Existing expense and bank reconciliation modules remain responsible for actual records and postings. |
| 11 | Reports and month-end close | Completed in owner policy settings and existing report-module boundaries. Owners can configure default report period, export approval, dashboard metrics, scheduled reports, close checklist, reconciliation and backup prerequisites, and owner-only reopening. Existing financial reports remain linked to accounting data rather than duplicated in settings. |
| 12 | Backup, synchronization, notifications, privacy/local AI, and integrations | Completed as governed settings surfaces. Sync policy, Wi-Fi-only behavior, backup frequency/retention, restore approval, conflict policy, notification categories, local-AI mode, data minimization, prompt retention, employee AI access, email/SMS, bank import, scanner, printer, Google Drive, and future-provider status are represented in the contract and policy form. Cloud sync remains opt-in and Supabase remains the source of truth. |
| 13 | Validation, migration, documentation, and delivery | In progress until final repository-wide checks and push complete. The additive migration is included in the repository but is not applied to production automatically. |

## Application structure

```text
Settings
├── Company and branches
├── Accounting and fiscal periods
├── Currency and exchange rates
├── Taxes
├── Documents and numbering
├── Employees, roles, and invitations
├── Approval workflows
├── CRM configuration
├── Products, inventory, and warehouses
├── POS and cash control
├── Payment methods
├── Notifications
├── Backup and synchronization
├── Privacy and local AI
├── Security and audit
├── Language, region, and appearance
├── Integrations
├── Expenses and reimbursements
├── Banking and reconciliation
├── Reports and analytics
└── Month-end close management
```

## Data and security boundaries

Guest mode persists the Owner Control Center snapshot and supported local records on the device. It does not send guest data to Supabase, Google Drive, payment providers, or AI services. An authenticated synchronization implementation must use tenant-scoped `tenant_settings`, RLS, revision checks, owner/settings permissions, and server audit rows.

The local approval center records only local preview decisions. It never executes a business mutation. Authenticated approval execution must use server-side permission checks, target ownership checks, concurrency checks, idempotency, accounting validation, and audit logging.

The local AI feature remains fail-closed by default. Rule-based and future model-backed engines can propose safe structured actions, but they cannot access SQL, HTTP, filesystem APIs, credentials, source code, or accounting execution paths.

## Remaining integration gates

The additive Supabase migration must be reviewed and applied explicitly in the target project. A future synchronization repository should map local settings snapshots to `tenant_settings` and resolve conflicts by revision rather than blindly overwriting data. Existing module screens should receive these settings through their repositories where a setting changes operational behavior; settings screens do not perform business postings themselves.

Before production release, the application should be tested on the Samsung Note9 target for layout, Arabic/RTL rendering, Drift persistence, warehouse creation, POS settings, backup failure behavior, and local-AI privacy. Production cloud migration, native model packaging, and payment-provider activation remain explicit deployment gates.
