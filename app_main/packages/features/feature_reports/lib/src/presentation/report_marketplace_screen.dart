// FILE: packages/features/feature_reports/lib/src/presentation/report_marketplace_screen.dart

import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_auth/feature_auth.dart'; // To get Current User
import 'package:feature_reports/src/data/report_models.dart';
import 'package:feature_reports/src/data/report_templates_repository.dart';
import 'package:feature_reports/src/presentation/dynamic_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

class ReportMarketplaceScreen extends ConsumerStatefulWidget {
  const ReportMarketplaceScreen({super.key});

  @override
  ConsumerState<ReportMarketplaceScreen> createState() =>
      _ReportMarketplaceScreenState();
}

class _ReportMarketplaceScreenState
    extends ConsumerState<ReportMarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportHubTitle),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: l10n.myReportsTab, icon: const Icon(Icons.folder)),
            Tab(
              text: l10n.marketplaceTab,
              icon: const Icon(Icons.cloud_download),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_InstalledReportsTab(), _MarketplaceTab()],
      ),
    );
  }
}

class _InstalledReportsTab extends ConsumerWidget {
  const _InstalledReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final stream = ref
        .watch(reportTemplatesRepositoryProvider)
        .watchInstalledReports();

    return StreamBuilder<List<ReportTemplate>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          // ✅ This will now work because EmptyStateWidget accepts 'title'
          return EmptyStateWidget(
            icon: Icons.folder_open,
            title: l10n.noInstalledReports,
            message: l10n.goToMarketplaceHint,
          );
        }

        return ListView.separated(
          itemCount: reports.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (ctx, index) {
            final report = reports[index];
            return ListTile(
              leading: Icon(Icons.description, color: context.appColors.info),
              title: Text(report.title),
              subtitle: Text(report.description),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: context.appColors.error,
                ),
                onPressed: () => ref
                    .read(reportTemplatesRepositoryProvider)
                    .deleteReport(report.id),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DynamicReportScreen(template: report),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MarketplaceTab extends ConsumerWidget {
  const _MarketplaceTab();

  Future<void> _handleInstall(
    BuildContext context,
    WidgetRef ref,
    ReportTemplate report,
    AppUser? user,
    AppLocalizations l10n,
  ) async {
    // 1. Check Logic: "Who Gets What"
    bool canInstall = false;
    bool requiresPayment = false;

    if (!report.isPremium) {
      // FREE TIER: Everyone can install simple reports
      canInstall = true;
    } else {
      // PREMIUM TIER
      if (user?.hasCloudAccess == true) {
        // ENTERPRISE: Included!
        canInstall = true;
      } else if (user?.isPro == true) {
        // PRO: Must Buy
        canInstall = true;
        requiresPayment = true;
      } else {
        // FREE USER: Locked
        canInstall = false;
      }
    }

    // 2. Execution
    if (!canInstall) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.premiumReportWarning),
          ),
        );
      }
      return;
    }

    if (requiresPayment) {
      // MOCK PAYMENT FLOW (Phase 6 Placeholder)
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.purchaseReportTitle),
          content: Text(l10n.buyReportPrompt(report.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.buyNowAction),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Simulate Processing
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.processingPayment)));
      }
      await Future.delayed(const Duration(seconds: 2));
    }

    if (!context.mounted) return;

    // 3. Install
    await ref.read(reportTemplatesRepositoryProvider).installReport(report);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.installedSuccessfully(report.title))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final stream = ref
        .watch(reportTemplatesRepositoryProvider)
        .watchStandardReports();
    final userAsync = ref.watch(currentUserStreamProvider);

    return StreamBuilder<List<ReportTemplate>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          // ✅ This will now work
          return EmptyStateWidget(
            icon: Icons.cloud_off,
            title: l10n.marketplaceUnavailable,
            message: l10n.noStandardReportsFound,
          );
        }

        return ListView.separated(
          itemCount: reports.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (ctx, index) {
            final report = reports[index];
            final user = userAsync.value;

            // Determine Button Style
            String label = l10n.installAction;
            IconData icon = Icons.download;
            Color color = context.appColors.info;

            if (report.isPremium) {
              if (user?.hasCloudAccess == true) {
                label = l10n.includedAction;
                icon = Icons.check_circle;
                color = context.appColors.success;
              } else if (user?.isPro == true) {
                label = l10n.buyPriceAction;
                icon = Icons.shopping_cart;
                color = context.appColors.primary;
              } else {
                label = l10n.lockedAction;
                icon = Icons.lock;
                color = context.appColors.subtleText;
              }
            }

            return ListTile(
              leading: Icon(Icons.analytics, color: color),
              title: Text(report.title),
              subtitle: Text(report.description),
              trailing: ElevatedButton.icon(
                onPressed: () => _handleInstall(context, ref, report, user, l10n),
                icon: Icon(icon, size: 16),
                label: Text(label),
                style: ElevatedButton.styleFrom(
                  // ignore: deprecated_member_use
                  backgroundColor: color.withValues(alpha: 0.1),
                  foregroundColor: color,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
