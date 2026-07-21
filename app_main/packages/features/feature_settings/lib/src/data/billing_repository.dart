import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart'; // For TenantSubscription, Billing Models

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(Supabase.instance.client);
});

class BillingRepository {
  final SupabaseClient _supabase;

  BillingRepository(this._supabase);

  Future<String> _getTenantId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final res = await _supabase
        .from('user_profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .maybeSingle();
    if (res == null || res['tenant_id'] == null)
      throw Exception('Tenant ID not found');
    return res['tenant_id'] as String;
  }

  /// 💳 MOCK PURCHASE
  /// Simulates a successful payment and instantly upgrades the tenant.
  Future<void> mockPurchaseSubscription(SubscriptionPlan plan) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Must be logged in to purchase.");

    final tenantId = await _getTenantId();

    print("💸 [Billing] Processing Mock Payment for ${plan.name}...");

    // Simulate Network Delay
    await Future.delayed(const Duration(seconds: 2));

    // Calculate Expiry (Monthly = 30 days, Annual = 365 days)
    final now = DateTime.now();
    DateTime? expiryDate;

    if (plan == SubscriptionPlan.enterpriseMonthly) {
      expiryDate = now.add(const Duration(days: 30));
    } else if (plan == SubscriptionPlan.enterpriseAnnual) {
      expiryDate = now.add(const Duration(days: 365));
    }
    // Lifetime has no expiry

    final Map<String, dynamic> updateData = {
      'plan': plan.name,
      'status': 'active',
    };

    if (expiryDate != null) {
      updateData['currentPeriodEnd'] = expiryDate.toIso8601String();
    }

    if (plan == SubscriptionPlan.free) {
      // Downgrade logic
      updateData['currentPeriodEnd'] = null;
    }

    // Special handling for Lifetime
    if (plan.name.contains('lifetime')) {
      updateData['isLifetimePro'] = true;
    }

    await _supabase.from('tenants').update(updateData).eq('id', tenantId);

    print("✅ [Billing] Payment Successful. Tenant Upgraded.");
  }

  /// 🕵️‍♂️ Watch Subscription Status
  /// Returns a free offline subscription immediately when not logged in,
  /// so the UI never gets stuck on an infinite loading spinner.
  Stream<TenantSubscription> watchSubscription() async* {
    final user = _supabase.auth.currentUser;

    // Not logged in → return a default free subscription and exit
    if (user == null) {
      yield TenantSubscription(tenantId: 'offline');
      return;
    }

    // Logged in → fetch tenant ID and stream live data
    try {
      final tenantId = await _getTenantId();
      yield* _supabase
          .from('tenants')
          .stream(primaryKey: ['id'])
          .eq('id', tenantId)
          .map((docs) {
            if (docs.isEmpty) return TenantSubscription(tenantId: tenantId);
            final doc = docs.first;
            return TenantSubscription.fromJson({
              'plan': doc['plan'],
              'status': doc['status'],
              'currentPeriodEnd':
                  doc['currentPeriodEnd'] ?? doc['current_period_end'],
              'isLifetimePro':
                  doc['isLifetimePro'] ?? doc['is_lifetime_pro'] ?? false,
            }, doc['id']);
          });
    } catch (e) {
      // On any error (e.g. Tenant ID not found), yield a default free subscription
      yield TenantSubscription(tenantId: user.id);
    }
  }
}
