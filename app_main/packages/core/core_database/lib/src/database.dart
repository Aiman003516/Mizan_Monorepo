import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:uuid/uuid.dart';
import 'package:core_database/src/initial_constants.dart';

part 'database.g.dart';

const Uuid _uuid = Uuid();

// 🧬 THE SCHEMA DNA
abstract class MizanTable extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  
  // This serves as the "last_modified" for the Sync Engine
  DateTimeColumn get lastUpdated =>
      dateTime().clientDefault(() => DateTime.now())();

  // --- ☁️ SAAS TRANSFORMATION MARKERS ---
  
  // 1. The Tenant ID (Nullable for Free Tier)
  TextColumn get tenantId => text().nullable()();

  // 2. The Soft Delete Flag
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// --- PHASE 2 TABLES ---
@DataClassName('AdjustingEntryTask')
class AdjustingEntryTasks extends MizanTable {
  DateTimeColumn get adjustmentDate => dateTime()();
  TextColumn get description => text()();
  TextColumn get taskType => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get proposedEntryJson => text()();
  TextColumn get journalEntryId =>
      text().nullable().references(Transactions, #id, onDelete: KeyAction.setNull)();
}

// --- PHASE 3 TABLES ---
@DataClassName('BankReconciliation')
class BankReconciliations extends MizanTable {
  TextColumn get accountId => text().references(Accounts, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get statementDate => dateTime()();
  IntColumn get statementEndingBalance => integer()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
}

@DataClassName('ReconciledTransaction')
class ReconciledTransactions extends MizanTable {
  TextColumn get reconciliationId => 
      text().references(BankReconciliations, #id, onDelete: KeyAction.cascade)();
  TextColumn get transactionId => 
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
}

// ⭐️ NEW TABLE: INVENTORY LAYERS (The "Isolated Ledger")
@DataClassName('InventoryCostLayer')
class InventoryCostLayers extends MizanTable {
  TextColumn get productId => text().references(Products, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get quantityPurchased => real()();
  RealColumn get quantityRemaining => real()();
  IntColumn get costPerUnit => integer()(); // Cents
}

// --- CORE TABLES ---
@DataClassName('Classification')
class Classifications extends MizanTable {
  TextColumn get name => text().unique()();
}

@DataClassName('Category')
class Categories extends MizanTable {
  TextColumn get name => text().unique()();
  TextColumn get imagePath => text().nullable()();
}

@DataClassName('Product')
class Products extends MizanTable {
  TextColumn get name => text()();
  IntColumn get price => integer()(); // Cents
  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.restrict)();
  TextColumn get barcode => text().nullable().unique()();
  TextColumn get imagePath => text().nullable()();
  RealColumn get quantityOnHand => real().withDefault(const Constant(0.0))();
  IntColumn get averageCost => integer().withDefault(const Constant(0))(); // Cents
}

@DataClassName('Account')
class Accounts extends MizanTable {
  TextColumn get name => text()();
  TextColumn get type => text()();
  IntColumn get initialBalance => integer()(); // Cents
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get classificationId =>
      text().nullable().references(Classifications, #id, onDelete: KeyAction.setNull)();
}

@DataClassName('Transaction')
class Transactions extends MizanTable {
  TextColumn get description => text()();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get attachmentPath => text().nullable()();
  TextColumn get currencyCode => text().withDefault(const Constant('Local'))();
  TextColumn get relatedTransactionId =>
      text().nullable().references(Transactions, #id, onDelete: KeyAction.setNull)();
  BoolColumn get isAdjustment => boolean().withDefault(const Constant(false))();
}

@DataClassName('TransactionEntry')
class TransactionEntries extends MizanTable {
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.restrict)();
  IntColumn get amount => integer()(); // Cents
  RealColumn get currencyRate => real().withDefault(const Constant(1.0))();
}

@DataClassName('Currency')
class Currencies extends MizanTable {
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get symbol => text().nullable()();
}

@DataClassName('PaymentMethod')
class PaymentMethods extends MizanTable {
  TextColumn get name => text().unique()();
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.restrict)();
}

@DataClassName('Order')
class Orders extends MizanTable {
  TextColumn get transactionId =>
      text().unique().references(Transactions, #id, onDelete: KeyAction.cascade)();
  IntColumn get totalAmount => integer()(); // Cents
}

@DataClassName('OrderItem')
class OrderItems extends MizanTable {
  TextColumn get orderId =>
      text().references(Orders, #id, onDelete: KeyAction.cascade)();
  TextColumn get productId =>
      text().references(Products, #id, onDelete: KeyAction.restrict)();
  TextColumn get productName => text()();
  RealColumn get quantity => real()();
  IntColumn get priceAtSale => integer()(); // Cents
  RealColumn get quantityReturned =>
      real().withDefault(const Constant(0.0))();
}

@DriftDatabase(tables: [
  Categories,
  Products,
  Classifications,
  Accounts,
  Transactions,
  TransactionEntries,
  Currencies,
  PaymentMethods,
  Orders,
  OrderItems,
  AdjustingEntryTasks,
  BankReconciliations,
  ReconciledTransactions,
  InventoryCostLayers,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // ⭐️ BUMPED VERSION: 17 -> 18
  @override
  int get schemaVersion => 18;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // 🛡️ IDEMPOTENT SEEDING: Safe to run multiple times
      await _createInitialAccounts();
      await _createInitialClassifications();
      await _createInitialCurrencies();
      await _createInitialPaymentMethods();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 15) {
        await m.createTable(adjustingEntryTasks);
        await m.addColumn(transactions, transactions.isAdjustment);
      }
      if (from < 16) {
        await m.createTable(bankReconciliations);
        await m.createTable(reconciledTransactions);
      }
      if (from < 17) {
        await m.createTable(inventoryCostLayers);
      }
      
      // 🚀 PHASE 2: SAAS MIGRATION (Version 18)
      if (from < 18) {
        // We cast these to MizanTable so we can access tenantId/isDeleted
        final tables = [
           categories, products, classifications, accounts, 
           transactions, transactionEntries, currencies, paymentMethods, 
           orders, orderItems, adjustingEntryTasks, 
           bankReconciliations, reconciledTransactions, inventoryCostLayers
        ];

        for (final table in tables) {
           // 🛡️ THE SAFETY CAST
           await m.addColumn(
             table as TableInfo<Table, dynamic>, 
             table.tenantId as GeneratedColumn<Object>
           );
           
           await m.addColumn(
             table as TableInfo<Table, dynamic>, 
             table.isDeleted as GeneratedColumn<Object>
           );
        }
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _createInitialAccounts() async {
    final now = DateTime.now();
    
    // 🛡️ CHECK BEFORE INSERT: Avoid duplicating accounts
    // Since 'name' is not unique in the DB schema, we manually check.
    final existing = await (select(accounts)..where((t) => t.name.equals(kCashAccountName))).get();
    if (existing.isNotEmpty) return;

    await into(accounts).insert(AccountsCompanion.insert(
      name: kCashAccountName, type: 'asset', initialBalance: 0,
      createdAt: Value(now), lastUpdated: Value(now), phoneNumber: const Value(null),
    ));
    await into(accounts).insert(AccountsCompanion.insert(
      name: kSalesRevenueAccountName, type: 'revenue', initialBalance: 0,
      createdAt: Value(now), lastUpdated: Value(now), phoneNumber: const Value(null),
    ));
    await into(accounts).insert(AccountsCompanion.insert(
      name: kEquityAccountName, type: 'equity', initialBalance: 0,
      createdAt: Value(now), lastUpdated: Value(now), phoneNumber: const Value(null),
    ));
    await into(accounts).insert(AccountsCompanion.insert(
      name: kInventoryAccountName, type: 'asset', initialBalance: 0,
      createdAt: Value(now), lastUpdated: Value(now), phoneNumber: const Value(null),
    ));
    await into(accounts).insert(AccountsCompanion.insert(
      name: kCogsAccountName, type: 'expense', initialBalance: 0,
      createdAt: Value(now), lastUpdated: Value(now), phoneNumber: const Value(null),
    ));
  }

  Future<void> _createInitialClassifications() async {
    final now = DateTime.now();
    // 🛡️ INSERT OR IGNORE: Skips if 'name' (Unique) already exists
    await into(classifications).insert(ClassificationsCompanion.insert(
      name: kClassificationClients, createdAt: Value(now), lastUpdated: Value(now),
    ), mode: InsertMode.insertOrIgnore);
    
    await into(classifications).insert(ClassificationsCompanion.insert(
      name: kClassificationSuppliers, createdAt: Value(now), lastUpdated: Value(now),
    ), mode: InsertMode.insertOrIgnore);
    
    await into(classifications).insert(ClassificationsCompanion.insert(
      name: kClassificationGeneral, createdAt: Value(now), lastUpdated: Value(now),
    ), mode: InsertMode.insertOrIgnore);
  }
  
  Future<void> _createInitialCurrencies() async {
    final now = DateTime.now();
    // 🛡️ INSERT OR IGNORE: Skips if 'code' (Unique) already exists
    await into(currencies).insert(CurrenciesCompanion.insert(
      code: 'Local',
      name: 'Local Currency',
      symbol: const Value(null),
      createdAt: Value(now),
      lastUpdated: Value(now),
    ), mode: InsertMode.insertOrIgnore);
    
    await into(currencies).insert(CurrenciesCompanion.insert(
      code: 'USD',
      name: 'US Dollar',
      symbol: const Value('\$'),
      createdAt: Value(now),
      lastUpdated: Value(now),
    ), mode: InsertMode.insertOrIgnore);
    
    await into(currencies).insert(CurrenciesCompanion.insert(
      code: 'SAR',
      name: 'Saudi Riyal',
      symbol: const Value('﷼'),
      createdAt: Value(now),
      lastUpdated: Value(now),
    ), mode: InsertMode.insertOrIgnore);
  }

  Future<void> _createInitialPaymentMethods() async {
    final cashAccount = await (select(accounts)
          ..where((tbl) => tbl.name.equals(kCashAccountName)))
        .getSingleOrNull();

    if (cashAccount != null) {
      final now = DateTime.now();
      // 🛡️ INSERT OR IGNORE: Skips if 'name' (Unique) already exists
      await into(paymentMethods).insert(PaymentMethodsCompanion.insert( 
            name: 'Cash',
            accountId: cashAccount.id,
            createdAt: Value(now),
            lastUpdated: Value(now),
          ), mode: InsertMode.insertOrIgnore);
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mizan.db'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}