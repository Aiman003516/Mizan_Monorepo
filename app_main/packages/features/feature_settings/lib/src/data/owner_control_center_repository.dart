import 'package:core_data/core_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'owner_control_center_contract.dart';

class OwnerControlCenterRepository {
  OwnerControlCenterRepository(this._preferences);

  static const key = 'mizan_owner_control_settings_v1';
  static const auditKey = 'mizan_owner_control_settings_audit_v1';
  final SharedPreferences _preferences;

  OwnerControlSettings load() {
    final encoded = _preferences.getString(key);
    if (encoded == null) return OwnerControlSettings();
    try {
      return OwnerControlSettings.decode(encoded);
    } on FormatException {
      // Fail closed to a clean local configuration rather than accepting an
      // unknown or partially corrupt settings document.
      return OwnerControlSettings();
    }
  }

  Future<OwnerControlSettings> save(OwnerControlSettings settings) async {
    final validation = OwnerControlSettings.validate(settings);
    if (!validation.isValid) {
      throw ArgumentError(validation.errors.join('; '));
    }
    final didSave = await _preferences.setString(key, settings.encode());
    if (!didSave) throw StateError('Owner settings could not be persisted');
    await _appendAudit(settings);
    return settings;
  }

  Future<OwnerControlSettings> saveSection(
    OwnerControlSettings current,
    String section,
    Map<String, Object?> values,
  ) {
    final next = current.copyWithSection(section, values);
    return save(next);
  }

  List<OwnerSettingsAuditEntry> auditLog() {
    final encoded = _preferences.getString(auditKey);
    if (encoded == null) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const [];
      return decoded
          .map(OwnerSettingsAuditEntry.fromJson)
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<void> _appendAudit(OwnerControlSettings settings) async {
    final next = [
      ...auditLog(),
      OwnerSettingsAuditEntry(
        revision: settings.revision,
        sectionNames: settings.sections.keys.toList(growable: false),
        createdAt: DateTime.now().toUtc(),
      ),
    ];
    final bounded = next.length > 100 ? next.sublist(next.length - 100) : next;
    await _preferences.setString(
      auditKey,
      jsonEncode(bounded.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    await _preferences.remove(key);
    await _preferences.remove(auditKey);
  }
}

class OwnerSettingsAuditEntry {
  const OwnerSettingsAuditEntry({
    required this.revision,
    required this.sectionNames,
    required this.createdAt,
  });

  final int revision;
  final List<String> sectionNames;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'revision': revision,
    'section_names': sectionNames,
    'created_at': createdAt.toIso8601String(),
  };

  factory OwnerSettingsAuditEntry.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid audit entry');
    final json = Map<String, Object?>.from(value);
    final sections = json['section_names'];
    if (json['revision'] is! int ||
        (json['revision'] as int) < 0 ||
        sections is! List ||
        !sections.every((item) => item is String) ||
        json['created_at'] is! String ||
        DateTime.tryParse(json['created_at'] as String) == null) {
      throw const FormatException('Audit entry values are invalid');
    }
    return OwnerSettingsAuditEntry(
      revision: json['revision'] as int,
      sectionNames: List<String>.from(sections),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

final ownerControlCenterRepositoryProvider =
    Provider<OwnerControlCenterRepository>((ref) {
      return OwnerControlCenterRepository(ref.watch(sharedPreferencesProvider));
    });

final ownerControlSettingsProvider =
    StateNotifierProvider<OwnerControlSettingsController, OwnerControlSettings>(
      (ref) => OwnerControlSettingsController(
        ref.watch(ownerControlCenterRepositoryProvider),
      ),
    );

class OwnerControlSettingsController
    extends StateNotifier<OwnerControlSettings> {
  OwnerControlSettingsController(this._repository) : super(_repository.load());

  final OwnerControlCenterRepository _repository;

  Future<void> saveSection(String section, Map<String, Object?> values) async {
    state = await _repository.saveSection(state, section, values);
  }

  Future<void> replace(OwnerControlSettings settings) async {
    state = await _repository.save(settings);
  }

  Future<void> reset() async {
    await _repository.clear();
    state = OwnerControlSettings();
  }
}
