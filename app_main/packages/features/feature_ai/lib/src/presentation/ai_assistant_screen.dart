import 'dart:convert';

import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_agent_repository.dart';
import '../local_ai/local_ai_engine.dart';
import '../local_ai/local_ai_knowledge_base.dart';
import '../local_ai/local_ai_navigation.dart';
import '../local_ai/local_ai_proposal.dart';
import '../local_ai/local_ai_provider.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key, this.onConnectAccount, this.onNavigate});

  final VoidCallback? onConnectAccount;
  final ValueChanged<LocalAiNavigationTarget>? onNavigate;

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
  String? _confirmationToken;
  bool _isSending = false;
  bool _isCreatingDraft = false;
  LocalAiProposal? _localProposal;
  LocalAiNavigationTarget? _localNavigationTarget;
  String? _localFallbackWarning;

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
                              DropdownMenuItem(
                                value: 'customer_update',
                                child: Text(l10n.aiActionTypeCustomerUpdate),
                              ),
                              DropdownMenuItem(
                                value: 'vendor_update',
                                child: Text(l10n.aiActionTypeVendorUpdate),
                              ),
                              DropdownMenuItem(
                                value: 'invoice_update',
                                child: Text(l10n.aiActionTypeInvoiceUpdate),
                              ),
                              DropdownMenuItem(
                                value: 'bill_update',
                                child: Text(l10n.aiActionTypeBillUpdate),
                              ),
                              DropdownMenuItem(
                                value: 'balance_adjustment',
                                child: Text(l10n.aiActionTypeBalanceAdjustment),
                              ),
                              DropdownMenuItem(
                                value: 'journal_entry_post',
                                child: Text(l10n.aiActionTypeJournalPost),
                              ),
                              DropdownMenuItem(
                                value: 'customer_archive',
                                child: Text(l10n.aiActionTypeCustomerArchive),
                              ),
                              DropdownMenuItem(
                                value: 'vendor_archive',
                                child: Text(l10n.aiActionTypeVendorArchive),
                              ),
                              DropdownMenuItem(
                                value: 'invoice_void',
                                child: Text(l10n.aiActionTypeInvoiceVoid),
                              ),
                              DropdownMenuItem(
                                value: 'bill_void',
                                child: Text(l10n.aiActionTypeBillVoid),
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
      setState(() {
        _actionDraft = draft;
        _confirmationToken = draft.confirmationToken;
      });
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
      setState(() {
        _actionDraft = cancelled;
        _confirmationToken = null;
      });
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
    final token = _confirmationToken;
    if (draft == null) return;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.aiActionConfirmationRequired,
          ),
        ),
      );
      return;
    }
    try {
      final confirmed = await ref
          .read(aiAgentRepositoryProvider)
          .confirmActionDraft(
            actionRequestId: draft.id,
            confirmationToken: token,
          );
      if (!mounted) return;
      setState(() {
        _actionDraft = confirmed;
        _confirmationToken = null;
      });
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            confirmed.status == 'executed'
                ? l10n.aiActionExecuted
                : l10n.aiActionExecutionFailed,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final message =
          error is AiAgentException && error.code == 'MIZAN_AI_ACTION_HTTP_400'
          ? l10n.aiActionConfirmationRequired
          : l10n.aiActionExecutionFailed;
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
      'executed' => l10n.aiActionExecuted,
      'failed' => l10n.aiActionExecutionFailed,
      'expired' => l10n.aiActionInvalid,
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
      'customer_update' => l10n.aiActionTypeCustomerUpdate,
      'vendor_update' => l10n.aiActionTypeVendorUpdate,
      'invoice_update' => l10n.aiActionTypeInvoiceUpdate,
      'bill_update' => l10n.aiActionTypeBillUpdate,
      'balance_adjustment' => l10n.aiActionTypeBalanceAdjustment,
      'journal_entry_post' => l10n.aiActionTypeJournalPost,
      'customer_archive' => l10n.aiActionTypeCustomerArchive,
      'vendor_archive' => l10n.aiActionTypeVendorArchive,
      'invoice_void' => l10n.aiActionTypeInvoiceVoid,
      'bill_void' => l10n.aiActionTypeBillVoid,
      _ => actionType,
    };
  }

  Widget _buildActionDraftCard(BuildContext context, AppLocalizations l10n) {
    final draft = _actionDraft!;
    final prettyPayload = const JsonEncoder.withIndent(
      '  ',
    ).convert(draft.payload);
    final canAct =
        draft.status == 'pending' &&
        _confirmationToken != null &&
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
            Text(
              draft.status == 'executed'
                  ? l10n.aiActionExecuted
                  : l10n.aiActionDraftForReview,
            ),
            if (draft.actionType == 'balance_adjustment' ||
                draft.actionType == 'journal_entry_post') ...[
              const SizedBox(height: 8),
              Text(
                l10n.aiActionFinancialWarning,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (draft.actionType == 'customer_archive' ||
                draft.actionType == 'vendor_archive' ||
                draft.actionType == 'invoice_void' ||
                draft.actionType == 'bill_void') ...[
              const SizedBox(height: 8),
              Text(
                l10n.aiActionCannotDeletePosted,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            SelectableText(prettyPayload),
            if (draft.executionResult != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                const JsonEncoder.withIndent(
                  '  ',
                ).convert(draft.executionResult),
              ),
            ],
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

  String _localResponse(
    LocalAiProposal proposal,
    String locale,
    AppLocalizations l10n,
  ) {
    if (proposal.intent == LocalAiIntent.navigate && proposal.route != null) {
      final target = LocalAiNavigationCatalog.destinations.firstWhere(
        (item) => item.id == proposal.route,
      );
      return l10n.aiLocalNavigationSuggestion(target.labelFor(locale));
    }
    if (proposal.intent == LocalAiIntent.explain) {
      final query = proposal.fields['query'];
      final chunks = LocalAiKnowledgeBase.search(
        query is String ? query : '',
        locale: locale,
      );
      if (chunks.isNotEmpty) {
        return chunks
            .map(
              (chunk) => '${chunk.titleFor(locale)}: ${chunk.bodyFor(locale)}',
            )
            .join('\n\n');
      }
      return l10n.aiLocalExplanation;
    }
    if (proposal.isMutation) return l10n.aiLocalProposalNotExecuted;
    if (proposal.intent == LocalAiIntent.requestMissingInformation) {
      return l10n.aiLocalNeedDetails;
    }
    return l10n.aiLocalUnavailable;
  }

  Widget _buildLocalFallbackBanner() {
    final warning = _localFallbackWarning;
    if (warning == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade700),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade900),
          const SizedBox(width: 8),
          Expanded(child: Text(warning)),
        ],
      ),
    );
  }

  Widget _buildLocalNavigationCard(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final target = _localNavigationTarget;
    if (target == null) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ListTile(
        leading: const Icon(Icons.open_in_new),
        title: Text(
          l10n.aiLocalNavigationSuggestion(
            target.labelFor(Localizations.localeOf(context).languageCode),
          ),
        ),
        trailing: FilledButton.tonal(
          onPressed: widget.onNavigate == null
              ? null
              : () {
                  widget.onNavigate!(target);
                  if (mounted) setState(() => _localNavigationTarget = null);
                },
          child: Text(l10n.aiLocalNavigate),
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

    _composerController.clear();
    setState(() {
      _localProposal = null;
      _localNavigationTarget = null;
      _localFallbackWarning = null;
      _messages.add(AiChatMessage(role: 'user', content: text));
      _isSending = true;
    });
    _scrollToEnd();

    if (!isCloudMode) {
      try {
        final result = await ref
            .read(localAiEngineProvider)
            .propose(LocalAiRequest(text: text, locale: locale));
        if (!mounted) return;
        if (result.isReady) {
          final proposal = result.proposal!;
          final target = proposal.route == null
              ? null
              : LocalAiNavigationCatalog.destinations
                    .cast<LocalAiNavigationTarget?>()
                    .firstWhere(
                      (item) => item?.id == proposal.route,
                      orElse: () => null,
                    );
          setState(() {
            _localProposal = proposal;
            _localNavigationTarget = target;
            _localFallbackWarning = result.usedSafeFallback
                ? l10n.aiLocalFallbackWarning
                : null;
            _messages.add(
              AiChatMessage(
                role: 'assistant',
                content: _localResponse(proposal, locale, l10n),
              ),
            );
          });
        } else {
          setState(() {
            _messages.add(
              AiChatMessage(
                role: 'assistant',
                content: result.localizedMessage(l10n),
              ),
            );
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _messages.add(
              AiChatMessage(
                role: 'assistant',
                content: l10n.aiLocalUnavailable,
              ),
            );
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isSending = false);
          _scrollToEnd();
        }
      }
      return;
    }

    try {
      final response = await ref
          .read(aiAgentRepositoryProvider)
          .sendMessage(
            message: text,
            locale: locale,
            conversationId: _conversationId,
          );
      if (!mounted) return;
      final proposal = response.actionProposal;
      setState(() {
        _conversationId = response.conversationId;
        _messages.add(
          AiChatMessage(role: 'assistant', content: response.message),
        );
      });
      if (proposal != null && proposal.requiresConfirmation) {
        await _createActionDraft(proposal.actionType, proposal.payload);
      }
    } catch (error) {
      if (!mounted) return;
      final message = _aiErrorMessage(error, l10n);
      setState(() {
        _messages.add(AiChatMessage(role: 'assistant', content: message));
      });
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

  String _aiErrorMessage(Object error, AppLocalizations l10n) {
    if (error is AiGuestModeException) return l10n.aiAssistantSignInRequired;
    if (error is AiAgentException) {
      final code = error.code;
      if (code.contains('404') || error.message.contains('not deployed')) {
        return l10n.aiAssistantUnavailable;
      }
      if (code.contains('401') || code.contains('AUTH')) {
        return l10n.aiAssistantSignInRequired;
      }
      if (code.contains('403') || code.contains('PERMISSION')) {
        return l10n.aiAssistantPermissionDenied;
      }
      if (code.contains('408') || code.contains('429') || code.contains('5')) {
        return l10n.aiAssistantRetryLater;
      }
      if (code.contains('INVALID_MESSAGE') || code.contains('UNSUPPORTED')) {
        return l10n.aiAssistantRequestUnsupported;
      }
    }
    return l10n.aiAssistantError;
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
            if (_localFallbackWarning != null) _buildLocalFallbackBanner(),
            if (_localProposal?.intent == LocalAiIntent.navigate)
              _buildLocalNavigationCard(context, l10n),
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
          isCloudMode ? l10n.aiAssistantInputHint : l10n.aiLocalNoCloud,
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
                enabled: !_isSending,
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
              onPressed: !_isSending ? _send : null,
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
