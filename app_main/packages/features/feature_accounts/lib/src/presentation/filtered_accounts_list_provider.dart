import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_accounts/src/data/accounts_repository.dart';

final filteredAccountsProvider =
StreamProvider.family<List<Account>, String>((ref, classificationName) async* {
  final accountsRepo = ref.watch(accountsRepositoryProvider);
  final classificationId = await accountsRepo.getClassificationIdByName(classificationName);

  if (classificationId != null) {
    yield* accountsRepo.watchAccountsByClassification(classificationId);
  } else {
    yield [];
  }
});