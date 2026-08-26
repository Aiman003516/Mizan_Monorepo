import 'dart:convert';

import 'package:flutter/services.dart';

import 'local_ai_engine.dart';
import 'local_ai_proposal.dart';
import 'local_ai_validator.dart';

const localAiNativeChannelName = 'com.mizan/local_ai';

class LocalAiModelManifest {
  const LocalAiModelManifest({
    required this.modelId,
    required this.modelVersion,
    required this.artifactName,
    required this.sha256,
    required this.tokenizerVersion,
    required this.supportedLocales,
    required this.minimumAppVersion,
    required this.task,
    required this.quantization,
  });

  final String modelId;
  final String modelVersion;
  final String artifactName;
  final String sha256;
  final String tokenizerVersion;
  final List<String> supportedLocales;
  final String minimumAppVersion;
  final String task;
  final String quantization;

  Map<String, Object?> toJson() => {
    'schema_version': 'mizan.local-ai.model/v1',
    'model_id': modelId,
    'model_version': modelVersion,
    'artifact_name': artifactName,
    'sha256': sha256,
    'tokenizer_version': tokenizerVersion,
    'supported_locales': supportedLocales,
    'minimum_app_version': minimumAppVersion,
    'task': task,
    'quantization': quantization,
  };

  String encode() => jsonEncode(toJson());

  factory LocalAiModelManifest.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid local AI model manifest');
    }
    final json = Map<String, Object?>.from(value);
    const keys = {
      'schema_version',
      'model_id',
      'model_version',
      'artifact_name',
      'sha256',
      'tokenizer_version',
      'supported_locales',
      'minimum_app_version',
      'task',
      'quantization',
    };
    if (json.keys.length != keys.length ||
        !json.keys.toSet().containsAll(keys)) {
      throw const FormatException('Local AI model manifest keys are invalid');
    }

    final supportedLocales = json['supported_locales'];
    if (supportedLocales is! List ||
        supportedLocales.any((locale) => locale is! String)) {
      throw const FormatException('Model locales must be a string list');
    }
    final manifest = LocalAiModelManifest(
      modelId: _requiredText(json['model_id'], 'model_id'),
      modelVersion: _requiredText(json['model_version'], 'model_version'),
      artifactName: _requiredText(json['artifact_name'], 'artifact_name'),
      sha256: _requiredText(json['sha256'], 'sha256'),
      tokenizerVersion: _requiredText(
        json['tokenizer_version'],
        'tokenizer_version',
      ),
      supportedLocales: List<String>.from(supportedLocales),
      minimumAppVersion: _requiredText(
        json['minimum_app_version'],
        'minimum_app_version',
      ),
      task: _requiredText(json['task'], 'task'),
      quantization: _requiredText(json['quantization'], 'quantization'),
    );
    _validateManifest(manifest, json['schema_version']);
    return manifest;
  }

  static String _requiredText(Object? value, String field) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$field must be a non-empty string');
    }
    return LocalAiTextNormalizer.normalize(value);
  }

  static void _validateManifest(
    LocalAiModelManifest manifest,
    Object? schemaVersion,
  ) {
    if (schemaVersion != 'mizan.local-ai.model/v1') {
      throw const FormatException(
        'Unsupported local AI model manifest version',
      );
    }
    if (!RegExp(r'^[a-zA-Z0-9._-]+\.tflite$').hasMatch(manifest.artifactName)) {
      throw const FormatException('Model artifact name is unsafe');
    }
    if (!RegExp(
      r'^[0-9a-f]{64}$',
      caseSensitive: false,
    ).hasMatch(manifest.sha256)) {
      throw const FormatException('Model checksum must be SHA-256');
    }
    if (manifest.supportedLocales.isEmpty ||
        manifest.supportedLocales.any(
          (locale) => locale != 'ar' && locale != 'en',
        )) {
      throw const FormatException('Model locales must be ar or en');
    }
    if (manifest.task != 'proposal_extraction') {
      throw const FormatException('Unsupported local AI model task');
    }
    if (!const {
      'float32',
      'float16',
      'dynamic_range_int8',
      'int8',
    }.contains(manifest.quantization)) {
      throw const FormatException('Unsupported local AI quantization');
    }
  }
}

enum LocalAiNativeStatus { unavailable, loading, ready, failed }

class LocalAiNativeResult {
  const LocalAiNativeResult._({
    required this.status,
    this.proposalJson,
    this.message,
  });

  const LocalAiNativeResult.ready(String proposalJson)
    : this._(status: LocalAiNativeStatus.ready, proposalJson: proposalJson);

  const LocalAiNativeResult.unavailable(String message)
    : this._(status: LocalAiNativeStatus.unavailable, message: message);

  const LocalAiNativeResult.failed(String message)
    : this._(status: LocalAiNativeStatus.failed, message: message);

  final LocalAiNativeStatus status;
  final String? proposalJson;
  final String? message;
}

abstract interface class LocalAiNativeInferenceBridge {
  Future<LocalAiNativeResult> loadModel(LocalAiModelManifest manifest);

  Future<LocalAiNativeResult> infer({
    required String text,
    required String locale,
  });

