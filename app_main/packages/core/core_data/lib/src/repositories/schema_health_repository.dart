import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final schemaHealthRepositoryProvider = Provider<SchemaHealthRepository>(
  (ref) => SchemaHealthRepository(Supabase.instance.client),
);

class SchemaHealthCheck {
  const SchemaHealthCheck({
    required this.code,
    required this.severity,
    required this.passed,
    required this.observedCount,
    required this.details,
  });

  final String code;
  final String severity;
  final bool passed;
  final int observedCount;
  final String details;

  factory SchemaHealthCheck.fromJson(Map<String, dynamic> json) {
    return SchemaHealthCheck(
      code: json['check_code']?.toString() ?? 'unknown',
      severity: json['severity']?.toString() ?? 'info',
      passed: json['passed'] == true,
      observedCount: (json['observed_count'] as num?)?.toInt() ?? 0,
      details: json['details']?.toString() ?? '',
    );
  }
}

class SchemaHealthReport {
  const SchemaHealthReport(this.checks);

  final List<SchemaHealthCheck> checks;

  bool get hasCriticalFailure =>
      checks.any((check) => !check.passed && check.severity == 'critical');

  bool get hasFailure => checks.any((check) => !check.passed);

  int get passedCount => checks.where((check) => check.passed).length;
}

class SchemaHealthRepository {
  const SchemaHealthRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<SchemaHealthReport> run() async {
    final response = await _supabase.rpc('run_schema_health_check');
    if (response is! List) {
      throw const FormatException(
        'Schema health returned an invalid response.',
      );
    }
    final checks = response
        .whereType<Map>()
        .map(
          (row) => SchemaHealthCheck.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
    return SchemaHealthReport(checks);
  }
}
