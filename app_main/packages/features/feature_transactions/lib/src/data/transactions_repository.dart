import 'package:drift/drift.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:uuid/uuid.dart';

// UPDATED Local Imports
import 'package:feature_transactions/src/presentation/pos_receipt_provider.dart';
import 'package:feature_accounts/feature_accounts.dart' hide databaseProvider;
import 'package:feature_transactions/src/data/database_provider.dart';
// REMOVED: import 'package:feature_reports/feature_reports.dart';
// REMOVED: import 'package:feature_reports/src/data/report_models.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final accountsRepo = ref.watch(accountsRepositoryProvider);
  return TransactionsRepository(db, accountsRepo, const Uuid());
});

// REMOVED: transactionDetailsProvider (now in feature_reports)

//
// 💡--- THIS IS THE FIX (Part 1) ---
// The provider now watches the REPOSITORY, not the database directly.
final orderForTransactionProvider =
    FutureProvider.autoDispose.family<Order?, String>((ref, transactionId) {
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.getOrderForTransaction(transactionId);
});

// 💡--- THIS IS THE FIX (Part 2) ---
// The provider now watches the REPOSITORY, not the database directly.
final orderItemsStreamProvider =
    StreamProvider.autoDispose.family<List<OrderItem>, String>((ref, orderId) {
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.watchOrderItems(orderId);
});
//
//

class TransactionsRepository {
  TransactionsRepository(this._db, this._accountsRepo, this._uuid);
  final AppDatabase _db;
  final AccountsRepository _accountsRepo;
  final Uuid _uuid;

  //
  // 💡--- THIS IS THE FIX (Part 3) ---
  // We add the missing query methods to the repository.
  Future<Order?> getOrderForTransaction(String transactionId) {
    return (_db.select(_db.orders)
          ..where((o) => o.transactionId.equals(transactionId)))
        .getSingleOrNull();
  }

  Stream<List<OrderItem>> watchOrderItems(String orderId) {
    return (_db.select(_db.orderItems)
          ..where((oi) => oi.orderId.equals(orderId)))
        .watch();
  }
  //
  //

  Stream<List<Transaction>> watchAllTransactions() {
    return (_db.select(_db.transactions)
          ..orderBy([
            (t) => d.OrderingTerm.desc(t.transactionDate),
          ]))
        .watch();
  }

  Stream<List<TransactionEntry>> watchEntriesForTransaction(
      String transactionId) {
    return (_db.select(_db.transactionEntries)
          ..where((te) => te.transactionId.equals(transactionId)))
        .watch();
  }

  Future<void> createTransaction({
    required String description,
    required DateTime transactionDate,
    required List<TransactionEntriesCompanion> entries,
    String? attachmentPath,
    String currencyCode = 'Local',
    String? relatedTransactionId,
  }) {
    return _db.transaction(() async {
      final newTransactionId = _uuid.v4();
      final now = DateTime.now();

      final transactionCompanion = TransactionsCompanion.insert(
        id: d.Value(newTransactionId),
        description: description,
        transactionDate: transactionDate,
        attachmentPath: d.Value(attachmentPath),
        currencyCode: d.Value(currencyCode),
        createdAt: d.Value(now),
        lastUpdated: d.Value(now),
        relatedTransactionId: d.Value(relatedTransactionId),
      );
      await _db.into(_db.transactions).insert(transactionCompanion);

      for (final entry in entries) {
        final entryWithId = entry.copyWith(
          transactionId: d.Value(newTransactionId),
          createdAt: d.Value(now),
          lastUpdated: d.Value(now),
        );
        await _db.into(_db.transactionEntries).insert(entryWithId);
      }
    });
  }

