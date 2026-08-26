import 'dart:io';

import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'invitation_code_field.dart';

class EmployeeSignInScreen extends ConsumerStatefulWidget {
  const EmployeeSignInScreen({super.key});

  @override
  ConsumerState<EmployeeSignInScreen> createState() =>
      _EmployeeSignInScreenState();
}

class _EmployeeSignInScreenState extends ConsumerState<EmployeeSignInScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isValidating = false;
  String _code = '';
  String? _errorMessage;
  Map<String, dynamic>? _inviteDetails;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    final pending = ref.read(pendingInvitationServiceProvider).read();
    if (pending != null) {
      _code = pending.code;
      _emailController.text = pending.recipientEmail ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _validateCode();
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    if (_code.length != 6) return;
    final email = _emailController.text.trim().toLowerCase();
    final emailError = InputValidators.optionalEmail(
      email,
      invalidMessage: l10n.invalidEmail,
    );
    if (emailError != null) {
      setState(() => _errorMessage = emailError);
      return;
    }
    setState(() {
      _isValidating = true;
      _errorMessage = null;
      _inviteDetails = null;
    });
    try {
      final result = await ref
          .read(staffRepositoryProvider)
          .validateInviteCode(_code, email: email.isEmpty ? null : email);
      if (result == null) {
        await ref.read(pendingInvitationServiceProvider).clear();
        if (!mounted) return;
        setState(() => _errorMessage = l10n.invalidInviteCode);
        return;
      }
      final assignedEmail =
          result['recipientEmail']?.toString().trim().toLowerCase() ?? '';
      if (assignedEmail.isNotEmpty &&
          email.isNotEmpty &&
          assignedEmail != email) {
        throw const AuthException(
          'This invitation is assigned to a different email address.',
        );
      }
      if (assignedEmail.isNotEmpty && email.isEmpty) {
        _emailController.text = assignedEmail;
      }
      final expiresAt = DateTime.tryParse(
        result['expiresAt']?.toString() ?? '',
      );
      final pending = await ref
          .read(pendingInvitationServiceProvider)
          .save(
            code: _code,
            recipientEmail: assignedEmail.isEmpty ? email : assignedEmail,
            recipientPhone: result['recipientPhone']?.toString(),
            displayName: result['displayName']?.toString(),
            tenantId: result['tenantId']?.toString(),
            roleId: result['roleId']?.toString(),
            token: result['token']?.toString(),
            expiresAt: expiresAt,
          );
      if (!mounted) return;
      ref.read(pendingInvitationProvider.notifier).state = pending;
      setState(() {
        _inviteDetails = result;
        _nameController.text = result['displayName']?.toString() ?? '';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _verificationError(error));
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  String _verificationError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('different email'))
      return l10n.invitationEmailMismatch;
    if (message.contains('expired')) return l10n.inviteCodeExpired;
    if (message.contains('used')) return l10n.inviteCodeUsed;
    if (message.contains('network') || message.contains('timeout')) {
      return l10n.invitationNetworkError;
    }
    return l10n.invalidInviteCode;
  }

  Future<void> _finishWithPassword() async {
    if (_inviteDetails == null || !(_formKey.currentState?.validate() ?? false))
      return;
    final email = _emailController.text.trim().toLowerCase();
    final phone = _inviteDetails!['recipientPhone']?.toString().trim() ?? '';
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final auth = ref.read(authRepositoryProvider);
      var currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        final response = email.isNotEmpty
            ? await auth.signUpWithEmail(email, _passwordController.text)
            : await auth.signUpWithPhone(phone, _passwordController.text);
        currentUser = response.user;
        if (response.session == null || currentUser == null) {
          throw AuthException(l10n.emailConfirmationRequired);
        }
      } else if (email.isNotEmpty &&
          currentUser.email?.toLowerCase() != email) {
        throw const AuthException(
          'This invitation is assigned to a different email address.',
        );
      } else {
        await auth.updatePassword(_passwordController.text);
      }
      await _redeem(currentUser);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _accountError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    if (_inviteDetails == null || !Platform.isAndroid) {
      setState(() => _errorMessage = l10n.googleInviteAndroidOnly);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final driveClient = await ref.read(authRepositoryProvider).signIn();
      if (driveClient == null)
        throw const AuthException('Google sign-in was cancelled.');
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null)
        throw const AuthException('Google did not create a cloud session.');
      final assignedEmail =
          _inviteDetails!['recipientEmail']?.toString().toLowerCase() ?? '';
      if (assignedEmail.isNotEmpty &&
          currentUser.email?.toLowerCase() != assignedEmail) {
        throw const AuthException(
          'This invitation is assigned to a different email address.',
        );
      }
      await _redeem(currentUser);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _accountError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _redeem(User user) async {
    await ref
        .read(staffRepositoryProvider)
        .redeemInvite(
          code: _code,
          userId: user.id,
          displayName: _nameController.text.trim(),
          email: user.email,
        );
    await ref.read(pendingInvitationServiceProvider).clear();
    ref.read(pendingInvitationProvider.notifier).state = null;
    ref.invalidate(currentUserStreamProvider);
    ref.invalidate(cloudDataModeStateProvider);
    ref.invalidate(userRoleProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.joinedOrganization),
        backgroundColor: context.appColors.success,
      ),
    );
    Navigator.of(context).pop(true);
  }

  String _accountError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('different email'))
      return l10n.invitationEmailMismatch;
    if (message.contains('password')) return l10n.passwordSetupFailed;
    if (message.contains('already registered') ||
        message.contains('already exists')) {
      return l10n.accountAlreadyExistsUseSignIn;
    }
    return l10n.accountSetupFailed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final verified = _inviteDetails != null;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinOrganization), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.group_add_outlined, size: 64, color: colors.primary),
                const SizedBox(height: 16),
                Text(
                  l10n.joinOrganization,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.inviteEmailCodeIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  enabled: !verified,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => InputValidators.optionalEmail(
                    value,
                    invalidMessage: l10n.invalidEmail,
                  ),
                  onChanged: (_) {
                    if (_inviteDetails != null)
                      setState(() => _inviteDetails = null);
                  },
                ),
                const SizedBox(height: 20),
                Text(l10n.inviteCode, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                InvitationCodeField(
                  initialCode: _code,
                  enabled: !_isValidating && !verified,
                  pasteLabel: l10n.paste,
                  fieldLabel: l10n.inviteCode,
                  onChanged: (value) {
                    setState(() {
                      _code = value;
                      if (value.length < 6) {
                        _inviteDetails = null;
                        _errorMessage = null;
                      }
                    });
                    if (value.length == 6) _validateCode();
                  },
                ),
                if (_isValidating) const LinearProgressIndicator(),
                if (verified) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: colors.primaryContainer,
                    child: ListTile(
                      leading: Icon(
                        Icons.verified_outlined,
                        color: colors.primary,
                      ),
                      title: Text(l10n.validInviteCodeTitle),
                      subtitle: Text(
                        '${_inviteDetails!['tenantName'] ?? ''}\n${l10n.roleLabel(_inviteDetails!['roleName']?.toString() ?? l10n.role)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.yourName,
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value?.trim().isEmpty == true
                        ? l10n.pleaseEnterYourName
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return l10n.requiredField;
                      if (value.length < 8) return l10n.passwordMinLength;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.confirmPassword,
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value != _passwordController.text
                        ? l10n.passwordsDoNotMatch
                        : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isLoading ? null : _finishWithPassword,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.setPasswordAndJoin),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _continueWithGoogle,
                    icon: const Icon(Icons.account_circle_outlined),
                    label: Text(l10n.continueWithGoogle),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: colors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: colors.error),
                          ),
                        ),
                      ],
                    ),
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
