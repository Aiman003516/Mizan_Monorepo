# Mizan Supabase Migration Registry

This registry is the canonical human-readable dependency map for the additive Supabase migration stream. Migrations execute in filename order. Production application remains a separate approval gate. Every new migration must declare an owner, prerequisites, affected bounded context, RLS/grants, verification SQL, and forward-fix/rollback notes.

| Migration | Bounded context | Purpose | Prerequisites / gate |
|---|---|---|---|
| `20260825122999_legacy_status_preflight.sql` | Platform | Legacy status preflight repair | Baseline database inspection |
| `20260825123000_cloud_source_of_truth.sql` | Platform / Workforce / CRM | Tenants, identity, RBAC, CRM, documents, audit | Legacy preflight |
| `20260825190000_enable_realtime_publication.sql` | Sync | Realtime publication for live UI streams | Cloud source of truth |
| `20260826150000_employee_invitation_phase1.sql` | Workforce | Initial invitation contract | Platform identity/RBAC |
| `20260826170000_employee_management_phase2.sql` | Workforce | Employee and role management | Invitation phase 1 |
| `20260826190000_owner_control_center_phase1.sql` | Workforce / Governance | Owner controls and settings | Workforce foundation |
| `20260826200000_employee_invitation_phase3.sql` | Workforce | Invitation repair and onboarding | Employee management |
| `20260827100000_ai_agent_phase1.sql` | AI Governance | Read-only agent foundation | Platform identity/RBAC |
| `20260827110000_ai_action_requests_phase2.sql` | AI Governance | Proposal/request records | AI phase 1 |
| `20260827130000_ai_action_execution_phase3.sql` | AI Governance | Confirmation-gated execution | AI requests and ledger contracts |
| `20260827150000_ai_action_expansion_phase4.sql` | AI Governance | Additional governed action types | AI execution phase 3 |
| `20260827160000_platform_foundation_hardening.sql` | Platform / Security | Platform hardening and tenant controls | Cloud source of truth |
| `20260827170000_accounting_ledger_foundation.sql` | Ledger | Books, accounts, journals, periods, posting | Platform hardening |
| `20260827180000_crm_pipeline_foundation.sql` | CRM | Pipeline, opportunities, interactions | Cloud CRM and platform hardening |
| `20260827190000_accounting_flutter_contract.sql` | Ledger | Flutter-facing accounting RPC contracts | Ledger foundation |
| `20260827200000_schema_health_preflight.sql` | Platform / Governance | Data-quality and schema health checks | Ledger and CRM foundations |
| `20260827210000_dimensions_books_fx.sql` | Ledger / Tax | Dimensions, books, FX provenance | Ledger foundation |
| `20260827220000_tax_engine_foundation.sql` | Tax | Deterministic tax engine | Ledger, dimensions, FX |
| `20260827230000_revenue_recognition_foundation.sql` | Ledger / AR | Controlled revenue recognition | Ledger, dimensions, tax |
| `20260827240000_ar_ap_settlement_aging.sql` | AR/AP | Settlement, aging, payment allocation foundation | Ledger, tax, CRM |
| `20260827241000_dimensions_books_fx_repair.sql` | Ledger / Tax | Additive FX/dimensions repair | Dimensions/books/FX |
| `20260827250000_inventory_pos_accounting_bridge.sql` | Inventory/POS | Stock/POS accounting bridge | Ledger, AR/AP, tax |
| `20260827260000_crm_360_health_cpq.sql` | CRM / Sales | CRM 360, health, CPQ foundation | CRM pipeline, AR/AP, ledger |
| `20260827270000_transactional_outbox_events.sql` | Sync | Outbox, idempotency, conflicts | Platform and domain foundations |
| `20260827280000_document_intake_anomaly_policy.sql` | Documents / AI Governance | Protected intake, extraction evidence, anomaly policy | Platform, outbox, tax |
| `20260827290000_reviewed_extension_registry.sql` | Extensions / Governance | Reviewed declarative extensions | Platform permissions and audit |
| `20260827291000_repair_crm_balance_consistency.sql` | AR/AP / CRM | Balance consistency triggers | CRM, invoice/bill, ledger foundations |
| `20260827292000_crm_edit_rpc_wrappers.sql` | CRM / Security | Authenticated tenant-derived CRM edit wrappers | CRM foundation, platform permissions |
| `20260827293000_manual_balance_adjustment_workflow.sql` | AR/AP / Ledger | Atomic manual adjustment register and posting RPC | Ledger, CRM, periods, permissions, audit |
| `20260828000000_approval_enforcement_phase3.sql` | Governance / Security | Branch-aware approval requests, immutable decision events, and server decision RPCs | Manual balance adjustment workflow, platform branches, tenant permissions |
| `20260828010000_approval_balance_adjustment_gate.sql` | Governance / AR | One-time approved balance-adjustment execution and execution audit | Approval enforcement Phase 3, manual balance adjustment workflow |

## Required migration header

New migrations must begin with a comment block in this form:

```sql
-- Mizan migration
-- id: 20260828000000_example_feature.sql
-- owner: bounded-context-name
-- prerequisites: 20260827293000_manual_balance_adjustment_workflow.sql
-- changes: additive tables, RPCs, indexes, policies, or triggers
-- security: RLS/policies/grants and tenant-scope behavior
-- verification: supabase/tests/example_feature.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists
```

## Deployment gate

Before a migration is applied to a target database:

1. Confirm the file exists in this registry and is later than its prerequisites.
2. Run the schema-health preflight for each affected tenant or a documented representative test tenant.
3. Verify all new tables have tenant scope, RLS, grants, tenant-leading indexes where appropriate, audit behavior, and explicit realtime publication decisions.
4. Verify all client RPC calls have declared functions and required privileges.
5. Run the associated SQL regression tests in a disposable or staging database.
6. Record the applied migration, verification result, schema health result, and any forward-fix in the deployment log.
7. Obtain explicit production approval before applying SQL to production.

## Ownership rule

A migration may create tables and functions for one bounded context plus narrowly defined cross-context contracts. It must not silently create a second version of an existing domain concept. When a legacy concept must be replaced, use an expand/migrate/verify/contract sequence and preserve compatibility until all clients have moved.