  Future<void> createPosSale({
    required TransactionsCompanion transactionCompanion,
    required List<TransactionEntriesCompanion> entries,
    required List<PosReceiptItem> items,
    required double totalAmount,
  }) {
    return _db.transaction(() async {
      final now = DateTime.now();
      final newTransactionId = _uuid.v4();

      final inventoryAccountId =
          await _accountsRepo.getAccountIdByName(kInventoryAccountName);
      final cogsAccountId =
          await _accountsRepo.getAccountIdByName(kCogsAccountName);

      if (inventoryAccountId == null || cogsAccountId == null) {
        throw Exception("Critical Error: Inventory or COGS accounts not found.");
      }

      double totalCostOfGoodsSold = 0.0;

      for (final item in items) {
        final product = await (_db.select(_db.products)
              ..where((p) => p.id.equals(item.product.id)))
            .getSingle();
        final costForThisItem = product.averageCost * item.quantity;
        totalCostOfGoodsSold += costForThisItem;

        final newQuantity = product.quantityOnHand - item.quantity;
        await (_db.update(_db.products)
              ..where((p) => p.id.equals(item.product.id)))
            .write(
          ProductsCompanion(
            quantityOnHand: d.Value(newQuantity),
            lastUpdated: d.Value(now),
          ),
        );
      }

      await _db.into(_db.transactions).insert(transactionCompanion.copyWith(
            id: d.Value(newTransactionId),
            createdAt: d.Value(now),
            lastUpdated: d.Value(now),
          ));

      for (final entry in entries) {
        await _db.into(_db.transactionEntries).insert(entry.copyWith(
              transactionId: d.Value(newTransactionId),
              createdAt: d.Value(now),
              lastUpdated: d.Value(now),
            ));
      }

      await _db
          .into(_db.transactionEntries)
          .insert(TransactionEntriesCompanion.insert(
            transactionId: newTransactionId,
            accountId: cogsAccountId,
            amount: totalCostOfGoodsSold,
            createdAt: d.Value(now),
            lastUpdated: d.Value(now),
          ));
      await _db
          .into(_db.transactionEntries)
          .insert(TransactionEntriesCompanion.insert(
            transactionId: newTransactionId,
            accountId: inventoryAccountId,
            amount: -totalCostOfGoodsSold,
            createdAt: d.Value(now),
            lastUpdated: d.Value(now),
          ));

      final newOrderId = _uuid.v4();
      await _db.into(_db.orders).insert(OrdersCompanion.insert(
            id: d.Value(newOrderId),
            transactionId: newTransactionId,
            totalAmount: totalAmount,
            createdAt: d.Value(now),
            lastUpdated: d.Value(now),
          ));

      for (final item in items) {
        await _db.into(_db.orderItems).insert(OrderItemsCompanion.insert(
              orderId: newOrderId,
              productId: item.product.id,
              productName: item.product.name,
              quantity: item.quantity.toDouble(),
              priceAtSale: item.product.price,
              createdAt: d.Value(now),
              lastUpdated: d.Value(now),
            ));
      }
    });
  }

  Future<void> createJournalTransaction({
    required String description,
    required DateTime transactionDate,
    required List<TransactionEntriesCompanion> entries,
  }) async {
    double balance = 0.0;
    if (entries.isEmpty) {
      throw Exception('Cannot save a transaction with no entries.');
    }
    for (final entry in entries) {
      balance += entry.amount.value;
    }

    if (balance.abs() > 0.001) {
      throw Exception('Transaction is unbalanced! Balance: $balance');
    }

    return _db.transaction(() async {
      final newTransactionId = _uuid.v4();
      await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
            id: d.Value(newTransactionId),
            description: description,
            transactionDate: transactionDate,
          ));
      for (final entry in entries) {
        await _db.into(_db.transactionEntries).insert(entry.copyWith(
              transactionId: d.Value(newTransactionId),
            ));
      }
    });
  }

  Future<void> processPartialReturn({
    required String originalTransactionId,
    required String originalPaymentAccountId,
    required String originalSalesAccountId,
    required Map<OrderItem, double> itemsToReturn,
    required double totalRefundAmount,
    required String currencyCode,
    required String returnDescription,
  }) {
    return _db.transaction(() async {
      final now = DateTime.now();
      final newTransactionId = _uuid.v4();

      await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
            id: d.Value(newTransactionId),
            description: returnDescription,
            transactionDate: now,
            currencyCode: d.Value(currencyCode),
            relatedTransactionId: d.Value(originalTransactionId),
            createdAt: d.Value(now),
            lastUpdated: d.Value(now),
          ));

      await _db.into(_db.transactionEntries).insert(
            TransactionEntriesCompanion.insert(
              transactionId: newTransactionId,
              accountId: originalPaymentAccountId,
              amount: -totalRefundAmount,
              currencyRate: const d.Value(1.0),
              createdAt: d.Value(now),
              lastUpdated: d.Value(now),
            ));

      await _db.into(_db.transactionEntries).insert(
            TransactionEntriesCompanion.insert(
              transactionId: newTransactionId,
              accountId: originalSalesAccountId,
              amount: totalRefundAmount,
              currencyRate: const d.Value(1.0),
              createdAt: d.Value(now),
              lastUpdated: d.Value(now),
            ));

      for (final entry in itemsToReturn.entries) {
        final item = entry.key;
        final quantityToReturn = entry.value;
        final newQuantityReturned = item.quantityReturned + quantityToReturn;

        await (_db.update(_db.orderItems)
              ..where((tbl) => tbl.id.equals(item.id)))
            .write(
          OrderItemsCompanion(
            quantityReturned: d.Value(newQuantityReturned),
            lastUpdated: d.Value(now),
          ),
        );
      }
    });
  }

  // DELETED watchTransactionDetails()
  // DELETED watchTransactionDetailsByTransactionId()

  Future<void> deleteTransaction(String id) {
    return (_db.delete(_db.transactions)..where((tbl) => tbl.id.equals(id)))
        .go();
  }
}