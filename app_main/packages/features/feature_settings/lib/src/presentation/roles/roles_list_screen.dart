import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'role_editor_screen.dart';

class RolesListScreen extends ConsumerWidget {
  const RolesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(rolesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Roles'),
      ),
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
            return const Center(child: Text("No roles defined. Create one!"));
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
                    ? 'Full System Access' 
                    : '${role.permissions.length} Permissions'
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  if (role.isSystemAdmin) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('System Admin role cannot be edited.')),
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
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}