import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps customer 360 metrics and health factors', () {
    final customer = CrmCustomer360.fromJson({
      'customer_id': 'customer-1',
      'customer_name': 'Al Noor Store',
      'email': 'contact@example.com',
      'phone': '+967700000000',
      'balance': 25000,
      'credit_limit': 100000,
      'invoice_count': 4,
      'outstanding_minor': 12500,
      'overdue_invoice_count': 1,
      'open_opportunity_count': 2,
      'interaction_count': 5,
      'health_score': 75,
      'health_risk_level': 'healthy',
      'health_factors': {'calculation': 'deterministic_advisory_v1'},
    });

    expect(customer.customerName, 'Al Noor Store');
    expect(customer.outstandingMinor, 12500);
    expect(customer.healthScore, 75);
    expect(customer.healthRiskLevel, 'healthy');
    expect(customer.healthFactors['calculation'], 'deterministic_advisory_v1');
  });

  test('serializes quote line amounts as integer minor units', () {
    const line = CrmQuoteLineInput(
      description: 'Monthly support',
      quantity: 3,
      unitPriceMinor: 4500,
    );

    expect(line.toJson(), {
      'description': 'Monthly support',
      'quantity': 3,
      'unit_price_minor': 4500,
    });
  });
}
