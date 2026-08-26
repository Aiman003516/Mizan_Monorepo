import 'dart:io';

import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_data_import/src/data/file_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'invitation_import_mapper.dart';

class BulkInviteStaffScreen extends ConsumerStatefulWidget {
  const BulkInviteStaffScreen({super.key});

  @override
  ConsumerState<BulkInviteStaffScreen> createState() =>
      _BulkInviteStaffScreenState();
}

class _BulkInviteStaffScreenState extends ConsumerState<BulkInviteStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _parser = FileParser();
  final _mapper = InvitationImportMapper();
  AppRole? _selectedRole;
  ParsedFileResult? _file;
  String? _emailColumn;
  String? _phoneColumn;
  String? _nameColumn;
  String _deliveryChannel = 'manual';
  List<BulkInvitationResult> _results = const [];
  List<String> _rowErrors = const [];
  bool _isParsing = false;
  bool _isSubmitting = false;

  String? _autoColumn(List<String> headers, Set<String> aliases) =>
      InvitationImportMapper.autoDetect(headers, aliases);

  Future<void> _pickFile() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isParsing = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'xlsx', 'xls'],
        withData: false,
      );
      if (picked == null || picked.files.single.path == null) return;
      final parsed = await _parser.parseFile(File(picked.files.single.path!));
      if (!mounted) return;
      if (parsed.headers.isEmpty || parsed.rows.isEmpty) {
        throw const FormatException('The selected file has no data rows.');
      }
      setState(() {
        _file = parsed;
        _emailColumn = _autoColumn(parsed.headers, {
          'email',
          'emailaddress',
          'mail',
          'e-mail',
          'e_mail',
        });
        _phoneColumn = _autoColumn(parsed.headers, {
          'phone',
          'phonenumber',
          'mobile',
          'mobilenumber',
          'telephone',
          'tel',
        });
        _nameColumn = _autoColumn(parsed.headers, {
          'name',
          'fullname',
          'displayname',
          'employeename',
          'recipientname',
        });
        _results = const [];
        _rowErrors = const [];
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.fileImportFailed}: $error')),
      );
    } finally {
      if (mounted) setState(() => _isParsing = false);
    }
  }

  List<BulkInvitationRecipient> _buildRecipients() {
    final l10n = AppLocalizations.of(context)!;
    final file = _file;
    if (file == null) return const [];
    final mapped = _mapper.map(
      file: file,
      emailColumn: _emailColumn,
      phoneColumn: _phoneColumn,
      nameColumn: _nameColumn,
      deliveryChannel: _deliveryChannel,
    );
    _rowErrors = mapped
        .where((row) => !row.isValid)
        .map(
          (row) =>
              '${row.rowNumber}: ${switch (row.errorCode) {
                'invalid_email' => l10n.invalidEmail,
                'invalid_phone' => l10n.invalidPhone,
                'duplicate' => l10n.duplicateImportRow,
                _ => l10n.invitationContactRequired,
              }}',
        )
        .toList(growable: false);
    return mapped
        .where((row) => row.isValid)
        .map((row) => row.recipient!)
        .toList(growable: false);
  }

  Future<void> _submit() async {
    if (_selectedRole == null || _file == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final recipients = _buildRecipients();
    if (recipients.isEmpty || recipients.length > 100) {
      setState(() {});
      return;
    }
    setState(() {
      _isSubmitting = true;
      _results = const [];
    });
    try {
      final results = await ref
          .read(staffRepositoryProvider)
          .createInvitationsBulkRecipients(
            roleId: _selectedRole!.id,
            recipients: recipients,
          );
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
        (message.contains('create_invitations_bulk_recipients') &&
            (message.contains('function') ||
                message.contains('does not exist')))) {
      return l10n.invitationSetupRequired;
    }
    if (message.contains('permission') || message.contains('forbidden')) {
      return l10n.invitationPermissionDenied;
    }
    if (message.contains('network') || message.contains('timeout')) {
      return l10n.invitationNetworkError;
    }
    return l10n.invitationCreationFailed;
  }

  Future<void> _shareResults() async {
    final l10n = AppLocalizations.of(context)!;
    final successful = _results.where((result) => result.success).toList();
    if (successful.isEmpty) return;
    final lines = successful.map((result) {
      final contact = result.email.isNotEmpty ? result.email : result.phone;
      return '${result.recipientLabel} — $contact\n${l10n.inviteShareText(result.code ?? '—')}';
    });
    await Share.share(lines.join('\n\n'));
  }

  Widget _columnDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final headers = _file?.headers ?? const <String>[];
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: [
        DropdownMenuItem(
          value: '',
          child: Text(AppLocalizations.of(context)!.notSet),
        ),
        ...headers.map(
          (header) => DropdownMenuItem(value: header, child: Text(header)),
        ),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rolesAsync = ref.watch(rolesStreamProvider);
    final recipients = _file == null
        ? const <BulkInvitationRecipient>[]
        : _buildRecipients();
    final successful = _results.where((result) => result.success).length;
    final failed = _results.length - successful;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bulkInviteStaff)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(l10n.bulkInviteHint),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isParsing || _isSubmitting ? null : _pickFile,
              icon: _isParsing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: Text(
                _file == null ? l10n.chooseImportFile : _file!.fileName,
              ),
            ),
            if (_file != null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.mapImportColumns,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _columnDropdown(
                label: l10n.emailColumn,
                value: _emailColumn ?? '',
                onChanged: (value) => setState(() => _emailColumn = value),
              ),
              const SizedBox(height: 8),
              _columnDropdown(
                label: l10n.phoneColumn,
                value: _phoneColumn ?? '',
                onChanged: (value) => setState(() => _phoneColumn = value),
              ),
              const SizedBox(height: 8),
              _columnDropdown(
                label: l10n.nameColumn,
                value: _nameColumn ?? '',
                onChanged: (value) => setState(() => _nameColumn = value),
              ),
              const SizedBox(height: 8),
              Text(l10n.importMappingConfirmation),
              const SizedBox(height: 12),
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
                  DropdownMenuItem(value: 'sms', child: Text(l10n.smsDelivery)),
                ],
                onChanged: (value) =>
                    setState(() => _deliveryChannel = value ?? 'manual'),
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
              const SizedBox(height: 12),
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
                  onChanged: (value) => setState(() => _selectedRole = value),
                  validator: (value) =>
                      value == null ? l10n.requiredField : null,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => Text(l10n.errorLoadingData),
              ),
              const SizedBox(height: 12),
              Text(l10n.bulkInviteCount(recipients.length)),
              if (_rowErrors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.importRowsRejected(_rowErrors.length),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                ..._rowErrors
                    .take(5)
                    .map(
                      (error) => Text(
                        error,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
              ],
              const SizedBox(height: 12),
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
            ],
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              Text(
                l10n.bulkInviteResults,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                failed == 0
                    ? l10n.bulkInviteCreated(successful)
                    : l10n.bulkInvitePartial(successful, failed),
              ),
              ..._results.map(
                (result) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    result.success ? Icons.check_circle : Icons.error_outline,
                    color: result.success
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.error,
                  ),
                  title: Text(result.recipientLabel),
                  subtitle: Text(
                    result.success
                        ? '${result.email.isNotEmpty ? result.email : result.phone} — ${result.code ?? '—'}'
                        : result.error ?? l10n.invitationCreationFailed,
                  ),
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
