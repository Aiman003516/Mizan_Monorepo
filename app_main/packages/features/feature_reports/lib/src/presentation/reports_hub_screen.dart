// FILE: packages/features/feature_reports/lib/src/presentation/reports_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:shared_ui/shared_ui.dart';

// --- EXISTING REPORT IMPORTS ---
import 'profit_and_loss_screen.dart';
import 'balance_sheet_screen.dart';
import 'trial_balance_screen.dart';
import 'total_amounts_screen.dart';
import 'monthly_amounts_screen.dart';
import 'total_classifications_screen.dart';
import 'account_activity_screen.dart';
import 'report_marketplace_screen.dart';

class ReportsHubScreen extends ConsumerWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports & Analytics"),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront),
            tooltip: "Report Marketplace",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportMarketplaceScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECTION 1: FINANCIAL STATEMENTS
            _buildSectionHeader(context, "Financial Statements", Icons.account_balance),
            _buildGrid(context, [
              _ReportCard(
                title: l10n.profitAndLoss, // String (Correct)
                icon: Icons.show_chart,
                color: Colors.blue,
                onTap: () => _nav(context, const ProfitAndLossScreen()),
              ),
              _ReportCard(
                title: l10n.balanceSheet, // String (Correct)
                icon: Icons.account_balance_wallet,
                color: Colors.indigo,
                onTap: () => _nav(context, const BalanceSheetScreen()),
              ),
              _ReportCard(
                title: l10n.trialBalance, // String (Correct)
                icon: Icons.scale,
                color: Colors.teal,
                onTap: () => _nav(context, const TrialBalanceScreen()),
              ),
              _ReportCard(
                // ✅ FIX: Use 'accountActivity' instead of 'generalLedger' (which doesn't exist)
                title: l10n.accountActivity, 
                icon: Icons.menu_book,
                color: Colors.blueGrey,
                onTap: () => _nav(context, const AccountActivityScreen()),
              ),
            ]),

            const SizedBox(height: 24),

            // SECTION 2: PERFORMANCE & SALES
            _buildSectionHeader(context, "Performance", Icons.bar_chart),
            _buildGrid(context, [
              _ReportCard(
                // ✅ FIX: Use 'totalAmountsReport' (String) instead of 'totalAmounts' (Function)
                title: l10n.totalAmountsReport, 
                icon: Icons.pie_chart,
                color: Colors.orange,
                onTap: () => _nav(context, const TotalAmountsScreen()),
              ),
              _ReportCard(
                // ✅ FIX: Use 'monthlyAmountsReport' (String) instead of 'monthlyAmounts' (Function)
                title: l10n.monthlyAmountsReport,
                icon: Icons.calendar_month,
                color: Colors.deepOrange,
                onTap: () => _nav(context, const MonthlyAmountsScreen()),
              ),
              _ReportCard(
                // ✅ FIX: Use localized string instead of hardcoded
                title: l10n.totalClassifications, 
                icon: Icons.category,
                color: Colors.amber,
                onTap: () => _nav(context, const TotalClassificationsScreen()),
              ),
            ]),

            const SizedBox(height: 24),

            // SECTION 3: UPCOMING (The "Power 10" Placeholders)
            _buildSectionHeader(context, "Inventory & Operations (Coming Soon)", Icons.inventory_2),
            _buildGrid(context, [
              _ReportCard(
                title: "Stock Velocity",
                icon: Icons.speed,
                color: Colors.grey,
                isLocked: true,
              ),
              _ReportCard(
                title: "Low Stock Alert",
                icon: Icons.warning_amber,
                color: Colors.grey,
                isLocked: true,
              ),
              _ReportCard(
                title: "Sales by Cashier",
                icon: Icons.badge,
                color: Colors.grey,
                isLocked: true,
              ),
              _ReportCard(
                title: "Tax Liability",
                icon: Icons.receipt_long,
                color: Colors.grey,
                isLocked: true,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<Widget> children) {
    // Responsive Grid: 2 columns on mobile, 4 on desktop
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 800 ? 4 : 2;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5, // Widescreen cards
      children: children,
    );
  }

  void _nav(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLocked;

  const _ReportCard({
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLocked ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: isLocked ? Colors.grey : color, width: 4)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon, 
                size: 32, 
                color: isLocked ? Colors.grey.shade400 : color
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLocked ? Colors.grey : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isLocked) 
                    const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}