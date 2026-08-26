import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps document anomaly evidence and severity', () {
    final anomaly = DocumentAnomaly.fromJson({
      'anomaly_id': 'anomaly-1',
      'rule_code': 'INVALID_TOTAL_MINOR',
      'severity': 'high',
      'message': 'Total is invalid',
      'evidence': {'value': '-1'},
    });

    expect(anomaly.id, 'anomaly-1');
    expect(anomaly.ruleCode, 'INVALID_TOTAL_MINOR');
    expect(anomaly.severity, 'high');
    expect(anomaly.evidence['value'], '-1');
  });

  test('maps policy context and defaults missing fields safely', () {
    final policy = AiPolicyContext.fromJson({
      'policy_code': 'NO_AUTO_POSTING',
      'scope': 'accounting',
      'action': 'post_journal',
      'policy_text': 'A human must confirm posting.',
    });
    final empty = AiPolicyContext.fromJson({});

    expect(policy.policyCode, 'NO_AUTO_POSTING');
    expect(policy.policyText, contains('human'));
    expect(empty.scope, isEmpty);
    expect(empty.policyText, isEmpty);
  });
}
