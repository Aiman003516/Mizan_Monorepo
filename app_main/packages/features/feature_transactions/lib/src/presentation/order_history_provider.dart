import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_transactions/src/data/transactions_repository.dart';

final posSalesHistoryProvider = StreamProvider<List<Transaction>>((ref) {
  final transactionsRepo = ref.watch(transactionsRepositoryProvider);

  return transactionsRepo.watchAllTransactions().map((allTransactions) {
    return allTransactions.where((t) {
      final isPosSale = t.description.startsWith('POS Sale');
      final isOriginalSale = t.relatedTransactionId == null;
      return isPosSale && isOriginalSale;
    }).toList();
  });
});

final posReturnsProvider = StreamProvider<List<Transaction>>((ref) {
  final transactionsRepo = ref.watch(transactionsRepositoryProvider);

  return transactionsRepo.watchAllTransactions().map((allTransactions) {
    return allTransactions.where((t) {
      return t.relatedTransactionId != null &&
          (t.description.startsWith('Return for') || t.description.startsWith('Partial Return for'));
    }).toList();
  });
});