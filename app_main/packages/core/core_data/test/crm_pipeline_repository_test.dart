import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a pipeline stage response', () {
    final stage = CrmPipelineStage.fromJson({
      'id': 'stage-1',
      'name': 'Qualified',
      'sort_order': 2,
      'probability_percent': 50,
      'is_won': false,
      'is_lost': false,
      'is_active': true,
    });

    expect(stage.id, 'stage-1');
    expect(stage.name, 'Qualified');
    expect(stage.sortOrder, 2);
    expect(stage.probabilityPercent, 50);
  });

  test('parses opportunity relationships and dates safely', () {
    final opportunity = CrmOpportunity.fromJson({
      'id': 'opp-1',
      'title': 'Retail expansion',
      'stage_id': 'stage-1',
      'crm_pipeline_stages': {'name': 'Qualified'},
      'lead_id': 'lead-1',
      'customer_id': 'customer-1',
      'amount_minor': 125000,
      'currency_code': 'SAR',
      'expected_close_on': '2026-12-31',
      'status': 'open',
      'probability_percent': 65,
      'updated_at': '2026-08-27T12:00:00Z',
    });

    expect(opportunity.stageName, 'Qualified');
    expect(opportunity.amountMinor, 125000);
    expect(opportunity.currencyCode, 'SAR');
    expect(opportunity.expectedCloseOn?.year, 2026);
    expect(opportunity.probabilityPercent, 65);
  });
}
