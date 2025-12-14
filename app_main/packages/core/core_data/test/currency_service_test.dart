// Unit tests for CurrencyService
// Tests exchange rate conversion, revaluation logic, and gain/loss calculations

import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/src/services/currency_service.dart';

void main() {
  group('ExchangeRate', () {
    test('should convert amount correctly', () {
      final rate = ExchangeRate(
        fromCurrency: 'USD',
        toCurrency: 'SAR',
        rate: 3.75,
        date: DateTime.now(),
      );

      // $100 USD = 375 SAR
      expect(rate.convert(10000), equals(37500)); // in cents
    });

    test('should calculate inverse rate', () {
      final rate = ExchangeRate(
        fromCurrency: 'USD',
        toCurrency: 'SAR',
        rate: 3.75,
        date: DateTime.now(),
      );

      final inverse = rate.inverse;

      expect(inverse.fromCurrency, equals('SAR'));
      expect(inverse.toCurrency, equals('USD'));
      expect(inverse.rate, closeTo(0.2667, 0.001)); // 1/3.75
    });

    test('should handle same currency (rate = 1.0)', () {
      final rate = ExchangeRate(
        fromCurrency: 'USD',
        toCurrency: 'USD',
        rate: 1.0,
        date: DateTime.now(),
      );

      expect(rate.convert(10000), equals(10000));
    });
  });

  group('RevaluationResult', () {
    test('should identify gain correctly', () {
      const result = RevaluationResult(
        accountId: 'acc1',
        currency: 'USD',
        originalBalance: 100000,
        revaluedBalance: 110000,
        gainOrLoss: 10000,
      );

      expect(result.hasGainOrLoss, isTrue);
      expect(result.isGain, isTrue);
      expect(result.isLoss, isFalse);
    });

    test('should identify loss correctly', () {
      const result = RevaluationResult(
        accountId: 'acc1',
        currency: 'USD',
        originalBalance: 100000,
        revaluedBalance: 90000,
        gainOrLoss: -10000,
      );

      expect(result.hasGainOrLoss, isTrue);
      expect(result.isGain, isFalse);
      expect(result.isLoss, isTrue);
    });

    test('should identify no change', () {
      const result = RevaluationResult(
        accountId: 'acc1',
        currency: 'USD',
        originalBalance: 100000,
        revaluedBalance: 100000,
        gainOrLoss: 0,
      );

      expect(result.hasGainOrLoss, isFalse);
    });
  });

  group('Exchange Rate Calculations', () {
    late MockCurrencyService service;

    setUp(() {
      service = MockCurrencyService();
    });

    test('should store and retrieve exchange rates', () {
      service.setExchangeRate('USD', 'SAR', 3.75);

      final rate = service.getExchangeRate('USD', 'SAR');
      expect(rate, isNotNull);
      expect(rate!.rate, equals(3.75));
    });

    test('should retrieve inverse rate automatically', () {
      service.setExchangeRate('USD', 'SAR', 3.75);

      final inverseRate = service.getExchangeRate('SAR', 'USD');
      expect(inverseRate, isNotNull);
      expect(inverseRate!.rate, closeTo(0.2667, 0.001));
    });

    test('should return rate 1.0 for same currency', () {
      final rate = service.getExchangeRate('USD', 'USD');
      expect(rate, isNotNull);
      expect(rate!.rate, equals(1.0));
    });

    test('should convert between currencies', () {
      service.setExchangeRate('USD', 'EUR', 0.92);

      final euroAmount = service.convertAmount(10000, 'USD', 'EUR');
      expect(euroAmount, equals(9200)); // $100 = €92
    });

    test('should throw when rate not found', () {
      expect(
        () => service.convertAmount(10000, 'USD', 'JPY'),
        throwsArgumentError,
      );
    });
  });

  group('Currency Revaluation Scenarios', () {
    test(
      'should calculate unrealized gain on strengthening foreign currency',
      () {
        // Scenario: We hold 100,000 cents (1000 USD) in a USD account
        // Our base currency is SAR
        // Original rate: 1 USD = 3.70 SAR, so 1000 USD = 3700 SAR (370000 halalas)
        // New rate: 1 USD = 3.80 SAR, so 1000 USD = 3800 SAR (380000 halalas)
        // Gain: 100 SAR (10000 halalas)

        const foreignAmountUsd = 100000; // 1000 USD in cents
        const originalRate = 3.70; // SAR per USD
        const newRate = 3.80;

        final originalInBase = (foreignAmountUsd * originalRate)
            .round(); // 370000
        final revaluedInBase = (foreignAmountUsd * newRate).round(); // 380000
        final gainOrLoss = revaluedInBase - originalInBase;

        expect(originalInBase, equals(370000));
        expect(revaluedInBase, equals(380000));
        expect(gainOrLoss, equals(10000)); // 100 SAR gain
        expect(gainOrLoss, greaterThan(0)); // Gain
      },
    );

    test('should calculate unrealized loss on weakening foreign currency', () {
      // Original: 1000 USD @ 3.80 SAR = 3800 SAR
      // New rate: 3.70 SAR
      // Revalued: 1000 USD @ 3.70 SAR = 3700 SAR
      // Loss: 100 SAR

      const originalInBase = 380000; // 3800 SAR in halalas
      const originalRate = 3.80;
      const newRate = 3.70;

      final foreignAmount = (originalInBase / originalRate).round();
      final revaluedInBase = (foreignAmount * newRate).round();
      final gainOrLoss = revaluedInBase - originalInBase;

      expect(gainOrLoss, lessThan(0)); // Loss
    });
  });

  group('Edge Cases', () {
    test('should handle very small rates', () {
      final rate = ExchangeRate(
        fromCurrency: 'JPY',
        toCurrency: 'USD',
        rate: 0.0067, // 1 JPY = $0.0067
        date: DateTime.now(),
      );

      // 10000 JPY = $67
      expect(rate.convert(1000000), equals(6700));
    });

    test('should handle very large rates', () {
      final rate = ExchangeRate(
        fromCurrency: 'USD',
        toCurrency: 'VND',
        rate: 24500, // 1 USD = 24,500 VND
        date: DateTime.now(),
      );

      // $100 = 2,450,000 VND
      expect(rate.convert(10000), equals(245000000));
    });

    test('should preserve rate date', () {
      final date = DateTime(2024, 1, 15);
      final rate = ExchangeRate(
        fromCurrency: 'USD',
        toCurrency: 'EUR',
        rate: 0.92,
        date: date,
      );

      expect(rate.date, equals(date));
    });
  });
}

/// Mock currency service for testing without database
class MockCurrencyService {
  final Map<String, ExchangeRate> _rateCache = {};

  void setExchangeRate(String from, String to, double rate, {DateTime? date}) {
    final key = '${from}_$to';
    _rateCache[key] = ExchangeRate(
      fromCurrency: from,
      toCurrency: to,
      rate: rate,
      date: date ?? DateTime.now(),
    );
    // Also store inverse
    final inverseKey = '${to}_$from';
    _rateCache[inverseKey] = ExchangeRate(
      fromCurrency: to,
      toCurrency: from,
      rate: 1 / rate,
      date: date ?? DateTime.now(),
    );
  }

  ExchangeRate? getExchangeRate(String from, String to) {
    if (from == to) {
      return ExchangeRate(
        fromCurrency: from,
        toCurrency: to,
        rate: 1.0,
        date: DateTime.now(),
      );
    }
    return _rateCache['${from}_$to'];
  }

  int convertAmount(int amount, String from, String to) {
    final rate = getExchangeRate(from, to);
    if (rate == null) {
      throw ArgumentError('No exchange rate found for $from -> $to');
    }
    return rate.convert(amount);
  }
}
