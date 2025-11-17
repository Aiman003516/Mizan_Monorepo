import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_accounts/src/data/accounts_repository.dart';

final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  final accountsRepository = ref.watch(accountsRepositoryProvider);
  return accountsRepository.watchAccounts();
});

final allAccountsStreamProvider = StreamProvider<List<Account>>((ref) {
  final accountsRepository = ref.watch(accountsRepositoryProvider);
  return accountsRepository.watchAllAccounts();
});