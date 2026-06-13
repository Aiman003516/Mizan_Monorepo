import 'dart:io';
import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart'; // AppColors extension
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // 🟢 NEW

// Local Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_dashboard/src/presentation/dashboard_card.dart';
import 'package:feature_dashboard/src/presentation/dashboard_providers.dart';
import 'package:feature_dashboard/src/presentation/widgets/cash_flow_chart.dart'; // 🟢 NEW

// 🛡️ Imports for Security
import 'package:shared_ui/shared_ui.dart'; // For PermissionGuard
import 'package:core_data/core_data.dart'; // For AppPermission

// Feature Imports
import 'package:feature_transactions/feature_transactions.dart';
import 'package:feature_products/feature_products.dart';
import 'package:feature_reports/feature_reports.dart';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden');
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _backupDatabase(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final didConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupAndRestore),
        content: Text(l10n.createLocalBackupPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.backup),
          ),
        ],
      ),
    );

    if (didConfirm != true) return;

    String? outputDirectory = await FilePicker.platform.getDirectoryPath();

    if (outputDirectory == null) return;

    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final sourceFile = File(p.join(dbFolder.path, 'mizan.db'));

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final destinationPath = p.join(
        outputDirectory,
        'mizan_backup_$timestamp.db',
      );

      await sourceFile.copy(destinationPath);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.backupSuccessful),
          backgroundColor: context.appColors.success,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.backupFailed), backgroundColor: context.appColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final totalRevenue = ref.watch(totalRevenueProvider);
    final totalExpenses = ref.watch(totalExpensesProvider);
    final totalReceivable = ref.watch(totalReceivableProvider);
    final totalPayable = ref.watch(totalPayableProvider);

    return Scaffold(
      appBar: AppBar(
        // ⚡ CHANGED: Title is now explicitly "Main"
        title: Text(l10n.mainDashboard),
        actions: [
          IconButton(
            tooltip: l10n.backupAndRestore,
            icon: const Icon(Icons.sync),
            onPressed: () => _backupDatabase(context, ref),
          ),
        ],
      ),

      // ⚡ ADDED: Drawer Menu
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: context.appColors.onPrimary,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Mizan Enterprise",
                    style: TextStyle(
                      color: context.appColors.onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: Text(l10n.dashboard), // "Dashboard"
              onTap: () {
                // Close drawer (Already on dashboard)
                Navigator.pop(context);
              },
            ),
            // Add more drawer items here (e.g., Settings, Profile) as needed
          ],
        ),
      ),

      // 🚀 NEW: Quick Action FAB
      floatingActionButton: SpeedDial(
        icon: Icons.flash_on,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: context.appColors.onPrimary,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        spacing: 12,
        spaceBetweenChildren: 8,
        tooltip: 'Quick Actions',
        children: [
          SpeedDialChild(
            child: const Icon(Icons.point_of_sale),
            backgroundColor: context.appColors.success,
            foregroundColor: context.appColors.onPrimary,
            label: l10n.newSale,
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (ctx) => const PosScreen()));
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.shopping_cart),
            backgroundColor: context.appColors.warning,
            foregroundColor: context.appColors.onPrimary,
            label: l10n.newPurchase,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const PurchaseScreen()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.receipt),
            backgroundColor: context.appColors.info,
            foregroundColor: context.appColors.onPrimary,
            label: l10n.addNewTransaction,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const GeneralJournalScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- FINANCIAL SUMMARY (VISUAL CHART) ---
          Text(
            l10n.financialSnapshot,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          PermissionGuard(
            permission: AppPermission.viewFinancialReports,
            fallback: const SizedBox.shrink(),
            child: SizedBox(
              height: 250, // Fixed height for chart area
              child: Row(
                children: [
                  // 📊 Chart on the Left (Flex 2)
                  Expanded(
                    flex: 2,
                    child: totalRevenue.when(
                      data: (rev) => totalExpenses.when(
                        data: (exp) =>
                            CashFlowChart(revenue: rev, expenses: exp),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 💰 Summaries on the Right (Flex 1)
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            context: context,
                            title: l10n.totalReceivable, // "Money In"
                            asyncValue: totalReceivable,
                            color: context.appColors.info,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            context: context,
                            title: l10n.totalPayable, // "Money Out"
                            asyncValue: totalPayable,
                            color: context.appColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // --- TRANSACTION ACTIONS ---
          Text(
            l10n.quickAccess,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, // 2 columns for better mobile view
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              PermissionGuard(
                permission: AppPermission.performSale,
                child: DashboardCard(
                  title: l10n.newSale,
                  icon: Icons.point_of_sale,
                  color: context.appColors.success,
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const PosScreen())),
                ),
              ),
              PermissionGuard(
                permission: AppPermission.manageProducts,
                child: DashboardCard(
                  title: l10n.products,
                  icon: Icons.inventory,
                  color: context.appColors.warning,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProductsHubScreen(),
                    ),
                  ),
                ),
              ),
              PermissionGuard(
                permission: AppPermission.viewSalesHistory,
                child: DashboardCard(
                  title: l10n.orderHistory,
                  icon: Icons.history,
                  color: context.appColors.secondary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OrderHistoryScreen(),
                    ),
                  ),
                ),
              ),
              PermissionGuard(
                permission: AppPermission.viewFinancialReports,
                child: DashboardCard(
                  title: l10n.reports,
                  icon: Icons.bar_chart,
                  color: context.appColors.accent,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AnalyticsDashboardScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String title,
    required AsyncValue<double> asyncValue,
    required Color color,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            asyncValue.when(
              data: (value) => Text(
                l10n.currencyFormat(value),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text(
                l10n.error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
