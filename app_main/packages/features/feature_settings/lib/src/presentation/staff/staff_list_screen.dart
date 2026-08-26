import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bulk_invite_staff_screen.dart';
import 'invite_staff_screen.dart';

class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final staffAsync = ref.watch(staffStreamProvider);
    final invitationsAsync = ref.watch(invitationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.staffManagement),
        actions: [
          IconButton(
            tooltip: l10n.bulkInviteStaff,
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BulkInviteStaffScreen(),
                ),
              );
              ref.invalidate(invitationsStreamProvider);
            },
          ),
          IconButton(
            tooltip: l10n.inviteStaff,
            icon: const Icon(Icons.person_add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InviteStaffScreen()),
              );
              ref.invalidate(invitationsStreamProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.activeStaff),
            Tab(text: l10n.pendingStaff),
            Tab(text: l10n.suspendedStaff),
            Tab(text: l10n.expiredStaff),
            Tab(text: l10n.revokedStaff),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _search = value.trim().toLowerCase()),
              decoration: InputDecoration(
                labelText: l10n.searchStaff,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStaffTab(staffAsync, 'active'),
                _buildInvitationTab(invitationsAsync, 'pending'),
                _buildStaffTab(staffAsync, 'suspended'),
                _buildInvitationTab(invitationsAsync, 'expired'),
                _buildInvitationTab(invitationsAsync, 'revoked'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffTab(
    AsyncValue<List<StaffMember>> staffAsync,
    String status,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return staffAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildErrorState(l10n),
      data: (staffList) {
        final filtered = staffList.where((member) {
          final matchesStatus = member.status.toLowerCase() == status;
          if (!matchesStatus) return false;
          if (_search.isEmpty) return true;
          return '${member.displayName} ${member.email} ${member.roleId}'
              .toLowerCase()
              .contains(_search);
        }).toList();
        if (filtered.isEmpty) {
          return Center(child: Text(l10n.noStaffFound));
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => _buildStaffTile(filtered[index]),
        );
      },
    );
  }

  Widget _buildStaffTile(StaffMember member) {
    final l10n = AppLocalizations.of(context)!;
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
          : PopupMenuButton<String>(
              tooltip: l10n.changeRole,
              onSelected: (value) {
                switch (value) {
                  case 'role':
                    _changeRole(member);
                  case 'status':
                    _changeStatus(member);
                  case 'remove':
                    _confirmRemove(member);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'role', child: Text(l10n.changeRole)),
                PopupMenuItem(
                  value: 'status',
                  child: Text(
                    member.status == 'suspended'
                        ? l10n.reactivateStaff
                        : l10n.suspendStaff,
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Text(
                    l10n.removeAccess,
                    style: TextStyle(color: context.appColors.error),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInvitationTab(
    AsyncValue<List<StaffInvitation>> invitationsAsync,
    String status,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return invitationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildErrorState(l10n),
      data: (invitations) {
        final filtered = invitations.where((invitation) {
          final normalizedStatus = invitation.status.toLowerCase();
          final matchesStatus = switch (status) {
            'pending' =>
              (normalizedStatus == 'pending' || normalizedStatus == 'sent') &&
                  !invitation.isExpired,
            'expired' => normalizedStatus == 'expired' || invitation.isExpired,
            'revoked' => normalizedStatus == 'revoked',
            _ => false,
          };
          return matchesStatus &&
              (_search.isEmpty ||
                  invitation.email.toLowerCase().contains(_search));
        }).toList();
        if (filtered.isEmpty) {
          return Center(child: Text(l10n.noStaffFound));
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final invitation = filtered[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.mail_outline)),
              title: Text(
                invitation.email,
                textDirection: TextDirection.ltr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(invitation.roleId),
              trailing: status == 'pending'
                  ? PopupMenuButton<String>(
                      onSelected: (_) => _revokeInvitation(invitation),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'revoke',
                          child: Text(l10n.revokeInvitation),
                        ),
                      ],
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(l10n.errorLoadingData, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(staffStreamProvider);
              ref.invalidate(invitationsStreamProvider);
            },
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Future<void> _changeRole(StaffMember member) async {
    final l10n = AppLocalizations.of(context)!;
    final roles = ref
        .read(rolesStreamProvider)
        .valueOrNull
        ?.where((role) => role.id != 'owner')
        .toList();
    if (roles == null || roles.isEmpty) {
      _showError(l10n.errorLoadingData);
      return;
    }
    var selectedRoleId = roles.any((role) => role.id == member.roleId)
        ? member.roleId
        : roles.first.id;
    final roleId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.changeRole),
          content: DropdownButtonFormField<String>(
            initialValue: selectedRoleId,
            items: roles
                .map(
                  (role) =>
                      DropdownMenuItem(value: role.id, child: Text(role.name)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setDialogState(() => selectedRoleId = value);
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancelBtn),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selectedRoleId),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    if (roleId == null || roleId == member.roleId) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .updateStaffRole(member.uid, roleId);
      ref.invalidate(staffStreamProvider);
    } catch (_) {
      _showError(l10n.errorLoadingData);
    }
  }

  Future<void> _changeStatus(StaffMember member) async {
    final l10n = AppLocalizations.of(context)!;
    final nextStatus = member.status == 'suspended' ? 'active' : 'suspended';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          nextStatus == 'suspended' ? l10n.suspendStaff : l10n.reactivateStaff,
        ),
        content: Text(member.displayName),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelBtn),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .setStaffStatus(member.uid, nextStatus);
      ref.invalidate(staffStreamProvider);
    } catch (_) {
      _showError(l10n.errorLoadingData);
    }
  }

  Future<void> _revokeInvitation(StaffInvitation invitation) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(staffRepositoryProvider).revokeInvitation(invitation.id);
      ref.invalidate(invitationsStreamProvider);
    } catch (_) {
      _showError(l10n.errorLoadingData);
    }
  }

  void _confirmRemove(StaffMember member) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.removeStaffTitle(member.displayName)),
        content: Text(l10n.removeStaffWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancelBtn),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref
                    .read(staffRepositoryProvider)
                    .removeStaffMember(member.uid);
                ref.invalidate(staffStreamProvider);
              } catch (_) {
                _showError(l10n.errorLoadingData);
              }
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
