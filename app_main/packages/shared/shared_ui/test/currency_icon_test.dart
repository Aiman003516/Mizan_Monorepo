import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  group('CurrencySymbols', () {
    test('uses the official Saudi Riyal sign for SAR', () {
      expect(CurrencySymbols.forCode('sar'), '\u20C1');
    });

    test('provides recognizable symbols for common currencies', () {
      expect(CurrencySymbols.forCode('USD'), r'$');
      expect(CurrencySymbols.forCode('EUR'), '€');
      expect(CurrencySymbols.forCode('GBP'), '£');
      expect(CurrencySymbols.forCode('AED'), 'د.إ');
      expect(CurrencySymbols.forCode('YER'), '﷼');
    });

    test('uses a custom symbol only for an unknown code', () {
      expect(CurrencySymbols.forCode('ABC', fallback: '¤'), '¤');
      expect(CurrencySymbols.forCode('USD', fallback: '¤'), r'$');
      expect(CurrencySymbols.forCode('ABC'), 'ABC');
    });
  });

  testWidgets('renders SAR with the bundled SaudiRiyal font', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CurrencyIcon(code: 'SAR')),
      ),
    );

    final symbol = tester.widget<Text>(
      find.text(CurrencySymbols.saudiRiyalSign),
    );
    expect(symbol.style?.fontFamily, 'SaudiRiyal');
  });
}
