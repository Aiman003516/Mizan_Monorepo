import 'package:drift/drift.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:core_data/core_data.dart'; // Preferences
import 'package:uuid/uuid.dart';

// We need Feature Accounts to find Inventory/COGS accounts
import 'package:feature_accounts/feature_accounts.dart' hide databaseProvider;
import 'package:feature_transactions/src/data/database_provider.dart';
import 'package:feature_transactions/src/presentation/pos_receipt_provider.dart';

// ⭐️ RENAMED to avoid conflict with PurchaseItem in purchase_screen.dart
class RepoPurchaseItem {
  final String productId;
  final double quantity;
  final int costPerUnitCents; // The cost entered by user

  RepoPurchaseItem({
    required this.productId,
    required this.quantity,
    required this.costPerUnitCents,
  });
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final accountsRepo = ref.watch(accountsRepositoryProvider);
  final prefsRepo = ref.watch(preferencesRepositoryProvider);
  
  // 🛡️ TEMP FIX: Hardcode Tenant ID to match CloudSyncService
  // In Phase 4, we will read this from the AuthRepository.
  return TransactionsRepository(db, accountsRepo, const Uuid(), prefsRepo, tenantId: 'test_tenant_123');
});

final orderForTransactionProvider =
    FutureProvider.autoDispose.family<Order?, String>((ref, transactionId) {
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.getOrderForTransaction(transactionId);
});

final orderItemsStreamProvider =
    StreamProvider.autoDispose.family<List<OrderItem>, String>((ref, orderId) {
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.watchOrderItems(orderId);
});

class TransactionsRepository {
  // Added optional tenantId parameter
  TransactionsRepository(this._db, this._accountsRepo, this._uuid, this._prefsRepo, {this.tenantId});

  final AppDatabase _db;
  final AccountsRepository _accountsRepo;
  final Uuid _uuid;
  final PreferencesRepository _prefsRepo;
  final String? tenantId; // 🌍 The Scope Context

  /// 🔒 THE GUARD CLAUSE
  void _enforcePeriodLock(DateTime date) {
    final lockDate = _prefsRepo.getPeriodLockDate();
    if (lockDate != null) {
      if (!date.isAfter(lockDate)) {
        throw Exception(
          "Period Closed: Cannot create or modify transactions on or before ${lockDate.toString().split(' ')[0]}.",
        );
      }
    }
  }

  // --- READ METHODS ---

