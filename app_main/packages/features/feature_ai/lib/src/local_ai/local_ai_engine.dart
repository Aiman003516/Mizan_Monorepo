import 'package:core_l10n/app_localizations.dart';

import 'local_ai_proposal.dart';
import 'local_ai_validator.dart';

enum LocalAiEngineStatus { unavailable, ready, failed }

enum LocalAiDiagnosticCode {
  disabled,
  runtimeNotPackaged,
  invalidRuntimeResponse,
  modelUnavailable,
  runtimeFailed,
  unsupportedLocale,
  localeNotInManifest,
  modelLoadFailed,
  inferenceFailed,
}

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
    this.code,
    this.fallbackCode,
  });

  const LocalAiEngineResult.unavailable({
    String? message,
    LocalAiDiagnosticCode? code,
  }) : this._(
         status: LocalAiEngineStatus.unavailable,
         message: message,
         code: code,
       );

  const LocalAiEngineResult.ready(
    LocalAiProposal proposal, {
    LocalAiDiagnosticCode? fallbackCode,
  }) : this._(
         status: LocalAiEngineStatus.ready,
         proposal: proposal,
         fallbackCode: fallbackCode,
       );

  const LocalAiEngineResult.failed(
    String message, {
    LocalAiDiagnosticCode? code,
  }) : this._(status: LocalAiEngineStatus.failed, message: message, code: code);

  final LocalAiEngineStatus status;
  final LocalAiProposal? proposal;
  final String? message;
  final LocalAiDiagnosticCode? code;
  final LocalAiDiagnosticCode? fallbackCode;

  bool get usedSafeFallback => fallbackCode != null;

  LocalAiEngineResult markSafeFallback(LocalAiDiagnosticCode reason) {
    return LocalAiEngineResult._(
      status: status,
      proposal: proposal,
      message: message,
      code: code,
      fallbackCode: reason,
    );
  }

  String localizedMessage(AppLocalizations l10n) {
    return switch (code) {
      LocalAiDiagnosticCode.disabled => l10n.localAiDisabled,
      LocalAiDiagnosticCode.runtimeNotPackaged =>
        l10n.localAiRuntimeNotPackaged,
      LocalAiDiagnosticCode.invalidRuntimeResponse =>
        l10n.localAiInvalidRuntimeResponse,
      LocalAiDiagnosticCode.modelUnavailable => l10n.localAiModelUnavailable,
      LocalAiDiagnosticCode.runtimeFailed => l10n.localAiRuntimeFailed,
      LocalAiDiagnosticCode.unsupportedLocale => l10n.localAiUnsupportedLocale,
      LocalAiDiagnosticCode.localeNotInManifest =>
        l10n.localAiLocaleNotSupported,
      LocalAiDiagnosticCode.modelLoadFailed => l10n.localAiModelLoadFailed,
      LocalAiDiagnosticCode.inferenceFailed => l10n.localAiInferenceFailed,
      null => message ?? l10n.localAiGenericFailure,
    };
  }

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
      code: LocalAiDiagnosticCode.disabled,
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
