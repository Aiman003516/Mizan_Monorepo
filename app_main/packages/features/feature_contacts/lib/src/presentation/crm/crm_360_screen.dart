import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Crm360Screen extends ConsumerStatefulWidget {
  const Crm360Screen({super.key});

  @override
  ConsumerState<Crm360Screen> createState() => _Crm360ScreenState();
}

class _Crm360ScreenState extends ConsumerState<Crm360Screen> {
  late Future<List<CrmCustomer360>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(crm360RepositoryProvider).listCustomer360();
  }

  Future<void> _refresh() async {
    setState(
      () => _future = ref.read(crm360RepositoryProvider).listCustomer360(),
    );
    await _future;
  }

  Future<void> _showHistory(CrmCustomer360 customer) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final items = await ref
          .read(crm360RepositoryProvider)
          .listInteractions(
            entityType: 'customer',
            entityId: customer.customerId,
          );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              customer.customerName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (items.isEmpty) Text(l10n.crm360NoInteractions),
            for (final item in items)
              ListTile(
                leading: const Icon(Icons.forum_outlined),
                title: Text(item.summary),
                subtitle: Text(
                  '${item.channel} · ${item.direction} · ${item.occurredAt.toLocal().toIso8601String().split('T').first}',
                ),
              ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.crm360HistoryFailed)));
      }
    }
  }

  Future<void> _submitQuote() async {
    final l10n = AppLocalizations.of(context)!;
    final quoteController = TextEditingController();
    final reasonController = TextEditingController();
    final result = await showDialog<({String quoteId, String reason})>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.crmQuoteApproval),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quoteController,
              decoration: InputDecoration(labelText: l10n.crmQuoteId),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.crmApprovalReason),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, (
              quoteId: quoteController.text.trim(),
              reason: reasonController.text.trim(),
            )),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    quoteController.dispose();
    reasonController.dispose();
    if (result == null || result.quoteId.isEmpty || !mounted) return;
    try {
      await ref
          .read(crm360RepositoryProvider)
          .submitQuoteForApproval(
            quoteId: result.quoteId,
            reason: result.reason,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.crmQuoteApprovalSubmitted)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.crmQuoteApprovalFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.crm360Title),
        actions: [
          IconButton(
            onPressed: _submitQuote,
            tooltip: l10n.crmQuoteApproval,
            icon: const Icon(Icons.request_quote_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<CrmCustomer360>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton.tonalIcon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.crm360LoadFailed),
              ),
            );
          }
          final customers = snapshot.data ?? const <CrmCustomer360>[];
          if (customers.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.crm360Empty),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      customer.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        Text(
                          '${l10n.crm360Outstanding}: ${customer.outstandingMinor / 100}',
                        ),
                        Text(
                          '${l10n.crm360OpenOpportunities}: ${customer.openOpportunityCount}',
                        ),
                        Text(
                          '${l10n.crm360Health}: ${customer.healthScore ?? l10n.crm360NotCalculated}',
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      onPressed: () => _showHistory(customer),
                      tooltip: l10n.crm360History,
                      icon: const Icon(Icons.history),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
