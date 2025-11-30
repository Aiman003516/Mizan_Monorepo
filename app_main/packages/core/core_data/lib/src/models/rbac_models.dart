// FILE: packages/core/core_data/lib/src/models/rbac_models.dart

/// 🛡️ THE PERMISSION REGISTRY
/// This Enum defines every distinct action a user can perform in Mizan.
/// We store these as Strings in Firestore to allow flexibility.
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
/// A Role is simply a named bucket of permissions.
/// e.g., Name: "Cashier", Permissions: [performSale, viewInventory]
class AppRole {
  final String id;
  final String name;
  final List<AppPermission> permissions;
  final bool isSystemAdmin; // If true, bypasses all checks (Owner)

  const AppRole({
    required this.id,
    required this.name,
    required this.permissions,
    this.isSystemAdmin = false,
  });

  /// Factory to create the "Owner" role (All Powerful)
  factory AppRole.owner() {
    return const AppRole(
      id: 'owner',
      name: 'Owner',
      permissions: [], // Permissions ignored because isSystemAdmin is true
      isSystemAdmin: true,
    );
  }

  /// Convert from Firestore JSON
  factory AppRole.fromJson(Map<String, dynamic> json, String id) {
    final permsData = json['permissions'] as List<dynamic>? ?? [];
    
    // Convert Strings back to Enums safely
    final permissions = permsData.map((p) {
      try {
        return AppPermission.values.byName(p as String);
      } catch (e) {
        return null; // Ignore unknown/deprecated permissions
      }
    }).whereType<AppPermission>().toList();

    return AppRole(
      id: id,
      name: json['name'] as String? ?? 'Unknown Role',
      permissions: permissions,
      isSystemAdmin: json['isSystemAdmin'] as bool? ?? false,
    );
  }

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'permissions': permissions.map((e) => e.name).toList(),
      'isSystemAdmin': isSystemAdmin,
    };
  }

  /// 🛡️ THE CHECKER
  /// Does this role have the power to do X?
  bool hasPermission(AppPermission permission) {
    if (isSystemAdmin) return true;
    return permissions.contains(permission);
  }
}