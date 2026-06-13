/// Universal CSV Export Service.
/// Provides a simple interface to convert data to CSV format.
class CsvExportService {
  /// Converts a list of maps to CSV string.
  /// [data] - List of records as Map<String, dynamic>
  /// [columns] - Optional list of column names to include (in order)
  String toCSV(List<Map<String, dynamic>> data, {List<String>? columns}) {
    if (data.isEmpty) return '';

    final headers = columns ?? data.first.keys.toList();
    final buffer = StringBuffer();

    // Write header row
    buffer.writeln(headers.map(_escapeCSV).join(','));

    // Write data rows
    for (final row in data) {
      final values = headers.map((h) => _escapeCSV(row[h]?.toString() ?? ''));
      buffer.writeln(values.join(','));
    }

    return buffer.toString();
  }

  /// Escapes a value for CSV format.
  String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Helper to convert common entities to CSV-ready maps.
  Map<String, dynamic> transactionToMap(dynamic transaction) {
    return {
      'ID': transaction.id,
      'Date': transaction.transactionDate.toIso8601String(),
      'Description': transaction.description,
      'Currency': transaction.currencyCode,
    };
  }

  Map<String, dynamic> invoiceToMap(dynamic invoice) {
    return {
      'Invoice Number': invoice.invoiceNumber,
      'Date': invoice.invoiceDate.toIso8601String(),
      'Due Date': invoice.dueDate.toIso8601String(),
      'Subtotal': (invoice.subtotal / 100).toStringAsFixed(2),
      'Tax': (invoice.taxAmount / 100).toStringAsFixed(2),
      'Total': (invoice.totalAmount / 100).toStringAsFixed(2),
      'Status': invoice.status,
    };
  }

  Map<String, dynamic> productToMap(dynamic product) {
    return {
      'Name': product.name,
      'Price': (product.price / 100).toStringAsFixed(2),
      'Quantity': product.quantityOnHand,
      'Barcode': product.barcode ?? '',
    };
  }
}

/// Singleton instance for easy access
final csvExportService = CsvExportService();
