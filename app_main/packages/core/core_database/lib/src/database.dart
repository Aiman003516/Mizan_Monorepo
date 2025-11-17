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

abstract class MizanTable extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get lastUpdated =>
      dateTime().clientDefault(() => DateTime.now())();

@override
  Set<Column> get primaryKey => {id};      
}

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
  RealColumn get price => real()();
  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.restrict)();
  TextColumn get barcode => text().nullable().unique()();
  TextColumn get imagePath => text().nullable()();
  RealColumn get quantityOnHand => real().withDefault(const Constant(0.0))();
  RealColumn get averageCost => real().withDefault(const Constant(0.0))();
}

@DataClassName('Account')
class Accounts extends MizanTable {
  TextColumn get name => text()();
  TextColumn get type => text()();
  RealColumn get initialBalance => real()();
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
}

@DataClassName('TransactionEntry')
class TransactionEntries extends MizanTable {
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.restrict)();
  RealColumn get amount => real()();
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
  RealColumn get totalAmount => real()();
}

@DataClassName('OrderItem')
class OrderItems extends MizanTable {
  TextColumn get orderId =>
      text().references(Orders, #id, onDelete: KeyAction.cascade)();
  TextColumn get productId =>
      text().references(Products, #id, onDelete: KeyAction.restrict)();
  TextColumn get productName => text()();
  RealColumn get quantity => real()();
  RealColumn get priceAtSale => real()();
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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createInitialAccounts();
      await _createInitialClassifications();
      await _createInitialCurrencies();
      await _createInitialPaymentMethods();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      for (var targetVersion = from + 1; targetVersion <= to; targetVersion++) {
        switch (targetVersion) {
          case 3:
            await m.addColumn(accounts, accounts.phoneNumber);
            break;
          case 4:
            await m.createTable(classifications);
            await m.addColumn(accounts, accounts.classificationId);
            await _createInitialClassifications();
            break;
          case 5:
            await m.addColumn(transactions, transactions.currencyCode);
            await m.addColumn(transactionEntries, transactionEntries.currencyRate);
            break;
          case 6:
            await m.createTable(currencies);
            await _createInitialCurrencies();
            break;
          case 7:
            await m.addColumn(products, products.barcode);
            break;
          case 8:
            await m.addColumn(transactions, transactions.relatedTransactionId);
            break;
          case 9:
            await m.addColumn(categories, categories.imagePath);
            await m.addColumn(products, products.imagePath);
            break;
          case 10:
            await m.createTable(paymentMethods);
            await _createInitialPaymentMethods();
            break;
          case 11:
            await m.createTable(orders);
            await m.createTable(orderItems);
            break;
          case 12:
            await m.addColumn(orderItems, orderItems.quantityReturned);
            break;
          case 13:
            await m.addColumn(products, products.quantityOnHand);
            await m.addColumn(products, products.averageCost);
            break;
        }
      }
    },
  );

  Future<void> _createInitialAccounts() async {
    final now = DateTime.now();
    await into(accounts).insert(AccountsCompanion.insert(
      name: kCashAccountName, type: 'asset', initialBalance: 0.0,
      createdAt: Value(now), lastUpdated: Value(now), phoneNumber: const Value(null),
    ));
    await into(accounts).insert(AccountsCompanion.insert(
      name: kSalesRevenueAccountName, type: 'revenue', initialBalance: 0.0,
      createdAt: Value(now), lastUpdated: Value(now), phoneNumber: const Value(null),
    ));
    await into(accounts).insert(AccountsCompanion.insert(
      name: kEquityAccountName, type: 'equity', initialBalance: 0.0,
      createdAt: Value(now), lastUpdated: Value(now), phoneNumber: const Value(null),
    ));
    await into(accounts).insert(AccountsCompanion.insert(
      name: kInventoryAccountName, type: 'asset', initialBalance: 0.0,
      createdAt: Value(now), lastUpdated: Value(now), phoneNumber: const Value(null),
    ));
    await into(accounts).insert(AccountsCompanion.insert(
      name: kCogsAccountName, type: 'expense', initialBalance: 0.0,
      createdAt: Value(now), lastUpdated: Value(now), phoneNumber: const Value(null),
    ));
  }

  Future<void> _createInitialClassifications() async {
    final now = DateTime.now();
    await into(classifications).insert(ClassificationsCompanion.insert(
      name: kClassificationClients, createdAt: Value(now), lastUpdated: Value(now),
    ));
    await into(classifications).insert(ClassificationsCompanion.insert(
      name: kClassificationSuppliers, createdAt: Value(now), lastUpdated: Value(now),
    ));
    await into(classifications).insert(ClassificationsCompanion.insert(
      name: kClassificationGeneral, createdAt: Value(now), lastUpdated: Value(now),
    ));
  }
  
  Future<void> _createInitialCurrencies() async {
    final now = DateTime.now();
    await into(currencies).insert(CurrenciesCompanion.insert(
      code: 'Local',
      name: 'Local Currency',
      symbol: const Value(null),
      createdAt: Value(now),
      lastUpdated: Value(now),
    ));
    await into(currencies).insert(CurrenciesCompanion.insert(
      code: 'USD',
      name: 'US Dollar',
      symbol: const Value('\$'),
      createdAt: Value(now),
      lastUpdated: Value(now),
    ));
    await into(currencies).insert(CurrenciesCompanion.insert(
      code: 'SAR',
      name: 'Saudi Riyal',
      symbol: const Value('﷼'),
      createdAt: Value(now),
      lastUpdated: Value(now),
    ));
  }

  Future<void> _createInitialPaymentMethods() async {
    final cashAccount = await (select(accounts)
          ..where((tbl) => tbl.name.equals(kCashAccountName)))
        .getSingleOrNull();

    if (cashAccount != null) {
      final now = DateTime.now();
      await into(paymentMethods).insert(PaymentMethodsCompanion.insert( 
            name: 'Cash',
            accountId: cashAccount.id,
            createdAt: Value(now),
            lastUpdated: Value(now),
          ));
    }
  }

  // ALL PUBLIC HELPER/BUSINESS LOGIC METHODS HAVE BEEN REMOVED
  // (e.g., getAccountIdByName, updateProduct, createPosSale, etc.)
  // They will be added to feature-specific repositories.

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