import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'invite_staff_screen.dart'; // We will create this next

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InviteStaffScreen()),
              );
            },
          ),
        ],
      ),
      body: staffAsync.when(
        data: (staffList) {
          if (staffList.isEmpty) {
            return const Center(child: Text("No staff found. Invite someone!"));
          }
          return ListView.separated(
            itemCount: staffList.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = staffList[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: member.isOwner ? Colors.purple : Colors.blue,
                  child: Text(
                    member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(member.displayName),
                subtitle: Text(
                  member.isOwner ? 'Owner' : 'Role: ${member.roleId} • ${member.email}',
                ),
                trailing: member.isOwner
                    ? const Icon(Icons.star, color: Colors.amber)
                    : PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Change Role'),
                          ),
                          const PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove Access', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'remove') {
                            _confirmRemove(context, ref, member);
                          }
                          // TODO: Implement 'edit' to show Role Picker dialog
                        },
                      ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref, StaffMember member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Remove ${member.displayName}?"),
        content: const Text("They will lose access to this business immediately."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(staffRepositoryProvider).removeStaffMember(member.uid);
            },
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}