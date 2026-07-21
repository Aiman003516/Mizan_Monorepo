// Ghost Money Reconciliation Screen
import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feature_settings/src/data/ghost_money_repository.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class GhostMoneyScreen extends ConsumerStatefulWidget {
  const GhostMoneyScreen({super.key});

  @override
  ConsumerState<GhostMoneyScreen> createState() => _GhostMoneyScreenState();
}

class _GhostMoneyScreenState extends ConsumerState<GhostMoneyScreen> {
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _dateFormat = DateFormat('MMM d, yyyy h:mm a');

  String _formatAmount(int amountInCents) {
    return _currencyFormat.format(amountInCents / 100);
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(ghostMoneySummaryProvider);
    final entriesAsync = ref.watch(unreconciledGhostMoneyProvider);

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ghostMoneyTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.whatIsGhostMoneyTooltip,
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Summary Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.pendingReconciliation,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  summaryAsync.when(
                    data: (summary) {
                      if (summary.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 48,
                                    color: context.appColors.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n.allBalanced,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: context.appColors.success,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.noGhostMoneyToReconcile,
                                    style: TextStyle(
                                      color: context.appColors.subtleText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: summary.entries.map((entry) {
                          final s = entry.value;
                          final isPositive = s.totalAmount > 0;

                          return SizedBox(
                            width: (MediaQuery.of(context).size.width - 44) / 2,
                            child: Card(
                              child: InkWell(
                                onTap: () => _showReconcileDialog(s),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            s.currency,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Icon(
                                            isPositive
                                                ? Icons.trending_up
                                                : Icons.trending_down,
                                            color: isPositive
                                                ? context.appColors.success
                                                : context.appColors.error,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatAmount(s.totalAmount),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: isPositive
                                                  ? context.appColors.success
                                                  : context.appColors.error,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${s.entryCount} ${s.entryCount == 1 ? l10n.entryLabel : l10n.entriesLabel}',
                                        style: TextStyle(
                                          color: context.appColors.subtleText,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),
                ],
              ),
            ),
          ),

          // Recent Entries Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                l10n.recentEntries,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Entries List
          entriesAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(l10n.noEntriesToDisplay),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final entry = entries[index];
                  final isPositive = entry.ghostAmount > 0;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPositive
                          ? context.appColors.success.withValues(alpha: 0.1)
                          : context.appColors.error.withValues(alpha: 0.1),
                      child: Icon(
                        isPositive ? Icons.add : Icons.remove,
                        color: isPositive
                            ? context.appColors.success
                            : context.appColors.error,
                        size: 20,
                      ),
                    ),
                    title: Text(_formatAmount(entry.ghostAmount)),
                    subtitle: Text(
                      '${entry.sourceType} • ${entry.reason}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      _dateFormat.format(entry.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: context.appColors.subtleText,
                      ),
                    ),
                    onTap: () => _reconcileEntry(entry.id),
                  );
                }, childCount: entries.length),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) =>
                SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.whatIsGhostMoney),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [Text(l10n.ghostMoneyDialogContent)],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.gotItBtn),
          ),
        ],
      ),
    );
  }

  void _showReconcileDialog(GhostMoneySummary summary) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reconcileAmount(summary.currency)),
        content: Text(
          l10n.writeOffConfirmation(
            _formatAmount(summary.totalAmount),
            summary.entryCount,
            summary.entryCount == 1 ? l10n.entryLabel : l10n.entriesLabel,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelBtn),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _reconcileCurrency(summary.currency);
            },
            child: Text(l10n.reconcileBtn),
          ),
        ],
      ),
    );
  }

  Future<void> _reconcileCurrency(String currency) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final repo = ref.read(ghostMoneyRepositoryProvider);
      final count = await repo.reconcileByCurrency(currency);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.reconciledEntries(count, currency)),
            backgroundColor: context.appColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    }
  }

  Future<void> _reconcileEntry(String id) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final repo = ref.read(ghostMoneyRepositoryProvider);
      await repo.reconcileEntry(id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.entryReconciled),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    }
  }
}
