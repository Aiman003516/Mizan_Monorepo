// FILE: packages/features/feature_reports/lib/src/presentation/report_marketplace_screen.dart

import 'package:core_data/core_data.dart';
import 'package:feature_auth/feature_auth.dart'; // To get Current User
import 'package:feature_reports/src/data/report_models.dart';
import 'package:feature_reports/src/data/report_templates_repository.dart';
import 'package:feature_reports/src/presentation/dynamic_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

class ReportMarketplaceScreen extends ConsumerStatefulWidget {
  const ReportMarketplaceScreen({super.key});

  @override
  ConsumerState<ReportMarketplaceScreen> createState() => _ReportMarketplaceScreenState();
}

class _ReportMarketplaceScreenState extends ConsumerState<ReportMarketplaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Hub'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Reports', icon: Icon(Icons.folder)),
            Tab(text: 'Marketplace', icon: Icon(Icons.cloud_download)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _InstalledReportsTab(),
          _MarketplaceTab(),
        ],
      ),
    );
  }
}

class _InstalledReportsTab extends ConsumerWidget {
  const _InstalledReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(reportTemplatesRepositoryProvider).watchInstalledReports();

    return StreamBuilder<List<ReportTemplate>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          // ✅ This will now work because EmptyStateWidget accepts 'title'
          return const EmptyStateWidget(
            icon: Icons.folder_open,
            title: "No Installed Reports",
            message: "Go to the Marketplace to download standard reports.",
          );
        }

        return ListView.separated(
          itemCount: reports.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (ctx, index) {
            final report = reports[index];
            return ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: Text(report.title),
              subtitle: Text(report.description),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => ref.read(reportTemplatesRepositoryProvider).deleteReport(report.id),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DynamicReportScreen(template: report)),
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
      BuildContext context, WidgetRef ref, ReportTemplate report, AppUser? user) async {
    
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🔒 Premium Report. Upgrade to Pro or Enterprise.")),
      );
      return;
    }

    if (requiresPayment) {
      // MOCK PAYMENT FLOW (Phase 6 Placeholder)
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Purchase Report"),
          content: Text("Buy '${report.title}' for \$4.99?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Buy Now")),
          ],
        ),
      );

      if (confirmed != true) return;
      
      // Simulate Processing
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing Payment...")));
      }
      await Future.delayed(const Duration(seconds: 2));
    }

    // 3. Install
    await ref.read(reportTemplatesRepositoryProvider).installReport(report);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Installed ${report.title}")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(reportTemplatesRepositoryProvider).watchStandardReports();
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
          return const EmptyStateWidget(
            icon: Icons.cloud_off,
            title: "Marketplace Unavailable",
            message: "No standard reports found online.",
          );
        }

        return ListView.separated(
          itemCount: reports.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (ctx, index) {
            final report = reports[index];
            final user = userAsync.value;

            // Determine Button Style
            String label = "Install";
            IconData icon = Icons.download;
            Color color = Colors.blue;

            if (report.isPremium) {
              if (user?.hasCloudAccess == true) {
                label = "Included";
                icon = Icons.check_circle;
                color = Colors.green;
              } else if (user?.isPro == true) {
                label = "Buy \$4.99";
                icon = Icons.shopping_cart;
                color = Colors.amber.shade800;
              } else {
                label = "Locked";
                icon = Icons.lock;
                color = Colors.grey;
              }
            }

            return ListTile(
              leading: Icon(Icons.analytics, color: color),
              title: Text(report.title),
              subtitle: Text(report.description),
              trailing: ElevatedButton.icon(
                onPressed: () => _handleInstall(context, ref, report, user),
                icon: Icon(icon, size: 16),
                label: Text(label),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.withOpacity(0.1),
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