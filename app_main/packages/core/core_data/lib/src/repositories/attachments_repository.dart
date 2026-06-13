import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';

/// Attachments Repository for file management.
class AttachmentsRepository {
  final AppDatabase _db;

  AttachmentsRepository(this._db);

  /// Adds an attachment to a transaction.
  Future<void> addToTransaction({
    required String transactionId,
    required String filePath,
    required String fileName,
    String? mimeType,
  }) async {
    await _db
        .into(_db.attachments)
        .insert(
          AttachmentsCompanion.insert(
            filePath: filePath,
            fileName: fileName,
            transactionId: Value(transactionId),
            mimeType: Value(mimeType),
          ),
        );
  }

  /// Adds an attachment to an invoice.
  Future<void> addToInvoice({
    required String invoiceId,
    required String filePath,
    required String fileName,
    String? mimeType,
  }) async {
    await _db
        .into(_db.attachments)
        .insert(
          AttachmentsCompanion.insert(
            filePath: filePath,
            fileName: fileName,
            invoiceId: Value(invoiceId),
            mimeType: Value(mimeType),
          ),
        );
  }

  /// Gets attachments for a transaction.
  Future<List<Attachment>> getForTransaction(String transactionId) async {
    return (_db.select(
      _db.attachments,
    )..where((a) => a.transactionId.equals(transactionId))).get();
  }

  /// Gets attachments for an invoice.
  Future<List<Attachment>> getForInvoice(String invoiceId) async {
    return (_db.select(
      _db.attachments,
    )..where((a) => a.invoiceId.equals(invoiceId))).get();
  }

  /// Deletes an attachment.
  Future<void> delete(String id) async {
    await (_db.delete(_db.attachments)..where((a) => a.id.equals(id))).go();
  }
}

final attachmentsRepositoryProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AttachmentsRepository(db);
});
