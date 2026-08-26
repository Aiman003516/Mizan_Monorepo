import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CrmPipelineScreen extends ConsumerStatefulWidget {
  const CrmPipelineScreen({super.key});

  @override
  ConsumerState<CrmPipelineScreen> createState() => _CrmPipelineScreenState();
}

class _CrmPipelineScreenState extends ConsumerState<CrmPipelineScreen> {
  late Future<
    ({List<CrmPipelineStage> stages, List<CrmOpportunity> opportunities})
  >
  _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<({List<CrmPipelineStage> stages, List<CrmOpportunity> opportunities})>
  _load() async {
    final repository = ref.read(crmPipelineRepositoryProvider);
    final stages = await repository.listStages();
    final opportunities = await repository.listOpportunities();
    return (stages: stages, opportunities: opportunities);
  }

  Future<void> _refresh() async {
    setState(() => _loadFuture = _load());
    await _loadFuture;
  }

  Future<void> _moveOpportunity(
    CrmOpportunity opportunity,
    List<CrmPipelineStage> stages,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (stages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.crmPipelineNoStages)));
      return;
    }
    var selectedStage = stages.any((stage) => stage.id == opportunity.stageId)
        ? opportunity.stageId
        : stages.first.id;
    final noteController = TextEditingController();
    final result = await showDialog<({String stageId, String note})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.crmMoveOpportunity),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedStage,
                decoration: InputDecoration(labelText: l10n.crmStage),
                items: [
                  for (final stage in stages)
                    DropdownMenuItem(value: stage.id, child: Text(stage.name)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedStage = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.crmTransitionNote,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, (
                stageId: selectedStage,
                note: noteController.text.trim(),
              )),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    noteController.dispose();
    if (result == null || !mounted) return;
    try {
      await ref
          .read(crmPipelineRepositoryProvider)
          .transitionOpportunity(
            opportunityId: opportunity.id,
            stageId: result.stageId,
            note: result.note,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.crmTransitionSaved)));
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.crmTransitionFailed)));
    }
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    return switch (status) {
      'won' => l10n.crmWon,
      'lost' => l10n.crmLost,
      'cancelled' => l10n.crmCancelled,
      _ => l10n.crmOpen,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<
      ({List<CrmPipelineStage> stages, List<CrmOpportunity> opportunities})
    >(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: FilledButton.tonalIcon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.crmPipelineLoadFailed),
            ),
          );
        }
        final data = snapshot.data!;
        if (data.opportunities.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Text(l10n.crmPipelineIntro),
                const SizedBox(height: 32),
                Icon(
                  Icons.filter_alt_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Center(child: Text(l10n.crmPipelineEmpty)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.crmPipelineIntro,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              for (final opportunity in data.opportunities)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      opportunity.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          Text(
                            '${l10n.crmStage}: ${opportunity.stageName ?? l10n.crmStage}',
                          ),
                          Text(
                            '${l10n.crmAmount}: ${opportunity.amountMinor / 100} ${opportunity.currencyCode}',
                          ),
                          Text(
                            '${l10n.crmProbability}: ${opportunity.probabilityPercent.toStringAsFixed(0)}%',
                          ),
                          Text(
                            '${l10n.crmExpectedClose}: ${opportunity.expectedCloseOn?.toLocal().toIso8601String().split('T').first ?? l10n.crmNoDate}',
                          ),
                        ],
                      ),
                    ),
                    trailing: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Chip(
                          label: Text(_statusLabel(l10n, opportunity.status)),
                        ),
                        IconButton(
                          tooltip: l10n.crmMoveOpportunity,
                          onPressed: () =>
                              _moveOpportunity(opportunity, data.stages),
                          icon: const Icon(Icons.swap_vert_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
