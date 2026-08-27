import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_ai_engine.dart';
import 'local_ai_model_catalog.dart';
import 'local_ai_native_bridge.dart';
import 'local_ai_orchestrator.dart';
import 'rule_based_local_ai_engine.dart';

/// The reviewed GGUF tier is enabled on Android and Windows, where the
/// platform runners package the pinned llama.cpp runtime. The orchestrator
/// remains rule-first, and the model is only queried when deterministic local
/// handling cannot resolve the request.
final localAiModelEngineProvider = Provider<LocalAiEngine>((ref) {
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.windows) {
    return const DisabledLocalAiEngine();
  }
  return NativeGgufLocalAiEngine(
    bridge: MethodChannelLocalAiNativeInferenceBridge(),
    manifest: qwen3MizanLocalModel,
  );
});

/// Guest/offline assistance remains rule-first. The native model is only a
/// fallback for requests that the deterministic tier cannot resolve, and all
/// model output still passes the proposal validator before reaching the UI.
final localAiEngineProvider = Provider<LocalAiEngine>((ref) {
  return LocalAiOrchestrator(
    ruleEngine: const RuleBasedLocalAiEngine(),
    modelEngine: ref.watch(localAiModelEngineProvider),
  );
});
