import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_transactions/src/data/transactions_repository.dart';

bool _hasPosSource(Transaction transaction, String source) {
  final attributes = transaction.customAttributes;
  if (attributes == null || attributes.isEmpty) return false;
  try {
    final decoded = jsonDecode(attributes);
    return decoded is Map && decoded['source'] == source;
  } catch (_) {
    return false;
  }
}

final posSalesHistoryProvider = StreamProvider<List<Transaction>>((ref) {
  final transactionsRepo = ref.watch(transactionsRepositoryProvider);

  return transactionsRepo.watchAllTransactions().map((allTransactions) {
    return allTransactions.where((transaction) {
      final markedSale = _hasPosSource(transaction, 'pos_sale');
      final legacySale = transaction.description.startsWith('POS Sale');
      return (markedSale || legacySale) &&
          transaction.relatedTransactionId == null;
    }).toList();
  });
});

final posReturnsProvider = StreamProvider<List<Transaction>>((ref) {
  final transactionsRepo = ref.watch(transactionsRepositoryProvider);

  return transactionsRepo.watchAllTransactions().map((allTransactions) {
    return allTransactions.where((transaction) {
      final markedReturn = _hasPosSource(transaction, 'pos_return');
      final legacyReturn =
          transaction.description.startsWith('Return for') ||
          transaction.description.startsWith('Partial Return for');
      return (markedReturn || legacyReturn) &&
          transaction.relatedTransactionId != null;
    }).toList();
  });
});
