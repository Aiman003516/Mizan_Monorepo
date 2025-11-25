import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// UPDATED Local Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_dashboard/src/presentation/dashboard_card.dart';
import 'package:feature_dashboard/src/presentation/dashboard_providers.dart';

// Feature Imports (For Navigation)
import 'package:feature_transactions/feature_transactions.dart';
import 'package:feature_products/feature_products.dart'; // ⭐️ Added for Products Hub
import 'package:feature_reports/feature_reports.dart';   // ⭐️ Added for Reports

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// This provider must be overridden in app_mizan
// (Kept from your code to ensure backup logic works as currently wired)
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

    if (outputDirectory == null) {
      return;
    }

    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final sourceFile = File(p.join(dbFolder.path, 'mizan.db'));

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final destinationPath =
          p.join(outputDirectory, 'mizan_backup_$timestamp.db');

      // Close DB before copy to ensure data integrity
      await ref.read(databaseProvider).close();
      await sourceFile.copy(destinationPath);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.backupSuccessful(destinationPath)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.backupFailed(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
    // Note: The AppDatabase (via LazyDatabase) will automatically re-open on the next query.
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
        title: Text(l10n.dashboard),
        actions: [
          IconButton(
            tooltip: l10n.backupAndRestore,
            icon: const Icon(Icons.sync),
            onPressed: () => _backupDatabase(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- TRANSACTION ACTIONS ---
          DashboardCard(
            title: l10n.newSale,
            icon: Icons.point_of_sale,
            color: Colors.green,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const PosScreen()),
              );
            },
          ),
          DashboardCard(
            title: l10n.newPurchase,
            icon: Icons.shopping_cart,
            color: Colors.orange,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const PurchaseScreen()),
              );
            },
          ),
          DashboardCard(
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
          
          // --- MANAGEMENT ACTIONS ---
          DashboardCard(
            title: l10n.products, // Ensure this exists in l10n or use "Products"
            icon: Icons.inventory,
            color: Colors.amber.shade700,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const ProductsHubScreen()),
              );
            },
          ),
          DashboardCard(
            title: l10n.orderHistory,
            icon: Icons.history,
            color: Colors.purple,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const OrderHistoryScreen()),
              );
            },
          ),
          DashboardCard(
            title: l10n.reports, // Ensure this exists in l10n or use "Reports"
            icon: Icons.bar_chart,
            color: Colors.teal,
            onTap: () {
              Navigator.of(context).push(
                // Navigating to Trial Balance as the main report for now
                MaterialPageRoute(builder: (ctx) => const TrialBalanceScreen()),
              );
            },
          ),

          // ⭐️ NEW: ACCOUNTING / ADJUSTMENTS BUTTON ⭐️
          DashboardCard(
            title: "Accounting", // TODO: Add to l10n
            icon: Icons.tune,
            color: Colors.blueGrey,
            onTap: () {
              Navigator.of(context).push(
                // Leads to the "Airlock" screen we just built
                MaterialPageRoute(builder: (ctx) => const AdjustingEntriesScreen()),
              );
            },
          ),

          const SizedBox(height: 24),
          
          // --- FINANCIAL SUMMARY ---
          Text(l10n.quickActions, style: Theme.of(context).textTheme.titleMedium), // Using "Quick Actions" label as section header
          const SizedBox(height: 8),

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