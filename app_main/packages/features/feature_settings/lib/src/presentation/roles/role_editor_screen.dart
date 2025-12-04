import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart'; // Exports AppRole, AppPermission, RolesRepository

class RoleEditorScreen extends ConsumerStatefulWidget {
  final AppRole? roleToEdit;

  const RoleEditorScreen({super.key, this.roleToEdit});

  @override
  ConsumerState<RoleEditorScreen> createState() => _RoleEditorScreenState();
}

class _RoleEditorScreenState extends ConsumerState<RoleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  // Local state for the checklist
  final Set<AppPermission> _selectedPermissions = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.roleToEdit != null) {
      // Editing Mode: Populate data
      _nameController.text = widget.roleToEdit!.name;
      _selectedPermissions.addAll(widget.roleToEdit!.permissions);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 📝 Helper to get human-readable labels
  String _getPermissionLabel(AppPermission p) {
    switch (p) {
      case AppPermission.viewDashboard: return "View Dashboard";
      case AppPermission.viewFinancialReports: return "View Financial Reports";
      case AppPermission.performSale: return "Perform Sales (POS)";
      case AppPermission.voidTransaction: return "Void/Delete Transactions";
      case AppPermission.processRefund: return "Process Refunds";
      case AppPermission.viewSalesHistory: return "View Sales History";
      case AppPermission.viewInventory: return "View Inventory";
      case AppPermission.manageProducts: return "Add/Edit Products";
      case AppPermission.adjustInventory: return "Stock Adjustments";
      case AppPermission.manageStaff: return "Manage Staff & Roles";
      case AppPermission.manageSettings: return "System Settings";
      case AppPermission.switchTenant: return "Switch Business Branch";
    }
  }

  Future<void> _saveRole() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPermissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one permission.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newRole = AppRole(
        // If editing, keep ID. If new, pass empty string (Repository will auto-id)
        id: widget.roleToEdit?.id ?? '', 
        name: _nameController.text.trim(),
        permissions: _selectedPermissions.toList(),
        isSystemAdmin: false, // Custom roles are never System Admins
      );

      await ref.read(rolesRepositoryProvider).saveRole(newRole);

      if (mounted) {
        Navigator.pop(context); // Close screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role saved successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving role: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.roleToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Role' : 'Create New Role'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveRole,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  // --- Identity Section ---
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Role Name',
                        hintText: 'e.g., Senior Cashier',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Name is required' : null,
                    ),
                  ),
                  const Divider(),
                  
                  // --- Permissions Section ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Permissions",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  
                  Expanded(
                    child: ListView.separated(
                      itemCount: AppPermission.values.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final permission = AppPermission.values[index];
                        final isSelected = _selectedPermissions.contains(permission);

                        return CheckboxListTile(
                          title: Text(_getPermissionLabel(permission)),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedPermissions.add(permission);
                              } else {
                                _selectedPermissions.remove(permission);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}