  Future<void> unloadModel();
}

/// Flutter-side boundary for the Android implementation.
///
/// The Android channel must return only proposal JSON. It must never expose a
/// database handle, a network client, a credential, or an arbitrary method
/// invocation surface to Dart or the model.
class MethodChannelLocalAiNativeInferenceBridge
    implements LocalAiNativeInferenceBridge {
  MethodChannelLocalAiNativeInferenceBridge([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(localAiNativeChannelName);

  final MethodChannel _channel;

  @override
  Future<LocalAiNativeResult> loadModel(LocalAiModelManifest manifest) async {
    try {
      final result = await _channel.invokeMethod<Object?>('load_model', {
        'manifest_json': manifest.encode(),
      });
      return _parseResult(result);
    } on MissingPluginException {
      return const LocalAiNativeResult.unavailable(
        'No Android local AI runtime is packaged.',
      );
    } on PlatformException catch (error) {
      return LocalAiNativeResult.failed(error.message ?? error.code);
    }
  }

  @override
  Future<LocalAiNativeResult> infer({
    required String text,
    required String locale,
  }) async {
    try {
      final result = await _channel.invokeMethod<Object?>('infer', {
        'text': text,
        'locale': locale,
      });
      return _parseResult(result);
    } on MissingPluginException {
      return const LocalAiNativeResult.unavailable(
        'No Android local AI runtime is packaged.',
      );
    } on PlatformException catch (error) {
      return LocalAiNativeResult.failed(error.message ?? error.code);
    }
  }

  @override
  Future<void> unloadModel() => _channel.invokeMethod<void>('unload_model');

  LocalAiNativeResult _parseResult(Object? value) {
    if (value is! Map) {
      return const LocalAiNativeResult.failed(
        'Android local AI runtime returned an invalid response.',
      );
    }
    final map = Map<Object?, Object?>.from(value);
    final status = map['status'];
    final message = map['message'];
    final proposalJson = map['proposal_json'];
    if (status == 'ready' && proposalJson is String) {
      return LocalAiNativeResult.ready(proposalJson);
    }
    if (status == 'unavailable') {
      return LocalAiNativeResult.unavailable(
        message is String ? message : 'Local AI model is unavailable.',
      );
    }
    return LocalAiNativeResult.failed(
      message is String ? message : 'Android local AI runtime failed.',
    );
  }
}

/// Adapter that keeps native inference proposal-only and validates its output
/// before it can reach any presentation or application layer.
class NativeTfliteLocalAiEngine implements LocalAiEngine {
  NativeTfliteLocalAiEngine({required this.bridge, required this.manifest});

  final LocalAiNativeInferenceBridge bridge;
  final LocalAiModelManifest manifest;
  LocalAiEngineStatus _status = LocalAiEngineStatus.unavailable;

  @override
  String get engineId =>
      'native-tflite-${manifest.modelId}-${manifest.modelVersion}';

  @override
  LocalAiEngineStatus get status => _status;

  @override
  Future<LocalAiEngineResult> propose(LocalAiRequest request) async {
    if (request.locale != 'ar' && request.locale != 'en') {
      return const LocalAiEngineResult.failed(
        'Local AI supports Arabic (ar) and English (en) only.',
      );
    }
    if (!manifest.supportedLocales.contains(request.locale)) {
      return const LocalAiEngineResult.failed(
        'The packaged local model does not support this locale.',
      );
    }

    if (_status != LocalAiEngineStatus.ready) {
      final loadResult = await bridge.loadModel(manifest);
      if (loadResult.status == LocalAiNativeStatus.unavailable) {
        _status = LocalAiEngineStatus.unavailable;
        return LocalAiEngineResult.unavailable(message: loadResult.message);
      }
      if (loadResult.status != LocalAiNativeStatus.ready) {
        _status = LocalAiEngineStatus.failed;
        return LocalAiEngineResult.failed(
          loadResult.message ?? 'Local AI model failed to load.',
        );
      }
      _status = LocalAiEngineStatus.ready;
    }

    final result = await bridge.infer(
      text: request.text,
      locale: request.locale,
    );
    if (result.status == LocalAiNativeStatus.unavailable) {
      _status = LocalAiEngineStatus.unavailable;
      return LocalAiEngineResult.unavailable(message: result.message);
    }
    if (result.status != LocalAiNativeStatus.ready ||
        result.proposalJson == null) {
      _status = LocalAiEngineStatus.failed;
      return LocalAiEngineResult.failed(
        result.message ?? 'Local AI inference failed.',
      );
    }

    try {
      final proposal = LocalAiProposal.decode(result.proposalJson!);
      final validation = LocalAiProposalValidator.validate(proposal);
      if (!validation.isValid) {
        return LocalAiEngineResult.failed(validation.errors.join('; '));
      }
      return LocalAiEngineResult.ready(proposal);
    } on FormatException catch (error) {
      return LocalAiEngineResult.failed(error.message);
    }
  }

  Future<void> unload() async {
    await bridge.unloadModel();
    _status = LocalAiEngineStatus.unavailable;
  }
}
