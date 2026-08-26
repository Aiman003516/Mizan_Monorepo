# Mizan Hard-Coded-Text Candidate Register

> This register preserves the original 227-entry audit baseline and records the verified post-cleanup state. The audit is heuristic: it also flags identifiers, numbers, masking tokens, punctuation, and internal exception text that must not be sent through Flutter localization.

## Verified summary

| Measure | Result |
|---|---:|
| Original heuristic candidates | 227 |
| Candidates no longer present after cleanup | 153 |
| Residual heuristic candidates | 74 |
| Screens/pages audited | 102 |
| Missing Arabic keys | 0 |
| Placeholder mismatches | 0 |
| Missing localization references | 0 |
| Legacy Arabic-only keys | 22 |

## What was localized

The genuine user-facing literals from the baseline were moved to the English and Arabic catalogs or replaced with existing localized messages. This includes report controls and empty states, import results and row errors, adjusting-entry and period-end workflows, reconciliation screens, account and currency labels, owner settings, staff and approval displays, depreciation messages, synchronization warnings, and local-AI runtime diagnostics. Placeholder-bearing messages were regenerated and checked for parity.

## Residual candidates after cleanup

The following residual rows are audit heuristics rather than untranslated user-facing prose. They are retained intentionally because removing or translating them would damage identifiers, numeric formatting, masking, receipt layout, or server/domain-layer independence.

| # | Source | Literal | Classification | Decision |
|---:|---|---|---|---|
| 1 | `apps/lib/main.dart:72` | `Mizan` | Intentional brand name | Keep as brand identity; no translation is appropriate. |
| 2 | `apps/lib/main.dart:167` | `Mizan` | Intentional brand name | Keep as brand identity; no translation is appropriate. |
| 3 | `packages/core/core_data/lib/src/tenant_context.dart:34` | `Tenant membership was not found.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 4 | `packages/core/core_data/lib/src/repositories/roles_repository.dart:117` | `Tenant membership was not found.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 5 | `packages/core/core_data/lib/src/repositories/roles_repository.dart:128` | `System administrator roles are managed by the system.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 6 | `packages/core/core_data/lib/src/repositories/roles_repository.dart:156` | `System administrator roles are managed by the system.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 7 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:295` | `Tenant membership was not found.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 8 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:344` | `Invitation resend returned no code.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 9 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:362` | `An email address or phone number is required.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 10 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:382` | `Invitation creation returned no code.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 11 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:407` | `Invitation creation returned no code.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 12 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:426` | `Invite creation returned no code.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 13 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:478` | `Invite redemption returned no role.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 14 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:494` | `Bulk invitations require between 1 and 100 recipients.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 15 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:508` | `Bulk invitation creation returned no results.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 16 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:538` | `Bulk invitations require between 1 and 100 valid recipients.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 17 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:555` | `Bulk invitation creation returned no results.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 18 | `packages/core/core_data/lib/src/repositories/cloud_crm_repository.dart:554` | `At least one invoice item is required.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 19 | `packages/core/core_data/lib/src/repositories/cloud_crm_repository.dart:586` | `Invoice creation returned no committed document.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 20 | `packages/core/core_data/lib/src/repositories/cloud_crm_repository.dart:925` | `At least one bill item is required.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 21 | `packages/core/core_data/lib/src/repositories/cloud_crm_repository.dart:954` | `Bill creation returned no committed document.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 22 | `packages/core/core_data/lib/src/repositories/crm_pipeline_repository.dart:262` | `CRM stage transition returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 23 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:302` | `Accounting books returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 24 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:321` | `Accounting dimensions returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 25 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:376` | `Tax calculation returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 26 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:406` | `Tax snapshot returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 27 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:441` | `A journal entry requires at least two lines.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 28 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:452` | `Journal debits and credits must balance.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 29 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:483` | `Journal draft creation returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 30 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:497` | `Journal posting returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 31 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:511` | `Period closing returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 32 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:548` | `Accounting report returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 33 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:574` | `Trial balance returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 34 | `packages/core/core_data/lib/src/repositories/revenue_recognition_repository.dart:74` | `Revenue schedule returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 35 | `packages/core/core_data/lib/src/repositories/revenue_recognition_repository.dart:114` | `Revenue contract returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 36 | `packages/core/core_data/lib/src/repositories/revenue_recognition_repository.dart:138` | `Revenue recognition draft returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 37 | `packages/core/core_data/lib/src/repositories/ar_ap_settlement_repository.dart:123` | `Settlement draft returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 38 | `packages/core/core_data/lib/src/repositories/ar_ap_settlement_repository.dart:136` | `Aging report returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 39 | `packages/core/core_data/lib/src/repositories/inventory_pos_repository.dart:113` | `A POS sale number and at least one line are required.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 40 | `packages/core/core_data/lib/src/repositories/inventory_pos_repository.dart:140` | `Quantity must be positive and finite.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 41 | `packages/core/core_data/lib/src/repositories/inventory_pos_repository.dart:149` | `Minor-unit amount cannot be negative.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 42 | `packages/core/core_data/lib/src/repositories/inventory_pos_repository.dart:158` | `Inventory/POS operation returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 43 | `packages/core/core_data/lib/src/repositories/crm_360_repository.dart:83` | `Customer 360 returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 44 | `packages/core/core_data/lib/src/repositories/crm_360_repository.dart:103` | `Customer health returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 45 | `packages/core/core_data/lib/src/repositories/crm_360_repository.dart:121` | `Interaction summary is required.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 46 | `packages/core/core_data/lib/src/repositories/crm_360_repository.dart:138` | `Interaction returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 47 | `packages/core/core_data/lib/src/repositories/crm_360_repository.dart:159` | `Quote number, customer, and at least one line are required.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 48 | `packages/core/core_data/lib/src/repositories/crm_360_repository.dart:177` | `Quote draft returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 49 | `packages/core/core_data/lib/src/repositories/event_outbox_repository.dart:116` | `ERP event envelope is invalid.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 50 | `packages/core/core_data/lib/src/repositories/event_outbox_repository.dart:133` | `ERP event enqueue returned no identifier.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 51 | `packages/core/core_data/lib/src/repositories/event_outbox_repository.dart:151` | `ERP event claim returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 52 | `packages/core/core_data/lib/src/repositories/event_outbox_repository.dart:181` | `ERP event completion returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 53 | `packages/core/core_data/lib/src/repositories/event_outbox_repository.dart:224` | `Sync conflict returned no identifier.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 54 | `packages/core/core_data/lib/src/repositories/event_outbox_repository.dart:247` | `Sync conflict resolution returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 55 | `packages/core/core_data/lib/src/repositories/document_intake_repository.dart:122` | `Document anomaly scan returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 56 | `packages/core/core_data/lib/src/repositories/document_intake_repository.dart:143` | `AI policy context returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 57 | `packages/core/core_data/lib/src/repositories/document_intake_repository.dart:156` | `Document operation returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 58 | `packages/core/core_data/lib/src/repositories/extension_registry_repository.dart:102` | `Extension registration returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 59 | `packages/core/core_data/lib/src/repositories/extension_registry_repository.dart:117` | `Extension registry returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 60 | `packages/core/core_data/lib/src/repositories/extension_registry_repository.dart:145` | `Extension review returned no result.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 61 | `packages/core/core_data/lib/src/services/saas_seeding_service.dart:20` | `A real tenant identifier is required.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 62 | `packages/features/feature_accounts/lib/src/presentation/add_account_screen.dart:563` | `0.00` | Formatting or masking token | Numeric precision, password masking, or receipt decoration; not natural-language UI. |
| 63 | `packages/features/feature_accounts/lib/src/presentation/add_account_screen.dart:599` | `0.00` | Formatting or masking token | Numeric precision, password masking, or receipt decoration; not natural-language UI. |
| 64 | `packages/features/feature_auth/lib/src/data/auth_repository.dart:151` | `Business bootstrap returned no tenant identifier.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 65 | `packages/features/feature_reports/lib/src/presentation/cash_flow_screen.dart:248` | `${_dateRange.start.year}` | Dynamic UI text | Requires a localized message with placeholders; addressed or explicitly mapped in the current source. |
| 66 | `packages/features/feature_reports/lib/src/presentation/monthly_amounts_screen.dart:305` | `$monthName ${summary.year}` | Dynamic UI text | Requires a localized message with placeholders; addressed or explicitly mapped in the current source. |
| 67 | `packages/features/feature_reports/lib/src/presentation/operations_report_screens.dart:138` | `${index + 1}` | Dynamic display value | Identifiers, counts, dates, amounts, or separators; localized labels are handled separately. |
| 68 | `packages/features/feature_reports/lib/src/presentation/revenue_recognition_screen.dart:156` | `$amount · ${_localizedStatus(l10n, line.status)}` | Dynamic display value | Identifiers, counts, dates, amounts, or separators; localized labels are handled separately. |
| 69 | `packages/features/feature_settings/lib/src/data/currencies_repository.dart:41` | `Tenant membership was not found.` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 70 | `packages/features/feature_settings/lib/src/presentation/security_settings_screen.dart:97` | `********` | Formatting or masking token | Numeric precision, password masking, or receipt decoration; not natural-language UI. |
| 71 | `packages/features/feature_settings/lib/src/presentation/owner_company_setup_wizard_screen.dart:346` | `${index + 1}` | Dynamic display value | Identifiers, counts, dates, amounts, or separators; localized labels are handled separately. |
| 72 | `packages/features/feature_settings/lib/src/presentation/schema_health_screen.dart:118` | `${check.observedCount}` | Dynamic display value | Identifiers, counts, dates, amounts, or separators; localized labels are handled separately. |
| 73 | `packages/features/feature_transactions/lib/src/data/receipt_service.dart:78` | `*** ${l10n.ok} ***` | Internal technical contract | Not widget-facing; keep domain/repository diagnostics independent of Flutter l10n. |
| 74 | `packages/shared/shared_ui/lib/src/widgets/document_form_body.dart:516` | `0.00` | Formatting or masking token | Numeric precision, password masking, or receipt decoration; not natural-language UI. |

