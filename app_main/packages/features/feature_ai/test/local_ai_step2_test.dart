import 'package:flutter_test/flutter_test.dart';
import 'package:feature_ai/feature_ai.dart';

class _FakeNativeBridge implements LocalAiNativeInferenceBridge {
  _FakeNativeBridge({required this.loadResult, required this.inferResult});

  final LocalAiNativeResult loadResult;
  final LocalAiNativeResult inferResult;
  int loadCalls = 0;
  int inferCalls = 0;
  int unloadCalls = 0;

  @override
  Future<LocalAiNativeResult> loadModel(LocalAiModelManifest manifest) async {
    loadCalls++;
    return loadResult;
  }

  @override
  Future<LocalAiNativeResult> infer({
    required String text,
    required String locale,
  }) async {
    inferCalls++;
    return inferResult;
  }

  @override
  Future<void> unloadModel() async {
    unloadCalls++;
  }
}

LocalAiModelManifest _manifest() => LocalAiModelManifest(
  modelId: 'proposal_extractor_ar_en',
  modelVersion: '1.0.0',
  artifactName: 'model.tflite',
  sha256: '0' * 64,
  tokenizerVersion: 'rules-tokenizer-v1',
  supportedLocales: const ['ar', 'en'],
  minimumAppVersion: '0.1.0',
  task: 'proposal_extraction',
  quantization: 'int8',
);

LocalAiProposal _validProposal() => const LocalAiProposal(
  intent: LocalAiIntent.explain,
  actionType: LocalAiActionTypes.none,
  fields: {'query': 'Explain debit and credit'},
  entities: [],
  missingFields: [],
  confidence: 0.99,
  requiresConfirmation: false,
  locale: 'en',
);

