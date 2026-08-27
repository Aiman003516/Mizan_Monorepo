import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses procurement lifecycle statuses', () {
    expect(
      ProcurementDocumentStatus.fromDatabase('pending_approval'),
      ProcurementDocumentStatus.pendingApproval,
    );
    expect(
      ProcurementDocumentStatus.fromDatabase('partially_received'),
      ProcurementDocumentStatus.partiallyReceived,
    );
    expect(
      ProcurementDocumentStatus.fromDatabase('posted'),
      ProcurementDocumentStatus.posted,
    );
  });

  test('serializes purchase-order line in minor units', () {
    const line = ProcurementLineInput(
      productId: 'product-1',
      description: 'Raw material',
      quantity: 2.5,
      unitPriceMinor: 1200,
      taxMinor: 75,
    );

    expect(line.toPurchaseOrderJson(), {
      'product_id': 'product-1',
      'description': 'Raw material',
      'ordered_quantity': 2.5,
      'unit_price_minor': 1200,
      'tax_minor': 75,
    });
  });

  test('maps blocked three-way match evidence', () {
    final result = ThreeWayMatchResult.fromJson({
      'bill_line_id': 'bill-line-1',
      'purchase_order_id': 'po-1',
      'purchase_order_line_id': 'po-line-1',
      'ordered_quantity': 10,
      'received_quantity': 5,
      'returned_quantity': 1,
      'available_quantity': 4,
      'billed_quantity': 6,
      'ordered_unit_price_minor': 1000,
      'billed_unit_price_minor': 1100,
      'price_variance_minor': 100,
      'currency_code': 'YER',
      'match_status': 'blocked',
      'blocking_reason':
          'Billed quantity exceeds received quantity after returns.',
    });

    expect(result.isBlocked, isTrue);
    expect(result.availableQuantity, 4);
    expect(result.priceVarianceMinor, 100);
    expect(result.blockingReason, contains('exceeds'));
  });

  test('rejects unknown procurement status', () {
    expect(
      () => ProcurementDocumentStatus.fromDatabase('unknown'),
      throwsA(isA<FormatException>()),
    );
  });
}
