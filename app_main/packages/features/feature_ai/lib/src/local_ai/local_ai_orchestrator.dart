import 'local_ai_engine.dart';
import 'local_ai_proposal.dart';

/// Routes local requests without allowing any engine to execute business
/// actions. Deterministic rules are preferred because they are auditable and
/// predictable; a reviewed model may be used only for requests the rules
/// cannot resolve and only when that model reports ready.
class LocalAiOrchestrator implements LocalAiEngine {
  const LocalAiOrchestrator({
    required this.ruleEngine,
    required this.modelEngine,
  });

  final LocalAiEngine ruleEngine;
  final LocalAiEngine modelEngine;

  @override
  String get engineId => 'orchestrator-v1';

  @override
  LocalAiEngineStatus get status {
    if (ruleEngine.status == LocalAiEngineStatus.ready) {
      return LocalAiEngineStatus.ready;
    }
    return modelEngine.status;
  }

  @override
  Future<LocalAiEngineResult> propose(LocalAiRequest request) async {
    final deterministic = await ruleEngine.propose(request);
    final deterministicProposal = deterministic.proposal;
    final shouldTryModel =
        modelEngine.status == LocalAiEngineStatus.ready &&
        (deterministic.status != LocalAiEngineStatus.ready ||
            deterministicProposal == null ||
            deterministicProposal.intent ==
                LocalAiIntent.requestMissingInformation);

    if (!shouldTryModel) return deterministic;

    final modelResult = await modelEngine.propose(request);
    if (modelResult.status == LocalAiEngineStatus.ready) return modelResult;

    // The deterministic result is safer and more useful than exposing a model
    // failure. If it was unavailable too, preserve the model diagnostic.
    if (deterministic.status != LocalAiEngineStatus.unavailable) {
      return deterministic;
    }
    return modelResult;
  }
}
