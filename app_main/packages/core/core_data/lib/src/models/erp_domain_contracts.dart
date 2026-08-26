import 'dart:convert';

enum LedgerBookType { leading, local, extension, simulation }

extension LedgerBookTypeCodec on LedgerBookType {
  String get wireValue => switch (this) {
    LedgerBookType.leading => 'leading',
    LedgerBookType.local => 'local',
    LedgerBookType.extension => 'extension',
    LedgerBookType.simulation => 'simulation',
  };

  static LedgerBookType fromWire(String? value) {
    return LedgerBookType.values.firstWhere(
      (book) => book.wireValue == value?.trim().toLowerCase(),
      orElse: () => LedgerBookType.leading,
    );
  }
}

/// Controlled dimensions attached to a document or ledger line.
/// Unknown keys are rejected at construction time so reporting dimensions do
/// not silently drift between clients.
class DimensionSet {
  static const allowedKeys = <String>{
    'branch_id',
    'cost_center_id',
    'project_id',
    'campaign_id',
    'region_id',
    'fund_id',
  };

  const DimensionSet._(this.values);

  factory DimensionSet.fromMap(Map<String, dynamic> input) {
    final normalized = <String, String>{};
    for (final entry in input.entries) {
      final key = entry.key.trim().toLowerCase();
      final value = entry.value?.toString().trim() ?? '';
      if (!allowedKeys.contains(key)) {
        throw FormatException('Unsupported accounting dimension: $key');
      }
      if (value.isEmpty) {
        throw FormatException('Accounting dimension $key must not be empty');
      }
      normalized[key] = value;
    }
    return DimensionSet._(Map.unmodifiable(normalized));
  }

  final Map<String, String> values;

  static const empty = DimensionSet._(<String, String>{});

  bool get isEmpty => values.isEmpty;
  String? operator [](String key) => values[key];

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(values);

  @override
  bool operator ==(Object other) {
    return other is DimensionSet && _mapsEqual(values, other.values);
  }

  @override
  int get hashCode => Object.hashAll(
    values.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );

  static bool _mapsEqual(Map<String, String> left, Map<String, String> right) {
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) return false;
    }
    return true;
  }
}

class FinancialEventEnvelope {
  const FinancialEventEnvelope({
    required this.eventId,
    required this.schemaVersion,
    required this.tenantId,
    required this.aggregateType,
    required this.aggregateId,
    required this.eventType,
    required this.occurredAt,
    required this.payload,
  });

  final String eventId;
  final int schemaVersion;
  final String tenantId;
  final String aggregateType;
  final String aggregateId;
  final String eventType;
  final DateTime occurredAt;
  final Map<String, dynamic> payload;

  factory FinancialEventEnvelope.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    if (payload is! Map) {
      throw const FormatException('Financial event payload must be an object');
    }
    return FinancialEventEnvelope(
      eventId: _requiredString(json, 'event_id'),
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
      tenantId: _requiredString(json, 'tenant_id'),
      aggregateType: _requiredString(json, 'aggregate_type'),
      aggregateId: _requiredString(json, 'aggregate_id'),
      eventType: _requiredString(json, 'event_type'),
      occurredAt: _requiredDate(json, 'occurred_at'),
      payload: Map<String, dynamic>.from(payload),
    );
  }

  Map<String, dynamic> toJson() => {
    'event_id': eventId,
    'schema_version': schemaVersion,
    'tenant_id': tenantId,
    'aggregate_type': aggregateType,
    'aggregate_id': aggregateId,
    'event_type': eventType,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'payload': payload,
  };

  String encode() => jsonEncode(toJson());
}

enum IntegrationJobStatus { queued, running, succeeded, failed, cancelled }

extension IntegrationJobStatusCodec on IntegrationJobStatus {
  String get wireValue => name;

  static IntegrationJobStatus fromWire(String? value) {
    return IntegrationJobStatus.values.firstWhere(
      (status) => status.wireValue == value?.trim().toLowerCase(),
      orElse: () => IntegrationJobStatus.queued,
    );
  }
}

class IntegrationJob {
  const IntegrationJob({
    required this.id,
    required this.kind,
    required this.status,
    required this.idempotencyKey,
    required this.createdAt,
    this.completedAt,
    this.errorCode,
  });

  final String id;
  final String kind;
  final IntegrationJobStatus status;
  final String idempotencyKey;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorCode;

  factory IntegrationJob.fromJson(Map<String, dynamic> json) {
    return IntegrationJob(
      id: _requiredString(json, 'id'),
      kind: _requiredString(json, 'kind'),
      status: IntegrationJobStatusCodec.fromWire(json['status']?.toString()),
      idempotencyKey: _requiredString(json, 'idempotency_key'),
      createdAt: _requiredDate(json, 'created_at'),
      completedAt: _optionalDate(json['completed_at']),
      errorCode: json['error_code']?.toString(),
    );
  }
}

enum ExtensionHook { preValidate, preSave, postSave }

extension ExtensionHookCodec on ExtensionHook {
  String get wireValue => switch (this) {
    ExtensionHook.preValidate => 'pre_validate',
    ExtensionHook.preSave => 'pre_save',
    ExtensionHook.postSave => 'post_save',
  };
}

class ExtensionDescriptor {
  const ExtensionDescriptor({
    required this.id,
    required this.name,
    required this.version,
    required this.hook,
    required this.capabilities,
    required this.enabled,
  });

  final String id;
  final String name;
  final String version;
  final ExtensionHook hook;
  final Set<String> capabilities;
  final bool enabled;

  factory ExtensionDescriptor.fromJson(Map<String, dynamic> json) {
    final rawCapabilities = json['capabilities'];
    final capabilities = rawCapabilities is List
        ? rawCapabilities.map((value) => value.toString()).toSet()
        : <String>{};
    return ExtensionDescriptor(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      version: _requiredString(json, 'version'),
      hook: ExtensionHook.values.firstWhere(
        (hook) => hook.wireValue == json['hook']?.toString(),
        orElse: () => ExtensionHook.preValidate,
      ),
      capabilities: Set.unmodifiable(capabilities),
      enabled: json['enabled'] == true,
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString().trim() ?? '';
  if (value.isEmpty) throw FormatException('$key is required');
  return value;
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final value = _optionalDate(json[key]);
  if (value == null) throw FormatException('$key must be a valid date');
  return value;
}

DateTime? _optionalDate(dynamic value) {
  if (value is DateTime) return value.toUtc();
  return DateTime.tryParse(value?.toString() ?? '')?.toUtc();
}
