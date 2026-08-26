import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _receivablesAgingProvider =
    FutureProvider.autoDispose<List<ArApAgingEntry>>(
      (ref) => ref.read(arApSettlementRepositoryProvider).receivablesAging(),
    );
final _payablesAgingProvider = FutureProvider.autoDispose<List<ArApAgingEntry>>(
  (ref) => ref.read(arApSettlementRepositoryProvider).payablesAging(),
);
final _settlementAccountsProvider =
    FutureProvider.autoDispose<List<ChartAccount>>(
      (ref) => ref.read(accountingLedgerRepositoryProvider).listAccounts(),
    );

class ArApAgingScreen extends ConsumerWidget {
  const ArApAgingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.arApAging),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.receivables),
              Tab(text: l10n.payables),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AgingList(
              entries: ref.watch(_receivablesAgingProvider),
              refresh: () => ref.refresh(_receivablesAgingProvider.future),
              receivable: true,
            ),
            _AgingList(
              entries: ref.watch(_payablesAgingProvider),
              refresh: () => ref.refresh(_payablesAgingProvider.future),
              receivable: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _AgingList extends ConsumerWidget {
  const _AgingList({
    required this.entries,
    required this.refresh,
    required this.receivable,
  });

  final AsyncValue<List<ArApAgingEntry>> entries;
  final Future<void> Function() refresh;
  final bool receivable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: refresh,
      child: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(l10n.arApAgingLoadFailed, textAlign: TextAlign.center),
          ],
        ),
        data: (items) => items.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    l10n.arApAgingNoOutstanding,
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _AgingCard(
                  entry: items[index],
                  onSettle: () => _openSettlement(context, ref, items[index]),
                ),
              ),
      ),
    );
  }

  Future<void> _openSettlement(
    BuildContext context,
    WidgetRef ref,
    ArApAgingEntry entry,
  ) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _SettlementDialog(entry: entry, receivable: receivable),
    );
    if (created == true) {
      ref.invalidate(
        receivable ? _receivablesAgingProvider : _payablesAgingProvider,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.settlementDraftCreated),
          ),
        );
      }
    }
  }
}

class _AgingCard extends StatelessWidget {
  const _AgingCard({required this.entry, required this.onSettle});

  final ArApAgingEntry entry;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOverdue = entry.daysOverdue > 0;
    final color = isOverdue
        ? Theme.of(context).colorScheme.error
        : Colors.green;
    final amount =
        '${(entry.outstandingMinor / 100).toStringAsFixed(2)} ${entry.currencyCode}';
    final bucket = switch (entry.agingBucket) {
      '1_30' => l10n.aging1To30,
      '31_60' => l10n.aging31To60,
      '61_90' => l10n.aging61To90,
      'over_90' => l10n.agingOver90,
      _ => l10n.current,
    };
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(
            isOverdue ? Icons.warning_amber : Icons.schedule,
            color: color,
          ),
        ),
        title: Text(entry.documentNumber),
        subtitle: Text(
          '${entry.dueDate.toLocal().toString().split(' ').first} · $bucket',
        ),
        trailing: SizedBox(
          width: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (isOverdue)
                Text(
                  '${entry.daysOverdue} ${l10n.daysOverdue}',
                  style: TextStyle(color: color, fontSize: 12),
                ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: onSettle,
                  child: Text(l10n.createSettlementDraft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettlementDialog extends ConsumerStatefulWidget {
  const _SettlementDialog({required this.entry, required this.receivable});

  final ArApAgingEntry entry;
  final bool receivable;

  @override
  ConsumerState<_SettlementDialog> createState() => _SettlementDialogState();
}

class _SettlementDialogState extends ConsumerState<_SettlementDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _entryController;
  late final TextEditingController _methodController;
  late final TextEditingController _referenceController;
  String? _cashAccountId;
  String? _counterpartyAccountId;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: (widget.entry.outstandingMinor / 100).toStringAsFixed(2),
    );
    _entryController = TextEditingController(
      text:
          'SET-${widget.entry.documentNumber}-${DateTime.now().millisecondsSinceEpoch}',
    );
    _methodController = TextEditingController(text: 'Cash');
    _referenceController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _entryController.dispose();
    _methodController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accounts = ref.watch(_settlementAccountsProvider);
    return AlertDialog(
      title: Text(l10n.createSettlementDraft),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: accounts.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Text(l10n.settlementAccountsLoadFailed),
            data: (allAccounts) {
              final cash = allAccounts
                  .where((a) => a.accountType == 'asset')
                  .toList();
              final counterpartyType = widget.receivable
                  ? 'asset'
                  : 'liability';
              final counterparties = allAccounts
                  .where((a) => a.accountType == counterpartyType)
                  .toList();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.entry.documentNumber} · ${widget.entry.currencyCode}',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.settlementAmount,
                      helperText: l10n.settlementAmountHint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _accountDropdown(
                    label: l10n.cashAccount,
                    accounts: cash,
                    value: _cashAccountId,
                    onChanged: (value) =>
                        setState(() => _cashAccountId = value),
                  ),
                  const SizedBox(height: 8),
                  _accountDropdown(
                    label: widget.receivable
                        ? l10n.receivableAccount
                        : l10n.payableAccount,
                    accounts: counterparties,
                    value: _counterpartyAccountId,
                    onChanged: (value) =>
                        setState(() => _counterpartyAccountId = value),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _methodController,
                    decoration: InputDecoration(labelText: l10n.paymentMethod),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _referenceController,
                    decoration: InputDecoration(labelText: l10n.reference),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _entryController,
                    decoration: InputDecoration(
                      labelText: l10n.journalEntryNumber,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.createDraft),
        ),
      ],
    );
  }

  Widget _accountDropdown({
    required String label,
    required List<ChartAccount> accounts,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: accounts.any((account) => account.id == value)
          ? value
          : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: accounts
          .map(
            (account) => DropdownMenuItem<String>(
              value: account.id,
              child: Text(
                '${account.code} · ${account.name}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    final amountMinor = amount == null ? 0 : (amount * 100).round();
    if (amountMinor <= 0 || amountMinor > widget.entry.outstandingMinor) {
      setState(
        () => _error = AppLocalizations.of(context)!.settlementAmountInvalid,
      );
      return;
    }
    if (_cashAccountId == null ||
        _counterpartyAccountId == null ||
        _methodController.text.trim().isEmpty ||
        _entryController.text.trim().isEmpty) {
      setState(
        () => _error = AppLocalizations.of(context)!.settlementFieldsRequired,
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(arApSettlementRepositoryProvider)
          .createSettlementDraft(
            direction: widget.receivable ? 'receivable' : 'payable',
            invoiceId: widget.receivable ? widget.entry.documentId : null,
            billId: widget.receivable ? null : widget.entry.documentId,
            amountMinor: amountMinor,
            currencyCode: widget.entry.currencyCode,
            paymentMethod: _methodController.text,
            reference: _referenceController.text,
            cashAccountId: _cashAccountId!,
            counterpartyAccountId: _counterpartyAccountId!,
            entryNumber: _entryController.text,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = AppLocalizations.of(context)!.settlementDraftFailed;
        });
      }
    }
  }
}