void main() {
  group('RuleBasedLocalAiEngine', () {
    const engine = RuleBasedLocalAiEngine();

    test('classifies an English explanation without confirmation', () async {
      final result = await engine.propose(
        const LocalAiRequest(
          text: 'Explain the difference between debit and credit',
          locale: 'en',
        ),
      );

      expect(result.status, LocalAiEngineStatus.ready);
      expect(result.proposal?.intent, LocalAiIntent.explain);
      expect(result.proposal?.actionType, LocalAiActionTypes.none);
      expect(result.proposal?.requiresConfirmation, isFalse);
    });

    test('extracts an English customer email update', () async {
      final result = await engine.propose(
        const LocalAiRequest(
          text: 'Edit customer "Acme Trading" email billing@example.test',
          locale: 'en-US',
        ),
      );

      expect(result.status, LocalAiEngineStatus.ready);
      expect(result.proposal?.actionType, LocalAiActionTypes.customerUpdate);
      expect(result.proposal?.fields['record_name'], 'Acme Trading');
      expect(
        (result.proposal?.fields['patch'] as Map)['email'],
        'billing@example.test',
      );
      expect(result.proposal?.requiresConfirmation, isTrue);
    });

    test('extracts Arabic vendor phone update', () async {
      final result = await engine.propose(
        const LocalAiRequest(
          text: 'تحديث المورد "شركة النور" الهاتف +967 700 123 456',
          locale: 'ar',
        ),
      );

      expect(result.status, LocalAiEngineStatus.ready);
      expect(result.proposal?.actionType, LocalAiActionTypes.vendorUpdate);
      expect(result.proposal?.fields['record_name'], 'شركة النور');
      expect(
        (result.proposal?.fields['patch'] as Map)['phone'],
        '+967 700 123 456',
      );
    });

    test('extracts invoice number, date, and currency', () async {
      final result = await engine.propose(
        const LocalAiRequest(
          text: 'Update invoice INV-1007 due date 2026-09-30 currency SAR',
          locale: 'en',
        ),
      );

      expect(result.status, LocalAiEngineStatus.ready);
      expect(result.proposal?.actionType, LocalAiActionTypes.invoiceUpdate);
      expect(result.proposal?.fields['record_number'], 'INV-1007');
      expect(
        (result.proposal?.fields['patch'] as Map)['due_date'],
        '2026-09-30',
      );
      expect((result.proposal?.fields['patch'] as Map)['currency_code'], 'SAR');
    });

    test(
      'returns missing information instead of guessing a mutation',
      () async {
        final result = await engine.propose(
          const LocalAiRequest(text: 'Edit a customer', locale: 'en'),
        );

        expect(result.status, LocalAiEngineStatus.ready);
        expect(
          result.proposal?.intent,
          LocalAiIntent.requestMissingInformation,
        );
        expect(result.proposal?.missingFields, contains('record_name'));
        expect(result.proposal?.missingFields, contains('patch'));
        expect(result.proposal?.requiresConfirmation, isFalse);
      },
    );

    test('refuses deletion and source-code requests', () async {
      final result = await engine.propose(
        const LocalAiRequest(
          text: 'Delete the customer and edit source code automatically',
          locale: 'en',
        ),
      );

      expect(result.status, LocalAiEngineStatus.ready);
      expect(result.proposal?.intent, LocalAiIntent.unsupported);
      expect(result.proposal?.actionType, LocalAiActionTypes.unsupported);
    });

    test('rejects unsupported locales without producing a proposal', () async {
      final result = await engine.propose(
        const LocalAiRequest(text: 'Explain balance sheet', locale: 'fr'),
      );

      expect(result.status, LocalAiEngineStatus.failed);
      expect(result.proposal, isNull);
    });
  });

  group('LocalAiModelManifest', () {
    test('round-trips a valid manifest', () {
      final decoded = LocalAiModelManifest.fromJson(_manifest().toJson());

      expect(decoded.modelId, 'proposal_extractor_ar_en');
      expect(decoded.quantization, 'int8');
      expect(decoded.supportedLocales, ['ar', 'en']);
    });

    test('rejects unsafe artifact names and invalid checksums', () {
      expect(
        () => LocalAiModelManifest.fromJson({
          ..._manifest().toJson(),
          'artifact_name': '../model.tflite',
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => LocalAiModelManifest.fromJson({
          ..._manifest().toJson(),
          'sha256': 'not-a-checksum',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('NativeTfliteLocalAiEngine', () {
    test('fails closed when Android runtime is unavailable', () async {
      final bridge = _FakeNativeBridge(
        loadResult: const LocalAiNativeResult.unavailable('not packaged'),
        inferResult: const LocalAiNativeResult.failed('not reached'),
      );
      final engine = NativeTfliteLocalAiEngine(
        bridge: bridge,
        manifest: _manifest(),
      );

      final result = await engine.propose(
        const LocalAiRequest(text: 'Explain debit', locale: 'en'),
      );

      expect(result.status, LocalAiEngineStatus.unavailable);
      expect(result.proposal, isNull);
      expect(bridge.loadCalls, 1);
      expect(bridge.inferCalls, 0);
    });

    test('revalidates native proposal JSON before returning it', () async {
      final proposal = _validProposal();
      final bridge = _FakeNativeBridge(
        loadResult: const LocalAiNativeResult.ready('loaded'),
        inferResult: LocalAiNativeResult.ready(proposal.encode()),
      );
      final engine = NativeTfliteLocalAiEngine(
        bridge: bridge,
        manifest: _manifest(),
      );

      final result = await engine.propose(
        const LocalAiRequest(text: 'Explain debit', locale: 'en'),
      );

      expect(result.status, LocalAiEngineStatus.ready);
      expect(result.proposal?.intent, LocalAiIntent.explain);
      expect(bridge.loadCalls, 1);
      expect(bridge.inferCalls, 1);

      await engine.unload();
      expect(bridge.unloadCalls, 1);
      expect(engine.status, LocalAiEngineStatus.unavailable);
    });

    test('rejects malformed or unsafe native proposal output', () async {
      final bridge = _FakeNativeBridge(
        loadResult: const LocalAiNativeResult.ready('loaded'),
        inferResult: const LocalAiNativeResult.ready('{"unexpected":true}'),
      );
      final engine = NativeTfliteLocalAiEngine(
        bridge: bridge,
        manifest: _manifest(),
      );

      final result = await engine.propose(
        const LocalAiRequest(text: 'Explain debit', locale: 'en'),
      );

      expect(result.status, LocalAiEngineStatus.failed);
      expect(result.proposal, isNull);
    });
  });
}
