import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';

/// Notification Service for in-app alerts.
class NotificationService {
  final AppDatabase _db;

  NotificationService(this._db);

  /// Creates a new notification.
  Future<void> create({
    required String title,
    required String body,
    required String type, // system, business, inventory
    String? relatedEntityId,
  }) async {
    await _db
        .into(_db.appNotifications)
        .insert(
          AppNotificationsCompanion.insert(
            title: title,
            body: body,
            notificationType: type,
            relatedEntityId: Value(relatedEntityId),
          ),
        );
  }

  /// Returns unread notification count.
  Future<int> getUnreadCount() async {
    final count =
        await (_db.selectOnly(_db.appNotifications)
              ..addColumns([_db.appNotifications.id.count()])
              ..where(_db.appNotifications.isRead.equals(false)))
            .map((row) => row.read(_db.appNotifications.id.count()))
            .getSingle();
    return count ?? 0;
  }

  /// Watches all notifications.
  Stream<List<AppNotification>> watchAll() {
    return (_db.select(
      _db.appNotifications,
    )..orderBy([(n) => OrderingTerm.desc(n.createdAt)])).watch();
  }

  /// Marks a notification as read.
  Future<void> markAsRead(String id) async {
    await (_db.update(_db.appNotifications)..where((n) => n.id.equals(id)))
        .write(const AppNotificationsCompanion(isRead: Value(true)));
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    await (_db.update(
      _db.appNotifications,
    )).write(const AppNotificationsCompanion(isRead: Value(true)));
  }
}

final notificationServiceProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return NotificationService(db);
});
