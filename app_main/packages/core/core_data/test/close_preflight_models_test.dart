import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a blocking close-preflight check', () {
    final check = ClosePreflightCheck.fromJson({
      'check_code': 'draft_journals',
      'severity': 'high',
      'blocking': true,
      'issue_count': 2,
      'message': 'Draft journal entries remain.',
    });

    expect(check.checkCode, 'draft_journals');
    expect(check.severity, 'high');
    expect(check.blocking, isTrue);
    expect(check.issueCount, 2);
  });

  test('defaults malformed optional values safely', () {
    final check = ClosePreflightCheck.fromJson({});

    expect(check.checkCode, isEmpty);
    expect(check.severity, 'info');
    expect(check.blocking, isFalse);
    expect(check.issueCount, 0);
  });
}
