import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';

/// Comments Repository for contextual notes.
class CommentsRepository {
  final AppDatabase _db;

  CommentsRepository(this._db);

  /// Adds a comment to an invoice.
  Future<void> addToInvoice({
    required String invoiceId,
    required String content,
    String? userId,
  }) async {
    await _db
        .into(_db.comments)
        .insert(
          CommentsCompanion.insert(
            content: content,
            invoiceId: Value(invoiceId),
            userId: Value(userId),
          ),
        );
  }

  /// Adds a comment to a transaction.
  Future<void> addToTransaction({
    required String transactionId,
    required String content,
    String? userId,
  }) async {
    await _db
        .into(_db.comments)
        .insert(
          CommentsCompanion.insert(
            content: content,
            transactionId: Value(transactionId),
            userId: Value(userId),
          ),
        );
  }

  /// Gets comments for an invoice.
  Stream<List<Comment>> watchForInvoice(String invoiceId) {
    return (_db.select(_db.comments)
          ..where((c) => c.invoiceId.equals(invoiceId))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .watch();
  }

  /// Gets comments for a transaction.
  Stream<List<Comment>> watchForTransaction(String transactionId) {
    return (_db.select(_db.comments)
          ..where((c) => c.transactionId.equals(transactionId))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .watch();
  }
}

final commentsRepositoryProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CommentsRepository(db);
});
