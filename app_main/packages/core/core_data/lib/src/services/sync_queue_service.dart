import 'dart:convert';

import 'package:core_database/core_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  return SyncQueueService(ref.watch(appDatabaseProvider));
});

class SyncQueueService {
  SyncQueueService(this._db);

  final AppDatabase _db;

  Future<void> enqueue({
    required String tenantId,
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now().toUtc();
    await _db
        .into(_db.syncQueueEntries)
        .insert(
          SyncQueueEntriesCompanion.insert(
            id: Value('${tableName}_$recordId'),
            tenantId: Value(tenantId),
            entityTable: tableName,
            recordId: recordId,
            operation: operation,
            payloadJson: jsonEncode(payload),
            queuedAt: Value(now),
            lastUpdated: Value(now),
            status: const Value('pending'),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<List<SyncQueueEntry>> pending(String tenantId, {int limit = 100}) {
    return (_db.select(_db.syncQueueEntries)
          ..where((entry) => entry.tenantId.equals(tenantId))
          ..where((entry) => entry.status.isIn(['pending', 'retry']))
          ..orderBy([
            (entry) => OrderingTerm.asc(entry.queuedAt),
            (entry) => OrderingTerm.asc(entry.id),
          ])
          ..limit(limit))
        .get();
  }

  Map<String, dynamic> decodePayload(SyncQueueEntry entry) {
    final decoded = jsonDecode(entry.payloadJson);
    if (decoded is! Map) {
      throw const FormatException('Sync payload must be a JSON object.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> markSucceeded(String id) async {
    await (_db.delete(
      _db.syncQueueEntries,
    )..where((entry) => entry.id.equals(id))).go();
  }

  Future<void> markFailed(String id, Object error) async {
    final message = error.toString();
    final entry = await (_db.select(
      _db.syncQueueEntries,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (entry == null) return;
    final now = DateTime.now().toUtc();
    await (_db.update(
      _db.syncQueueEntries,
    )..where((row) => row.id.equals(id))).write(
      SyncQueueEntriesCompanion(
        attemptCount: Value(entry.attemptCount + 1),
        lastAttemptAt: Value(now),
        lastError: Value(
          message.length > 1000 ? message.substring(0, 1000) : message,
        ),
        lastUpdated: Value(now),
        status: const Value('retry'),
      ),
    );
  }
}
