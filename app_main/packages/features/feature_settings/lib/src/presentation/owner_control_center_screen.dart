import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'owner_company_setup_wizard_screen.dart';
import 'owner_accounting_settings_screen.dart';
import 'owner_policy_settings_screen.dart';
import 'owner_employee_settings_screen.dart';
import 'owner_branch_settings_screen.dart';
import 'owner_approval_center_screen.dart';
import '../data/owner_approval_repository.dart';
import 'owner_security_audit_screen.dart';
import 'owner_inventory_settings_screen.dart';
import 'owner_payment_settings_screen.dart';
import 'owner_crm_settings_screen.dart';
import 'owner_pos_settings_screen.dart';
import 'owner_finance_operations_settings_screen.dart';
import '../data/owner_control_center_contract.dart';
import '../data/owner_control_center_repository.dart';

class OwnerControlCenterScreen extends ConsumerWidget {
  const OwnerControlCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final roleAsync = ref.watch(userRoleProvider);
    final isGuest = roleAsync.valueOrNull?.id == 'guest';
    final settings = ref.watch(ownerControlSettingsProvider);
    final pendingApprovals = ref
        .watch(ownerApprovalRequestsProvider)
        .where((request) => request.status == 'pending')
        .length;
    final branchValues = settings.section(
      OwnerSettingSections.branches,
    )['branch_records'];
    final branchCount = branchValues is List ? branchValues.length : 0;
    final auditCount = ref
        .watch(ownerControlCenterRepositoryProvider)
        .auditLog()
        .length;
    final configured = settings.sections.values
        .where((section) => section.isNotEmpty)
        .length;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ownerControlCenter)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: context.appColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.ownerControlCenter,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.ownerControlCenterIntro),
                  const SizedBox(height: 12),
                  Text(
                    isGuest
                        ? l10n.guestSettingsLocalOnly
                        : roleAsync.when(
                            data: (role) => role.isSystemAdmin
                                ? l10n.systemAdministrator
                                : role.name,
                            loading: () => l10n.loading,
                            error: (_, __) => l10n.role,
                          ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: configured / OwnerSettingSections.all.length,
                    minHeight: 6,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.configuredCount(
                      configured,
                      OwnerSettingSections.all.length,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.fact_check, size: 18),
                        label: Text(
                          '${l10n.approvalCenter}: $pendingApprovals',
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.storefront, size: 18),
                        label: Text('${l10n.branchManagement}: $branchCount'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.history, size: 18),
                        label: Text(
                          '${l10n.settingsAuditHistory}: $auditCount',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._sections(context, l10n).map(
            (section) => _OwnerSectionTile(
              section: section,
              onTap: () => _openSection(context, section),
            ),
          ),
        ],
      ),
    );
  }

  List<_OwnerSection> _sections(BuildContext context, AppLocalizations l10n) =>
      [
        _OwnerSection(
          OwnerSettingSections.company,
          l10n.companyAndBranches,
          Icons.business,
          l10n.companyProfileReportHint,
        ),
        _OwnerSection(
          OwnerSettingSections.accounting,
          l10n.accountingAndPeriods,
          Icons.account_balance,
          l10n.ownerSettingsComingNext,
        ),
        _OwnerSection(
          OwnerSettingSections.currencies,
          l10n.currenciesAndExchangeRates,
          Icons.currency_exchange,
          l10n.currencyOptions,
        ),
        _OwnerSection(
          OwnerSettingSections.taxes,
          l10n.taxSettings,
          Icons.receipt_long,
          l10n.ownerSettingsComingNext,
        ),
        _OwnerSection(
          OwnerSettingSections.documents,
          l10n.documentsAndNumbering,
          Icons.format_list_numbered,
          l10n.ownerSettingsComingNext,
        ),
        _OwnerSection(
          OwnerSettingSections.employees,
          l10n.employeesRolesInvitations,
          Icons.groups,
          l10n.viewListInviteMembers,
        ),
        _OwnerSection(
          OwnerSettingSections.approvals,
          l10n.approvalWorkflows,
          Icons.fact_check,
          l10n.ownerSettingsComingNext,
        ),
        _OwnerSection(
          OwnerSettingSections.crm,
          l10n.crmConfiguration,
          Icons.people_alt,
          l10n.crmSectionTitle,
        ),
        _OwnerSection(
          OwnerSettingSections.inventory,
          l10n.productsInventoryWarehouses,
          Icons.inventory_2,
          l10n.ownerSettingsComingNext,
        ),
        _OwnerSection(
          OwnerSettingSections.pos,
          l10n.posAndCashControl,
          Icons.point_of_sale,
          l10n.ownerSettingsComingNext,
        ),
        _OwnerSection(
          OwnerSettingSections.payments,
          l10n.paymentMethodsSettings,
          Icons.payments,
          l10n.ownerSettingsComingNext,
        ),
        _OwnerSection(
          OwnerSettingSections.notifications,
          l10n.notificationsSettings,
          Icons.notifications_active,
          l10n.ownerSettingsComingNext,
        ),
        _OwnerSection(
          OwnerSettingSections.sync,
          l10n.backupAndSyncSettings,
          Icons.sync,
          l10n.dataAndSync,
        ),
        _OwnerSection(
          OwnerSettingSections.privacy,
          l10n.privacyAndLocalAiSettings,
          Icons.privacy_tip,
          l10n.ownerSettingsComingNext,
        ),
        _OwnerSection(
          OwnerSettingSections.security,
          l10n.securityAndAuditSettings,
          Icons.security,
          l10n.securityOptions,
        ),
        _OwnerSection(
          OwnerSettingSections.localization,
          l10n.languageRegionAppearance,
          Icons.language,
          l10n.language,
        ),
        _OwnerSection(
          OwnerSettingSections.integrations,
          l10n.integrationsSettings,
          Icons.integration_instructions,
          l10n.ownerSettingsComingNext,
        ),
        _OwnerSection(
          OwnerSettingSections.expenses,
          l10n.expenseSettings,
          Icons.receipt_long,
          l10n.reimbursementApprovalRequired,
        ),
        _OwnerSection(
          OwnerSettingSections.banking,
          l10n.bankingAndReconciliation,
          Icons.account_balance,
          l10n.reconciliationRequiresOwner,
        ),
        _OwnerSection(
          OwnerSettingSections.reports,
          l10n.reportsSettings,
          Icons.bar_chart,
          l10n.reportExportRequiresOwner,
        ),
        _OwnerSection(
          OwnerSettingSections.close,
          l10n.closeManagement,
          Icons.lock_clock,
          l10n.closeRequiresBackup,
        ),
      ];

  Future<void> _openSection(BuildContext context, _OwnerSection section) async {
    final Widget? destination = switch (section.id) {
      OwnerSettingSections.company => const OwnerCompanySetupWizardScreen(),
      OwnerSettingSections.branches => const OwnerBranchSettingsScreen(),
      OwnerSettingSections.accounting => const OwnerAccountingSettingsScreen(),
      OwnerSettingSections.currencies => const OwnerAccountingSettingsScreen(),
      OwnerSettingSections.taxes => const OwnerAccountingSettingsScreen(),
      OwnerSettingSections.documents => const OwnerAccountingSettingsScreen(),
      OwnerSettingSections.employees => const OwnerEmployeeSettingsScreen(),
      OwnerSettingSections.security => const OwnerSecurityAuditScreen(),
      OwnerSettingSections.approvals => const OwnerApprovalCenterScreen(),
      OwnerSettingSections.crm => const OwnerCrmSettingsScreen(),
      OwnerSettingSections.inventory => const OwnerInventorySettingsScreen(),
      OwnerSettingSections.pos => const OwnerPosSettingsScreen(),
      OwnerSettingSections.payments => const OwnerPaymentSettingsScreen(),
      OwnerSettingSections.notifications => OwnerPolicySettingsScreen(
        section: section.id,
      ),
      OwnerSettingSections.sync => OwnerPolicySettingsScreen(
        section: section.id,
      ),
      OwnerSettingSections.privacy => OwnerPolicySettingsScreen(
        section: section.id,
      ),
      OwnerSettingSections.localization => OwnerPolicySettingsScreen(
        section: section.id,
      ),
      OwnerSettingSections.integrations => OwnerPolicySettingsScreen(
        section: section.id,
      ),
      OwnerSettingSections.expenses => OwnerFinanceOperationsSettingsScreen(
        section: section.id,
      ),
      OwnerSettingSections.banking => OwnerFinanceOperationsSettingsScreen(
        section: section.id,
      ),
      OwnerSettingSections.reports => OwnerPolicySettingsScreen(
        section: section.id,
      ),
      OwnerSettingSections.close => OwnerPolicySettingsScreen(
        section: section.id,
      ),
      _ => null,
    };

    if (!context.mounted) return;
    if (destination == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OwnerSettingsSectionScreen(section: section),
        ),
      );
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => destination));
  }
}

class OwnerSettingsSectionScreen extends ConsumerWidget {
  const OwnerSettingsSectionScreen({required this.section, super.key});

  final _OwnerSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final saved = ref.watch(ownerControlSettingsProvider).section(section.id);
    return Scaffold(
      appBar: AppBar(title: Text(section.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(section.icon, color: context.appColors.primary),
              title: Text(section.title),
              subtitle: Text(section.description),
            ),
          ),
          const SizedBox(height: 16),
          if (saved.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  saved.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
                ),
              ),
            ),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.ownerSettingsComingNext),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerSectionTile extends StatelessWidget {
  const _OwnerSectionTile({required this.section, required this.onTap});

  final _OwnerSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(section.icon, color: context.appColors.primary),
        title: Text(section.title),
        subtitle: Text(section.description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _OwnerSection {
  const _OwnerSection(this.id, this.title, this.icon, this.description);

  final String id;
  final String title;
  final IconData icon;
  final String description;
}
