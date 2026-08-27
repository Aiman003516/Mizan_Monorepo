import '../models/procurement_models.dart';

/// Client-side validation shared by procurement UI and repositories.
///
/// The server repeats every rule and remains authoritative. These checks keep
/// malformed input from reaching RPC serialization and provide deterministic
/// validation that can be covered without a live Supabase session.
abstract final class ProcurementValidation {
  static final RegExp _currencyPattern = RegExp(r'^[A-Z]{3,5}$');
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  static String currency(String value) {
    final normalized = value.trim().toUpperCase();
    if (!_currencyPattern.hasMatch(normalized)) {
      throw ArgumentError.value(value, 'currencyCode');
    }
    return normalized;
  }

  static void documentNumber(String value, String name) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 80) {
      throw ArgumentError.value(value, name);
    }
  }

  static void reason(String value, String name) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 1000) {
      throw ArgumentError.value(value, name);
    }
  }

  static void idempotencyKey(String value, String name) {
    final normalized = value.trim();
    if (normalized.length < 8 || normalized.length > 200) {
      throw ArgumentError.value(value, name);
    }
  }

  static void purpose(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 1000) {
      throw ArgumentError.value(value, 'purpose');
    }
  }

  static void id(String value, String name) {
    if (!_uuidPattern.hasMatch(value.trim())) {
      throw ArgumentError.value(value, name);
    }
  }

  static void quantity(double value) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(value, 'quantity');
    }
  }

  static void nonNegativeMinor(int value, String name) {
    if (value < 0) throw ArgumentError.value(value, name);
  }

  static void lines(
    List<ProcurementLineInput> values, {
    bool requisition = false,
  }) {
    if (values.isEmpty) throw ArgumentError.value(values, 'lines');
    for (final line in values) {
      final description = line.description.trim();
      if (description.isEmpty || description.length > 500) {
        throw ArgumentError.value(line.description, 'description');
      }
      quantity(line.quantity);
      nonNegativeMinor(line.unitPriceMinor, 'unitPriceMinor');
      nonNegativeMinor(line.taxMinor, 'taxMinor');
      if (requisition && line.taxMinor != 0) {
        throw ArgumentError('Requisition lines do not accept tax amounts');
      }
    }
  }

  static void receiptLines(List<ProcurementReceiptLineInput> values) {
    if (values.isEmpty) throw ArgumentError.value(values, 'lines');
    for (final line in values) {
      id(line.purchaseOrderLineId, 'purchaseOrderLineId');
      quantity(line.quantity);
      nonNegativeMinor(line.unitCostMinor, 'unitCostMinor');
    }
  }
}
