// FILE: packages/core/core_data/lib/src/services/saas_seeding_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rbac_models.dart';

final saasSeedingServiceProvider = Provider<SaasSeedingService>((ref) {
  return SaasSeedingService(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

class SaasSeedingService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // 🛡️ ARCHITECT NOTE: In Phase 5, this will be dynamic (User ID or UUID).
  // For now, we use a fixed ID to ensure all your devices sync to the same place.
  static const String _tenantId = 'test_tenant_123';

  SaasSeedingService(this._firestore, this._auth);

  /// 👑 ACTIVATION PROTOCOL
  /// This runs ONCE when the buyer sets up their system.
  /// It creates the 'Owner' role and assigns the current user to it.
  Future<void> activateSystemForBuyer() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("⛔ Authentication required to activate system.");
    }

    print("🚀 [SaaS] Activating Business License for: ${user.email}");

    final batch = _firestore.batch();

    // 1. Define the ONE True Role: The Owner
    // We do NOT create Cashiers/Managers here. That is for the Admin to do later.
    final ownerRole = AppRole(
      id: 'owner',
      name: 'System Administrator', // Professional Name
      permissions: [], // isSystemAdmin = true, so explicit permissions aren't needed
      isSystemAdmin: true,
    );

    // 2. Prepare Database Paths
    final tenantRef = _firestore.collection('tenants').doc(_tenantId);
    final rolesRef = tenantRef.collection('roles');
    final membersRef = tenantRef.collection('members');

    // 3. Write the Owner Role
    batch.set(rolesRef.doc(ownerRole.id), ownerRole.toJson());


    final trialEnd = DateTime.now().add(const Duration(days: 14));

    // 4. Assign the Buyer (You) as the Owner
      batch.set(tenantRef, {
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': user.uid,
            
            // Billing Fields
            'plan': 'enterpriseMonthly', 
            'status': 'active',
            'currentPeriodEnd': Timestamp.fromDate(trialEnd),
            'isLifetimePro': false,
            'stripeCustomerId': null,
          }, SetOptions(merge: true));

    // 5. Initialize Tenant Meta-Data (Optional but Professional)
    batch.set(tenantRef, {
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': user.uid,
      'status': 'active',
      'plan': 'enterprise_v1',
    }, SetOptions(merge: true));

    await batch.commit();
    print("✅ [SaaS] System Activated. You are now the System Admin.");
  }
}