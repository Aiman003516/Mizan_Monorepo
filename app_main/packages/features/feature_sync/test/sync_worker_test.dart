import 'package:flutter_test/flutter_test.dart';
import 'package:feature_sync/src/data/sync_service.dart';

void main() {
  test('classifies disabled Drive API 403 as setup-required', () {
    final error = Exception(
      'DetailedApiRequestError(status: 403, message: Google Drive API has not been used in project 1075825975613 before or it is disabled.)',
    );

    expect(SyncService.isNonRetryableSilentBackupError(error), isTrue);
  });

  test('keeps transient network failure retryable', () {
    final error = Exception('SocketException: connection reset by peer');

    expect(SyncService.isNonRetryableSilentBackupError(error), isFalse);
  });
}
