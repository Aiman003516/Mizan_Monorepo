// FILE: packages/shared/shared_ui/lib/src/widgets/permission_guard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';

/// 🛡️ PERMISSION GUARD
/// A widget that only reveals its child if the user has the required permission.
///
/// Usage:
/// PermissionGuard(
///   permission: AppPermission.manageSettings,
///   child: SettingsButton(),
///   fallback: SizedBox.shrink(), // Optional: What to show if denied (default: nothing)
/// )
class PermissionGuard extends ConsumerWidget {
  final AppPermission permission;
  final Widget child;
  final Widget fallback;

  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);

    return roleAsync.when(
      data: (role) {
        if (role.hasPermission(permission)) {
          return child;
        }
        return fallback;
      },
      // While loading or error, we deny access by default (Safety First 🔒)
      loading: () => fallback,
      error: (_, __) => fallback,
    );
  }
}