// FILE: packages/features/feature_accounts/lib/src/data/classifications_repository.dart

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
// FIX: Import the provider from the correct file
import 'package:feature_accounts/src/data/database_provider.dart';

final classificationsRepositoryProvider = Provider<ClassificationsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ClassificationsRepository(db);
});

final classificationsStreamProvider = StreamProvider<List<Classification>>((ref) {
  return ref.watch(classificationsRepositoryProvider).watchClassifications();
});

class ClassificationsRepository {
  ClassificationsRepository(this._db);
  final AppDatabase _db;

  Stream<List<Classification>> watchClassifications() {
    return (_db.select(_db.classifications)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<void> createClassification({required String name}) {
    final companion = ClassificationsCompanion.insert(name: name);
    return _db.into(_db.classifications).insert(companion);
  }

  Future<void> updateClassification(Classification classification) {
    return _db.update(_db.classifications).replace(
        classification.toCompanion(false).copyWith(lastUpdated: Value(DateTime.now())));
  }

  Future<void> deleteClassification(String id) {
    return (_db.delete(_db.classifications)..where((tbl) => tbl.id.equals(id))).go();
  }
}