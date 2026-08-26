import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_ai_proposal.dart';
import 'local_ai_validator.dart';

enum LocalAiEngineStatus { unavailable, ready, failed }

class LocalAiRequest {
  const LocalAiRequest({
    required this.text,
    required this.locale,
    this.context = const <String, Object?>{},
  });

  final String text;
  final String locale;
  final Map<String, Object?> context;
}

class LocalAiEngineResult {
  const LocalAiEngineResult._({
    required this.status,
    this.proposal,
    this.message,
  });

  const LocalAiEngineResult.unavailable({String? message})
    : this._(status: LocalAiEngineStatus.unavailable, message: message);

  const LocalAiEngineResult.ready(LocalAiProposal proposal)
    : this._(status: LocalAiEngineStatus.ready, proposal: proposal);

  const LocalAiEngineResult.failed(String message)
    : this._(status: LocalAiEngineStatus.failed, message: message);

  final LocalAiEngineStatus status;
  final LocalAiProposal? proposal;
  final String? message;

  bool get isReady => status == LocalAiEngineStatus.ready && proposal != null;
}

/// Local assistant inference boundary.
///
/// Implementations may classify text and prepare proposals only. They must not
/// execute business mutations, access Supabase credentials, invoke arbitrary
/// network APIs, run SQL, or access application files.
abstract interface class LocalAiEngine {
  String get engineId;
  LocalAiEngineStatus get status;

  Future<LocalAiEngineResult> propose(LocalAiRequest request);
}

/// Safe default until a reviewed model runtime is explicitly enabled.
class DisabledLocalAiEngine implements LocalAiEngine {
  const DisabledLocalAiEngine();

  @override
  String get engineId => 'disabled';

  @override
  LocalAiEngineStatus get status => LocalAiEngineStatus.unavailable;

  @override
  Future<LocalAiEngineResult> propose(LocalAiRequest request) async {
    return const LocalAiEngineResult.unavailable(
      message: 'Local AI is not enabled on this device.',
    );
  }
}

/// Test/development engine for validating the proposal boundary without a
/// model or network. It validates the supplied proposal before returning it.
class FixedProposalLocalAiEngine implements LocalAiEngine {
  FixedProposalLocalAiEngine(this._proposal);

  final LocalAiProposal _proposal;

  @override
  String get engineId => 'fixed-proposal-test';

  @override
  LocalAiEngineStatus get status => LocalAiEngineStatus.ready;

  @override
  Future<LocalAiEngineResult> propose(LocalAiRequest request) async {
    final validation = LocalAiProposalValidator.validate(_proposal);
    if (!validation.isValid) {
      return LocalAiEngineResult.failed(validation.errors.join('; '));
    }
    return LocalAiEngineResult.ready(_proposal);
  }
}

/// The application default remains disabled. Product composition code may
/// explicitly override this provider after the local-only setting is enabled.
final localAiEngineProvider = Provider<LocalAiEngine>((ref) {
  return const DisabledLocalAiEngine();
});
