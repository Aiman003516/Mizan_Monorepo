import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core_data/core_data.dart'; // For Subscription Models
import '../../data/billing_repository.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch live subscription status
    final subAsync = ref.watch(StreamProvider.autoDispose((ref) {
      return ref.watch(billingRepositoryProvider).watchSubscription();
    }));

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Subscription")),
      body: subAsync.when(
        data: (subscription) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _CurrentPlanCard(subscription: subscription),
                const SizedBox(height: 24),
                const Text(
                  "Available Plans (MOCK MODE)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // 1. ENTERPRISE PLAN
                _PlanCard(
                  title: "Enterprise (Monthly)",
                  // ⚡ FIX: Escaped the $ sign
                  price: "\$30 / month",
                  features: const ["Cloud Sync", "Multi-User", "Web Access"],
                  color: Colors.blue,
                  isCurrent: subscription.plan == SubscriptionPlan.enterpriseMonthly,
                  onTap: () => _confirmPurchase(context, ref, SubscriptionPlan.enterpriseMonthly),
                ),

                // 2. LIFETIME PRO (Simulated as a plan for now, usually separate)
                // Note: You might need to add 'lifetime' to your SubscriptionPlan enum 
                // or handle isLifetimePro separately. For this mock, we assume logic handles it.
                
                // 3. FREE PLAN (Downgrade)
                _PlanCard(
                  title: "Free Tier",
                  // ⚡ FIX: Escaped the $ sign
                  price: "\$0 / forever",
                  features: const ["Local Only", "Manual Backup"],
                  color: Colors.grey,
                  isCurrent: subscription.plan == SubscriptionPlan.free,
                  onTap: () => _confirmPurchase(context, ref, SubscriptionPlan.free),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  void _confirmPurchase(BuildContext context, WidgetRef ref, SubscriptionPlan plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Confirm Mock Purchase"),
        content: Text("Simulate payment for ${plan.name}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              try {
                await ref.read(billingRepositoryProvider).mockPurchaseSubscription(plan);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Mock Payment Successful!")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Pay Now (Mock)"),
          ),
        ],
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  final TenantSubscription subscription;
  const _CurrentPlanCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final expiry = subscription.currentPeriodEnd != null 
        ? dateFormat.format(subscription.currentPeriodEnd!) 
        : "Never";

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("CURRENT PLAN", style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              subscription.plan.name.toUpperCase(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Status: ${subscription.status.name}"),
            Text("Renews: $expiry"),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;
  final Color color;
  final bool isCurrent;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.features,
    required this.color,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isCurrent ? 0 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: isCurrent ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                    Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    ...features.map((f) => Text("• $f", style: TextStyle(color: Colors.grey[700]))),
                  ],
                ),
              ),
              if (isCurrent)
                const Icon(Icons.check_circle, color: Colors.green, size: 32)
              else
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                  child: const Text("Buy"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}