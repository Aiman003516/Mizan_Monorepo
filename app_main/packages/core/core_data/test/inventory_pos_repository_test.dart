import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps an inventory balance using minor-unit cost', () {
    final balance = InventoryBalance.fromJson({
      'id': 'balance-1',
      'warehouse_id': 'main',
      'product_id': 'product-1',
      'quantity_on_hand': 4.5,
      'average_cost_minor': 1250,
      'currency_code': 'SAR',
    });

    expect(balance.warehouseId, 'main');
    expect(balance.quantityOnHand, 4.5);
    expect(balance.averageCostMinor, 1250);
    expect(balance.currencyCode, 'SAR');
  });

  test('serializes POS sale line input without changing minor units', () {
    const line = PosSaleLineInput(
      productId: ' product-1 ',
      quantity: 2,
      unitPriceMinor: 3750,
    );

    expect(line.toJson(), {
      'product_id': 'product-1',
      'quantity': 2,
      'unit_price_minor': 3750,
    });
  });
}
