import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = DeterministicTaxEngine();

  test('calculates exclusive tax using integer minor units', () {
    final result = engine.calculate(
      const TaxCalculationInput(
        taxableMinor: 10000,
        rateBasisPoints: 1500,
        currencyCode: 'sar',
      ),
    );

    expect(result.netMinor, 10000);
    expect(result.taxMinor, 1500);
    expect(result.totalMinor, 11500);
    expect(result.formula, 'net * rate / 10000');
    expect(result.currencyCode, 'SAR');
  });

  test('calculates inclusive tax from gross amount', () {
    final result = engine.calculate(
      const TaxCalculationInput(
        taxableMinor: 11500,
        rateBasisPoints: 1500,
        currencyCode: 'SAR',
        isInclusive: true,
      ),
    );

    expect(result.taxMinor, 1500);
    expect(result.netMinor, 10000);
    expect(result.totalMinor, 11500);
  });

  test('exemption produces zero tax and preserves the taxable amount', () {
    final result = engine.calculate(
      const TaxCalculationInput(
        taxableMinor: 12345,
        rateBasisPoints: 1500,
        currencyCode: 'YER',
        isExempt: true,
        jurisdictionCode: 'YE',
        taxCode: 'EXEMPT',
      ),
    );

    expect(result.taxMinor, 0);
    expect(result.netMinor, 12345);
    expect(result.totalMinor, 12345);
    expect(result.formula, 'exempt');
    expect(result.jurisdictionCode, 'YE');
  });

  test('rejects invalid tax inputs', () {
    expect(
      () => engine.calculate(
        const TaxCalculationInput(
          taxableMinor: -1,
          rateBasisPoints: 1500,
          currencyCode: 'SAR',
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => engine.calculate(
        const TaxCalculationInput(
          taxableMinor: 100,
          rateBasisPoints: 10001,
          currencyCode: 'SAR',
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => engine.calculate(
        const TaxCalculationInput(
          taxableMinor: 100,
          rateBasisPoints: 1500,
          currencyCode: 'S',
        ),
      ),
      throwsArgumentError,
    );
  });
}
