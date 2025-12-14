// FILE: feature_data_import/lib/src/data/field_mapper.dart
// Purpose: Map imported columns to database fields or create custom fields

import 'dart:convert';

/// Represents a mapping from a source column to a target field
class FieldMapping {
  /// Column name from the imported file
  final String sourceColumn;

  /// Target entity (accounts, products, transactions, etc.)
  final String targetEntity;

  /// Target field name (null if creating custom field)
  final String? targetField;

  /// Custom field definition (if creating new field)
  final CustomFieldDef? customField;

  /// Whether this mapping is skipped (column ignored)
  final bool isSkipped;

  const FieldMapping({
    required this.sourceColumn,
    required this.targetEntity,
    this.targetField,
    this.customField,
    this.isSkipped = false,
  });

  /// Create a mapping to an existing database field
  factory FieldMapping.toExistingField({
    required String sourceColumn,
    required String targetEntity,
    required String targetField,
  }) {
    return FieldMapping(
      sourceColumn: sourceColumn,
      targetEntity: targetEntity,
      targetField: targetField,
    );
  }

  /// Create a mapping to a new custom field
  factory FieldMapping.toCustomField({
    required String sourceColumn,
    required String targetEntity,
    required CustomFieldDef customField,
  }) {
    return FieldMapping(
      sourceColumn: sourceColumn,
      targetEntity: targetEntity,
      customField: customField,
    );
  }

  /// Create a skipped mapping (ignore this column)
  factory FieldMapping.skipped(String sourceColumn) {
    return FieldMapping(
      sourceColumn: sourceColumn,
      targetEntity: '',
      isSkipped: true,
    );
  }

  /// Whether this maps to a custom field
  bool get isCustomField => customField != null;

  /// Whether this maps to an existing field
  bool get isExistingField => targetField != null && !isCustomField;

  Map<String, dynamic> toJson() => {
        'sourceColumn': sourceColumn,
        'targetEntity': targetEntity,
        'targetField': targetField,
        'customField': customField?.toJson(),
        'isSkipped': isSkipped,
      };

  factory FieldMapping.fromJson(Map<String, dynamic> json) => FieldMapping(
        sourceColumn: json['sourceColumn'] as String,
        targetEntity: json['targetEntity'] as String,
        targetField: json['targetField'] as String?,
        customField: json['customField'] != null
            ? CustomFieldDef.fromJson(
                json['customField'] as Map<String, dynamic>)
            : null,
        isSkipped: json['isSkipped'] as bool? ?? false,
      );
}

/// Definition for a new custom field
class CustomFieldDef {
  /// Field name (will be stored in customAttributes JSON)
  final String name;

  /// Field type: text, number, date, boolean
  final String type;

  /// Display label for the field
  final String label;

  /// Whether field is required
  final bool isRequired;

  const CustomFieldDef({
    required this.name,
    required this.type,
    required this.label,
    this.isRequired = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'label': label,
        'isRequired': isRequired,
      };

  factory CustomFieldDef.fromJson(Map<String, dynamic> json) => CustomFieldDef(
        name: json['name'] as String,
        type: json['type'] as String,
        label: json['label'] as String,
        isRequired: json['isRequired'] as bool? ?? false,
      );
}

/// Known entity types and their mappable fields
class EntityFieldDefinitions {
  static const Map<String, List<FieldDef>> entities = {
    'accounts': [
      FieldDef(
          name: 'name', label: 'Account Name', type: 'text', required: true),
      FieldDef(
          name: 'type', label: 'Account Type', type: 'text', required: true),
      FieldDef(
          name: 'initialBalance', label: 'Initial Balance', type: 'number'),
      FieldDef(name: 'phoneNumber', label: 'Phone Number', type: 'text'),
    ],
    'products': [
      FieldDef(
          name: 'name', label: 'Product Name', type: 'text', required: true),
      FieldDef(name: 'price', label: 'Price', type: 'number', required: true),
      FieldDef(name: 'barcode', label: 'Barcode', type: 'text'),
      FieldDef(name: 'quantityOnHand', label: 'Quantity', type: 'number'),
      FieldDef(name: 'averageCost', label: 'Average Cost', type: 'number'),
    ],
    'transactions': [
      FieldDef(
          name: 'description',
          label: 'Description',
          type: 'text',
          required: true),
      FieldDef(
          name: 'transactionDate', label: 'Date', type: 'date', required: true),
      FieldDef(name: 'currencyCode', label: 'Currency', type: 'text'),
    ],
    'categories': [
      FieldDef(
          name: 'name', label: 'Category Name', type: 'text', required: true),
    ],
  };

