import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_products/src/data/database_provider.dart';



final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoriesRepository(db);
});

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoriesRepositoryProvider).watchCategories();
});

class CategoriesRepository {
  CategoriesRepository(this._db);
  final AppDatabase _db;

  Stream<List<Category>> watchCategories() {
    return (_db.select(_db.categories)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<void> createCategory({required String name, String? imagePath}) {
    final companion = CategoriesCompanion.insert(
      name: name,
      imagePath: Value(imagePath),
    );
    return _db.into(_db.categories).insert(companion);
  }

  // Logic moved from database.dart
  Future<void> updateCategory(Category original, {required String newName, String? newImagePath}) {
    final companion = original.toCompanion(false).copyWith(
          name: Value(newName),
          imagePath: Value(newImagePath),
          lastUpdated: Value(DateTime.now()),
        );
    return _db.update(_db.categories).replace(companion);
  }

  Future<void> deleteCategory(String id) {
    return (_db.delete(_db.categories)..where((tbl) => tbl.id.equals(id))).go();
  }
}