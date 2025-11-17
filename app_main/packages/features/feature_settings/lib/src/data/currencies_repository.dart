import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';

// This provider must be overridden in app_mizan
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden');
});

final currenciesRepositoryProvider = Provider<CurrenciesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CurrenciesRepository(db);
});

final currenciesStreamProvider = StreamProvider<List<Currency>>((ref) {
  return ref.watch(currenciesRepositoryProvider).watchCurrencies();
});

class CurrenciesRepository {
  CurrenciesRepository(this._db);
  final AppDatabase _db;

  Stream<List<Currency>> watchCurrencies() {
    return (_db.select(_db.currencies)
      ..orderBy([(t) => OrderingTerm.asc(t.code)]))
        .watch();
  }

  Future<void> createCurrency({
    required String code,
    required String name,
    String? symbol,
  }) {
    final companion = CurrenciesCompanion.insert(
      code: code,
      name: name,
      symbol: Value(symbol),
    );
    return _db.into(_db.currencies).insert(companion);
  }

  // Logic moved from database.dart
  Future<void> updateCurrency(Currency currency) {
    return _db.update(_db.currencies).replace(
        currency.toCompanion(false).copyWith(lastUpdated: Value(DateTime.now())));
  }

  Future<void> deleteCurrency(String id) {
    return (_db.delete(_db.currencies)..where((tbl) => tbl.id.equals(id))).go();
  }
}