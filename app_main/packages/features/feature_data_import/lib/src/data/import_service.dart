// FILE: feature_data_import/lib/src/data/import_service.dart
// Purpose: Core import engine - validates and imports data

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';

import 'file_parser.dart';
import 'field_mapper.dart';

/// Result of an import operation
class ImportResult {
  final int successCount;
  final int errorCount;
  final List<ImportError> errors;
  final Duration duration;

  const ImportResult({
    required this.successCount,
    required this.errorCount,
    required this.errors,
    required this.duration,
  });

  bool get hasErrors => errorCount > 0;
  int get totalCount => successCount + errorCount;
}

/// Error during import
class ImportError {
  final int rowNumber;
  final String columnName;
  final String message;
  final dynamic value;

  const ImportError({
    required this.rowNumber,
    required this.columnName,
    required this.message,
    this.value,
  });

  @override
  String toString() => 'Row $rowNumber, Column "$columnName": $message';
}

/// Preview of data before import
class ImportPreview {
  final ParsedFileResult parsedData;
  final List<FieldMapping> suggestedMappings;
  final String targetEntity;

  const ImportPreview({
    required this.parsedData,
    required this.suggestedMappings,
    required this.targetEntity,
  });
}

/// Main import service
class ImportService {
  final AppDatabase _db;
  final FileParser _parser;

  ImportService(this._db) : _parser = FileParser();

  /// Parse file and generate import preview with suggested mappings
  Future<ImportPreview> parseAndPreview(File file, String targetEntity) async {
    final parsedData = await _parser.parseFile(file);

    final suggestedMappings = FieldMapperService.autoSuggestMappings(
      parsedData.headers,
      targetEntity,
    );

    return ImportPreview(
      parsedData: parsedData,
      suggestedMappings: suggestedMappings,
      targetEntity: targetEntity,
    );
  }

  /// Execute import with given mappings
  Future<ImportResult> executeImport({
    required ParsedFileResult parsedData,
    required List<FieldMapping> mappings,
    required String targetEntity,
  }) async {
    final stopwatch = Stopwatch()..start();
    final errors = <ImportError>[];
    int successCount = 0;

    for (var i = 0; i < parsedData.rows.length; i++) {
      final rowNumber = i + 2; // +2 because row 1 is header
      final row = parsedData.rows[i];

      try {
        // Validate required fields
        final validationErrors = _validateRow(row, mappings, rowNumber);
        if (validationErrors.isNotEmpty) {
          errors.addAll(validationErrors);
          continue;
        }

        // Apply mappings to get structured data
        final mappedData = FieldMapperService.applyMappings(row, mappings);

        // Insert into database based on entity type
        await _insertRow(targetEntity, mappedData);
        successCount++;
      } catch (e) {
        errors.add(ImportError(
          rowNumber: rowNumber,
          columnName: '',
          message: 'Unexpected error: $e',
        ));
      }
    }

    stopwatch.stop();
    return ImportResult(
      successCount: successCount,
      errorCount: errors.length,
      errors: errors,
      duration: stopwatch.elapsed,
    );
  }

  /// Validate a row based on mappings
  List<ImportError> _validateRow(
    Map<String, dynamic> row,
    List<FieldMapping> mappings,
    int rowNumber,
  ) {
    final errors = <ImportError>[];

    for (final mapping in mappings) {
      if (mapping.isSkipped) continue;

      final value = row[mapping.sourceColumn];

      // Check required fields
      if (mapping.isExistingField) {
        final fieldDefs =
            EntityFieldDefinitions.getFieldsFor(mapping.targetEntity);
        final fieldDef =
            fieldDefs.where((f) => f.name == mapping.targetField).firstOrNull;

        if (fieldDef != null &&
            fieldDef.required &&
            (value == null || value.toString().trim().isEmpty)) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            columnName: mapping.sourceColumn,
            message: '${fieldDef.label} is required',
            value: value,
          ));
        }
      }

      if (mapping.customField?.isRequired == true &&
          (value == null || value.toString().trim().isEmpty)) {
        errors.add(ImportError(
          rowNumber: rowNumber,
          columnName: mapping.sourceColumn,
          message: '${mapping.customField!.label} is required',
          value: value,
        ));
      }
    }

    return errors;
  }

  /// Insert a mapped row into the database
  Future<void> _insertRow(String entity, Map<String, dynamic> data) async {
    switch (entity) {
      case 'accounts':
        await _db.into(_db.accounts).insert(
              AccountsCompanion.insert(
                name: data['name'] as String? ?? 'Imported Account',
                type: data['type'] as String? ?? 'asset',
                initialBalance: data['initialBalance'] as int? ?? 0,
                phoneNumber: Value(data['phoneNumber'] as String?),
                customAttributes: Value(data['customAttributes'] as String?),
              ),
            );
        break;

      case 'products':
        // Need to get or create a default category
        final categoryId = await _getOrCreateDefaultCategory();
        await _db.into(_db.products).insert(
              ProductsCompanion.insert(
                name: data['name'] as String? ?? 'Imported Product',
                price: data['price'] as int? ?? 0,
                categoryId: categoryId,
                barcode: Value(data['barcode'] as String?),
                quantityOnHand: Value(data['quantityOnHand'] as double? ?? 0.0),
                averageCost: Value(data['averageCost'] as int? ?? 0),
                customAttributes: Value(data['customAttributes'] as String?),
              ),
            );
        break;

      case 'categories':
        await _db.into(_db.categories).insert(
              CategoriesCompanion.insert(
                name: data['name'] as String? ?? 'Imported Category',
              ),
            );
        break;

      default:
        throw UnsupportedError(
            'Import to entity "$entity" is not yet supported');
    }
  }

  /// Get or create a default category for product imports
  Future<String> _getOrCreateDefaultCategory() async {
    final existing = await (_db.select(_db.categories)
          ..where((t) => t.name.equals('Imported'))
          ..limit(1))
        .getSingleOrNull();

    if (existing != null) return existing.id;

    final newCategory = await _db.into(_db.categories).insertReturning(
          CategoriesCompanion.insert(name: 'Imported'),
        );
    return newCategory.id;
  }
}

/// Provider for ImportService
final importServiceProvider = Provider<ImportService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ImportService(db);
});
