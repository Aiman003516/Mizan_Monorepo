import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_transactions/src/data/transactions_repository.dart';

/// This is the StreamProvider our UI will watch.
final transactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  final transactionsRepository = ref.watch(transactionsRepositoryProvider);
  return transactionsRepository.watchAllTransactions();
});