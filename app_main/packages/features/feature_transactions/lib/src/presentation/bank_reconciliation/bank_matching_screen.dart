import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:intl/intl.dart';

class BankMatchingScreen extends ConsumerStatefulWidget {
  const BankMatchingScreen({super.key});

  @override
  ConsumerState<BankMatchingScreen> createState() => _BankMatchingScreenState();
}

class _BankMatchingScreenState extends ConsumerState<BankMatchingScreen> {
  final AppinioSwiperController controller = AppinioSwiperController();
  List<BankTransaction> _pendingTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = ref.read(bankReconciliationRepositoryProvider);
    final data = await repo.getPendingBankTransactions();
    if (mounted) {
      setState(() {
        _pendingTransactions = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingTransactions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Bank Reconciliation")),
        body: const Center(
          child: Text("All caught up! No transactions to reconcile."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Bank Matching")),
      backgroundColor: context.appColors.border,
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Swipe RIGHT to Match, LEFT to Skip",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.appColors.subtleText),
            ),
          ),
          Expanded(
            child: AppinioSwiper(
              controller: controller,
              cardCount: _pendingTransactions.length,
              cardBuilder: (context, index) {
                final transaction = _pendingTransactions[index];
                return _buildCard(transaction);
              },
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildCard(BankTransaction transaction) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        height: 600,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance,
              size: 64,
              color: context.appColors.info,
            ),
            const SizedBox(height: 24),
            Text(
              transaction.description,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat.yMMMd().format(transaction.date),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: context.appColors.subtleText),
            ),
            const SizedBox(height: 32),
            Text(
              transaction.amount.toStringAsFixed(2),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: transaction.amount < 0 ? context.appColors.error : context.appColors.success,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.appColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb, size: 16, color: context.appColors.info),
                  const SizedBox(width: 8),
                  Text(
                    "Mizan suggests: ${ref.read(bankReconciliationRepositoryProvider).suggestCategory(transaction.description) ?? 'Uncategorized'}",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
