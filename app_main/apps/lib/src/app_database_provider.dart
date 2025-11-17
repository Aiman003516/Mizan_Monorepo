import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';

// This is the CONCRETE implementation of the provider.
// All feature packages that 'watch(databaseProvider)' will be
// overridden to receive this single instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});