import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Local Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_dashboard/src/presentation/dashboard_card.dart';
import 'package:feature_dashboard/src/presentation/dashboard_providers.dart';

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
      final destinationPath =
          p.join(outputDirectory, 'mizan_backup_$timestamp.db');

      await sourceFile.copy(destinationPath);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.backupSuccessful),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.backupFailed),
          backgroundColor: Colors.red,
        ),
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
        title: const Text("Main"),
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
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   Icon(Icons.account_balance_wallet, color: Colors.white, size: 48),
                   SizedBox(height: 16),
                   Text(
                     "Mizan Enterprise",
                     style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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

      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- TRANSACTION ACTIONS ---
          
          PermissionGuard(
            permission: AppPermission.performSale,
            child: DashboardCard(
              title: l10n.newSale,
              icon: Icons.point_of_sale,
              color: Colors.green,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const PosScreen()),
                );
              },
            ),
          ),

          PermissionGuard(
            permission: AppPermission.manageProducts,
            child: DashboardCard(
              title: l10n.newPurchase,
              icon: Icons.shopping_cart,
              color: Colors.orange,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const PurchaseScreen()),
                );
              },
            ),
          ),

          PermissionGuard(
            permission: AppPermission.voidTransaction,
            child: DashboardCard(
              title: l10n.addNewTransaction,
              icon: Icons.post_add,
              color: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (ctx) => const GeneralJournalScreen()),
                );
              },
            ),
          ),
          
          // --- MANAGEMENT ACTIONS ---
          
          PermissionGuard(
            permission: AppPermission.manageProducts,
            child: DashboardCard(
              title: l10n.products, 
              icon: Icons.inventory,
              color: Colors.amber.shade700,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const ProductsHubScreen()),
                );
              },
            ),
          ),

          PermissionGuard(
            permission: AppPermission.viewSalesHistory,
            child: DashboardCard(
              title: l10n.orderHistory,
              icon: Icons.history,
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const OrderHistoryScreen()),
                );
              },
            ),
          ),

          PermissionGuard(
            permission: AppPermission.viewFinancialReports,
            child: DashboardCard(
              title: l10n.reports,
              icon: Icons.bar_chart,
              color: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const AnalyticsDashboardScreen()),
                );
              },
            ),
          ),

          PermissionGuard(
            permission: AppPermission.viewFinancialReports,
            child: DashboardCard(
              title: "Accounting", 
              icon: Icons.tune,
              color: Colors.blueGrey,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const AdjustingEntriesScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          
          // --- FINANCIAL SUMMARY ---
          Text(l10n.quickActions, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          PermissionGuard(
            permission: AppPermission.viewFinancialReports,
            fallback: const SizedBox.shrink(),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context: context,
                        title: l10n.totalRevenue,
                        asyncValue: totalRevenue,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        context: context,
                        title: l10n.totalExpenses,
                        asyncValue: totalExpenses,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context: context,
                        title: l10n.totalReceivable,
                        asyncValue: totalReceivable,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        context: context,
                        title: l10n.totalPayable,
                        asyncValue: totalPayable,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            asyncValue.when(
              data: (value) => Text(
                l10n.currencyFormat(value),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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