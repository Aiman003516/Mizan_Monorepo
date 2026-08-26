import 'dart:convert';

import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_agent_repository.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key, this.onConnectAccount});

  final VoidCallback? onConnectAccount;

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _composerController = TextEditingController();
  final _scrollController = ScrollController();
  final _draftPayloadController = TextEditingController(text: '{}');
  final _messages = <AiChatMessage>[];
  String? _conversationId;
  AiActionRequest? _actionDraft;
  bool _isSending = false;
  bool _isCreatingDraft = false;

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    _draftPayloadController.dispose();
    super.dispose();
  }

  Future<void> _openDraftComposer() async {
    final l10n = AppLocalizations.of(context)!;
    final value =
        await showDialog<({String actionType, Map<String, dynamic> payload})>(
          context: context,
          builder: (dialogContext) {
            var selectedAction = 'customer_draft';
            String? validationError;
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: Text(l10n.aiActionPreview),
                  content: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: selectedAction,
                            items: [
                              DropdownMenuItem(
                                value: 'invoice_draft',
                                child: Text(l10n.aiActionTypeInvoice),
                              ),
                              DropdownMenuItem(
                                value: 'bill_draft',
                                child: Text(l10n.aiActionTypeBill),
                              ),
                              DropdownMenuItem(
                                value: 'customer_draft',
                                child: Text(l10n.aiActionTypeCustomer),
                              ),
                              DropdownMenuItem(
                                value: 'vendor_draft',
                                child: Text(l10n.aiActionTypeVendor),
                              ),
                              DropdownMenuItem(
                                value: 'staff_invitation_batch_draft',
                                child: Text(l10n.aiActionTypeStaffInvitation),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => selectedAction = value);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: l10n.aiActionDraftStatus,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _draftPayloadController,
                            minLines: 8,
                            maxLines: 14,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              labelText: l10n.aiActionDraftPayload,
                              hintText: l10n.aiActionPayloadHint,
                              alignLabelWithHint: true,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          if (validationError != null) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                validationError!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () {
                        try {
                          final decoded = jsonDecode(
                            _draftPayloadController.text,
                          );
                          if (decoded is! Map) throw const FormatException();
                          Navigator.pop(dialogContext, (
                            actionType: selectedAction,
                            payload: Map<String, dynamic>.from(decoded),
                          ));
                        } on FormatException {
                          setDialogState(
                            () => validationError = l10n.aiActionInvalidPayload,
                          );
                        } on Object {
                          setDialogState(
                            () => validationError = l10n.aiActionInvalidPayload,
                          );
                        }
                      },
                      child: Text(l10n.aiActionPrepareDraft),
                    ),
                  ],
                );
              },
            );
          },
        );
    if (value == null || !mounted) return;
    await _createActionDraft(value.actionType, value.payload);
  }

  Future<void> _createActionDraft(
    String actionType,
    Map<String, dynamic> payload,
  ) async {
    setState(() => _isCreatingDraft = true);
    try {
      final draft = await ref
          .read(aiAgentRepositoryProvider)
          .createActionDraft(
            actionType: actionType,
            payload: payload,
            conversationId: _conversationId,
          );
      if (!mounted) return;
      setState(() => _actionDraft = draft);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.aiActionDraftCreated),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final message = error is AiGuestModeException
          ? l10n.aiAssistantSignInRequired
          : error is AiAgentException && error.code.contains('PERMISSION')
          ? l10n.aiActionPermissionDenied
          : l10n.aiActionInvalid;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isCreatingDraft = false);
    }
  }

  Future<void> _cancelActionDraft() async {
    final draft = _actionDraft;
    if (draft == null) return;
    try {
      final cancelled = await ref
          .read(aiAgentRepositoryProvider)
          .cancelActionDraft(draft.id);
      if (!mounted) return;
      setState(() => _actionDraft = cancelled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.aiActionCancelled),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.aiActionInvalid)),
      );
    }
  }

  Future<void> _confirmActionDraft() async {
    final draft = _actionDraft;
    if (draft == null) return;
    try {
      final confirmed = await ref
          .read(aiAgentRepositoryProvider)
          .confirmActionDraft(draft.id);
      if (!mounted) return;
      setState(() => _actionDraft = confirmed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.aiActionExecutionDisabled,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final message =
          error is AiAgentException &&
              error.code == 'MIZAN_AI_ACTION_NOT_ENABLED'
          ? l10n.aiActionExecutionDisabled
          : l10n.aiActionInvalid;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _draftStatusLabel(AppLocalizations l10n, String status) {
    return switch (status) {
      'pending' => l10n.aiActionDraftPending,
      'confirmed' => l10n.aiActionDraftConfirmed,
      'cancelled' => l10n.aiActionDraftCancelled,
      _ => l10n.aiActionInvalid,
    };
  }

  String _actionTypeLabel(AppLocalizations l10n, String actionType) {
    return switch (actionType) {
      'invoice_draft' => l10n.aiActionTypeInvoice,
      'bill_draft' => l10n.aiActionTypeBill,
      'customer_draft' => l10n.aiActionTypeCustomer,
      'vendor_draft' => l10n.aiActionTypeVendor,
      'staff_invitation_batch_draft' => l10n.aiActionTypeStaffInvitation,
      _ => l10n.aiActionPreview,
    };
  }

  Widget _buildActionDraftCard(BuildContext context, AppLocalizations l10n) {
    final draft = _actionDraft!;
    final prettyPayload = const JsonEncoder.withIndent(
      '  ',
    ).convert(draft.payload);
    final canAct =
        draft.status == 'pending' &&
        (draft.expiresAt == null || draft.expiresAt!.isAfter(DateTime.now()));
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _actionTypeLabel(l10n, draft.actionType),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(_draftStatusLabel(l10n, draft.status))),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.aiActionDraftForReview),
            const SizedBox(height: 8),
            SelectableText(prettyPayload),
            if (canAct) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _cancelActionDraft,
                    child: Text(l10n.aiActionCancelDraft),
                  ),
                  FilledButton(
                    onPressed: _confirmActionDraft,
                    child: Text(l10n.aiActionConfirmDraft),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _composerController.text.trim();
    if (text.isEmpty || _isSending) return;

    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final isCloudMode = ref.read(cloudDataModeProvider);
    if (!isCloudMode) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.aiAssistantGuestMode)));
      return;
    }

    _composerController.clear();
    setState(() {
      _messages.add(AiChatMessage(role: 'user', content: text));
      _isSending = true;
    });
    _scrollToEnd();

    try {
      final response = await ref
          .read(aiAgentRepositoryProvider)
          .sendMessage(
            message: text,
            locale: locale,
            conversationId: _conversationId,
          );
      if (!mounted) return;
      setState(() {
        _conversationId = response.conversationId;
        _messages.add(
          AiChatMessage(role: 'assistant', content: response.message),
        );
      });
    } catch (error) {
      if (!mounted) return;
      final message = error is AiGuestModeException
          ? l10n.aiAssistantSignInRequired
          : l10n.aiAssistantError;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToEnd();
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCloudMode = ref.watch(cloudDataModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiAssistantTitle),
        actions: [
          IconButton(
            tooltip: l10n.aiActionPreview,
            onPressed: isCloudMode && !_isCreatingDraft
                ? _openDraftComposer
                : null,
            icon: _isCreatingDraft
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fact_check_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n, isCloudMode),
            if (_actionDraft != null) _buildActionDraftCard(context, l10n),
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(context, l10n, isCloudMode)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) =>
                          _MessageBubble(message: _messages[index]),
                    ),
            ),
            if (_isSending)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.aiAssistantThinking,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            _buildComposer(context, l10n, isCloudMode),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    bool isCloudMode,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.aiAssistantReadOnly,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(l10n.aiAssistantIntro),
          if (!isCloudMode) ...[
            const SizedBox(height: 12),
            Text(l10n.aiAssistantGuestMode),
            if (widget.onConnectAccount != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton(
                  onPressed: widget.onConnectAccount,
                  child: Text(l10n.aiAssistantConnectAccount),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    bool isCloudMode,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          isCloudMode
              ? l10n.aiAssistantInputHint
              : l10n.aiAssistantSignInRequired,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildComposer(
    BuildContext context,
    AppLocalizations l10n,
    bool isCloudMode,
  ) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _composerController,
                minLines: 1,
                maxLines: 5,
                enabled: isCloudMode && !_isSending,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: l10n.aiAssistantInputHint,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: l10n.aiAssistantSend,
              onPressed: isCloudMode && !_isSending ? _send : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SelectableText(
          message.content,
          style: TextStyle(
            color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
