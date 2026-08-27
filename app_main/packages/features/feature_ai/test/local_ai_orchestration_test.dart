import 'package:feature_ai/feature_ai.dart';
import 'package:flutter_test/flutter_test.dart';

LocalAiProposal _explanationProposal() => const LocalAiProposal(
  intent: LocalAiIntent.explain,
  actionType: LocalAiActionTypes.none,
  fields: {'query': 'Explain journal entries'},
  entities: [],
  missingFields: [],
  confidence: 0.9,
  requiresConfirmation: false,
  locale: 'en',
);

void main() {
  group('local navigation', () {
    const engine = RuleBasedLocalAiEngine();

    test('resolves English navigation to an allowlisted destination', () async {
      final result = await engine.propose(
        const LocalAiRequest(text: 'Go to reports', locale: 'en'),
      );

      expect(result.isReady, isTrue);
      expect(result.proposal?.intent, LocalAiIntent.navigate);
      expect(result.proposal?.actionType, LocalAiActionTypes.navigate);
      expect(result.proposal?.route, 'reportsHub');
      expect(
        LocalAiNavigationCatalog.isAllowed(result.proposal!.route!),
        isTrue,
      );
    });

    test('resolves Arabic supplier guidance to the supplier page', () async {
      final result = await engine.propose(
        const LocalAiRequest(text: 'كيف أضيف مورد جديد؟', locale: 'ar'),
      );

      expect(result.isReady, isTrue);
      expect(result.proposal?.route, 'vendors');
      expect(result.proposal?.requiresConfirmation, isFalse);
    });
  });

  group('local knowledge base', () {
    test('returns bounded English workflow guidance', () {
      final results = LocalAiKnowledgeBase.search(
        'How do I post a journal entry?',
        locale: 'en',
      );

      expect(results, isNotEmpty);
      expect(results.length, lessThanOrEqualTo(3));
      expect(results.first.id, 'journal-basics');
    });

    test('returns Arabic workflow guidance without tenant data', () {
      final results = LocalAiKnowledgeBase.search(
        'كيف تتم التسوية البنكية؟',
        locale: 'ar',
      );

      expect(results.map((item) => item.id), contains('bank-reconciliation'));
      expect(results.first.bodyFor('ar'), isNot(contains('tenant')));
    });
  });

  group('local orchestrator', () {
    test('prefers deterministic result when it can answer', () async {
      final orchestrator = LocalAiOrchestrator(
        ruleEngine: const RuleBasedLocalAiEngine(),
        modelEngine: FixedProposalLocalAiEngine(_explanationProposal()),
      );

      final result = await orchestrator.propose(
        const LocalAiRequest(text: 'Go to customers', locale: 'en'),
      );

      expect(result.proposal?.intent, LocalAiIntent.navigate);
      expect(result.proposal?.route, 'customers');
    });

    test('marks the safe fallback when the model is disabled', () async {
      final orchestrator = LocalAiOrchestrator(
        ruleEngine: const RuleBasedLocalAiEngine(),
        modelEngine: const DisabledLocalAiEngine(),
      );

      final result = await orchestrator.propose(
        const LocalAiRequest(text: 'Edit a customer', locale: 'en'),
      );

      expect(result.proposal?.intent, LocalAiIntent.requestMissingInformation);
      expect(result.usedSafeFallback, isTrue);
      expect(result.fallbackCode, LocalAiDiagnosticCode.disabled);
    });

    test('uses a ready model only when rules need more information', () async {
      final orchestrator = LocalAiOrchestrator(
        ruleEngine: const RuleBasedLocalAiEngine(),
        modelEngine: FixedProposalLocalAiEngine(_explanationProposal()),
      );

      final result = await orchestrator.propose(
        const LocalAiRequest(text: 'Give me accounting guidance', locale: 'en'),
      );

      expect(result.proposal?.intent, LocalAiIntent.explain);
      expect(result.proposal?.source, 'local');
    });
  });

  group('navigation validation', () {
    test('rejects an unallowlisted route', () {
      const proposal = LocalAiProposal(
        intent: LocalAiIntent.navigate,
        actionType: LocalAiActionTypes.navigate,
        fields: {'query': 'open something'},
        entities: [],
        missingFields: [],
        confidence: 0.99,
        requiresConfirmation: false,
        locale: 'en',
        route: 'delete-everything',
      );

      final result = LocalAiProposalValidator.validate(proposal);

      expect(result.isValid, isFalse);
      expect(result.errors, contains('navigation route is not allowlisted'));
    });

    test('round-trips optional explanation and route fields', () {
      const proposal = LocalAiProposal(
        intent: LocalAiIntent.navigate,
        actionType: LocalAiActionTypes.navigate,
        fields: {'query': 'go to reports'},
        entities: [],
        missingFields: [],
        confidence: 0.95,
        requiresConfirmation: false,
        locale: 'en',
        explanation: 'Open the reports area.',
        route: 'reportsHub',
      );

      final decoded = LocalAiProposal.decode(proposal.encode());

      expect(decoded.explanation, 'Open the reports area.');
      expect(decoded.route, 'reportsHub');
      expect(LocalAiProposalValidator.validate(decoded).isValid, isTrue);
    });
  });
}
