import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'pending invitation survives reload and clears after redemption',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final service = PendingInvitationService(preferences);

      final saved = await service.save(
        code: '123456',
        tenantId: 'tenant-1',
        roleId: 'cashier',
        recipientEmail: 'employee@example.com',
        recipientPhone: '+967 711234567',
        displayName: 'Employee One',
        token: 'token-1',
        stage: 'verified',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      expect(saved?.code, '123456');
      expect(service.read()?.tenantId, 'tenant-1');
      expect(service.read()?.roleId, 'cashier');
      expect(service.read()?.recipientEmail, 'employee@example.com');
      expect(service.read()?.recipientPhone, '+967 711234567');
      expect(service.read()?.displayName, 'Employee One');
      expect(service.read()?.token, 'token-1');
      expect(service.read()?.stage, 'verified');

      await service.clear();
      expect(service.read() == null, true);
    },
  );

  test('expired pending invitation is discarded', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = PendingInvitationService(preferences);

    await service.save(
      code: '654321',
      expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
    );

    expect(service.read() == null, true);
  });
}