  /// Get fields for an entity
  static List<FieldDef> getFieldsFor(String entity) {
    return entities[entity] ?? [];
  }

  /// Get all entity names
  static List<String> get entityNames => entities.keys.toList();
}

/// Definition of a known database field
class FieldDef {
  final String name;
  final String label;
  final String type;
  final bool required;

  const FieldDef({
    required this.name,
    required this.label,
    required this.type,
    this.required = false,
  });
}

/// Service for managing field mappings
class FieldMapperService {
  /// Auto-suggest mappings based on column names
  static List<FieldMapping> autoSuggestMappings(
    List<String> sourceColumns,
    String targetEntity,
  ) {
    final knownFields = EntityFieldDefinitions.getFieldsFor(targetEntity);
    final mappings = <FieldMapping>[];

    for (final column in sourceColumns) {
      final normalizedColumn =
          column.toLowerCase().replaceAll(RegExp(r'[_\s-]'), '');

      // Try to find a matching known field
      FieldDef? matchedField;
      for (final field in knownFields) {
        final normalizedField = field.name.toLowerCase();
        final normalizedLabel =
            field.label.toLowerCase().replaceAll(RegExp(r'[_\s-]'), '');

        if (normalizedColumn == normalizedField ||
            normalizedColumn == normalizedLabel ||
            normalizedColumn.contains(normalizedField) ||
            normalizedField.contains(normalizedColumn)) {
          matchedField = field;
          break;
        }
      }

      if (matchedField != null) {
        mappings.add(FieldMapping.toExistingField(
          sourceColumn: column,
          targetEntity: targetEntity,
          targetField: matchedField.name,
        ));
      } else {
        // Suggest as custom field
        mappings.add(FieldMapping.toCustomField(
          sourceColumn: column,
          targetEntity: targetEntity,
          customField: CustomFieldDef(
            name: _sanitizeFieldName(column),
            type: 'text', // Default, can be changed by user
            label: column,
          ),
        ));
      }
    }

    return mappings;
  }

  /// Sanitize a column name to be a valid field name
  static String _sanitizeFieldName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Apply mappings to row data, returning structured result
  static Map<String, dynamic> applyMappings(
    Map<String, dynamic> sourceRow,
    List<FieldMapping> mappings,
  ) {
    final result = <String, dynamic>{};
    final customAttributes = <String, dynamic>{};

    for (final mapping in mappings) {
      if (mapping.isSkipped) continue;

      final value = sourceRow[mapping.sourceColumn];

      if (mapping.isExistingField) {
        result[mapping.targetField!] = _convertValue(value, 'text');
      } else if (mapping.isCustomField) {
        customAttributes[mapping.customField!.name] = _convertValue(
          value,
          mapping.customField!.type,
        );
      }
    }

    if (customAttributes.isNotEmpty) {
      result['customAttributes'] = jsonEncode(customAttributes);
    }

    return result;
  }

  /// Convert value to appropriate type
  static dynamic _convertValue(dynamic value, String type) {
    if (value == null) return null;

    final strValue = value.toString().trim();
    if (strValue.isEmpty) return null;

    switch (type) {
      case 'number':
        return int.tryParse(strValue) ??
            double.tryParse(strValue)?.round() ??
            0;
      case 'date':
        return DateTime.tryParse(strValue)?.toIso8601String();
      case 'boolean':
        final lower = strValue.toLowerCase();
        return lower == 'true' || lower == 'yes' || lower == '1';
      default:
        return strValue;
    }
  }
}
