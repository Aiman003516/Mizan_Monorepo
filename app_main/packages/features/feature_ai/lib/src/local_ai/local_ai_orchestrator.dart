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
    final needsModelHelp =
        deterministic.status != LocalAiEngineStatus.ready ||
        deterministicProposal == null ||
        deterministicProposal.intent == LocalAiIntent.requestMissingInformation;
    if (!needsModelHelp) return deterministic;

    if (modelEngine.status != LocalAiEngineStatus.ready) {
      return deterministic.markSafeFallback(
        modelEngine.engineId == 'disabled'
            ? LocalAiDiagnosticCode.disabled
            : LocalAiDiagnosticCode.modelUnavailable,
      );
    }

    final modelResult = await modelEngine.propose(request);
    if (modelResult.status == LocalAiEngineStatus.ready) return modelResult;

    // The deterministic result is safer and more useful than exposing a model
    // failure. Preserve it, but retain a typed diagnostic for the UI.
    if (deterministic.proposal != null) {
      return deterministic.markSafeFallback(
        modelResult.code ?? LocalAiDiagnosticCode.modelUnavailable,
      );
    }
    return modelResult;
  }
}
