import 'dart:io';

import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:share_plus/share_plus.dart';

class BulkInviteStaffScreen extends ConsumerStatefulWidget {
  const BulkInviteStaffScreen({super.key});

  @override
  ConsumerState<BulkInviteStaffScreen> createState() =>
      _BulkInviteStaffScreenState();
}

class _BulkInviteStaffScreenState extends ConsumerState<BulkInviteStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailsController = TextEditingController();
  AppRole? _selectedRole;
  List<BulkInvitationResult> _results = const [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailsController.dispose();
    super.dispose();
  }

  List<String> _parseEmails() {
    return _emailsController.text
        .split(RegExp(r'[\s,;]+'))
        .map((email) => email.trim().toLowerCase())
        .where((email) => email.isNotEmpty)
        .toSet()
        .toList();
  }

  String? _validateEmails(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final emails = _parseEmails();
    if (emails.isEmpty) return l10n.bulkInviteNoEmails;
    if (emails.length > 100) return l10n.bulkInviteLimit;
    for (final email in emails) {
      final error = InputValidators.optionalEmail(
        email,
        invalidMessage: l10n.invalidEmail,
      );
      if (error != null) return '$email: $error';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_selectedRole == null ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final emails = _parseEmails();
    setState(() {
      _isSubmitting = true;
      _results = const [];
    });
    try {
      final results = await ref
          .read(staffRepositoryProvider)
          .createInvitationsBulk(roleId: _selectedRole!.id, emails: emails);
      if (!mounted) return;
      setState(() => _results = results);
      final successful = results.where((result) => result.success).length;
      final failed = results.length - successful;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failed == 0
                ? AppLocalizations.of(context)!.bulkInviteCreated(successful)
                : AppLocalizations.of(
                    context,
                  )!.bulkInvitePartial(successful, failed),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_inviteErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _inviteErrorMessage(Object error) {
    final l10n = AppLocalizations.of(context)!;
    final message = error.toString().toLowerCase();
    if (message.contains('42883') ||
        message.contains('create_invitations_bulk') &&
            (message.contains('function') ||
                message.contains('does not exist')) ||
        message.contains('mizan_invite_setup')) {
      return l10n.invitationSetupRequired;
    }
    if (message.contains('42501') ||
        message.contains('permission') ||
        message.contains('not authorized') ||
        message.contains('forbidden')) {
      return l10n.invitationPermissionDenied;
    }
    if (message.contains('already') ||
        message.contains('pending') ||
        message.contains('duplicate') ||
        message.contains('unique constraint')) {
      return l10n.invitationAlreadyPending;
    }
    if (error is SocketException ||
        message.contains('timeout') ||
        message.contains('failed host lookup') ||
        message.contains('network')) {
      return l10n.invitationNetworkError;
    }
    return l10n.errorLoadingData;
  }

  Future<void> _shareResults() async {
    final successful = _results.where((result) => result.success).toList();
    if (successful.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final lines = successful.map((result) {
      final code = result.code ?? '—';
      return '${result.email}: $code\n${l10n.inviteShareText(code)}';
    });
    await Share.share(lines.join('\n\n'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rolesAsync = ref.watch(rolesStreamProvider);
    final successful = _results.where((result) => result.success).length;
    final failed = _results.length - successful;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bulkInviteStaff)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              l10n.bulkInviteHint,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailsController,
              minLines: 6,
              maxLines: 12,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: l10n.email,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: _validateEmails,
              onChanged: (_) => setState(() => _results = const []),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _emailsController,
              builder: (context, _, __) => Text(
                l10n.bulkInviteCount(_parseEmails().length),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.stepSelectRole,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            rolesAsync.when(
              data: (roles) {
                final assignableRoles = roles
                    .where((role) => role.id != 'owner')
                    .toList();
                return DropdownButtonFormField<AppRole>(
                  initialValue: _selectedRole,
                  hint: Text(l10n.chooseRoleHint),
                  items: assignableRoles
                      .map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(role.name),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _selectedRole = value),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null ? l10n.requiredField : null,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(l10n.errorLoadingData),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(l10n.generateInviteCode),
            ),
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                l10n.bulkInviteResults,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                failed == 0
                    ? l10n.bulkInviteCreated(successful)
                    : l10n.bulkInvitePartial(successful, failed),
              ),
              const SizedBox(height: 8),
              ..._results.map(
                (result) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    result.success ? Icons.check_circle : Icons.error_outline,
                    color: result.success
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    result.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                  ),
                  subtitle: result.success
                      ? Text('${l10n.stepShareCode}: ${result.code ?? '—'}')
                      : Text(l10n.errorLoadingData),
                ),
              ),
              if (successful > 0)
                OutlinedButton.icon(
                  onPressed: _shareResults,
                  icon: const Icon(Icons.share_outlined),
                  label: Text(l10n.shareViaApp),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
