import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// UPDATED Local Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_reports/src/data/reports_service.dart';

class TotalClassificationsScreen extends ConsumerWidget {
  const TotalClassificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(totalClassificationsSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.totalClassifications),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            tooltip: l10n.exportToPDF,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(l10n.classification,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(l10n.debit,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  flex: 2,
                  child: Text(l10n.credit,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  flex: 2,
                  child: Text(l10n.total,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: summaryAsync.when(
              data: (summaries) {
                if (summaries.isEmpty) {
                  return Center(child: Text(l10n.noClassificationTotals));
                }

                return ListView.builder(
                  itemCount: summaries.length,
                  itemBuilder: (context, index) {
                    final summary = summaries[index];
                    final isDebitBalance = summary.netBalance >= 0;
                    final balanceColor =
                    isDebitBalance ? Colors.green : Colors.red;

                    return ListTile(
                      title: Text(summary.name),
                      subtitle: Text('${l10n.currencyLabel} ${summary.currencyCode}',
                          style:
                          TextStyle(color: Theme.of(context).primaryColor)),
                      trailing: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                summary.totalDebit.toStringAsFixed(2),
                                style: const TextStyle(color: Colors.green),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                summary.totalCredit.toStringAsFixed(2),
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                summary.netBalance.abs().toStringAsFixed(2),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: balanceColor),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {},
                    );
                  },
                );
              },
              error: (err, stack) =>
                  Center(child: Text('${l10n.error} ${err.toString()}')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}