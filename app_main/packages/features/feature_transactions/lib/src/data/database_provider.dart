import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';

// REFACTOR: Instead of defining a new abstract provider, we simply
// point to the central Core Database provider.
// This allows this feature to "plug in" automatically.
final databaseProvider = Provider<AppDatabase>((ref) {
  return ref.watch(appDatabaseProvider);
});