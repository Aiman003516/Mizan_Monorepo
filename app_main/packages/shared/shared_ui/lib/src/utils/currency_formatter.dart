// FILE: packages/shared/shared_ui/lib/src/utils/currency_formatter.dart
import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Converts database cents (Int) to a UI-ready formatted string.
  /// Example: 1050 -> "$10.50"
  static String formatCentsToCurrency(int cents, {String symbol = '\$'}) {
    final double amount = cents / 100.0;
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(amount);
  }

  /// Converts database cents (Int) to a double for calculations/TextFields.
  /// Example: 1050 -> 10.50
  static double centsToDouble(int cents) {
    return cents / 100.0;
  }

  /// Converts a UI double (from TextField) to database cents (Int).
  /// Example: 10.50 -> 1050
  static int doubleToCents(double amount) {
    return (amount * 100).round();
  }
}