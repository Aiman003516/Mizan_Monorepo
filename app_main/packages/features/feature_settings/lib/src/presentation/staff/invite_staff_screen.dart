import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:shared_ui/shared_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:share_plus/share_plus.dart'; // Ensure you added this to pubspec

class InviteStaffScreen extends ConsumerStatefulWidget {
  const InviteStaffScreen({super.key});

  @override
  ConsumerState<InviteStaffScreen> createState() => _InviteStaffScreenState();
}

class _InviteStaffScreenState extends ConsumerState<InviteStaffScreen> {
  @override
  void dispose() {
    _recipientEmailController.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();
  final _recipientEmailController = TextEditingController();
  AppRole? _selectedRole;
  String? _generatedCode;
  bool _isLoading = false;

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
            recipientEmail: _recipientEmailController.text.trim(),
          );
      setState(() {
        _generatedCode = code;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorLoadingData)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _shareInvite() {
    if (_generatedCode == null) return;
    final l10n = AppLocalizations.of(context)!;
    final text = l10n.inviteShareText(_generatedCode!);
    Share.share(text);
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

  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesStreamProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inviteStaff)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _recipientEmailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return l10n.requiredField;
                  return InputValidators.optionalEmail(
                    email,
                    invalidMessage: l10n.invalidEmail,
                  );
                },
                onChanged: (_) => setState(() => _generatedCode = null),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.stepSelectRole,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              rolesAsync.when(
                data: (roles) {
                  // Filter out Admin/Owner roles usually, but for now show all except Owner if you want
                  final assignableRoles = roles
                      .where((r) => r.id != 'owner')
                      .toList();

                  return DropdownButtonFormField<AppRole>(
                    initialValue: _selectedRole,
                    hint: Text(l10n.chooseRoleHint),
                    items: assignableRoles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.name),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() {
                      _selectedRole = val;
                      _generatedCode = null; // Reset code if role changes
                    }),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => Text(l10n.errorLoadingData),
              ),
              const SizedBox(height: 32),

              if (_generatedCode == null)
                ElevatedButton(
                  onPressed: (_selectedRole == null || _isLoading)
                      ? null
                      : _generateCode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: context.appColors.onPrimary,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: context.appColors.onPrimary,
                          ),
                        )
                      : Text(l10n.generateInviteCode),
                ),

              if (_generatedCode != null) ...[
                const Divider(height: 40),
                Text(
                  l10n.stepShareCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.appColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.appColors.primary),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              _generatedCode!,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                color: context.appColors.onPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _copyInviteCode,
                            tooltip: l10n.copyInviteCode,
                            icon: Icon(
                              Icons.copy,
                              color: context.appColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.validFor24Hours,
                        style: TextStyle(
                          color: context.appColors.onPrimary.withValues(
                            alpha: 0.82,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _shareInvite,
                  icon: const Icon(Icons.share),
                  label: Text(l10n.shareViaApp),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: context.appColors.success,
                    foregroundColor: context.appColors.onPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
