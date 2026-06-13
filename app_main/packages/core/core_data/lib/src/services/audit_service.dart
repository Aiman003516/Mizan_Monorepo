import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';

/// Audit Service for logging all data changes.
class AuditService {
  final AppDatabase _db;

  AuditService(this._db);

  /// Logs a data change to the AuditLog table.
  Future<void> logChange({
    required String action, // 'INSERT', 'UPDATE', 'DELETE'
    required String tableName,
    required String recordId,
    String? userId,
    Map<String, dynamic>? changes, // {field: {old: x, new: y}}
  }) async {
    await _db
        .into(_db.auditLog)
        .insert(
          AuditLogCompanion.insert(
            action: action,
            targetTableName: tableName,
            recordId: recordId,
            userId: Value(userId),
            changesJson: Value(changes != null ? jsonEncode(changes) : null),
          ),
        );
  }

  /// Retrieves all audit entries for a specific record.
  Future<List<AuditLogEntry>> getAuditTrail(String recordId) async {
    return (_db.select(_db.auditLog)
          ..where((a) => a.recordId.equals(recordId))
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
        .get();
  }

  /// Retrieves recent audit entries (for admin dashboard).
  Future<List<AuditLogEntry>> getRecentActivity({int limit = 50}) async {
    return (_db.select(_db.auditLog)
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
          ..limit(limit))
        .get();
  }
}

final auditServiceProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AuditService(db);
});
