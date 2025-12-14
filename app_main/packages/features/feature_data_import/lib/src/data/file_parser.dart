// FILE: feature_data_import/lib/src/data/file_parser.dart
// Purpose: Parse CSV and Excel files into structured data

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

/// Result of parsing a file
class ParsedFileResult {
  /// Detected column headers
  final List<String> headers;

  /// Data rows (each row is a map of column name -> value)
  final List<Map<String, dynamic>> rows;

  /// Original file name
  final String fileName;

  /// File type detected
  final ImportFileType fileType;

  const ParsedFileResult({
    required this.headers,
    required this.rows,
    required this.fileName,
    required this.fileType,
  });

  /// Total number of rows
  int get rowCount => rows.length;

  /// Total number of columns
  int get columnCount => headers.length;
}

enum ImportFileType { csv, excel, unknown }

/// Parses CSV and Excel files into structured data
class FileParser {
  /// Parse a file and return structured data
  Future<ParsedFileResult> parseFile(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last.toLowerCase();

    if (fileName.endsWith('.csv')) {
      return _parseCsv(file, fileName);
    } else if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
      return _parseExcel(file, fileName);
    } else {
      throw UnsupportedError(
        'Unsupported file type. Please use CSV or Excel files.',
      );
    }
  }

  /// Parse CSV file
  Future<ParsedFileResult> _parseCsv(File file, String fileName) async {
    final content = await file.readAsString();
    final csvData = const CsvToListConverter().convert(content);

    if (csvData.isEmpty) {
      return ParsedFileResult(
        headers: [],
        rows: [],
        fileName: fileName,
        fileType: ImportFileType.csv,
      );
    }

    // First row is headers
    final headers = csvData.first.map((e) => e.toString().trim()).toList();

    // Remaining rows are data
    final rows = <Map<String, dynamic>>[];
    for (var i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      final rowMap = <String, dynamic>{};
      for (var j = 0; j < headers.length && j < row.length; j++) {
        rowMap[headers[j]] = row[j];
      }
      rows.add(rowMap);
    }

    return ParsedFileResult(
      headers: headers,
      rows: rows,
      fileName: fileName,
      fileType: ImportFileType.csv,
    );
  }

  /// Parse Excel file
  Future<ParsedFileResult> _parseExcel(File file, String fileName) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    // Use first sheet
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];

    if (sheet == null || sheet.rows.isEmpty) {
      return ParsedFileResult(
        headers: [],
        rows: [],
        fileName: fileName,
        fileType: ImportFileType.excel,
      );
    }

    // First row is headers
    final headerRow = sheet.rows.first;
    final headers = headerRow
        .map((cell) => cell?.value?.toString().trim() ?? '')
        .toList();

    // Remaining rows are data
    final rows = <Map<String, dynamic>>[];
    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final rowMap = <String, dynamic>{};
      for (var j = 0; j < headers.length && j < row.length; j++) {
        final cellValue = row[j]?.value;
        rowMap[headers[j]] = cellValue;
      }
      rows.add(rowMap);
    }

    return ParsedFileResult(
      headers: headers,
      rows: rows,
      fileName: fileName,
      fileType: ImportFileType.excel,
    );
  }

  /// Detect data type of a column based on sample values
  static String detectColumnType(List<dynamic> sampleValues) {
    if (sampleValues.isEmpty) return 'text';

    int numberCount = 0;
    int dateCount = 0;
    int boolCount = 0;

    for (final value in sampleValues) {
      if (value == null) continue;
      final str = value.toString().trim().toLowerCase();

      // Check if boolean
      if (str == 'true' ||
          str == 'false' ||
          str == 'yes' ||
          str == 'no' ||
          str == '1' ||
          str == '0') {
        boolCount++;
        continue;
      }

      // Check if number
      if (double.tryParse(str) != null) {
        numberCount++;
        continue;
      }

      // Check if date (simple patterns)
      if (DateTime.tryParse(str) != null ||
          RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}$').hasMatch(str)) {
        dateCount++;
        continue;
      }
    }

    final total = sampleValues.where((v) => v != null).length;
    if (total == 0) return 'text';

    // Return type with highest match rate (>70%)
    if (numberCount / total > 0.7) return 'number';
    if (dateCount / total > 0.7) return 'date';
    if (boolCount / total > 0.7) return 'boolean';

    return 'text';
  }
}
