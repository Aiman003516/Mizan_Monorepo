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
  final _messages = <AiChatMessage>[];
  String? _conversationId;
  bool _isSending = false;

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      appBar: AppBar(title: Text(l10n.aiAssistantTitle)),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n, isCloudMode),
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
