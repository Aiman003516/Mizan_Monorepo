import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'role_editor_screen.dart';

class RolesListScreen extends ConsumerWidget {
  const RolesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rolesAsync = ref.watch(rolesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageRoles)),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RoleEditorScreen()),
          );
        },
      ),
      body: rolesAsync.when(
        data: (roles) {
          if (roles.isEmpty) {
            return Center(child: Text(l10n.noRolesDefined));
          }
          return ListView.builder(
            itemCount: roles.length,
            itemBuilder: (context, index) {
              final role = roles[index];
              return ListTile(
                leading: Icon(
                  role.isSystemAdmin ? Icons.security : Icons.person_outline,
                  color: role.isSystemAdmin ? Colors.red : Colors.blue,
                ),
                title: Text(role.name),
                subtitle: Text(
                  role.isSystemAdmin
                      ? l10n.fullSystemAccess
                      : l10n.permissionsCount(role.permissions.length),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  if (role.isSystemAdmin) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.systemAdminReadonly)),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoleEditorScreen(roleToEdit: role),
                    ),
                  );
                },
                onLongPress: () {
                  // Optional: Add Delete Logic here
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.errorLoadingData),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(rolesStreamProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
