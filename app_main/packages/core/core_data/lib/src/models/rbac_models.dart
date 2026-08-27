// FILE: packages/core/core_data/lib/src/models/rbac_models.dart

/// 🛡️ THE APP USER (Enriched Identity)
/// Combines Firebase Auth (Email/UID) with Firestore Data (Tenant/Role).
class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? tenantId; // 👈 CRITICAL: Links user to a specific shop
  final String role; // e.g., 'owner', 'manager', 'staff'
  final bool isPro; // Lifetime License Flag

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

  /// Cloud access requires a tenant membership. Subscription checks are
  /// performed separately by the billing layer.
  bool get hasCloudAccess => tenantId != null && tenantId!.isNotEmpty;

  factory AppUser.fromMap(
    Map<String, dynamic> data, {
    required String uid,
    required String email,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: (data['displayName'] ?? data['display_name']) as String?,
      tenantId: (data['tenantId'] ?? data['tenant_id']) as String?,
      role: data['role'] as String? ?? 'staff',
      isPro: (data['isPro'] ?? data['is_pro']) as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'tenantId': tenantId,
      'role': role,
      'isPro': isPro,
      'lastLogin': DateTime.now().toIso8601String(),
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
  manageBranches, // Manage branch records and staff branch assignments
  approveRequests, // Decide governed approval requests
  manageProcurement,
  approveProcurement,
  receiveInventory,
  manageCrm,
  manageCustomers,
  manageVendors,
  createInvoices,
  manageInvoices,
  createBills,
  manageBills,
  manageAccounting,
  postJournalEntries,
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

  factory AppRole.guest() {
    return const AppRole(id: 'guest', name: 'Guest', permissions: []);
  }

  factory AppRole.fromJson(Map<String, dynamic> json, String id) {
    final rawPermissions = json['permissions'];
    final permsData = rawPermissions is List
        ? rawPermissions.whereType<String>().toList()
        : rawPermissions is Map
        ? rawPermissions.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key.toString())
              .toList()
        : const <String>[];

    final permissions = permsData
        .map((permissionName) {
          try {
            return AppPermission.values.byName(permissionName);
          } catch (e) {
            return null;
          }
        })
        .whereType<AppPermission>()
        .toList();

    return AppRole(
      id: id,
      name: json['name'] as String? ?? 'Unknown Role',
      permissions: permissions,
      isSystemAdmin:
          (json['isSystemAdmin'] ?? json['is_system_admin']) as bool? ?? false,
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
    final profile = json['user_profiles'] is Map
        ? Map<String, dynamic>.from(json['user_profiles'] as Map)
        : const <String, dynamic>{};
    final joined = json['joinedAt'] ?? json['created_at'] ?? json['createdAt'];
    return StaffMember(
      uid: (json['uid'] ?? json['user_id'] ?? json['id']) as String? ?? '',
      email: (json['email'] ?? profile['email']) as String? ?? '',
      displayName:
          (json['displayName'] ??
                  json['display_name'] ??
                  profile['display_name'])
              as String? ??
          'Unknown',
      roleId: (json['roleId'] ?? json['role_id']) as String? ?? 'guest',
      isOwner: (json['isOwner'] ?? json['is_owner']) as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      joinedAt: joined is DateTime
          ? joined
          : (joined is String ? DateTime.tryParse(joined) : null),
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
