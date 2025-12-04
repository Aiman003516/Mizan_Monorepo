// FILE: packages/core/core_data/lib/src/models/billing_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionPlan {
  free,
  enterpriseMonthly, // $30/mo
  enterpriseAnnual,  // $300/yr
}

enum SubscriptionStatus {
  active,
  pastDue, // Payment failed, grace period
  canceled,
  expired,
  lifetime, // Special status for one-time buyers
}

/// 💳 THE SUBSCRIPTION DATA
/// Represents the financial health of a Tenant.
class TenantSubscription {
  final String tenantId;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime? currentPeriodEnd;
  final bool isLifetimePro; // The $500 Unlock
  final String? stripeCustomerId;

  const TenantSubscription({
    required this.tenantId,
    this.plan = SubscriptionPlan.free,
    this.status = SubscriptionStatus.active, // Default active for free
    this.currentPeriodEnd,
    this.isLifetimePro = false,
    this.stripeCustomerId,
  });

  /// Factory: Create from Firestore
  factory TenantSubscription.fromJson(Map<String, dynamic> json, String id) {
    return TenantSubscription(
      tenantId: id,
      plan: _parsePlan(json['plan']),
      status: _parseStatus(json['status']),
      currentPeriodEnd: (json['currentPeriodEnd'] as Timestamp?)?.toDate(),
      isLifetimePro: json['isLifetimePro'] as bool? ?? false,
      stripeCustomerId: json['stripeCustomerId'] as String?,
    );
  }

  /// Convert to Firestore (For updates)
  Map<String, dynamic> toJson() {
    return {
      'plan': plan.name,
      'status': status.name,
      'currentPeriodEnd': currentPeriodEnd != null 
          ? Timestamp.fromDate(currentPeriodEnd!) 
          : null,
      'isLifetimePro': isLifetimePro,
      'stripeCustomerId': stripeCustomerId,
    };
  }

  // --- Helpers ---
  
  bool get hasCloudAccess {
    // Lifetime users get features, but Cloud Sync usually requires recurring server costs.
    // Adjust this logic based on your strict business rules.
    // Assuming Enterprise Subscription is required for Cloud Sync:
    return status == SubscriptionStatus.active || status == SubscriptionStatus.pastDue;
  }

  static SubscriptionPlan _parsePlan(String? val) {
    try {
      return SubscriptionPlan.values.byName(val ?? 'free');
    } catch (_) {
      return SubscriptionPlan.free;
    }
  }

  static SubscriptionStatus _parseStatus(String? val) {
    try {
      return SubscriptionStatus.values.byName(val ?? 'active');
    } catch (_) {
      return SubscriptionStatus.expired;
    }
  }
}