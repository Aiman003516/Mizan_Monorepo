import 'dart:convert';

/// Stable schema identifier for proposals produced by a local assistant model.
///
/// This is deliberately separate from the server action schema. A local model
/// proposes intent and fields; the application and server remain authoritative
/// for record identity, authorization, accounting validation, and execution.
const localAiProposalSchemaVersion = 'mizan.local-ai.proposal/v1';

abstract final class LocalAiActionTypes {
  static const none = 'none';
  static const unsupported = 'unsupported';
  static const customerUpdate = 'customer_update';
  static const vendorUpdate = 'vendor_update';
  static const invoiceUpdate = 'invoice_update';
  static const billUpdate = 'bill_update';
  static const balanceAdjustment = 'balance_adjustment';
  static const journalEntryPost = 'journal_entry_post';
  static const customerArchive = 'customer_archive';
  static const vendorArchive = 'vendor_archive';
  static const invoiceVoid = 'invoice_void';
  static const billVoid = 'bill_void';

  static const supportedMutations = <String>{
    customerUpdate,
    vendorUpdate,
    invoiceUpdate,
    billUpdate,
    balanceAdjustment,
    journalEntryPost,
    customerArchive,
    vendorArchive,
    invoiceVoid,
    billVoid,
  };
}

enum LocalAiIntent {
  explain,
  proposeMutation,
  requestMissingInformation,
  unsupported,
}

extension LocalAiIntentCodec on LocalAiIntent {
  String get value => switch (this) {
    LocalAiIntent.explain => 'explain',
    LocalAiIntent.proposeMutation => 'propose_mutation',
    LocalAiIntent.requestMissingInformation => 'request_missing_information',
    LocalAiIntent.unsupported => 'unsupported',
  };

  static LocalAiIntent parse(Object? value) {
    return switch (value) {
      'explain' => LocalAiIntent.explain,
      'propose_mutation' => LocalAiIntent.proposeMutation,
      'request_missing_information' => LocalAiIntent.requestMissingInformation,
      'unsupported' => LocalAiIntent.unsupported,
      _ => throw const FormatException('Invalid local AI intent'),
    };
  }
}

enum LocalAiEntityType {
  recordName,
  recordNumber,
  amountMinor,
  currencyCode,
  date,
  email,
  phone,
  accountName,
}

extension LocalAiEntityTypeCodec on LocalAiEntityType {
  String get value => switch (this) {
    LocalAiEntityType.recordName => 'record_name',
    LocalAiEntityType.recordNumber => 'record_number',
    LocalAiEntityType.amountMinor => 'amount_minor',
    LocalAiEntityType.currencyCode => 'currency_code',
    LocalAiEntityType.date => 'date',
    LocalAiEntityType.email => 'email',
    LocalAiEntityType.phone => 'phone',
    LocalAiEntityType.accountName => 'account_name',
  };

  static LocalAiEntityType parse(Object? value) {
    for (final type in LocalAiEntityType.values) {
      if (type.value == value) return type;
    }
    throw const FormatException('Invalid local AI entity type');
  }
}

class LocalAiEntity {
  const LocalAiEntity({
    required this.type,
    required this.text,
    required this.normalized,
    required this.confidence,
  });

  final LocalAiEntityType type;
  final String text;
  final String normalized;
  final double confidence;

  Map<String, Object?> toJson() => {
    'type': type.value,
    'text': text,
    'normalized': normalized,
    'confidence': confidence,
  };

  factory LocalAiEntity.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid local AI entity');
    final json = Map<String, Object?>.from(value);
    const keys = {'type', 'text', 'normalized', 'confidence'};
    if (!json.keys.toSet().containsAll(keys) ||
        json.keys.any((key) => !keys.contains(key))) {
      throw const FormatException('Local AI entity keys are invalid');
    }
    final text = json['text'];
    final normalized = json['normalized'];
    final confidence = json['confidence'];
    if (text is! String || normalized is! String || confidence is! num) {
      throw const FormatException('Local AI entity fields are invalid');
    }
    final confidenceValue = confidence.toDouble();
    if (confidenceValue < 0 || confidenceValue > 1) {
      throw const FormatException('Local AI entity confidence is invalid');
    }
    return LocalAiEntity(
      type: LocalAiEntityTypeCodec.parse(json['type']),
      text: text,
      normalized: normalized,
      confidence: confidenceValue,
    );
  }
}

class LocalAiProposal {
  const LocalAiProposal({
    required this.intent,
    required this.actionType,
    required this.fields,
    required this.entities,
    required this.missingFields,
    required this.confidence,
    required this.requiresConfirmation,
    required this.locale,
    this.source = 'local',
    this.schemaVersion = localAiProposalSchemaVersion,
  });

  final String schemaVersion;
  final LocalAiIntent intent;
  final String actionType;
  final Map<String, Object?> fields;
  final List<LocalAiEntity> entities;
  final List<String> missingFields;
  final double confidence;
  final bool requiresConfirmation;
  final String locale;
  final String source;

  bool get isMutation =>
      LocalAiActionTypes.supportedMutations.contains(actionType);

  Map<String, Object?> toJson() => {
    'schema_version': schemaVersion,
    'intent': intent.value,
    'action_type': actionType,
    'fields': fields,
    'entities': entities.map((entity) => entity.toJson()).toList(),
    'missing_fields': missingFields,
    'confidence': confidence,
    'requires_confirmation': requiresConfirmation,
    'locale': locale,
    'source': source,
  };

  String encode() => jsonEncode(toJson());

  factory LocalAiProposal.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid local AI proposal');
    final json = Map<String, Object?>.from(value);
    const keys = {
      'schema_version',
      'intent',
      'action_type',
      'fields',
      'entities',
      'missing_fields',
      'confidence',
      'requires_confirmation',
      'locale',
      'source',
    };
    final actualKeys = json.keys.toSet();
    if (actualKeys.length != keys.length || !actualKeys.containsAll(keys)) {
      throw const FormatException('Local AI proposal keys are invalid');
    }
    final schemaVersion = json['schema_version'];
    final actionType = json['action_type'];
    final fields = json['fields'];
    final entities = json['entities'];
    final missingFields = json['missing_fields'];
    final confidence = json['confidence'];
    final requiresConfirmation = json['requires_confirmation'];
    final locale = json['locale'];
    final source = json['source'];
    if (schemaVersion != localAiProposalSchemaVersion ||
        actionType is! String ||
        fields is! Map ||
        entities is! List ||
        missingFields is! List ||
        confidence is! num ||
        requiresConfirmation is! bool ||
        locale is! String ||
        source is! String) {
      throw const FormatException('Local AI proposal fields are invalid');
    }
    final confidenceValue = confidence.toDouble();
    if (confidenceValue < 0 ||
        confidenceValue > 1 ||
        locale.trim().isEmpty ||
        source.trim().isEmpty ||
        missingFields.any((item) => item is! String || item.trim().isEmpty)) {
      throw const FormatException('Local AI proposal values are invalid');
    }
    return LocalAiProposal(
      schemaVersion: schemaVersion as String,
      intent: LocalAiIntentCodec.parse(json['intent']),
      actionType: actionType,
      fields: Map<String, Object?>.from(fields),
      entities: entities.map(LocalAiEntity.fromJson).toList(growable: false),
      missingFields: missingFields.cast<String>().toList(growable: false),
      confidence: confidenceValue,
      requiresConfirmation: requiresConfirmation,
      locale: locale,
      source: source,
    );
  }

  factory LocalAiProposal.decode(String value) =>
      LocalAiProposal.fromJson(jsonDecode(value));
}
