import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:feature_settings/feature_settings.dart';

void main() {
  group('OwnerControlSettings', () {
    test('round trips a versioned settings snapshot', () {
      final settings = OwnerControlSettings().copyWithSection(
        OwnerSettingSections.accounting,
        {'base_currency_code': 'SAR', 'period_close_requires_owner': true},
      );
      final decoded = OwnerControlSettings.decode(settings.encode());
      expect(decoded.schemaVersion, ownerSettingsSchemaVersion);
      expect(
        decoded.section(OwnerSettingSections.accounting)['base_currency_code'],
        'SAR',
      );
      expect(decoded.revision, 1);
    });

    test('rejects unknown sections and keys', () {
      final settings = OwnerControlSettings(
        sections: {
          'unknown': {'value': true},
        },
      );
      expect(OwnerControlSettings.validate(settings).isValid, isFalse);
      expect(
        () => OwnerControlSettings.decode(settings.encode()),
        throwsFormatException,
      );
    });

    test('rejects an unsupported schema version', () {
      expect(
        () => OwnerControlSettings.fromJson({
          'schema_version': 'mizan.owner-settings/v0',
          'revision': 0,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'tenant_id': null,
          'sections': {},
        }),
        throwsFormatException,
      );
    });
  });

  group('OwnerControlCenterRepository', () {
    test('fails closed when persisted JSON is corrupt', () async {
      SharedPreferences.setMockInitialValues({
        OwnerControlCenterRepository.key: '{not-json',
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = OwnerControlCenterRepository(prefs);
      expect(repository.load().sections, isEmpty);
    });

    test('persists a validated section locally', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = OwnerControlCenterRepository(prefs);
      final saved = await repository.saveSection(
        OwnerControlSettings(),
        OwnerSettingSections.taxes,
        {'tax_period': 'monthly'},
      );
      expect(
        saved.section(OwnerSettingSections.taxes)['tax_period'],
        'monthly',
      );
      expect(
        repository.load().section(OwnerSettingSections.taxes)['tax_period'],
        'monthly',
      );
    });
  });

  group('OwnerApprovalRequest', () {
    test(
      'allows only pending-to-approved or pending-to-rejected decisions',
      () {
        final request = OwnerApprovalRequest(
          id: 'request-1',
          type: 'expense',
          requester: 'staff@example.test',
          reason: 'Office supplies',
          amountMinor: 1500,
          currencyCode: 'SAR',
          status: 'pending',
          createdAt: DateTime.now().toUtc(),
        );
        final approved = request.decide('approved');
        expect(approved.status, 'approved');
        expect(() => approved.decide('approved'), throwsStateError);
        expect(() => approved.decide('pending'), throwsStateError);
      },
    );
  });
}
