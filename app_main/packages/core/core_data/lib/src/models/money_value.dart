// FILE: packages/core/core_data/lib/src/models/money_value.dart
// Purpose: Integer-based money representation to eliminate floating-point precision issues

import 'package:intl/intl.dart';

/// A value class representing money stored as integers (smallest unit).
/// This eliminates floating-point precision issues ("ghost money").
///
/// Example: $100.50 is stored as 10050 (cents)
class MoneyValue {
  /// Amount in smallest unit (cents, fils, etc.)
  final int amount;

  /// ISO 4217 currency code (e.g., 'USD', 'SAR', 'EUR')
  final String currency;

  const MoneyValue({required this.amount, required this.currency});

  /// Create from a decimal value (user input)
  /// Example: MoneyValue.fromDecimal(100.50, 'USD') → amount: 10050
  factory MoneyValue.fromDecimal(
    double value,
    String currency, {
    int decimals = 2,
  }) {
    final multiplier = _getMultiplier(decimals);
    return MoneyValue(amount: (value * multiplier).round(), currency: currency);
  }

  /// Zero value for a currency
  factory MoneyValue.zero(String currency) {
    return MoneyValue(amount: 0, currency: currency);
  }

  /// Get the divisor for a currency (100 for USD, 1000 for some currencies)
  static int _getMultiplier(int decimals) {
    switch (decimals) {
      case 0:
        return 1;
      case 1:
        return 10;
      case 2:
        return 100;
      case 3:
        return 1000;
      default:
        return 100;
    }
  }

  /// Get decimal representation for display
  double toDecimal({int decimals = 2}) {
    return amount / _getMultiplier(decimals);
  }

  /// Format for display with currency symbol
  String toDisplayString({int decimals = 2, String? symbol}) {
    final formatter = NumberFormat.currency(
      symbol: symbol ?? currency,
      decimalDigits: decimals,
    );
    return formatter.format(toDecimal(decimals: decimals));
  }

  /// Add two money values (must be same currency)
  MoneyValue operator +(MoneyValue other) {
    assert(currency == other.currency, 'Cannot add different currencies');
    return MoneyValue(amount: amount + other.amount, currency: currency);
  }

  /// Subtract two money values (must be same currency)
  MoneyValue operator -(MoneyValue other) {
    assert(currency == other.currency, 'Cannot subtract different currencies');
    return MoneyValue(amount: amount - other.amount, currency: currency);
  }

  /// Multiply by a factor (returns integer amount, ghost money tracked separately)
  MoneyValue operator *(double factor) {
    return MoneyValue(amount: (amount * factor).round(), currency: currency);
  }

  /// Safe division that tracks ghost money (remainder)
  /// Returns (result per part, ghost money amount)
  static MoneyDivisionResult divide(
    int totalAmount,
    int parts,
    String currency,
  ) {
    if (parts <= 0) {
      throw ArgumentError('Parts must be greater than zero');
    }

    final perPart = totalAmount ~/ parts; // Integer division
    final remainder =
        totalAmount % parts; // Ghost money (cannot be distributed)

    return MoneyDivisionResult(
      perPart: MoneyValue(amount: perPart, currency: currency),
      ghostAmount: remainder,
      parts: parts,
    );
  }

  /// Apply percentage and return result with ghost tracking
  static MoneyPercentageResult percentage(
    int amount,
    double percent,
    String currency,
  ) {
    final exactResult = amount * (percent / 100);
    final roundedResult = exactResult.round();
    final ghostAmount = (exactResult - roundedResult).abs().round();

    return MoneyPercentageResult(
      result: MoneyValue(amount: roundedResult, currency: currency),
      ghostAmount: ghostAmount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MoneyValue &&
        other.amount == amount &&
        other.currency == currency;
  }

  @override
  int get hashCode => amount.hashCode ^ currency.hashCode;

  @override
  String toString() => 'MoneyValue($amount $currency)';
}

/// Result of dividing money into parts
class MoneyDivisionResult {
  /// Amount per part (after integer division)
  final MoneyValue perPart;

  /// Ghost money - the remainder that cannot be distributed evenly
  final int ghostAmount;

  /// Number of parts divided into
  final int parts;

  const MoneyDivisionResult({
    required this.perPart,
    required this.ghostAmount,
    required this.parts,
  });

  /// Check if there is ghost money
  bool get hasGhostMoney => ghostAmount > 0;
}

/// Result of applying a percentage to money
class MoneyPercentageResult {
  /// The calculated result
  final MoneyValue result;

  /// Ghost money from rounding
  final int ghostAmount;

  const MoneyPercentageResult({
    required this.result,
    required this.ghostAmount,
  });

  /// Check if there is ghost money
  bool get hasGhostMoney => ghostAmount > 0;
}
