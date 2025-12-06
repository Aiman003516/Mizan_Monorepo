// FILE: packages/core/core_data/lib/src/models/rbac_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 🛡️ THE APP USER (Enriched Identity)
/// Combines Firebase Auth (Email/UID) with Firestore Data (Tenant/Role).
class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? tenantId; // 👈 CRITICAL: Links user to a specific shop
  final String role;      // e.g., 'owner', 'manager', 'staff'
  final bool isPro;       // Lifetime License Flag

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.tenantId,
    this.role = 'staff',
    this.isPro = false,
  });

  /// ⚡ Computed Property: Is this user the Boss?
  bool get isOwner => role == 'owner';

  /// ⚡ Computed Property: Can they use Cloud features?
  bool get hasCloudAccess => tenantId != null;

  factory AppUser.fromFirestore(DocumentSnapshot doc, {required String uid, required String email}) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      uid: uid,
      email: email,
      displayName: data['displayName'] as String?,
      tenantId: data['tenantId'] as String?,
      role: data['role'] as String? ?? 'staff',
      isPro: data['isPro'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'tenantId': tenantId,
      'role': role,
      'isPro': isPro,
      'lastLogin': FieldValue.serverTimestamp(),
    };
  }
}

/// 🛡️ THE PERMISSION REGISTRY
/// This Enum defines every distinct action a user can perform in Mizan.
enum AppPermission {
  // --- Dashboard & Analytics ---
  viewDashboard,
  viewFinancialReports,
  
  // --- Sales & POS ---
  performSale,
  voidTransaction, // Delete/Cancel a sale
  processRefund,
  viewSalesHistory,
  
  // --- Inventory ---
  viewInventory,
  manageProducts, // Add/Edit/Delete Products
  adjustInventory, // Stock take / corrections
  
  // --- CRM & Admin ---
  manageStaff, // Invite users, change roles
  manageSettings, // Change currency, tax, company info
  switchTenant, // For multi-branch users (Future proofing)
}

/// 🔑 THE ROLE CONTAINER
class AppRole {
  final String id;
  final String name;
  final List<AppPermission> permissions;
  final bool isSystemAdmin; 

  const AppRole({
    required this.id,
    required this.name,
    required this.permissions,
    this.isSystemAdmin = false,
  });

  factory AppRole.owner() {
    return const AppRole(
      id: 'owner',
      name: 'Owner',
      permissions: [],
      isSystemAdmin: true,
    );
  }

  factory AppRole.fromJson(Map<String, dynamic> json, String id) {
    final permsData = json['permissions'] as List<dynamic>? ?? [];
    
    final permissions = permsData.map((p) {
      try {
        return AppPermission.values.byName(p as String);
      } catch (e) {
        return null; 
      }
    }).whereType<AppPermission>().toList();

    return AppRole(
      id: id,
      name: json['name'] as String? ?? 'Unknown Role',
      permissions: permissions,
      isSystemAdmin: json['isSystemAdmin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'permissions': permissions.map((e) => e.name).toList(),
      'isSystemAdmin': isSystemAdmin,
    };
  }

  bool hasPermission(AppPermission permission) {
    if (isSystemAdmin) return true;
    return permissions.contains(permission);
  }
}

/// 👤 THE STAFF MEMBER
class StaffMember {
  final String uid;
  final String email;
  final String displayName;
  final String roleId;
  final bool isOwner;
  final String status; 
  final DateTime? joinedAt;

  const StaffMember({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.roleId,
    this.isOwner = false,
    this.status = 'active',
    this.joinedAt,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Unknown',
      roleId: json['roleId'] as String? ?? 'guest',
      isOwner: json['isOwner'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      joinedAt: (json['joinedAt'] as dynamic)?.toDate(), 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'roleId': roleId,
      'isOwner': isOwner,
      'status': status,
      'joinedAt': joinedAt,
    };
  }
}