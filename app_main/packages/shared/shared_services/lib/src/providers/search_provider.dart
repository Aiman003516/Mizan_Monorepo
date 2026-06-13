import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global search query provider shared across all features.
/// Moved here from feature_dashboard to eliminate circular dependencies.
final mainDashboardSearchProvider = StateProvider<String>((ref) => '');
