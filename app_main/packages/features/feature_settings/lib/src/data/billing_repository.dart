import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart'; // For TenantSubscription, Billing Models
import 'package:firebase_auth/firebase_auth.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

class BillingRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  // 🛡️ Phase 4 Hardcoded Tenant (To be dynamic later)
  static const String _tenantId = 'test_tenant_123';

  BillingRepository(this._firestore, this._auth);

  /// 💳 MOCK PURCHASE
  /// Simulates a successful payment and instantly upgrades the tenant.
  Future<void> mockPurchaseSubscription(SubscriptionPlan plan) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Must be logged in to purchase.");

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

    // Update Firestore
    final tenantRef = _firestore.collection('tenants').doc(_tenantId);

    final Map<String, dynamic> updateData = {
      'plan': plan.name,
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (expiryDate != null) {
      updateData['currentPeriodEnd'] = Timestamp.fromDate(expiryDate);
    }
    
    if (plan == SubscriptionPlan.free) {
      // Downgrade logic
      updateData['currentPeriodEnd'] = null;
    }

    // Special handling for Lifetime
    // We usually set a flag that never expires
    if (plan.name.contains('lifetime')) { // Check your enum naming convention or pass explicit flag
       updateData['isLifetimePro'] = true;
    }

    await tenantRef.set(updateData, SetOptions(merge: true));
    
    print("✅ [Billing] Payment Successful. Tenant Upgraded.");
  }
  
  /// 🕵️‍♂️ Watch Subscription Status
  Stream<TenantSubscription> watchSubscription() {
    return _firestore.collection('tenants').doc(_tenantId).snapshots().map((doc) {
      if (!doc.exists) return const TenantSubscription(tenantId: _tenantId);
      return TenantSubscription.fromJson(doc.data()!, doc.id);
    });
  }
}