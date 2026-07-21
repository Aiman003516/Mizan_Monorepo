// FILE: packages/shared/shared_ui/lib/src/utils/currency_formatter.dart
import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Converts database cents (Int) to a UI-ready formatted string.
  /// Example: 1050, symbol='﷼' -> "﷼10.50"
  /// NOTE: Do NOT use the default symbol='$'. Always pass the user's
  /// configured symbol from PreferencesRepository.getCurrencySymbol().
  static String formatCentsToCurrency(int cents, {String symbol = ''}) {
    final double amount = cents / 100.0;
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(amount);
  }

  /// One-call convenience: converts cents to a fully formatted string
  /// using the correct symbol for the given currency code.
  /// Example: formatAmount(1050, 'SAR') -> "ر.س 10.50"
  static String formatAmount(int cents, String currencyCode) {
    final symbol = getCurrencySymbol(currencyCode);
    final double amount = cents / 100.0;
    return NumberFormat.currency(symbol: '$symbol ', decimalDigits: 2)
        .format(amount);
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

  /// Returns a concise currency symbol for the given currency code.
  /// Covers all currencies supported by the Mizan app.
  /// For 'Local' code (legacy sentinel), returns empty string — callers
  /// should resolve to the user's configured symbol from PreferencesRepository.
  static String getCurrencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'USD': return r'$';
      case 'SAR': return 'ر.س';
      case 'YER': return '﷼';
      case 'AED': return 'د.إ';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'KWD': return 'د.ك';
      case 'QAR': return 'ر.ق';
      case 'BHD': return 'د.ب';
      case 'OMR': return 'ر.ع';
      case 'EGP': return 'ج.م';
      case 'JOD': return 'د.أ';
      case 'IQD': return 'ع.د';
      case 'TRY': return '₺';
      case 'LOCAL': return ''; // Legacy sentinel — resolve via PreferencesRepository
      default: return code;
    }
  }

  static const Map<String, String> currencySymbols = {
    'USD': r'$',
    'SAR': 'ر.س',
    'YER': '﷼',
    'AED': 'د.إ',
    'EUR': '€',
    'GBP': '£',
    'KWD': 'د.ك',
    'QAR': 'ر.ق',
    'BHD': 'د.ب',
    'OMR': 'ر.ع',
    'EGP': 'ج.م',
    'JOD': 'د.أ',
    'IQD': 'ع.د',
    'TRY': '₺',
    'LOCAL': '',
  };
}