import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';

/// Quotes Repository for Estimates & Quotes management.
class QuotesRepository {
  final AppDatabase _db;

  QuotesRepository(this._db);

  /// Creates a new quote.
  Future<Quote> create({
    required String customerId,
    required DateTime quoteDate,
    DateTime? expiryDate,
    String status = 'draft',
    int subtotal = 0,
    int taxAmount = 0,
    int totalAmount = 0,
    String? notes,
  }) async {
    final id = await _db
        .into(_db.quotes)
        .insert(
          QuotesCompanion.insert(
            customerId: customerId,
            quoteDate: quoteDate,
            expiryDate: Value(expiryDate),
            subtotal: Value(subtotal),
            taxAmount: Value(taxAmount),
            totalAmount: Value(totalAmount),
            notes: Value(notes),
          ),
        );
    return (_db.select(
      _db.quotes,
    )..where((q) => q.rowId.equals(id))).getSingle();
  }

  /// Watches all quotes.
  Stream<List<Quote>> watchAll() {
    return (_db.select(
      _db.quotes,
    )..orderBy([(q) => OrderingTerm.desc(q.quoteDate)])).watch();
  }

  /// Converts a quote to an invoice.
  Future<Invoice> convertToInvoice(String quoteId) async {
    final quote = await (_db.select(
      _db.quotes,
    )..where((q) => q.id.equals(quoteId))).getSingle();

    // Create invoice from quote data
    final invoiceRowId = await _db
        .into(_db.invoices)
        .insert(
          InvoicesCompanion.insert(
            invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
            customerId: quote.customerId,
            invoiceDate: DateTime.now(),
            dueDate: DateTime.now().add(const Duration(days: 30)),
            subtotal: quote.subtotal,
            totalAmount: quote.totalAmount,
            taxAmount: Value(quote.taxAmount),
            notes: Value(quote.notes),
          ),
        );

    // Get the created invoice
    final invoice = await (_db.select(
      _db.invoices,
    )..where((i) => i.rowId.equals(invoiceRowId))).getSingle();

    // Copy quote items to invoice items
    final quoteItems = await (_db.select(
      _db.quoteItems,
    )..where((qi) => qi.quoteId.equals(quoteId))).get();

    for (final qi in quoteItems) {
      await _db
          .into(_db.invoiceItems)
          .insert(
            InvoiceItemsCompanion.insert(
              invoiceId: invoice.id,
              description: qi.description,
              quantity: qi.quantity,
              unitPrice: qi.unitPrice,
              amount: qi.lineTotal,
              productId: Value(qi.productId),
            ),
          );
    }

    // Update quote to mark as converted
    await (_db.update(_db.quotes)..where((q) => q.id.equals(quoteId))).write(
      QuotesCompanion(
        status: const Value('accepted'),
        convertedInvoiceId: Value(invoice.id),
      ),
    );

    return invoice;
  }
}

final quotesRepositoryProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return QuotesRepository(db);
});
