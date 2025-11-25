import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/src/database.dart';

/// The central Source of Truth for the AppDatabase.
/// All features should watch this provider.
/// 
/// In the Bootstrap phase (main.dart), we will override this 
/// with the actual initialized database instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider must be overridden in main.dart');
});