import 'package:flutter_test/flutter_test.dart';
import 'package:feature_ai/feature_ai.dart';

void main() {
  test('parses a valid read-only AI response', () {
    final response = AiAgentResponse.fromData({
      'conversation_id': 'conversation-1',
      'request_id': 'request-1',
      'message': 'Revenue increased this month.',
      'model': 'gpt-5-mini',
      'read_only': true,
    });

    expect(response.conversationId, 'conversation-1');
    expect(response.requestId, 'request-1');
    expect(response.message, 'Revenue increased this month.');
    expect(response.readOnly, isTrue);
  });

  test('rejects a response without a message or identifiers', () {
    expect(
      () => AiAgentResponse.fromData(const {}),
      throwsA(
        isA<AiAgentException>().having(
          (error) => error.code,
          'code',
          'MIZAN_AI_INVALID_RESPONSE',
        ),
      ),
    );
  });

  test('guest mode exception is explicit and safe', () {
    const error = AiGuestModeException();

    expect(error.code, 'MIZAN_AI_GUEST_MODE');
    expect(error.message, contains('authenticated tenant'));
  });
}
