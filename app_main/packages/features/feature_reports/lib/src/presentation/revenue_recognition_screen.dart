import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _revenueScheduleProvider =
    FutureProvider.autoDispose<List<RevenueScheduleLine>>(
      (ref) => ref.read(revenueRecognitionRepositoryProvider).listSchedule(),
    );

class RevenueRecognitionScreen extends ConsumerWidget {
  const RevenueRecognitionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final schedule = ref.watch(_revenueScheduleProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.revenueRecognition)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_revenueScheduleProvider.future),
        child: schedule.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(
                Icons.error_outline,
                size: 44,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.revenueRecognitionLoadFailed,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          data: (lines) => lines.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Icon(
                      Icons.event_note,
                      size: 52,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.revenueRecognitionNoSchedules,
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lines.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(l10n.revenueRecognitionIntro),
                        ),
                      );
                    }
                    final line = lines[index - 1];
                    return _ScheduleLineCard(
                      line: line,
                      onCreateDraft: line.isReady
                          ? () => _createDraft(context, ref, line)
                          : null,
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _createDraft(
    BuildContext context,
    WidgetRef ref,
    RevenueScheduleLine line,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text:
          'REV-${line.contractNumber}-${line.recognitionOn.year}${line.recognitionOn.month.toString().padLeft(2, '0')}',
    );
    final entryNumber = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.revenueRecognitionCreateDraft),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.journalEntryNumber),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.createDraft),
          ),
        ],
      ),
    );
    controller.dispose();
    if (entryNumber == null || entryNumber.isEmpty || !context.mounted) return;
    try {
      await ref
          .read(revenueRecognitionRepositoryProvider)
          .createRecognitionDraft(
            scheduleLineId: line.id,
            entryNumber: entryNumber,
          );
      ref.invalidate(_revenueScheduleProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.revenueRecognitionDraftCreated)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.revenueRecognitionDraftFailed)),
        );
      }
    }
  }
}

class _ScheduleLineCard extends StatelessWidget {
  const _ScheduleLineCard({required this.line, required this.onCreateDraft});

  final RevenueScheduleLine line;
  final VoidCallback? onCreateDraft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amount = '${line.amountMinor / 100} ${line.currencyCode}';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(line.isReady ? Icons.schedule : Icons.check),
        ),
        title: Text(
          '${line.contractNumber} · ${line.recognitionOn.toLocal().toString().split(' ').first}',
        ),
        subtitle: Text('$amount · ${_localizedStatus(l10n, line.status)}'),
        trailing: onCreateDraft == null
            ? null
            : OutlinedButton(
                onPressed: onCreateDraft,
                child: Text(l10n.revenueRecognitionCreateDraft),
              ),
      ),
    );
  }

  String _localizedStatus(AppLocalizations l10n, String status) {
    switch (status) {
      case 'draft_created':
        return l10n.revenueRecognitionDraftStatus;
      case 'recognized':
        return l10n.revenueRecognitionRecognizedStatus;
      case 'cancelled':
        return l10n.cancelled;
      default:
        return l10n.revenueRecognitionPlannedStatus;
    }
  }
}
