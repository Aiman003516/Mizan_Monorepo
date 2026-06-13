import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'invite_staff_screen.dart'; // We will create this next

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final staffAsync = ref.watch(staffStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.staffManagement),
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
                  backgroundColor: member.isOwner ? context.appColors.secondary : context.appColors.info,
                  child: Text(
                    member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                    style: TextStyle(color: context.appColors.onPrimary),
                  ),
                ),
                title: Text(member.displayName),
                subtitle: Text(
                  member.isOwner ? 'Owner' : 'Role: ${member.roleId} • ${member.email}',
                ),
                trailing: member.isOwner
                    ? Icon(Icons.star, color: context.appColors.warning)
                    : PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(l10n.changeRole),
                          ),
                          PopupMenuItem(
                            value: 'remove',
                            child: Text(l10n.removeAccess, style: TextStyle(color: context.appColors.error)),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'remove') {
                            _confirmRemove(context, ref, member);
                          }
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
            child: Text("Remove", style: TextStyle(color: context.appColors.error)),
          ),
        ],
      ),
    );
  }
}