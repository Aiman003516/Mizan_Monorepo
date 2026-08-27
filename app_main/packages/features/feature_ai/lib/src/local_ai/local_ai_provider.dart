import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_ai_engine.dart';
import 'local_ai_orchestrator.dart';
import 'rule_based_local_ai_engine.dart';

/// The reviewed model tier remains disabled until its runtime, artifact,
/// packaging, and device evidence have been approved.
final localAiModelEngineProvider = Provider<LocalAiEngine>((ref) {
  return const DisabledLocalAiEngine();
});

/// Guest/offline assistance uses the deterministic rule tier. A future model
/// can be injected by overriding [localAiModelEngineProvider] without changing
/// the UI or business-action boundaries.
final localAiEngineProvider = Provider<LocalAiEngine>((ref) {
  return LocalAiOrchestrator(
    ruleEngine: const RuleBasedLocalAiEngine(),
    modelEngine: ref.watch(localAiModelEngineProvider),
  );
});