## Complete original 227-entry baseline

The table below is the requested detailed view of every candidate reported by the original audit. “Resolved” means the exact path/literal pair no longer appears in the verified audit; residual rows are listed above with their semantic decision.

| # | Source | Original literal | Status | Classification |
|---:|---|---|---|---|
| 1 | `apps/lib/main.dart:72` | `Mizan` | Residual heuristic | Intentional brand name |
| 2 | `apps/lib/main.dart:167` | `Mizan` | Residual heuristic | Intentional brand name |
| 3 | `packages/core/core_data/lib/src/tenant_context.dart:34` | `Tenant membership was not found.` | Residual heuristic | Internal technical contract |
| 4 | `packages/core/core_data/lib/src/repositories/roles_repository.dart:117` | `Tenant membership was not found.` | Residual heuristic | Internal technical contract |
| 5 | `packages/core/core_data/lib/src/repositories/roles_repository.dart:128` | `System administrator roles are managed by the system.` | Residual heuristic | Internal technical contract |
| 6 | `packages/core/core_data/lib/src/repositories/roles_repository.dart:156` | `System administrator roles are managed by the system.` | Residual heuristic | Internal technical contract |
| 7 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:295` | `Tenant membership was not found.` | Residual heuristic | Internal technical contract |
| 8 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:344` | `Invitation resend returned no code.` | Residual heuristic | Internal technical contract |
| 9 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:362` | `An email address or phone number is required.` | Residual heuristic | Internal technical contract |
| 10 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:382` | `Invitation creation returned no code.` | Residual heuristic | Internal technical contract |
| 11 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:407` | `Invitation creation returned no code.` | Residual heuristic | Internal technical contract |
| 12 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:426` | `Invite creation returned no code.` | Residual heuristic | Internal technical contract |
| 13 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:478` | `Invite redemption returned no role.` | Residual heuristic | Internal technical contract |
| 14 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:494` | `Bulk invitations require between 1 and 100 recipients.` | Residual heuristic | Internal technical contract |
| 15 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:508` | `Bulk invitation creation returned no results.` | Residual heuristic | Internal technical contract |
| 16 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:538` | `Bulk invitations require between 1 and 100 valid recipients.` | Residual heuristic | Internal technical contract |
| 17 | `packages/core/core_data/lib/src/repositories/staff_repository.dart:555` | `Bulk invitation creation returned no results.` | Residual heuristic | Internal technical contract |
| 18 | `packages/core/core_data/lib/src/repositories/cloud_crm_repository.dart:554` | `At least one invoice item is required.` | Residual heuristic | Internal technical contract |
| 19 | `packages/core/core_data/lib/src/repositories/cloud_crm_repository.dart:586` | `Invoice creation returned no committed document.` | Residual heuristic | Internal technical contract |
| 20 | `packages/core/core_data/lib/src/repositories/cloud_crm_repository.dart:925` | `At least one bill item is required.` | Residual heuristic | Internal technical contract |
| 21 | `packages/core/core_data/lib/src/repositories/cloud_crm_repository.dart:954` | `Bill creation returned no committed document.` | Residual heuristic | Internal technical contract |
| 22 | `packages/core/core_data/lib/src/repositories/crm_pipeline_repository.dart:262` | `CRM stage transition returned no result.` | Residual heuristic | Internal technical contract |
| 23 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:302` | `Accounting books returned no result.` | Residual heuristic | Internal technical contract |
| 24 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:321` | `Accounting dimensions returned no result.` | Residual heuristic | Internal technical contract |
| 25 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:376` | `Tax calculation returned no result.` | Residual heuristic | Internal technical contract |
| 26 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:406` | `Tax snapshot returned no result.` | Residual heuristic | Internal technical contract |
| 27 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:441` | `A journal entry requires at least two lines.` | Residual heuristic | Internal technical contract |
| 28 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:452` | `Journal debits and credits must balance.` | Residual heuristic | Internal technical contract |
| 29 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:483` | `Journal draft creation returned no result.` | Residual heuristic | Internal technical contract |
| 30 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:497` | `Journal posting returned no result.` | Residual heuristic | Internal technical contract |
| 31 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:511` | `Period closing returned no result.` | Residual heuristic | Internal technical contract |
| 32 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:548` | `Accounting report returned no result.` | Residual heuristic | Internal technical contract |
| 33 | `packages/core/core_data/lib/src/repositories/accounting_ledger_repository.dart:574` | `Trial balance returned no result.` | Residual heuristic | Internal technical contract |
| 34 | `packages/core/core_data/lib/src/repositories/revenue_recognition_repository.dart:74` | `Revenue schedule returned no result.` | Residual heuristic | Internal technical contract |
| 35 | `packages/core/core_data/lib/src/repositories/revenue_recognition_repository.dart:114` | `Revenue contract returned no result.` | Residual heuristic | Internal technical contract |
| 36 | `packages/core/core_data/lib/src/repositories/revenue_recognition_repository.dart:138` | `Revenue recognition draft returned no result.` | Residual heuristic | Internal technical contract |
| 37 | `packages/core/core_data/lib/src/repositories/ar_ap_settlement_repository.dart:123` | `Settlement draft returned no result.` | Residual heuristic | Internal technical contract |
| 38 | `packages/core/core_data/lib/src/repositories/ar_ap_settlement_repository.dart:136` | `Aging report returned no result.` | Residual heuristic | Internal technical contract |
| 39 | `packages/core/core_data/lib/src/repositories/inventory_pos_repository.dart:113` | `A POS sale number and at least one line are required.` | Residual heuristic | Internal technical contract |
| 40 | `packages/core/core_data/lib/src/repositories/inventory_pos_repository.dart:140` | `Quantity must be positive and finite.` | Residual heuristic | Internal technical contract |
| 41 | `packages/core/core_data/lib/src/repositories/inventory_pos_repository.dart:149` | `Minor-unit amount cannot be negative.` | Residual heuristic | Internal technical contract |
| 42 | `packages/core/core_data/lib/src/repositories/inventory_pos_repository.dart:158` | `Inventory/POS operation returned no result.` | Residual heuristic | Internal technical contract |
| 43 | `packages/core/core_data/lib/src/repositories/crm_360_repository.dart:83` | `Customer 360 returned no result.` | Residual heuristic | Internal technical contract |
| 44 | `packages/core/core_data/lib/src/repositories/crm_360_repository.dart:103` | `Customer health returned no result.` | Residual heuristic | Internal technical contract |
| 45 | `packages/core/core_data/lib/src/repositories/crm_360_repository.dart:121` | `Interaction summary is required.` | Residual heuristic | Internal technical contract |
| 46 | `packages/core/core_data/lib/src/repositories/crm_360_repository.dart:138` | `Interaction returned no result.` | Residual heuristic | Internal technical contract |
| 47 | `packages/core/core_data/lib/src/repositories/crm_360_repository.dart:159` | `Quote number, customer, and at least one line are required.` | Residual heuristic | Internal technical contract |
| 48 | `packages/core/core_data/lib/src/repositories/crm_360_repository.dart:177` | `Quote draft returned no result.` | Residual heuristic | Internal technical contract |
| 49 | `packages/core/core_data/lib/src/repositories/event_outbox_repository.dart:116` | `ERP event envelope is invalid.` | Residual heuristic | Internal technical contract |
| 50 | `packages/core/core_data/lib/src/repositories/event_outbox_repository.dart:133` | `ERP event enqueue returned no identifier.` | Residual heuristic | Internal technical contract |
| 51 | `packages/core/core_data/lib/src/repositories/event_outbox_repository.dart:151` | `ERP event claim returned no result.` | Residual heuristic | Internal technical contract |
| 52 | `packages/core/core_data/lib/src/repositories/event_outbox_repository.dart:181` | `ERP event completion returned no result.` | Residual heuristic | Internal technical contract |
| 53 | `packages/core/core_data/lib/src/repositories/event_outbox_repository.dart:224` | `Sync conflict returned no identifier.` | Residual heuristic | Internal technical contract |
| 54 | `packages/core/core_data/lib/src/repositories/event_outbox_repository.dart:247` | `Sync conflict resolution returned no result.` | Residual heuristic | Internal technical contract |
| 55 | `packages/core/core_data/lib/src/repositories/document_intake_repository.dart:122` | `Document anomaly scan returned no result.` | Residual heuristic | Internal technical contract |
| 56 | `packages/core/core_data/lib/src/repositories/document_intake_repository.dart:143` | `AI policy context returned no result.` | Residual heuristic | Internal technical contract |
| 57 | `packages/core/core_data/lib/src/repositories/document_intake_repository.dart:156` | `Document operation returned no result.` | Residual heuristic | Internal technical contract |
| 58 | `packages/core/core_data/lib/src/repositories/extension_registry_repository.dart:102` | `Extension registration returned no result.` | Residual heuristic | Internal technical contract |
| 59 | `packages/core/core_data/lib/src/repositories/extension_registry_repository.dart:117` | `Extension registry returned no result.` | Residual heuristic | Internal technical contract |
| 60 | `packages/core/core_data/lib/src/repositories/extension_registry_repository.dart:145` | `Extension review returned no result.` | Residual heuristic | Internal technical contract |
| 61 | `packages/core/core_data/lib/src/services/saas_seeding_service.dart:20` | `A real tenant identifier is required.` | Residual heuristic | Internal technical contract |
| 62 | `packages/features/feature_accounts/lib/src/presentation/account_ledger_screen.dart:167` | `${l10n.error} $err` | Resolved / no longer reported | Dynamic UI text |
| 63 | `packages/features/feature_accounts/lib/src/presentation/add_account_screen.dart:267` | `${l10n.failedToSaveAccount} $e` | Resolved / no longer reported | Dynamic UI text |
| 64 | `packages/features/feature_accounts/lib/src/presentation/add_account_screen.dart:330` | `1 From = X To` | Resolved / no longer reported | User-facing literal |
| 65 | `packages/features/feature_accounts/lib/src/presentation/add_account_screen.dart:561` | `0.00` | Residual heuristic | Formatting or masking token |
| 66 | `packages/features/feature_accounts/lib/src/presentation/add_account_screen.dart:597` | `0.00` | Residual heuristic | Formatting or masking token |
| 67 | `packages/features/feature_accounts/lib/src/presentation/add_account_screen.dart:802` | `$from → $to` | Resolved / no longer reported | Dynamic display value |
| 68 | `packages/features/feature_accounts/lib/src/presentation/hierarchical_accounts_list.dart:44` | `Error: $err` | Resolved / no longer reported | User-facing literal |
| 69 | `packages/features/feature_accounts/lib/src/presentation/hierarchical_accounts_list.dart:48` | `Error: $err` | Resolved / no longer reported | User-facing literal |
| 70 | `packages/features/feature_auth/lib/src/data/auth_repository.dart:151` | `Business bootstrap returned no tenant identifier.` | Residual heuristic | Internal technical contract |
| 71 | `packages/features/feature_auth/lib/src/presentation/business_setup_screen.dart:59` | `${l10n.error} $e` | Resolved / no longer reported | Dynamic UI text |
| 72 | `packages/features/feature_contacts/lib/src/presentation/customers/ar_aging_report_screen.dart:43` | `Error: $e` | Resolved / no longer reported | User-facing literal |
| 73 | `packages/features/feature_contacts/lib/src/presentation/customers/customer_form_screen.dart:158` | `${l10n.error} $e` | Resolved / no longer reported | Dynamic UI text |
| 74 | `packages/features/feature_contacts/lib/src/presentation/customers/customer_form_screen.dart:200` | `${l10n.customerName} *` | Resolved / no longer reported | Dynamic display value |
| 75 | `packages/features/feature_contacts/lib/src/presentation/vendors/ap_aging_report_screen.dart:38` | `Error: $e` | Resolved / no longer reported | User-facing literal |
| 76 | `packages/features/feature_contacts/lib/src/presentation/vendors/vendor_form_screen.dart:194` | `${l10n.vendorName} *` | Resolved / no longer reported | Dynamic display value |
| 77 | `packages/features/feature_data_import/lib/src/data/import_service.dart:115` | `Unexpected error: $e` | Resolved / no longer reported | Internal technical contract |
| 78 | `packages/features/feature_data_import/lib/src/data/import_service.dart:155` | `${fieldDef.label} is required` | Resolved / no longer reported | Internal technical contract |
| 79 | `packages/features/feature_data_import/lib/src/data/import_service.dart:166` | `${mapping.customField!.label} is required` | Resolved / no longer reported | Internal technical contract |
| 80 | `packages/features/feature_data_import/lib/src/presentation/import_wizard_screen.dart:100` | `${_preview!.parsedData.rowCount} rows` | Resolved / no longer reported | Dynamic display value |
| 81 | `packages/features/feature_data_import/lib/src/presentation/import_wizard_screen.dart:212` | `Map to` | Resolved / no longer reported | User-facing literal |
| 82 | `packages/features/feature_data_import/lib/src/presentation/import_wizard_screen.dart:218` | `(Skip this column)` | Resolved / no longer reported | User-facing literal |
| 83 | `packages/features/feature_data_import/lib/src/presentation/import_wizard_screen.dart:221` | `${f.label}${f.required ?` | Resolved / no longer reported | Dynamic UI text |
| 84 | `packages/features/feature_data_import/lib/src/presentation/import_wizard_screen.dart:226` | `+ Create Custom Field` | Resolved / no longer reported | User-facing literal |
| 85 | `packages/features/feature_data_import/lib/src/presentation/import_wizard_screen.dart:291` | `${_result!.successCount} records imported successfully` | Resolved / no longer reported | Dynamic display value |
| 86 | `packages/features/feature_data_import/lib/src/presentation/import_wizard_screen.dart:297` | `Duration: ${_result!.duration.inSeconds}s` | Resolved / no longer reported | Dynamic display value |
| 87 | `packages/features/feature_data_import/lib/src/presentation/import_wizard_screen.dart:310` | `Row ${e.rowNumber}` | Resolved / no longer reported | Dynamic display value |
| 88 | `packages/features/feature_data_import/lib/src/presentation/import_wizard_screen.dart:315` | `... and ${_result!.errors.length - 10} more errors` | Resolved / no longer reported | Dynamic UI text |
| 89 | `packages/features/feature_products/lib/src/presentation/product_import_screen.dart:43` | `${l10n.error} $e` | Resolved / no longer reported | Dynamic UI text |
| 90 | `packages/features/feature_products/lib/src/presentation/product_import_screen.dart:83` | `${l10n.error} $e` | Resolved / no longer reported | Dynamic UI text |
| 91 | `packages/features/feature_products/lib/src/presentation/product_import_screen.dart:133` | `${l10n.error} $e` | Resolved / no longer reported | Dynamic UI text |
| 92 | `packages/features/feature_reports/lib/main.dart:13` | `Hello World!` | Resolved / no longer reported | User-facing literal |
| 93 | `packages/features/feature_reports/lib/src/presentation/analytics_dashboard_screen.dart:68` | `No sales data yet.` | Resolved / no longer reported | User-facing literal |
| 94 | `packages/features/feature_reports/lib/src/presentation/analytics_dashboard_screen.dart:133` | `Error: $e` | Resolved / no longer reported | User-facing literal |
| 95 | `packages/features/feature_reports/lib/src/presentation/analytics_dashboard_screen.dart:150` | `No category data.` | Resolved / no longer reported | User-facing literal |
| 96 | `packages/features/feature_reports/lib/src/presentation/analytics_dashboard_screen.dart:219` | `Error: $e` | Resolved / no longer reported | User-facing literal |
| 97 | `packages/features/feature_reports/lib/src/presentation/analytics_dashboard_screen.dart:235` | `No sales data.` | Resolved / no longer reported | User-facing literal |
| 98 | `packages/features/feature_reports/lib/src/presentation/analytics_dashboard_screen.dart:257` | `Error: $e` | Resolved / no longer reported | User-facing literal |
| 99 | `packages/features/feature_reports/lib/src/presentation/ar_ap_summary_cards.dart:24` | `Receivables` | Resolved / no longer reported | User-facing literal |
| 100 | `packages/features/feature_reports/lib/src/presentation/ar_ap_summary_cards.dart:30` | `Receivables` | Resolved / no longer reported | User-facing literal |
| 101 | `packages/features/feature_reports/lib/src/presentation/ar_ap_summary_cards.dart:36` | `Receivables` | Resolved / no longer reported | User-facing literal |
| 102 | `packages/features/feature_reports/lib/src/presentation/ar_ap_summary_cards.dart:53` | `Payables` | Resolved / no longer reported | User-facing literal |
| 103 | `packages/features/feature_reports/lib/src/presentation/ar_ap_summary_cards.dart:59` | `Payables` | Resolved / no longer reported | User-facing literal |
| 104 | `packages/features/feature_reports/lib/src/presentation/ar_ap_summary_cards.dart:65` | `Payables` | Resolved / no longer reported | User-facing literal |
| 105 | `packages/features/feature_reports/lib/src/presentation/cash_flow_screen.dart:132` | `Error loading data: $e` | Resolved / no longer reported | User-facing literal |
| 106 | `packages/features/feature_reports/lib/src/presentation/cash_flow_screen.dart:243` | `${_dateRange.start.year}` | Residual heuristic | Dynamic UI text |
| 107 | `packages/features/feature_reports/lib/src/presentation/dynamic_report_screen.dart:83` | `Run Report` | Resolved / no longer reported | User-facing literal |
| 108 | `packages/features/feature_reports/lib/src/presentation/dynamic_report_screen.dart:101` | `Set parameters and run report.` | Resolved / no longer reported | User-facing literal |
| 109 | `packages/features/feature_reports/lib/src/presentation/dynamic_report_screen.dart:103` | `No data found for these criteria.` | Resolved / no longer reported | User-facing literal |
| 110 | `packages/features/feature_reports/lib/src/presentation/monthly_amounts_screen.dart:305` | `$monthName ${summary.year}` | Residual heuristic | Dynamic UI text |
| 111 | `packages/features/feature_reports/lib/src/presentation/total_amounts_screen.dart:360` | `${l10n.error} ${err.toString()}` | Resolved / no longer reported | Dynamic UI text |
| 112 | `packages/features/feature_reports/lib/src/presentation/operations_report_screens.dart:138` | `${index + 1}` | Residual heuristic | Dynamic display value |
| 113 | `packages/features/feature_reports/lib/src/presentation/operations_report_screens.dart:157` | `${l10n.soldQuantity}: ${product.quantitySold}` | Resolved / no longer reported | Dynamic display value |
| 114 | `packages/features/feature_reports/lib/src/presentation/operations_report_screens.dart:158` | `${l10n.currentStock}: ${product.currentStock}` | Resolved / no longer reported | Dynamic display value |
| 115 | `packages/features/feature_reports/lib/src/presentation/ledger_control_screen.dart:175` | `${book.code} — ${book.name}` | Resolved / no longer reported | Dynamic display value |
| 116 | `packages/features/feature_reports/lib/src/presentation/ledger_control_screen.dart:214` | `${account.code} — ${account.name}` | Resolved / no longer reported | Dynamic display value |
| 117 | `packages/features/feature_reports/lib/src/presentation/ledger_control_screen.dart:232` | `${tax.code} — ${tax.name}` | Resolved / no longer reported | Dynamic display value |
| 118 | `packages/features/feature_reports/lib/src/presentation/revenue_recognition_screen.dart:156` | `$amount · ${_localizedStatus(l10n, line.status)}` | Residual heuristic | Dynamic display value |
| 119 | `packages/features/feature_reports/lib/src/presentation/bank/bank_reconciliation_screen.dart:186` | `Statement Balance:` | Resolved / no longer reported | User-facing literal |
| 120 | `packages/features/feature_reports/lib/src/presentation/bank/bank_reconciliation_screen.dart:197` | `Book Balance:` | Resolved / no longer reported | User-facing literal |
| 121 | `packages/features/feature_reports/lib/src/presentation/bank/bank_reconciliation_screen.dart:208` | `Selected Cleared:` | Resolved / no longer reported | User-facing literal |
| 122 | `packages/features/feature_reports/lib/src/presentation/bank/bank_reconciliations_list_screen.dart:20` | `Bank Reconciliations` | Resolved / no longer reported | User-facing literal |
| 123 | `packages/features/feature_reports/lib/src/presentation/bank/bank_reconciliations_list_screen.dart:26` | `New Reconciliation` | Resolved / no longer reported | User-facing literal |
| 124 | `packages/features/feature_reports/lib/src/presentation/bank/bank_reconciliations_list_screen.dart:158` | `New Reconciliation` | Resolved / no longer reported | User-facing literal |
| 125 | `packages/features/feature_reports/lib/src/presentation/bank/bank_reconciliations_list_screen.dart:166` | `Bank Account` | Resolved / no longer reported | User-facing literal |
| 126 | `packages/features/feature_reports/lib/src/presentation/bank/bank_reconciliations_list_screen.dart:179` | `Statement Date` | Resolved / no longer reported | User-facing literal |
| 127 | `packages/features/feature_reports/lib/src/presentation/bank/bank_reconciliations_list_screen.dart:198` | `Statement Ending Balance` | Resolved / no longer reported | User-facing literal |
| 128 | `packages/features/feature_reports/lib/src/presentation/bank/bank_reconciliations_list_screen.dart:210` | `Cancel` | Resolved / no longer reported | User-facing literal |
| 129 | `packages/features/feature_reports/lib/src/presentation/bank/bank_reconciliations_list_screen.dart:226` | `Create` | Resolved / no longer reported | User-facing literal |
| 130 | `packages/features/feature_reports/lib/src/presentation/tools/capital_budgeting_screen.dart:288` | `Year ${index + 1}` | Resolved / no longer reported | Dynamic UI text |
| 131 | `packages/features/feature_reports/lib/src/presentation/tools/financial_ratios_screen.dart:45` | `Select Period` | Resolved / no longer reported | User-facing literal |
| 132 | `packages/features/feature_reports/lib/src/presentation/tools/financial_ratios_screen.dart:51` | `Refresh` | Resolved / no longer reported | User-facing literal |
| 133 | `packages/features/feature_reports/lib/src/presentation/tools/financial_ratios_screen.dart:161` | `Analysis Period` | Resolved / no longer reported | User-facing literal |
| 134 | `packages/features/feature_reports/lib/src/presentation/tools/financial_ratios_screen.dart:172` | `Change` | Resolved / no longer reported | User-facing literal |
| 135 | `packages/features/feature_settings/lib/src/data/currencies_repository.dart:41` | `Tenant membership was not found.` | Residual heuristic | Internal technical contract |
| 136 | `packages/features/feature_settings/lib/src/presentation/company_profile_screen.dart:74` | `Failed to pick image: $e` | Resolved / no longer reported | User-facing literal |
| 137 | `packages/features/feature_settings/lib/src/presentation/company_profile_screen.dart:122` | `${l10n.failedToSaveProfile} $e` | Resolved / no longer reported | Dynamic UI text |
| 138 | `packages/features/feature_settings/lib/src/presentation/currency_settings_screen.dart:108` | `${l10n.failedToSave} $e` | Resolved / no longer reported | Dynamic UI text |
| 139 | `packages/features/feature_settings/lib/src/presentation/currency_settings_screen.dart:141` | `${l10n.codeLabel} ${currency.code}` | Resolved / no longer reported | Dynamic display value |
| 140 | `packages/features/feature_settings/lib/src/presentation/currency_settings_screen.dart:175` | `${l10n.error} ${err.toString()}` | Resolved / no longer reported | Dynamic UI text |
| 141 | `packages/features/feature_settings/lib/src/presentation/depreciation_screen.dart:170` | `Error: $err` | Resolved / no longer reported | User-facing literal |
| 142 | `packages/features/feature_settings/lib/src/presentation/depreciation_screen.dart:337` | `Error: $e` | Resolved / no longer reported | User-facing literal |
| 143 | `packages/features/feature_settings/lib/src/presentation/depreciation_screen.dart:388` | `Error: $e` | Resolved / no longer reported | User-facing literal |
| 144 | `packages/features/feature_settings/lib/src/presentation/fixed_assets_screen.dart:837` | `Run Depreciation` | Resolved / no longer reported | User-facing literal |
| 145 | `packages/features/feature_settings/lib/src/presentation/fixed_assets_screen.dart:842` | `Cancel` | Resolved / no longer reported | User-facing literal |
| 146 | `packages/features/feature_settings/lib/src/presentation/fixed_assets_screen.dart:846` | `Run Depreciation` | Resolved / no longer reported | User-facing literal |
| 147 | `packages/features/feature_settings/lib/src/presentation/ghost_money_screen.dart:172` | `Error: $err` | Resolved / no longer reported | User-facing literal |
| 148 | `packages/features/feature_settings/lib/src/presentation/ghost_money_screen.dart:245` | `Error: $err` | Resolved / no longer reported | User-facing literal |
| 149 | `packages/features/feature_settings/lib/src/presentation/ghost_money_screen.dart:323` | `Error: $e` | Resolved / no longer reported | User-facing literal |
| 150 | `packages/features/feature_settings/lib/src/presentation/ghost_money_screen.dart:349` | `Error: $e` | Resolved / no longer reported | User-facing literal |
| 151 | `packages/features/feature_settings/lib/src/presentation/onboarding_screen.dart:113` | `English` | Resolved / no longer reported | User-facing literal |
| 152 | `packages/features/feature_settings/lib/src/presentation/onboarding_screen.dart:123` | `العربية` | Resolved / no longer reported | User-facing literal |
| 153 | `packages/features/feature_settings/lib/src/presentation/onboarding_screen.dart:312` | `Please enter currency details` | Resolved / no longer reported | User-facing literal |
| 154 | `packages/features/feature_settings/lib/src/presentation/security_settings_screen.dart:97` | `********` | Residual heuristic | Formatting or masking token |
| 155 | `packages/features/feature_settings/lib/src/presentation/set_passcode_screen.dart:61` | `${l10n.failedToSavePasscode} $e` | Resolved / no longer reported | Dynamic UI text |
| 156 | `packages/features/feature_settings/lib/src/presentation/owner_control_center_screen.dart:117` | `${l10n.branchManagement}: $branchCount` | Resolved / no longer reported | Dynamic display value |
| 157 | `packages/features/feature_settings/lib/src/presentation/owner_company_setup_wizard_screen.dart:182` | `${l10n.error} $error` | Resolved / no longer reported | Dynamic UI text |
| 158 | `packages/features/feature_settings/lib/src/presentation/owner_company_setup_wizard_screen.dart:346` | `${index + 1}` | Residual heuristic | Dynamic display value |
| 159 | `packages/features/feature_settings/lib/src/presentation/owner_company_setup_wizard_screen.dart:392` | `cash, bank_transfer, jaib` | Resolved / no longer reported | User-facing literal |
| 160 | `packages/features/feature_settings/lib/src/presentation/owner_accounting_settings_screen.dart:413` | `$title ${l10n.documentPrefix}` | Resolved / no longer reported | Dynamic display value |
| 161 | `packages/features/feature_settings/lib/src/presentation/owner_policy_settings_screen.dart:62` | `${l10n.error} $error` | Resolved / no longer reported | Dynamic UI text |
| 162 | `packages/features/feature_settings/lib/src/presentation/owner_employee_settings_screen.dart:83` | `${l10n.error} $error` | Resolved / no longer reported | Dynamic UI text |
| 163 | `packages/features/feature_settings/lib/src/presentation/owner_approval_center_screen.dart:89` | `${l10n.requester}: ${request.requester}` | Resolved / no longer reported | Dynamic display value |
| 164 | `packages/features/feature_settings/lib/src/presentation/owner_approval_center_screen.dart:90` | `${l10n.approvalAmount}: $amount` | Resolved / no longer reported | Dynamic display value |
| 165 | `packages/features/feature_settings/lib/src/presentation/owner_approval_center_screen.dart:91` | `${l10n.approvalReason}: ${request.reason}` | Resolved / no longer reported | Dynamic display value |
| 166 | `packages/features/feature_settings/lib/src/presentation/owner_inventory_settings_screen.dart:81` | `${l10n.error} $error` | Resolved / no longer reported | Dynamic UI text |
| 167 | `packages/features/feature_settings/lib/src/presentation/owner_security_audit_screen.dart:59` | `Revision ${entry.revision}` | Resolved / no longer reported | Dynamic UI text |
| 168 | `packages/features/feature_settings/lib/src/presentation/owner_payment_settings_screen.dart:104` | `${l10n.error} $error` | Resolved / no longer reported | Dynamic UI text |
| 169 | `packages/features/feature_settings/lib/src/presentation/owner_crm_settings_screen.dart:94` | `${l10n.error} $error` | Resolved / no longer reported | Dynamic UI text |
| 170 | `packages/features/feature_settings/lib/src/presentation/owner_pos_settings_screen.dart:93` | `${l10n.error} $error` | Resolved / no longer reported | Dynamic UI text |
| 171 | `packages/features/feature_settings/lib/src/presentation/owner_finance_operations_settings_screen.dart:108` | `${l10n.error} $error` | Resolved / no longer reported | Dynamic UI text |
| 172 | `packages/features/feature_settings/lib/src/presentation/owner_close_management_screen.dart:76` | `${l10n.error} $error` | Resolved / no longer reported | Dynamic UI text |
| 173 | `packages/features/feature_settings/lib/src/presentation/owner_close_management_screen.dart:125` | `YYYY-MM-DD` | Resolved / no longer reported | User-facing literal |
| 174 | `packages/features/feature_settings/lib/src/presentation/schema_health_screen.dart:118` | `${check.observedCount}` | Residual heuristic | Dynamic display value |
| 175 | `packages/features/feature_settings/lib/src/presentation/staff/staff_list_screen.dart:290` | `$role • $readableStatus` | Resolved / no longer reported | Dynamic display value |
| 176 | `packages/features/feature_settings/lib/src/presentation/staff/staff_list_screen.dart:291` | `${l10n.deliveryChannel}: $channel` | Resolved / no longer reported | Dynamic display value |
| 177 | `packages/features/feature_settings/lib/src/presentation/staff/bulk_invite_staff_screen.dart:83` | `${l10n.fileImportFailed}: $error` | Resolved / no longer reported | Dynamic UI text |
| 178 | `packages/features/feature_sync/lib/src/presentation/sync_gatekeeper.dart:56` | `☁️ Sync Warning` | Resolved / no longer reported | User-facing literal |
| 179 | `packages/features/feature_sync/lib/src/presentation/sync_gatekeeper.dart:65` | `I Understand` | Resolved / no longer reported | User-facing literal |
| 180 | `packages/features/feature_transactions/lib/src/data/receipt_service.dart:76` | `*** ${l10n.ok} ***` | Residual heuristic | Internal technical contract |
| 181 | `packages/features/feature_transactions/lib/src/presentation/add_amount_screen.dart:210` | `${l10n.failedToSave} $e` | Resolved / no longer reported | Dynamic UI text |
| 182 | `packages/features/feature_transactions/lib/src/presentation/add_amount_screen.dart:296` | `${l10n.errorLoadingAccounts} $e` | Resolved / no longer reported | Dynamic UI text |
| 183 | `packages/features/feature_transactions/lib/src/presentation/add_amount_screen.dart:490` | `${l10n.errorLoadingHistory} $e` | Resolved / no longer reported | Dynamic UI text |
| 184 | `packages/features/feature_transactions/lib/src/presentation/adjusting_entries_screen.dart:24` | `Adjustments & Closing` | Resolved / no longer reported | User-facing literal |
| 185 | `packages/features/feature_transactions/lib/src/presentation/adjusting_entries_screen.dart:28` | `Close Period` | Resolved / no longer reported | User-facing literal |
| 186 | `packages/features/feature_transactions/lib/src/presentation/adjusting_entries_screen.dart:60` | `All adjustments approved!` | Resolved / no longer reported | User-facing literal |
| 187 | `packages/features/feature_transactions/lib/src/presentation/adjusting_entries_screen.dart:87` | `What do you need to record?` | Resolved / no longer reported | User-facing literal |
| 188 | `packages/features/feature_transactions/lib/src/presentation/adjusting_entries_screen.dart:195` | `Reject` | Resolved / no longer reported | User-facing literal |
| 189 | `packages/features/feature_transactions/lib/src/presentation/adjusting_entries_screen.dart:202` | `Approve` | Resolved / no longer reported | User-facing literal |
| 190 | `packages/features/feature_transactions/lib/src/presentation/adjusting_entries_screen.dart:256` | `Amount` | Resolved / no longer reported | User-facing literal |
| 191 | `packages/features/feature_transactions/lib/src/presentation/adjusting_entries_screen.dart:280` | `Error loading accounts` | Resolved / no longer reported | User-facing literal |
| 192 | `packages/features/feature_transactions/lib/src/presentation/adjusting_entries_screen.dart:287` | `Cancel` | Resolved / no longer reported | User-facing literal |
| 193 | `packages/features/feature_transactions/lib/src/presentation/adjusting_entries_screen.dart:290` | `Propose Adjustment` | Resolved / no longer reported | User-facing literal |
| 194 | `packages/features/feature_transactions/lib/src/presentation/bank_reconciliation_screen.dart:205` | `${l10n.error} $e` | Resolved / no longer reported | Dynamic UI text |
| 195 | `packages/features/feature_transactions/lib/src/presentation/bank_reconciliation_screen.dart:245` | `${l10n.clearedBalance}:` | Resolved / no longer reported | Dynamic display value |
| 196 | `packages/features/feature_transactions/lib/src/presentation/bank_reconciliation_screen.dart:401` | `${l10n.error} $e` | Resolved / no longer reported | Dynamic UI text |
| 197 | `packages/features/feature_transactions/lib/src/presentation/general_journal_screen.dart:299` | `Currency Code` | Resolved / no longer reported | User-facing literal |
| 198 | `packages/features/feature_transactions/lib/src/presentation/general_journal_screen.dart:301` | `e.g. USD` | Resolved / no longer reported | User-facing literal |
| 199 | `packages/features/feature_transactions/lib/src/presentation/general_journal_screen.dart:311` | `Exchange Rate` | Resolved / no longer reported | User-facing literal |
| 200 | `packages/features/feature_transactions/lib/src/presentation/make_payment_screen.dart:175` | `Error loading accounts: $e` | Resolved / no longer reported | User-facing literal |
| 201 | `packages/features/feature_transactions/lib/src/presentation/order_details_screen.dart:122` | `${l10n.error}: $err` | Resolved / no longer reported | Dynamic UI text |
| 202 | `packages/features/feature_transactions/lib/src/presentation/order_details_screen.dart:126` | `${l10n.error}: $err` | Resolved / no longer reported | Dynamic UI text |
| 203 | `packages/features/feature_transactions/lib/src/presentation/order_history_screen.dart:119` | `${l10n.error}: ${err.toString()}` | Resolved / no longer reported | Dynamic UI text |
| 204 | `packages/features/feature_transactions/lib/src/presentation/order_history_screen.dart:124` | `${l10n.error}: ${err.toString()}` | Resolved / no longer reported | Dynamic UI text |
| 205 | `packages/features/feature_transactions/lib/src/presentation/order_history_screen.dart:129` | `${l10n.error}: ${err.toString()}` | Resolved / no longer reported | Dynamic UI text |
| 206 | `packages/features/feature_transactions/lib/src/presentation/period_end_wizard_screen.dart:148` | `Error loading accounts: $e` | Resolved / no longer reported | User-facing literal |
| 207 | `packages/features/feature_transactions/lib/src/presentation/period_end_wizard_screen.dart:227` | `Confirm Period Close` | Resolved / no longer reported | User-facing literal |
| 208 | `packages/features/feature_transactions/lib/src/presentation/period_end_wizard_screen.dart:235` | `Cancel` | Resolved / no longer reported | User-facing literal |
| 209 | `packages/features/feature_transactions/lib/src/presentation/period_end_wizard_screen.dart:239` | `Confirm` | Resolved / no longer reported | User-facing literal |
| 210 | `packages/features/feature_transactions/lib/src/presentation/period_end_wizard_screen.dart:259` | `Period Closed Successfully.` | Resolved / no longer reported | User-facing literal |
| 211 | `packages/features/feature_transactions/lib/src/presentation/period_end_wizard_screen.dart:266` | `Error: $e` | Resolved / no longer reported | User-facing literal |
| 212 | `packages/features/feature_transactions/lib/src/presentation/pos_screen.dart:365` | `Error: $e` | Resolved / no longer reported | User-facing literal |
| 213 | `packages/features/feature_transactions/lib/src/presentation/pos_screen.dart:481` | `${l10n.transactionFailed} $e` | Resolved / no longer reported | Dynamic UI text |
| 214 | `packages/features/feature_transactions/lib/src/presentation/pos_screen.dart:669` | `${l10n.error}: $error` | Resolved / no longer reported | Dynamic UI text |
| 215 | `packages/features/feature_transactions/lib/src/presentation/purchase_screen.dart:206` | `Error: ${e.toString()}` | Resolved / no longer reported | Dynamic UI text |
| 216 | `packages/features/feature_transactions/lib/src/presentation/purchase_screen.dart:262` | `Error: ${e.toString()}` | Resolved / no longer reported | Dynamic UI text |
| 217 | `packages/features/feature_transactions/lib/src/presentation/return_items_screen.dart:125` | `${l10n.returnFailed}: $e` | Resolved / no longer reported | Dynamic UI text |
| 218 | `packages/features/feature_transactions/lib/src/presentation/return_items_screen.dart:333` | `${l10n.error}: $err` | Resolved / no longer reported | Dynamic UI text |
| 219 | `packages/features/feature_transactions/lib/src/presentation/bank_reconciliation/bank_matching_screen.dart:39` | `Bank Reconciliation` | Resolved / no longer reported | User-facing literal |
| 220 | `packages/features/feature_transactions/lib/src/presentation/bank_reconciliation/bank_matching_screen.dart:41` | `All caught up! No transactions to reconcile.` | Resolved / no longer reported | User-facing literal |
| 221 | `packages/features/feature_transactions/lib/src/presentation/bank_reconciliation/bank_matching_screen.dart:47` | `Bank Matching` | Resolved / no longer reported | User-facing literal |
| 222 | `packages/features/feature_ai/lib/src/local_ai/local_ai_engine.dart:68` | `Local AI is not enabled on this device.` | Resolved / no longer reported | Internal diagnostic contract |
| 223 | `packages/features/feature_ai/lib/src/local_ai/local_ai_native_bridge.dart:242` | `Local AI model is unavailable.` | Resolved / no longer reported | Internal diagnostic contract |
| 224 | `packages/features/feature_ai/lib/src/local_ai/local_ai_native_bridge.dart:246` | `Android local AI runtime failed.` | Resolved / no longer reported | Internal diagnostic contract |
| 225 | `packages/shared/shared_ui/lib/src/widgets/document_form_body.dart:186` | `${l10n.error} $e` | Resolved / no longer reported | Dynamic UI text |
| 226 | `packages/shared/shared_ui/lib/src/widgets/document_form_body.dart:247` | `${l10n.vendorInvoice} (${l10n.optional})` | Resolved / no longer reported | Dynamic display value |
| 227 | `packages/shared/shared_ui/lib/src/widgets/document_form_body.dart:516` | `0.00` | Residual heuristic | Formatting or masking token |

## Validation interpretation

The verified audit reports zero missing Arabic keys, zero placeholder mismatches, zero missing localization references, and 22 legacy Arabic-only keys. The residual count must not be interpreted as 74 untranslated strings: it is dominated by internal repository diagnostics, server-contract guard messages, brand text, dynamic numeric values, dates, identifiers, password masks, and receipt formatting. The source code was analyzed after regeneration of the localization output, and affected packages passed analysis and available tests.

## Files changed in this wave

| Area | Change |
|---|---|
| Catalogs | Added English/Arabic messages for report, import, accounting, settings, sync, depreciation, local-AI, and dynamic-label cases. |
| Presentation | Replaced genuine hard-coded labels and messages across reports, transactions, settings, accounts, contacts, imports, sync, and shared document UI. |
| Data import | Added structured ImportError types and locale-aware presentation for required-field and unexpected-error messages. |
| Local AI | Replaced fallback English diagnostics with stable diagnostic codes resolved through English/Arabic UI messages. |
| Verification | Regenerated l10n code; analyzed affected packages; ran available core-data, feature-AI, feature-settings, feature-reports, feature-sync, and shared-UI tests. |
