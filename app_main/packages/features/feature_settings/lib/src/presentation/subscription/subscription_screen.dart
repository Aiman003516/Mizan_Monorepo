import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_l10n/app_localizations.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core_data/core_data.dart'; // For Subscription Models
import '../../data/billing_repository.dart';

// ✅ TOP-LEVEL provider — never recreated on rebuild.
// Creating StreamProvider inside build() is invalid Riverpod usage and
// causes an infinite loading loop because each rebuild creates a new provider.
final _subscriptionStreamProvider =
    StreamProvider.autoDispose<TenantSubscription>((ref) {
      return ref.watch(billingRepositoryProvider).watchSubscription();
    });

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final subAsync = ref.watch(_subscriptionStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageSubscription)),
      body: subAsync.when(
        data: (subscription) {
          // Show offline notice if user is not logged in
          final isOffline = subscription.tenantId == 'offline';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (isOffline)
                  Card(
                    color: context.appColors.warning.withValues(alpha: 0.15),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: context.appColors.warning,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.subscriptionUnavailable,
                              style: TextStyle(
                                color: context.appColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isOffline) const SizedBox(height: 16),
                _CurrentPlanCard(subscription: subscription),
                const SizedBox(height: 24),
                Text(
                  l10n.availablePlans,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // 1. ENTERPRISE PLAN
                _PlanCard(
                  title: l10n.enterpriseMonthlyPlan,
                  price: l10n.enterpriseMonthlyPrice,
                  features: [
                    l10n.featureCloudSync,
                    l10n.featureMultiUser,
                    l10n.featureWebAccess,
                  ],
                  color: context.appColors.info,
                  isCurrent:
                      subscription.plan == SubscriptionPlan.enterpriseMonthly,
                  isDisabled: isOffline,
                  onTap: () => _confirmPurchase(
                    context,
                    ref,
                    SubscriptionPlan.enterpriseMonthly,
                    l10n,
                  ),
                ),

                // 2. FREE PLAN (Downgrade)
                _PlanCard(
                  title: l10n.freeTierPlan,
                  price: l10n.freeTierPrice,
                  features: [l10n.featureLocalOnly, l10n.featureManualBackup],
                  color: context.appColors.subtleText,
                  isCurrent: subscription.plan == SubscriptionPlan.free,
                  isDisabled: isOffline,
                  onTap: () => _confirmPurchase(
                    context,
                    ref,
                    SubscriptionPlan.free,
                    l10n,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 48,
                    color: context.appColors.subtleText,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.subscriptionUnavailable,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.appColors.subtleText),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmPurchase(
    BuildContext context,
    WidgetRef ref,
    SubscriptionPlan plan,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmMockPurchase),
        content: Text(l10n.simulatePaymentFor(plan.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(billingRepositoryProvider)
                    .mockPurchaseSubscription(plan);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.mockPaymentSuccess)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  final errorStr = e.toString().toLowerCase();
                  final msg =
                      (errorStr.contains('not logged in') ||
                          errorStr.contains('tenant id'))
                      ? l10n.paidFeatureMessage
                      : e.toString();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: context.appColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.payNowMock),
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
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final expiry = subscription.currentPeriodEnd != null
        ? dateFormat.format(subscription.currentPeriodEnd!)
        : l10n.planNeverExpires;

    return Card(
      color: context.appColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              l10n.currentPlanLabel,
              style: TextStyle(
                fontSize: 12,
                color: context.appColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subscription.plan.name.toUpperCase(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(l10n.planStatusLabel(subscription.status.name)),
            Text(l10n.planRenewsLabel(expiry)),
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
  final bool isDisabled;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.features,
    required this.color,
    required this.isCurrent,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final effectiveColor = isDisabled ? context.appColors.subtleText : color;

    return Card(
      elevation: isCurrent ? 0 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent
            ? BorderSide(color: effectiveColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: (isCurrent || isDisabled) ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: effectiveColor,
                      ),
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...features.map(
                      (f) => Text(
                        "• $f",
                        style: TextStyle(color: context.appColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Icon(
                  Icons.check_circle,
                  color: context.appColors.success,
                  size: 32,
                )
              else
                ElevatedButton(
                  onPressed: isDisabled ? null : onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: effectiveColor,
                    foregroundColor: context.appColors.onPrimary,
                  ),
                  child: Text(l10n.buyButton),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
