import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps an approved extension to the shared descriptor contract', () {
    final extension = ReviewedExtension.fromJson({
      'id': 'extension-1',
      'extension_key': 'invoice_hint',
      'display_name': 'Invoice hint',
      'version': '1.0.0',
      'hook': 'pre_validate',
      'capabilities': ['add_validation_hint'],
      'configuration': {'limit': 3},
      'status': 'approved',
      'reviewed_at': '2026-08-27T00:00:00Z',
    });

    expect(extension.enabled, isTrue);
    expect(extension.descriptor.hook, ExtensionHook.preValidate);
    expect(extension.descriptor.capabilities, {'add_validation_hint'});
    expect(extension.configuration['limit'], 3);
  });

  test('proposed extensions remain disabled', () {
    final extension = ReviewedExtension.fromJson({
      'id': 'extension-2',
      'extension_key': 'read_only',
      'display_name': 'Read only',
      'version': '1.0.0',
      'hook': 'post_save',
      'capabilities': [],
      'status': 'proposed',
    });

    expect(extension.enabled, isFalse);
    expect(extension.descriptor.enabled, isFalse);
    expect(extension.descriptor.hook, ExtensionHook.postSave);
  });
}
