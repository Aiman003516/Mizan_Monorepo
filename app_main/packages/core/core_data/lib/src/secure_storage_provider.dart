import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provider for FlutterSecureStorage
final flutterSecureStorageProvider =
    Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());