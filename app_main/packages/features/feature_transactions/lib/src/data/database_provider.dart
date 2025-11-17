import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';

/// The placeholder database provider for this feature.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden in main.dart');
});