  Future<List<Transaction>> getTransactions({int limit = 20, int offset = 0}) {
    return (_db.select(_db.transactions)
          ..orderBy([
            (t) => d.OrderingTerm.desc(t.transactionDate),
            (t) => d.OrderingTerm.desc(t.createdAt),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

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

  // --- 🏭 THE COSTING ENGINE (Phase 3.2) ---

  Future<int> _calculateCOGSAndConsumeLayers(String productId, double quantitySold) async {
    final method = _prefsRepo.getInventoryCostingMethod(); 
    
    final layers = await (_db.select(_db.inventoryCostLayers)
          ..where((l) => l.productId.equals(productId) & l.quantityRemaining.isBiggerThanValue(0))
          ..orderBy([(l) => d.OrderingTerm.asc(l.purchaseDate)]))
        .get();

    double totalCostAccumulator = 0;
    double qtyToSettle = quantitySold;

    int waCostPerUnit = 0;
    if (method == 'weighted_average') {
      double totalValue = 0;
      double totalQty = 0;
      for (var l in layers) {
        totalValue += l.quantityRemaining * l.costPerUnit;
        totalQty += l.quantityRemaining;
      }
      if (totalQty > 0) {
        waCostPerUnit = (totalValue / totalQty).round();
      }
    }

    for (var layer in layers) {
      if (qtyToSettle <= 0) break;

      double qtyFromThisLayer = 0;
      if (layer.quantityRemaining >= qtyToSettle) {
        qtyFromThisLayer = qtyToSettle;
      } else {
        qtyFromThisLayer = layer.quantityRemaining;
      }

      int unitCostUsed = (method == 'weighted_average') ? waCostPerUnit : layer.costPerUnit;
      
      totalCostAccumulator += (qtyFromThisLayer * unitCostUsed);

      await (_db.update(_db.inventoryCostLayers)..where((l) => l.id.equals(layer.id)))
          .write(InventoryCostLayersCompanion(
            quantityRemaining: d.Value(layer.quantityRemaining - qtyFromThisLayer),
            // We don't update tenantId on modification usually, but we could if moving ownership
          ));

      qtyToSettle -= qtyFromThisLayer;
    }

    if (qtyToSettle > 0) {
      final product = await (_db.select(_db.products)..where((p) => p.id.equals(productId))).getSingle();
      totalCostAccumulator += (qtyToSettle * product.averageCost);
    }

    return totalCostAccumulator.round();
  }

  // --- WRITE METHODS ---

  /// ⭐️ UPDATED: POS Sale with Dynamic Costing + TENANT ID
  Future<void> createPosSale({
    required TransactionsCompanion transactionCompanion,
    required List<TransactionEntriesCompanion> entries,
    required List<PosReceiptItem> items,
    required double totalAmount,
  }) {
    _enforcePeriodLock(transactionCompanion.transactionDate.value);

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

      int totalCostOfGoodsSoldCents = 0;

      for (final item in items) {
        final int costForThisItem = await _calculateCOGSAndConsumeLayers(item.product.id, item.quantity);
        totalCostOfGoodsSoldCents += costForThisItem;

        final product = await (_db.select(_db.products)..where((p) => p.id.equals(item.product.id))).getSingle();
        final newQuantity = product.quantityOnHand - item.quantity;
        
        await (_db.update(_db.products)..where((p) => p.id.equals(item.product.id)))
            .write(ProductsCompanion(
              quantityOnHand: d.Value(newQuantity),
              lastUpdated: d.Value(now),
            ));
      }

      // Create Transaction Header (WITH TENANT ID)
      await _db.into(_db.transactions).insert(transactionCompanion.copyWith(
            id: d.Value(newTransactionId),
            createdAt: d.Value(now),
            lastUpdated: d.Value(now),
            tenantId: d.Value(tenantId), // 👈 INJECTED
          ));

      // Create User Entries
      for (final entry in entries) {
        await _db.into(_db.transactionEntries).insert(entry.copyWith(
              transactionId: d.Value(newTransactionId),
              createdAt: d.Value(now),
              lastUpdated: d.Value(now),
              tenantId: d.Value(tenantId), // 👈 INJECTED
            ));
      }

      // Create COGS Entries
      await _db.into(_db.transactionEntries).insert(TransactionEntriesCompanion.insert(
            transactionId: newTransactionId,
            accountId: cogsAccountId,
            amount: totalCostOfGoodsSoldCents,
            createdAt: d.Value(now),
            lastUpdated: d.Value(now),
            tenantId: d.Value(tenantId), // 👈 INJECTED
          ));
      await _db.into(_db.transactionEntries).insert(TransactionEntriesCompanion.insert(
            transactionId: newTransactionId,
            accountId: inventoryAccountId,
            amount: -totalCostOfGoodsSoldCents,
            createdAt: d.Value(now),
            lastUpdated: d.Value(now),
            tenantId: d.Value(tenantId), // 👈 INJECTED
          ));

      // Create Order Record
      final newOrderId = _uuid.v4();
      await _db.into(_db.orders).insert(OrdersCompanion.insert(
            id: d.Value(newOrderId),
            transactionId: newTransactionId,
            totalAmount: (totalAmount * 100).round(),
            createdAt: d.Value(now),
            lastUpdated: d.Value(now),
            tenantId: d.Value(tenantId), // 👈 INJECTED
          ));

      for (final item in items) {
        await _db.into(_db.orderItems).insert(OrderItemsCompanion.insert(
              orderId: newOrderId,
              productId: item.product.id,
              productName: item.product.name,
              quantity: item.quantity,
              priceAtSale: item.product.price,
              createdAt: d.Value(now),
              lastUpdated: d.Value(now),
              tenantId: d.Value(tenantId), // 👈 INJECTED
            ));
      }
    });
  }

  /// ⭐️ NEW: Create Purchase with Layer Tracking + TENANT ID
  Future<void> createPurchaseTransaction({
    required String description,
    required DateTime transactionDate,
    required List<TransactionEntriesCompanion> entries,
    required List<RepoPurchaseItem> items,
    String? attachmentPath,
  }) async {
    _enforcePeriodLock(transactionDate);

    return _db.transaction(() async {
      final newTransactionId = _uuid.v4();
      final now = DateTime.now();

      await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
        id: d.Value(newTransactionId),
        description: description,
        transactionDate: transactionDate,
        attachmentPath: d.Value(attachmentPath),
        createdAt: d.Value(now),
        lastUpdated: d.Value(now),
        tenantId: d.Value(tenantId), // 👈 INJECTED
      ));

      for (final entry in entries) {
        await _db.into(_db.transactionEntries).insert(entry.copyWith(
          transactionId: d.Value(newTransactionId),
          createdAt: d.Value(now),
          lastUpdated: d.Value(now),
          tenantId: d.Value(tenantId), // 👈 INJECTED
        ));
      }

      for (final item in items) {
        await _db.into(_db.inventoryCostLayers).insert(InventoryCostLayersCompanion.insert(
          productId: item.productId,
          purchaseDate: transactionDate,
          quantityPurchased: item.quantity,
          quantityRemaining: item.quantity,
          costPerUnit: item.costPerUnitCents,
          createdAt: d.Value(now),
          lastUpdated: d.Value(now),
          tenantId: d.Value(tenantId), // 👈 INJECTED
        ));

        final product = await (_db.select(_db.products)..where((p) => p.id.equals(item.productId))).getSingle();
        final double oldTotalValue = product.averageCost * product.quantityOnHand;
        final double newPurchaseValue = item.costPerUnitCents * item.quantity;
        final double newTotalQty = product.quantityOnHand + item.quantity;
        
        int newAverageCost = product.averageCost;
        if (newTotalQty > 0) {
          newAverageCost = ((oldTotalValue + newPurchaseValue) / newTotalQty).round();
        }

        await (_db.update(_db.products)..where((p) => p.id.equals(item.productId)))
            .write(ProductsCompanion(
              quantityOnHand: d.Value(newTotalQty),
              averageCost: d.Value(newAverageCost),
              lastUpdated: d.Value(now),
            ));
      }
    });
  }

