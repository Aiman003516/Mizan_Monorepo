import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LedgerControlScreen extends ConsumerStatefulWidget {
  const LedgerControlScreen({super.key});

  @override
  ConsumerState<LedgerControlScreen> createState() =>
      _LedgerControlScreenState();
}

class _LedgerControlScreenState extends ConsumerState<LedgerControlScreen> {
  late Future<
    ({
      List<AccountingPeriod> periods,
      List<TaxCode> taxCodes,
      List<ChartAccount> accounts,
    })
  >
  _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<
    ({
      List<AccountingPeriod> periods,
      List<TaxCode> taxCodes,
      List<ChartAccount> accounts,
    })
  >
  _load() async {
    final repository = ref.read(accountingLedgerRepositoryProvider);
    final values = await Future.wait([
      repository.listPeriods(),
      repository.listTaxCodes(),
      repository.listAccounts(),
    ]);
    return (
      periods: values[0] as List<AccountingPeriod>,
      taxCodes: values[1] as List<TaxCode>,
      accounts: values[2] as List<ChartAccount>,
    );
  }

  Future<void> _refresh() async {
    setState(() => _loadFuture = _load());
    await _loadFuture;
  }

  Future<void> _closePeriod(AccountingPeriod period) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.closePeriod),
        content: Text(
          '${period.name}\n${period.startsOn.toLocal().toIso8601String().split('T').first} – ${period.endsOn.toLocal().toIso8601String().split('T').first}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.closePeriod),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(accountingLedgerRepositoryProvider).closePeriod(period.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.periodClosed)));
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.periodCloseFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<
      ({
        List<AccountingPeriod> periods,
        List<TaxCode> taxCodes,
        List<ChartAccount> accounts,
      })
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
              label: Text(l10n.ledgerLoadFailed),
            ),
          );
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.ledgerControlIntro),
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: l10n.accountingPeriods,
                icon: Icons.calendar_month_outlined,
                children: data.periods.isEmpty
                    ? [Text(l10n.noPeriods)]
                    : [
                        for (final period in data.periods)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(period.name),
                            subtitle: Text(
                              '${period.startsOn.toLocal().toIso8601String().split('T').first} – ${period.endsOn.toLocal().toIso8601String().split('T').first}',
                            ),
                            leading: Icon(
                              period.isLocked
                                  ? Icons.lock_outline
                                  : Icons.lock_open_outlined,
                            ),
                            trailing: period.status == 'open'
                                ? TextButton(
                                    onPressed: () => _closePeriod(period),
                                    child: Text(l10n.closePeriod),
                                  )
                                : Chip(label: Text(period.status)),
                          ),
                      ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: l10n.chartOfAccounts,
                icon: Icons.account_tree_outlined,
                children: data.accounts.isEmpty
                    ? [Text(l10n.noAccounts)]
                    : [
                        for (final account in data.accounts)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${account.code} — ${account.name}'),
                            subtitle: Text(
                              '${account.accountType} · ${account.normalBalance} · ${account.currencyCode}',
                            ),
                          ),
                      ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: l10n.taxCodes,
                icon: Icons.receipt_long_outlined,
                children: data.taxCodes.isEmpty
                    ? [Text(l10n.noTaxCodes)]
                    : [
                        for (final tax in data.taxCodes)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${tax.code} — ${tax.name}'),
                            subtitle: Text(
                              '${tax.ratePercent.toStringAsFixed(2)}% · ${tax.isInclusive ? l10n.taxInclusive : l10n.taxExclusive}',
                            ),
                          ),
                      ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}
