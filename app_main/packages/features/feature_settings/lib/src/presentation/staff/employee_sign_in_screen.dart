import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🎟️ Employee Sign-In Screen
/// Allows employees to join an organization using an invite code.
class EmployeeSignInScreen extends ConsumerStatefulWidget {
  const EmployeeSignInScreen({super.key});

  @override
  ConsumerState<EmployeeSignInScreen> createState() =>
      _EmployeeSignInScreenState();
}

class _EmployeeSignInScreenState extends ConsumerState<EmployeeSignInScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isValidating = false;
  String? _errorMessage;
  Map<String, dynamic>? _inviteDetails;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Validate the invite code without redeeming
  Future<void> _validateCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Code must be 6 digits';
        _inviteDetails = null;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final staffRepo = ref.read(staffRepositoryProvider);
      final result = await staffRepo.validateInviteCode(code);

      setState(() {
        _isValidating = false;
        if (result != null) {
          _inviteDetails = result;
          _errorMessage = null;
        } else {
          _inviteDetails = null;
          _errorMessage = 'Invalid or expired invite code';
        }
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
        _errorMessage = 'Error validating code: $e';
        _inviteDetails = null;
      });
    }
  }

  /// Redeem the invite code and join organization
  Future<void> _joinOrganization() async {
    if (!_formKey.currentState!.validate()) return;
    if (_inviteDetails == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final staffRepo = ref.read(staffRepositoryProvider);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('Please sign in first');
      }

      await staffRepo.redeemInvite(
        code: _codeController.text.trim(),
        userId: currentUser.uid,
        displayName: _nameController.text.trim(),
        email: currentUser.email,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.joinedOrganization),
            backgroundColor: context.appColors.success,
          ),
        );
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;

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
                // Header
                Icon(Icons.group_add, size: 64, color: colorScheme.primary),
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
                  'Enter the invite code from your administrator',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Invite Code Input
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.inviteCode,
                    hintText: '000000',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.vpn_key),
                    suffixIcon: _isValidating
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _inviteDetails != null
                        ? Icon(Icons.check_circle, color: context.appColors.success)
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the invite code';
                    }
                    if (value.length != 6) {
                      return 'Code must be 6 digits';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value.length == 6) {
                      _validateCode();
                    } else {
                      setState(() {
                        _inviteDetails = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Show invite details if valid
                if (_inviteDetails != null) ...[
                  Card(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: context.appColors.success,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Valid Invite Code!',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Role: ${_inviteDetails!['roleId'] ?? 'Staff'}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name Input
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.yourName,
                      hintText: l10n.enterDisplayName,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Join Button
                FilledButton(
                  onPressed: (_inviteDetails != null && !_isLoading)
                      ? _joinOrganization
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.appColors.onPrimary,
                            ),
                          )
                        : Text(
                            l10n.joinOrganization,
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: colorScheme.outline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: TextStyle(color: colorScheme.outline),
                      ),
                    ),
                    Expanded(child: Divider(color: colorScheme.outline)),
                  ],
                ),
                const SizedBox(height: 24),

                // Create New Organization Button
                OutlinedButton(
                  onPressed: () {
                    // Navigate to create organization flow
                    Navigator.of(context).pop(false);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Create New Organization',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
