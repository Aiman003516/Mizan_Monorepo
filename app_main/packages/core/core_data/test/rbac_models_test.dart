import 'package:flutter_test/flutter_test.dart';

import 'package:core_data/core_data.dart';

void main() {
  test('guest role denies every permission', () {
    final role = AppRole.guest();

    expect(role.isSystemAdmin, isFalse);
    expect(role.permissions, isEmpty);
    expect(role.hasPermission(AppPermission.manageSettings), isFalse);
    expect(role.hasPermission(AppPermission.manageCustomers), isFalse);
  });

  test('Supabase snake_case role rows parse correctly', () {
    final role = AppRole.fromJson({
      'name': 'CRM Manager',
      'permissions': ['manageCrm', 'manageCustomers', 'manageInvoices'],
      'is_system_admin': false,
    }, 'role-1');

    expect(role.name, 'CRM Manager');
    expect(role.isSystemAdmin, isFalse);
    expect(role.hasPermission(AppPermission.manageCrm), isTrue);
    expect(role.hasPermission(AppPermission.manageCustomers), isTrue);
    expect(role.hasPermission(AppPermission.manageInvoices), isTrue);
  });

  test('custom fields parse Supabase snake_case rows', () {
    final field = CustomFieldDefinition.fromJson({
      'key': 'customer_segment',
      'label': 'Customer Segment',
      'target_table': 'customers',
      'data_type': 'text',
      'is_required': true,
    }, 'field-1');

    expect(field.targetTable, 'customers');
    expect(field.type, CustomFieldType.text);
    expect(field.isRequired, isTrue);
    expect(field.toJson(), {
      'key': 'customer_segment',
      'label': 'Customer Segment',
      'target_table': 'customers',
      'data_type': 'text',
      'is_required': true,
    });
  });
}
