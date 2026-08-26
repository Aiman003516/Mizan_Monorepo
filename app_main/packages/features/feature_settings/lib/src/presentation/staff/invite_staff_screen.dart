import 'dart:io';

import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_ui/shared_ui.dart';

class InviteStaffScreen extends ConsumerStatefulWidget {
  const InviteStaffScreen({super.key});

  @override
  ConsumerState<InviteStaffScreen> createState() => _InviteStaffScreenState();
}

class _InviteStaffScreenState extends ConsumerState<InviteStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  AppRole? _selectedRole;
  String _deliveryChannel = 'manual';
  String? _generatedCode;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _contactValidator(String? _) {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    if (email.isEmpty && phone.isEmpty) return l10n.invitationContactRequired;
    final emailError = InputValidators.optionalEmail(
      email,
      invalidMessage: l10n.invalidEmail,
    );
    if (emailError != null) return emailError;
    return InputValidators.optionalPhone(
      phone,
      invalidMessage: l10n.invalidPhone,
    );
  }

  Future<void> _generateCode() async {
    if (_selectedRole == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final code = await ref
          .read(staffRepositoryProvider)
          .createInvite(
            _selectedRole!.id,
            recipientEmail: _emailController.text.trim(),
            recipientPhone: _phoneController.text.trim(),
            displayName: _nameController.text.trim(),
            deliveryChannel: _deliveryChannel,
          );
      if (!mounted) return;
      setState(() => _generatedCode = code);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_inviteErrorMessage(error, l10n))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _inviteErrorMessage(Object error, AppLocalizations l10n) {
    final message = error.toString().toLowerCase();
    if (message.contains('42883') ||
        (message.contains('create_invitation') &&
            (message.contains('function') ||
                message.contains('does not exist'))) ||
        message.contains('mizan_invite_setup')) {
      return l10n.invitationSetupRequired;
    }
    if (message.contains('contact_required'))
      return l10n.invitationContactRequired;
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
    return l10n.invitationCreationFailed;
  }

  String _shareText(AppLocalizations l10n) {
    final contact = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : _phoneController.text.trim();
    final name = _nameController.text.trim();
    return l10n.inviteShareTextWithRecipient(_generatedCode!, name, contact);
  }

  Future<void> _shareInvite() async {
    if (_generatedCode == null) return;
    await Share.share(_shareText(AppLocalizations.of(context)!));
  }

  Future<void> _copyInviteCode() async {
    final code = _generatedCode;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.inviteCodeCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesStreamProvider);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.inviteStaff)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.invitationRecipientDetails,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.name,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => value?.trim().isEmpty == true
                      ? l10n.nameIsRequired
                      : null,
                  onChanged: (_) => setState(() => _generatedCode = null),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.emailOptional,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => InputValidators.optionalEmail(
                    value,
                    invalidMessage: l10n.invalidEmail,
                  ),
                  onChanged: (_) {
                    _formKey.currentState?.validate();
                    setState(() => _generatedCode = null);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.phoneOptional,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => InputValidators.optionalPhone(
                    value,
                    invalidMessage: l10n.invalidPhone,
                  ),
                  onChanged: (_) {
                    _formKey.currentState?.validate();
                    setState(() => _generatedCode = null);
                  },
                ),
                FormField<String>(
                  validator: _contactValidator,
                  builder: (field) => field.hasError
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            field.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.invitationDeliveryIntent,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _deliveryChannel,
                  items: [
                    DropdownMenuItem(
                      value: 'manual',
                      child: Text(l10n.manualDelivery),
                    ),
                    DropdownMenuItem(
                      value: 'email',
                      child: Text(l10n.emailDelivery),
                    ),
                    DropdownMenuItem(
                      value: 'sms',
                      child: Text(l10n.smsDelivery),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _deliveryChannel = value ?? 'manual';
                    _generatedCode = null;
                  }),
                  decoration: InputDecoration(
                    labelText: l10n.deliveryChannel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.deliveryIntentDisclaimer,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.stepSelectRole,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                rolesAsync.when(
                  data: (roles) => DropdownButtonFormField<AppRole>(
                    initialValue: _selectedRole,
                    hint: Text(l10n.chooseRoleHint),
                    items: roles
                        .where((role) => role.id != 'owner')
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _selectedRole = value;
                      _generatedCode = null;
                    }),
                    validator: (value) =>
                        value == null ? l10n.requiredField : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => Text(l10n.errorLoadingData),
                ),
                const SizedBox(height: 24),
                if (_generatedCode == null)
                  FilledButton.icon(
                    onPressed: _selectedRole == null || _isLoading
                        ? null
                        : _generateCode,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.key_outlined),
                    label: Text(l10n.generateInviteCode),
                  ),
                if (_generatedCode != null) ...[
                  const Divider(height: 32),
                  Text(
                    l10n.stepShareCode,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.invitationCreatedFor(
                              _nameController.text.trim().isNotEmpty
                                  ? _nameController.text.trim()
                                  : _emailController.text.trim().isNotEmpty
                                  ? _emailController.text.trim()
                                  : _phoneController.text.trim(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SelectableText(
                                  _generatedCode!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        letterSpacing: 6,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                IconButton(
                                  onPressed: _copyInviteCode,
                                  tooltip: l10n.copyInviteCode,
                                  icon: const Icon(Icons.copy_outlined),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(l10n.deliveryIntentRecorded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _shareInvite,
                    icon: const Icon(Icons.share_outlined),
                    label: Text(l10n.shareViaApp),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