  // --- GENERIC METHODS + TENANT ID ---

  Future<void> createTransaction({
    required String description,
    required DateTime transactionDate,
    required List<TransactionEntriesCompanion> entries,
    String? attachmentPath,
    String currencyCode = 'Local',
    String? relatedTransactionId,
  }) {
    _enforcePeriodLock(transactionDate);

    return _db.transaction(() async {
      final newTransactionId = _uuid.v4();
      final now = DateTime.now();

      await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
        id: d.Value(newTransactionId),
        description: description,
        transactionDate: transactionDate,
        attachmentPath: d.Value(attachmentPath),
        currencyCode: d.Value(currencyCode),
        createdAt: d.Value(now),
        lastUpdated: d.Value(now),
        relatedTransactionId: d.Value(relatedTransactionId),
        tenantId: d.Value(tenantId), // 👈 INJECTED
      ));

      for (final entry in entries) {
        await _db.into(_db.transactionEntries).insert(entry.copyWith(
          transactionId: d.Value(newTransactionId),
          createdAt: d.Value(now),
          lastUpdated: d.Value(now),
          tenantId: d.Value(tenantId), // 👈 INJECTED
        ));
      }
    });
  }

  Future<void> createJournalTransaction({
    required String description,
    required DateTime transactionDate,
    required List<TransactionEntriesCompanion> entries,
  }) async {
    _enforcePeriodLock(transactionDate);

    int balance = 0;
    if (entries.isEmpty) throw Exception('Cannot save a transaction with no entries.');
    for (final entry in entries) balance += entry.amount.value;
    if (balance != 0) throw Exception('Transaction is unbalanced! Balance diff: $balance cents');

    return _db.transaction(() async {
      final newTransactionId = _uuid.v4();
      await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
            id: d.Value(newTransactionId),
            description: description,
            transactionDate: transactionDate,
            tenantId: d.Value(tenantId), // 👈 INJECTED
          ));
      for (final entry in entries) {
        await _db.into(_db.transactionEntries).insert(entry.copyWith(
              transactionId: d.Value(newTransactionId),
              tenantId: d.Value(tenantId), // 👈 INJECTED
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
    _enforcePeriodLock(DateTime.now());

    return _db.transaction(() async {
      final now = DateTime.now();
      final newTransactionId = _uuid.v4();
      final int refundCents = (totalRefundAmount * 100).round();

      await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
            id: d.Value(newTransactionId),
            description: returnDescription,
            transactionDate: now,
            currencyCode: d.Value(currencyCode),
            relatedTransactionId: d.Value(originalTransactionId),
            createdAt: d.Value(now),
            lastUpdated: d.Value(now),
            tenantId: d.Value(tenantId), // 👈 INJECTED
          ));

      await _db.into(_db.transactionEntries).insert(TransactionEntriesCompanion.insert(
            transactionId: newTransactionId,
            accountId: originalPaymentAccountId,
            amount: -refundCents,
            currencyRate: const d.Value(1.0),
            createdAt: d.Value(now),
            lastUpdated: d.Value(now),
            tenantId: d.Value(tenantId), // 👈 INJECTED
          ));

      await _db.into(_db.transactionEntries).insert(TransactionEntriesCompanion.insert(
            transactionId: newTransactionId,
            accountId: originalSalesAccountId,
            amount: refundCents,
            currencyRate: const d.Value(1.0),
            createdAt: d.Value(now),
            lastUpdated: d.Value(now),
            tenantId: d.Value(tenantId), // 👈 INJECTED
          ));

      for (final entry in itemsToReturn.entries) {
        final item = entry.key;
        final quantityToReturn = entry.value;
        final newQuantityReturned = item.quantityReturned + quantityToReturn;

        await (_db.update(_db.orderItems)..where((tbl) => tbl.id.equals(item.id)))
            .write(OrderItemsCompanion(
              quantityReturned: d.Value(newQuantityReturned),
              lastUpdated: d.Value(now),
            ));
      }
    });
  }

  Future<void> deleteTransaction(String id) async {
    final transaction = await (_db.select(_db.transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (transaction != null) {
      _enforcePeriodLock(transaction.transactionDate);
      await (_db.delete(_db.transactions)..where((tbl) => tbl.id.equals(id))).go();
    }
  }

  // --- CLOSE PERIOD (Phase 2.2) ---
  Future<void> closePeriod({
    required DateTime closingDate,
    required String retainedEarningsAccountId,
  }) async {
    _enforcePeriodLock(closingDate);

    return _db.transaction(() async {
      final query = _db.select(_db.transactionEntries).join([
        d.innerJoin(_db.accounts, _db.accounts.id.equalsExp(_db.transactionEntries.accountId)),
        d.innerJoin(_db.transactions, _db.transactions.id.equalsExp(_db.transactionEntries.transactionId)),
      ]);

      query.where(
        _db.accounts.type.isIn(['revenue', 'expense']) &
        _db.transactions.transactionDate.isSmallerOrEqualValue(closingDate)
      );

      final results = await query.get();
      final Map<String, int> accountBalances = {};
      
      for (final row in results) {
        final accountId = row.readTable(_db.accounts).id;
        final amount = row.readTable(_db.transactionEntries).amount;
        accountBalances[accountId] = (accountBalances[accountId] ?? 0) + amount;
      }

      final List<TransactionEntriesCompanion> closingLines = [];
      int netIncomeAccumulator = 0;

      accountBalances.forEach((accountId, balance) {
        if (balance != 0) {
          final closingAmount = -balance;
          closingLines.add(TransactionEntriesCompanion.insert(
            transactionId: 'TEMP',
            accountId: accountId,
            amount: closingAmount,
            currencyRate: const d.Value(1.0),
            tenantId: d.Value(tenantId), // 👈 INJECTED
          ));
          netIncomeAccumulator += closingAmount;
        }
      });

      if (closingLines.isEmpty) {
        throw Exception("No Revenue or Expense balances to close.");
      }

      closingLines.add(TransactionEntriesCompanion.insert(
        transactionId: 'TEMP',
        accountId: retainedEarningsAccountId,
        amount: -netIncomeAccumulator,
        currencyRate: const d.Value(1.0),
        tenantId: d.Value(tenantId), // 👈 INJECTED
      ));

      final newTransactionId = _uuid.v4();
      final now = DateTime.now();

      await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
        id: d.Value(newTransactionId),
        description: "Period Closing Entry (${closingDate.toString().split(' ')[0]})",
        transactionDate: closingDate,
        isAdjustment: const d.Value(true),
        createdAt: d.Value(now),
        lastUpdated: d.Value(now),
        tenantId: d.Value(tenantId), // 👈 INJECTED
      ));

      for (final line in closingLines) {
        await _db.into(_db.transactionEntries).insert(line.copyWith(
          transactionId: d.Value(newTransactionId),
          createdAt: d.Value(now),
          lastUpdated: d.Value(now),
        ));
      }

      await _prefsRepo.setPeriodLockDate(closingDate);
    });
  }
}