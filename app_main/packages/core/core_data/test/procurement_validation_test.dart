import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validUuid = '123e4567-e89b-12d3-a456-426614174000';

  group('ProcurementValidation', () {
    test('normalizes supported currency codes', () {
      expect(ProcurementValidation.currency(' yer '), 'YER');
      expect(ProcurementValidation.currency('USD'), 'USD');
    });

    test('rejects malformed currency codes', () {
      expect(
        () => ProcurementValidation.currency('US'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ProcurementValidation.currency('US D'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ProcurementValidation.currency('123'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validates exception reasons and idempotency keys', () {
      ProcurementValidation.reason(
        'Price variance approved by finance',
        'reason',
      );
      ProcurementValidation.idempotencyKey('exception-123', 'idempotencyKey');
      expect(
        () => ProcurementValidation.reason('', 'reason'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ProcurementValidation.idempotencyKey('short', 'idempotencyKey'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('requires UUID-shaped identifiers', () {
      ProcurementValidation.id(validUuid, 'id');
      expect(
        () => ProcurementValidation.id('temporary-id', 'id'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('requires finite positive quantities and non-negative amounts', () {
      ProcurementValidation.quantity(0.5);
      ProcurementValidation.nonNegativeMinor(0, 'amount');
      expect(
        () => ProcurementValidation.quantity(double.nan),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ProcurementValidation.quantity(0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ProcurementValidation.nonNegativeMinor(-1, 'amount'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validates requisition and receipt lines', () {
      final line = ProcurementLineInput(
        description: 'Paper',
        quantity: 2,
        unitPriceMinor: 100,
      );
      ProcurementValidation.lines([line], requisition: true);
      ProcurementValidation.receiptLines([
        const ProcurementReceiptLineInput(
          purchaseOrderLineId: validUuid,
          quantity: 1,
          unitCostMinor: 100,
        ),
      ]);
      expect(
        () => ProcurementValidation.lines([
          ProcurementLineInput(
            description: 'Taxed request',
            quantity: 1,
            unitPriceMinor: 100,
            taxMinor: 1,
          ),
        ], requisition: true),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
