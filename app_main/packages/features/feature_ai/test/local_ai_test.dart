import 'package:flutter_test/flutter_test.dart';
import 'package:feature_ai/feature_ai.dart';

LocalAiProposal _proposal({
  required String actionType,
  required Map<String, Object?> fields,
  LocalAiIntent intent = LocalAiIntent.proposeMutation,
  double confidence = 0.95,
  bool requiresConfirmation = true,
}) {
  return LocalAiProposal(
    intent: intent,
    actionType: actionType,
    fields: fields,
    entities: const [],
    missingFields: const [],
    confidence: confidence,
    requiresConfirmation: requiresConfirmation,
    locale: 'en',
  );
}

void main() {
  test('normalizes Arabic and Eastern Arabic digits', () {
    expect(
      LocalAiTextNormalizer.normalizeArabicDigits('٢٠٢٦-٠٨-٢٦'),
      '2026-08-26',
    );
    expect(LocalAiTextNormalizer.normalizeArabicDigits('۱۲۵۰۰'), '12500');
  });

  test('round-trips the versioned proposal schema', () {
    final proposal = LocalAiProposal(
      intent: LocalAiIntent.proposeMutation,
      actionType: LocalAiActionTypes.customerUpdate,
      fields: {
        'record_name': 'شركة النور',
        'patch': {'email': 'billing@example.test'},
      },
      entities: const [
        LocalAiEntity(
          type: LocalAiEntityType.email,
          text: 'billing@example.test',
          normalized: 'billing@example.test',
          confidence: 0.99,
        ),
      ],
      missingFields: const [],
      confidence: 0.96,
      requiresConfirmation: true,
      locale: 'ar',
    );

    final decoded = LocalAiProposal.decode(proposal.encode());

    expect(decoded.schemaVersion, localAiProposalSchemaVersion);
    expect(decoded.actionType, LocalAiActionTypes.customerUpdate);
    expect(decoded.fields['record_name'], 'شركة النور');
    expect(decoded.entities.single.normalized, 'billing@example.test');
  });

  test('rejects an unknown schema version', () {
    expect(
      () => LocalAiProposal.fromJson({
        ..._proposal(
          actionType: LocalAiActionTypes.customerUpdate,
          fields: const {},
        ).toJson(),
        'schema_version': 'mizan.local-ai.proposal/v99',
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('disabled engine fails closed and cannot return a mutation', () async {
    const engine = DisabledLocalAiEngine();
    final result = await engine.propose(
      const LocalAiRequest(text: 'edit the customer', locale: 'en'),
    );

    expect(engine.status, LocalAiEngineStatus.unavailable);
    expect(result.status, LocalAiEngineStatus.unavailable);
    expect(result.proposal, isNull);
  });

  test('valid customer edit passes deterministic validation', () {
    final result = LocalAiProposalValidator.validate(
      _proposal(
        actionType: LocalAiActionTypes.customerUpdate,
        fields: {
          'record_name': 'Acme Trading',
          'expected_updated_at': '2026-08-26T12:00:00Z',
          'patch': {'email': 'billing@example.test', 'is_on_hold': true},
        },
      ),
    );

    expect(result.isValid, isTrue, reason: result.errors.join('; '));
  });

  test('invalid customer email is rejected', () {
    final result = LocalAiProposalValidator.validate(
      _proposal(
        actionType: LocalAiActionTypes.customerUpdate,
        fields: {
          'record_name': 'Acme Trading',
          'patch': {'email': 'not-an-email'},
        },
      ),
    );

    expect(result.errors, contains('email is invalid'));
  });

  test('valid draft invoice edit passes date and item validation', () {
    final result = LocalAiProposalValidator.validate(
      _proposal(
        actionType: LocalAiActionTypes.invoiceUpdate,
        fields: {
          'record_number': 'INV-1007',
          'expected_updated_at': '2026-08-26T12:00:00Z',
          'patch': {
            'due_date': '2026-09-30',
            'currency_code': 'SAR',
            'items': [
              {
                'description': 'Consulting',
                'quantity': 2,
                'unit_price': 125000,
              },
            ],
          },
        },
      ),
    );

    expect(result.isValid, isTrue, reason: result.errors.join('; '));
  });

  test('impossible invoice date is rejected', () {
    final result = LocalAiProposalValidator.validate(
      _proposal(
        actionType: LocalAiActionTypes.invoiceUpdate,
        fields: {
          'record_number': 'INV-1007',
          'patch': {'due_date': '2026-02-30'},
        },
      ),
    );

    expect(result.errors, contains('due_date is invalid'));
  });

  test('invoice due date before invoice date is rejected', () {
    final result = LocalAiProposalValidator.validate(
      _proposal(
        actionType: LocalAiActionTypes.invoiceUpdate,
        fields: {
          'record_number': 'INV-1007',
          'patch': {'invoice_date': '2026-09-30', 'due_date': '2026-09-01'},
        },
      ),
    );

    expect(
      result.errors,
      contains('due_date cannot be before the document date'),
    );
  });

  test('unbalanced journal proposal is rejected', () {
    final result = LocalAiProposalValidator.validate(
      _proposal(
        actionType: LocalAiActionTypes.journalEntryPost,
        fields: {
          'description': 'Supplies',
          'transaction_date': '2026-08-26',
          'currency_code': 'USD',
          'lines': [
            {'account_id': 'expense', 'amount': 100},
            {'account_id': 'cash', 'amount': -90},
          ],
        },
      ),
    );

    expect(result.errors, contains('journal is unbalanced'));
  });

  test('mutation with low confidence or no confirmation is rejected', () {
    final lowConfidence = LocalAiProposalValidator.validate(
      _proposal(
        actionType: LocalAiActionTypes.customerUpdate,
        fields: {
          'record_name': 'Acme',
          'patch': {'phone': '+967700000000'},
        },
        confidence: 0.69,
      ),
    );
    final noConfirmation = LocalAiProposalValidator.validate(
      _proposal(
        actionType: LocalAiActionTypes.customerUpdate,
        fields: {
          'record_name': 'Acme',
          'patch': {'phone': '+967700000000'},
        },
        requiresConfirmation: false,
      ),
    );

    expect(lowConfidence.isValid, isFalse);
    expect(noConfirmation.isValid, isFalse);
  });

  test('unsafe delete request is represented as unsupported', () {
    final result = LocalAiProposalValidator.validate(
      _proposal(
        actionType: LocalAiActionTypes.unsupported,
        intent: LocalAiIntent.unsupported,
        fields: const {},
        confidence: 1,
        requiresConfirmation: false,
      ),
    );

    expect(result.isValid, isTrue, reason: result.errors.join('; '));
  });
}
