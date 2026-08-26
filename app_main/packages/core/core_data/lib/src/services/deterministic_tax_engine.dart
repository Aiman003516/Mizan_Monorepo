class TaxCalculationInput {
  const TaxCalculationInput({
    required this.taxableMinor,
    required this.rateBasisPoints,
    required this.currencyCode,
    this.isInclusive = false,
    this.isExempt = false,
    this.jurisdictionCode,
    this.taxCode,
  });

  final int taxableMinor;
  final int rateBasisPoints;
  final String currencyCode;
  final bool isInclusive;
  final bool isExempt;
  final String? jurisdictionCode;
  final String? taxCode;
}

class TaxCalculationResult {
  const TaxCalculationResult({
    required this.netMinor,
    required this.taxMinor,
    required this.totalMinor,
    required this.currencyCode,
    required this.rateBasisPoints,
    required this.isInclusive,
    required this.isExempt,
    required this.formula,
    this.jurisdictionCode,
    this.taxCode,
  });

  final int netMinor;
  final int taxMinor;
  final int totalMinor;
  final String currencyCode;
  final int rateBasisPoints;
  final bool isInclusive;
  final bool isExempt;
  final String formula;
  final String? jurisdictionCode;
  final String? taxCode;

  factory TaxCalculationResult.fromJson(Map<String, dynamic> json) {
    return TaxCalculationResult(
      netMinor: (json['net_minor'] as num?)?.toInt() ?? 0,
      taxMinor: (json['tax_minor'] as num?)?.toInt() ?? 0,
      totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0,
      currencyCode: json['currency_code']?.toString() ?? '',
      rateBasisPoints: (((json['rate_percent'] as num?)?.toDouble() ?? 0) * 100)
          .round(),
      isInclusive: json['is_inclusive'] == true,
      isExempt: json['is_exempt'] == true,
      formula: json['formula']?.toString() ?? '',
      jurisdictionCode: json['jurisdiction_code']?.toString(),
      taxCode: json['tax_code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'net_minor': netMinor,
    'tax_minor': taxMinor,
    'total_minor': totalMinor,
    'currency_code': currencyCode,
    'rate_basis_points': rateBasisPoints,
    'is_inclusive': isInclusive,
    'is_exempt': isExempt,
    'formula': formula,
    if (jurisdictionCode != null) 'jurisdiction_code': jurisdictionCode,
    if (taxCode != null) 'tax_code': taxCode,
  };
}

class DeterministicTaxEngine {
  const DeterministicTaxEngine();

  TaxCalculationResult calculate(TaxCalculationInput input) {
    if (input.taxableMinor < 0) {
      throw ArgumentError.value(
        input.taxableMinor,
        'taxableMinor',
        'Taxable amount cannot be negative',
      );
    }
    if (input.rateBasisPoints < 0 || input.rateBasisPoints > 10000) {
      throw ArgumentError.value(
        input.rateBasisPoints,
        'rateBasisPoints',
        'Tax rate must be between 0% and 100%',
      );
    }
    final currencyCode = input.currencyCode.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3,5}$').hasMatch(currencyCode)) {
      throw ArgumentError.value(
        input.currencyCode,
        'currencyCode',
        'Currency code must be uppercase and contain 3 to 5 letters',
      );
    }

    if (input.isExempt || input.rateBasisPoints == 0) {
      return TaxCalculationResult(
        netMinor: input.taxableMinor,
        taxMinor: 0,
        totalMinor: input.taxableMinor,
        currencyCode: currencyCode,
        rateBasisPoints: input.rateBasisPoints,
        isInclusive: input.isInclusive,
        isExempt: input.isExempt,
        formula: input.isExempt ? 'exempt' : 'zero_rate',
        jurisdictionCode: input.jurisdictionCode,
        taxCode: input.taxCode,
      );
    }

    if (input.isInclusive) {
      final taxMinor = _roundDivide(
        input.taxableMinor * input.rateBasisPoints,
        10000 + input.rateBasisPoints,
      );
      return TaxCalculationResult(
        netMinor: input.taxableMinor - taxMinor,
        taxMinor: taxMinor,
        totalMinor: input.taxableMinor,
        currencyCode: currencyCode,
        rateBasisPoints: input.rateBasisPoints,
        isInclusive: true,
        isExempt: false,
        formula: 'gross * rate / (10000 + rate)',
        jurisdictionCode: input.jurisdictionCode,
        taxCode: input.taxCode,
      );
    }

    final taxMinor = _roundDivide(
      input.taxableMinor * input.rateBasisPoints,
      10000,
    );
    return TaxCalculationResult(
      netMinor: input.taxableMinor,
      taxMinor: taxMinor,
      totalMinor: input.taxableMinor + taxMinor,
      currencyCode: currencyCode,
      rateBasisPoints: input.rateBasisPoints,
      isInclusive: false,
      isExempt: false,
      formula: 'net * rate / 10000',
      jurisdictionCode: input.jurisdictionCode,
      taxCode: input.taxCode,
    );
  }

  int _roundDivide(int numerator, int denominator) {
    return (numerator + (denominator ~/ 2)) ~/ denominator;
  }
}
