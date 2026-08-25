import 'package:flutter/material.dart';

/// Common display symbols for currencies supported by Mizan.
///
/// The code remains the source of truth. These values are presentation-only
/// and must never be used as accounting data or for parsing amounts.
class CurrencySymbols {
  const CurrencySymbols._();

  static const String saudiRiyalSign = '\u20C1';

  static const Map<String, String> iconSymbols = {
    'AED': 'د.إ',
    'AUD': r'$',
    'BHD': 'د.ب',
    'BDT': '৳',
    'BRL': r'R$',
    'CAD': r'$',
    'CHF': 'Fr',
    'CNY': '¥',
    'CZK': 'Kč',
    'DKK': 'kr',
    'DZD': 'دج',
    'EGP': 'ج.م',
    'EUR': '€',
    'GBP': '£',
    'HKD': r'$',
    'HUF': 'Ft',
    'IDR': 'Rp',
    'ILS': '₪',
    'INR': '₹',
    'IQD': 'ع.د',
    'JOD': 'د.أ',
    'JPY': '¥',
    'KES': 'KSh',
    'KWD': 'د.ك',
    'MAD': 'د.م.',
    'MXN': r'$',
    'MYR': 'RM',
    'NGN': '₦',
    'NOK': 'kr',
    'NZD': r'$',
    'OMR': 'ر.ع',
    'PHP': '₱',
    'PKR': '₨',
    'PLN': 'zł',
    'QAR': 'ر.ق',
    'SAR': saudiRiyalSign,
    'SEK': 'kr',
    'SGD': r'$',
    'THB': '฿',
    'TRY': '₺',
    'UAH': '₴',
    'USD': r'$',
    'VND': '₫',
    'XAF': 'FCFA',
    'XOF': 'CFA',
    'YER': '﷼',
    'ZAR': 'R',
  };

  static String forCode(String code, {String? fallback}) {
    final normalized = code.trim().toUpperCase();
    final knownSymbol = iconSymbols[normalized];
    if (knownSymbol != null) return knownSymbol;
    final customSymbol = fallback?.trim();
    return customSymbol == null || customSymbol.isEmpty
        ? normalized
        : customSymbol;
  }
}

/// A compact, direction-safe visual marker for a currency code.
///
/// SAR uses the official Saudi Riyal sign (U+20C1) and the bundled
/// SaudiRiyal font, which keeps the sign legible on Android versions whose
/// system font may not yet contain the Unicode 17 glyph.
class CurrencyIcon extends StatelessWidget {
  const CurrencyIcon({
    super.key,
    required this.code,
    this.symbol,
    this.size = 22,
  });

  final String code;
  final String? symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalizedCode = code.trim().toUpperCase();
    final isSaudiRiyal = normalizedCode == 'SAR';
    final displaySymbol = CurrencySymbols.forCode(
      normalizedCode,
      fallback: symbol,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: normalizedCode,
      child: Container(
        width: size + 18,
        height: size + 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Text(
          displaySymbol,
          textDirection: TextDirection.ltr,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            fontFamily: isSaudiRiyal ? 'SaudiRiyal' : null,
            fontSize: isSaudiRiyal ? size - 1 : size * 0.72,
            height: 1,
            fontWeight: FontWeight.w700,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
