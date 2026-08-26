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

  test('parses a structured action proposal from an AI response', () {
    final response = AiAgentResponse.fromData({
      'conversation_id': 'conversation-2',
      'request_id': 'request-2',
      'message': 'I prepared a customer draft for your review.',
      'read_only': true,
      'action_proposal': {
        'action_type': 'customer_draft',
        'payload': {'name': 'Acme'},
        'requires_confirmation': true,
      },
    });

    expect(response.actionProposal, isNotNull);
    expect(response.actionProposal!.actionType, 'customer_draft');
    expect(response.actionProposal!.payload['name'], 'Acme');
    expect(response.actionProposal!.requiresConfirmation, isTrue);
  });

  test('rejects a malformed action proposal', () {
    expect(
      () => AiAgentResponse.fromData({
        'conversation_id': 'conversation-3',
        'request_id': 'request-3',
        'message': 'Draft',
        'read_only': true,
        'action_proposal': {
          'action_type': 'customer_draft',
          'payload': {'name': 'Acme'},
          'requires_confirmation': false,
        },
      }),
      throwsA(
        isA<AiAgentException>().having(
          (error) => error.code,
          'code',
          'MIZAN_AI_INVALID_PROPOSAL',
        ),
      ),
    );
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

  test('parses a typed action draft', () {
    final draft = AiActionRequest.fromJson({
      'id': 'action-1',
      'action_type': 'customer_draft',
      'payload': {'name': 'Acme'},
      'preview': {'action_type': 'customer_draft'},
      'status': 'pending',
      'expires_at': '2026-08-26T12:00:00Z',
    });

    expect(draft.actionType, 'customer_draft');
    expect(draft.payload['name'], 'Acme');
    expect(draft.status, 'pending');
    expect(draft.expiresAt, isNotNull);
  });

  test('parses confirmation token and execution result', () {
    final draft = AiActionRequest.fromJson({
      'id': 'action-2',
      'action_type': 'invoice_draft',
      'payload': {'customer_id': 'customer-1'},
      'preview': {'action_type': 'invoice_draft'},
      'status': 'executed',
      'expires_at': '2026-08-26T12:00:00Z',
      'confirmation_token': 'token-1',
      'confirmed_at': '2026-08-26T11:59:00Z',
      'executed_at': '2026-08-26T11:59:01Z',
      'execution_result': {
        'invoice': {'id': 'invoice-1'},
      },
    });

    expect(draft.confirmationToken, 'token-1');
    expect(draft.status, 'executed');
    expect(draft.executionResult?['invoice'], isA<Map>());
    expect(draft.confirmedAt, isNotNull);
    expect(draft.executedAt, isNotNull);
  });

  test('rejects malformed confirmation or execution fields', () {
    expect(
      () => AiActionRequest.fromJson({
        'id': 'action-3',
        'action_type': 'customer_draft',
        'payload': {'name': 'Acme'},
        'preview': {'action_type': 'customer_draft'},
        'status': 'pending',
        'expires_at': '2026-08-26T12:00:00Z',
        'confirmation_token': 42,
      }),
      throwsA(isA<AiAgentException>()),
    );
  });

  test('rejects an incomplete action draft', () {
    expect(
      () => AiActionRequest.fromJson(const {}),
      throwsA(isA<AiAgentException>()),
    );
  });

  test('guest mode exception is explicit and safe', () {
    const error = AiGuestModeException();

    expect(error.code, 'MIZAN_AI_GUEST_MODE');
    expect(error.message, contains('authenticated tenant'));
  });
}
