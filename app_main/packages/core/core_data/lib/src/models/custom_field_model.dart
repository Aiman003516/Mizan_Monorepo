// FILE: packages/core/core_data/lib/src/models/custom_field_model.dart

/// 🧩 Supported Data Types for Custom Fields
enum CustomFieldType { text, number, boolean, date }

/// 🧩 The Definition of a Custom Field
/// e.g., "Color" (Text) for "Products"
class CustomFieldDefinition {
  final String id;
  final String key; // The JSON key (e.g., "color_code")
  final String label; // The Display Name (e.g., "Fabric Color")
  final String
  targetTable; // products, accounts, transactions, customers, vendors
  final CustomFieldType type;
  final bool isRequired;

  const CustomFieldDefinition({
    required this.id,
    required this.key,
    required this.label,
    required this.targetTable,
    this.type = CustomFieldType.text,
    this.isRequired = false,
  });

  /// Convert from Firestore
  factory CustomFieldDefinition.fromJson(Map<String, dynamic> json, String id) {
    return CustomFieldDefinition(
      id: id,
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? 'Unnamed Field',
      targetTable:
          (json['targetTable'] ?? json['target_table']) as String? ??
          'products',
      type: CustomFieldType.values.firstWhere(
        (e) =>
            e.name ==
            ((json['type'] ?? json['data_type']) as String? ?? 'text'),
        orElse: () => CustomFieldType.text,
      ),
      isRequired: (json['isRequired'] ?? json['is_required']) as bool? ?? false,
    );
  }

  /// Convert to Firestore
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'target_table': targetTable,
      'data_type': type.name,
      'is_required': isRequired,
    };
  }
}
