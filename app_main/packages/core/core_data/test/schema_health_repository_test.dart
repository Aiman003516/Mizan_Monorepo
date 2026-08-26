import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses passing and failing health checks', () {
    final passing = SchemaHealthCheck.fromJson({
      'check_code': 'tenant_context',
      'severity': 'critical',
      'passed': true,
      'observed_count': 1,
      'details': 'Tenant context is available.',
    });
    final failing = SchemaHealthCheck.fromJson({
      'check_code': 'rls_enabled.customers',
      'severity': 'critical',
      'passed': false,
      'observed_count': 0,
      'details': 'RLS is not enabled.',
    });
    final report = SchemaHealthReport([passing, failing]);

    expect(report.passedCount, 1);
    expect(report.hasFailure, isTrue);
    expect(report.hasCriticalFailure, isTrue);
    expect(failing.code, 'rls_enabled.customers');
  });

  test('does not classify high-severity non-critical findings as critical', () {
    final report = SchemaHealthReport([
      SchemaHealthCheck.fromJson({
        'check_code': 'tenant_leading_index.invoices',
        'severity': 'high',
        'passed': false,
        'observed_count': 0,
        'details': 'Review query plans.',
      }),
    ]);

    expect(report.hasFailure, isTrue);
    expect(report.hasCriticalFailure, isFalse);
  });
}
