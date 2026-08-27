import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/core_data.dart';

void main() {
  test('enforces the bounded page size', () {
    expect(CloudPageLimits.validate(1), 1);
    expect(CloudPageLimits.validate(100), 100);
    expect(() => CloudPageLimits.validate(0), throwsArgumentError);
    expect(() => CloudPageLimits.validate(101), throwsArgumentError);
  });

  test('serializes a deterministic keyset cursor', () {
    final cursor = CloudPageCursor(
      updatedAt: DateTime.utc(2026, 8, 29, 12, 30),
      id: '00000000-0000-0000-0000-000000000001',
    );

    expect(cursor.toRpcParams(), {
      'p_after_updated_at': '2026-08-29T12:30:00.000Z',
      'p_after_id': '00000000-0000-0000-0000-000000000001',
    });
  });

  test('reports whether another page exists', () {
    final finalPage = CloudPage<int>(items: [1], pageSize: 50);
    final nextPage = CloudPage<int>(
      items: [1, 2],
      pageSize: 2,
      nextCursor: CloudPageCursor(
        updatedAt: DateTime.utc(2026, 8, 29),
        id: '00000000-0000-0000-0000-000000000001',
      ),
    );

    expect(finalPage.hasMore, isFalse);
    expect(nextPage.hasMore, isTrue);
  });
}
