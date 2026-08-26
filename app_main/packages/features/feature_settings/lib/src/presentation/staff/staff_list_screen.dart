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
                MaterialPageRoute(
                  builder: (context) => const InviteStaffScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: staffAsync.when(
        data: (staffList) {
          if (staffList.isEmpty) {
            return Center(child: Text(l10n.noStaffFound));
          }
          return ListView.separated(
            itemCount: staffList.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = staffList[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: member.isOwner
                      ? context.appColors.secondary
                      : context.appColors.info,
                  child: Text(
                    member.displayName.isNotEmpty
                        ? member.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(color: context.appColors.onPrimary),
                  ),
                ),
                title: Text(member.displayName),
                subtitle: Text(
                  member.isOwner
                      ? l10n.ownerRole
                      : l10n.staffRoleAndEmail(member.roleId, member.email),
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
                            child: Text(
                              l10n.removeAccess,
                              style: TextStyle(color: context.appColors.error),
                            ),
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
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.errorLoadingData,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(staffStreamProvider),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref, StaffMember member) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeStaffTitle(member.displayName)),
        content: Text(l10n.removeStaffWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelBtn),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(staffRepositoryProvider)
                  .removeStaffMember(member.uid);
            },
            child: Text(
              l10n.remove,
              style: TextStyle(color: context.appColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
