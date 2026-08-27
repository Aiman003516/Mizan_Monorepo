import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

final _partyStatementProvider = FutureProvider.autoDispose
    .family<List<PartyStatementEntry>, String>((ref, request) {
      final separator = request.indexOf('|');
      if (separator <= 0 || separator == request.length - 1) {
        throw ArgumentError('Invalid party statement request');
      }
      final partyType = request.substring(0, separator);
      final partyId = request.substring(separator + 1);
      return ref
          .read(partyStatementRepositoryProvider)
          .fetchStatement(partyType: partyType, partyId: partyId);
    });

class PartyStatementScreen extends ConsumerWidget {
  const PartyStatementScreen({
    super.key,
    required this.partyType,
    required this.partyId,
    this.partyName,
  });

  final String partyType;
  final String partyId;
  final String? partyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statement = ref.watch(_partyStatementProvider('$partyType|$partyId'));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.partyStatement)),
      body: statement.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _StatementMessage(
          icon: Icons.error_outline,
          message: l10n.statementLoadFailed,
          action: TextButton(
            onPressed: () =>
                ref.invalidate(_partyStatementProvider('$partyType|$partyId')),
            child: Text(l10n.retry),
          ),
        ),
        data: (entries) => _StatementBody(
          partyName: partyName,
          entries: entries,
          partyType: partyType,
        ),
      ),
    );
  }
}

class _StatementBody extends StatelessWidget {
  const _StatementBody({
    this.partyName,
    required this.entries,
    required this.partyType,
  });

  final String? partyName;
  final List<PartyStatementEntry> entries;
  final String partyType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (entries.isEmpty) {
      return _StatementMessage(
        icon: Icons.receipt_long_outlined,
        message: l10n.statementNoEntries,
      );
    }
    final currencyCode = entries.first.currencyCode;
    final endingBalance = entries.last.runningBalanceMinor;
    return RefreshIndicator(
      onRefresh: () async {
        // The provider is invalidated by the parent on a route refresh.
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (partyName != null && partyName!.trim().isNotEmpty) ...[
            Text(partyName!, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
          ],
          Text(
            '${l10n.statement} · ${partyType == 'customer' ? l10n.receivables : l10n.payables}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l10n.statementRunningBalance)),
                  Text(
                    CurrencyFormatter.formatAmount(endingBalance, currencyCode),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...entries.map((entry) => _StatementEntryCard(entry: entry)),
        ],
      ),
    );
  }
}

class _StatementEntryCard extends StatelessWidget {
  const _StatementEntryCard({required this.entry});

  final PartyStatementEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final debit = entry.debitMinor > 0;
    final amount = debit ? entry.debitMinor : entry.creditMinor;
    final source = switch (entry.sourceType) {
      'invoice' => l10n.statementInvoice,
      'bill' => l10n.statementBill,
      'settlement' => l10n.statementSettlement,
      'balance_adjustment' => l10n.statementBalanceAdjustment,
      _ => entry.sourceType,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(debit ? Icons.arrow_downward : Icons.arrow_upward),
        ),
        title: Text(entry.reference.isEmpty ? source : entry.reference),
        subtitle: Text(
          '${entry.entryDate.toLocal().toString().split(' ').first} · $source\n${entry.description}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 132),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatAmount(amount, entry.currencyCode),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                CurrencyFormatter.formatAmount(
                  entry.runningBalanceMinor,
                  entry.currencyCode,
                ),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatementMessage extends StatelessWidget {
  const _StatementMessage({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}
