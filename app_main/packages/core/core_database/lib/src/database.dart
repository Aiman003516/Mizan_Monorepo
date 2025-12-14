// FILE: packages/core/core_database/lib/src/database.dart

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
  DateTimeColumn get lastUpdated =>
      dateTime().clientDefault(() => DateTime.now())();
  TextColumn get tenantId => text().nullable()();
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
  TextColumn get journalEntryId => text().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.setNull,
  )();
}

// --- PHASE 3 TABLES ---
@DataClassName('BankReconciliation')
class BankReconciliations extends MizanTable {
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get statementDate => dateTime()();
  IntColumn get statementEndingBalance => integer()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
}

@DataClassName('ReconciledTransaction')
class ReconciledTransactions extends MizanTable {
  TextColumn get reconciliationId => text().references(
    BankReconciliations,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
}

// --- PHASE 3.5: INVENTORY LAYERS ---
@DataClassName('InventoryCostLayer')
class InventoryCostLayers extends MizanTable {
  TextColumn get productId =>
      text().references(Products, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get quantityPurchased => real()();
  RealColumn get quantityRemaining => real()();
  IntColumn get costPerUnit => integer()();
}

// --- PHASE 5.3: LOCAL REPORT TEMPLATES (New Table) ---
@DataClassName('LocalReportTemplate')
class LocalReportTemplates extends MizanTable {
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get sqlQuery => text()(); // Raw SQL
  TextColumn get columnsJson => text()(); // JSON List of Columns
  TextColumn get parametersJson => text()(); // JSON List of Parameters
  BoolColumn get isPremium => boolean().withDefault(const Constant(false))();
}

// --- PHASE 1C: GHOST MONEY TRACKING ---
@DataClassName('GhostMoneyEntry')
class GhostMoneyEntries extends MizanTable {
  TextColumn get sourceType =>
      text()(); // 'TRANSACTION', 'SPLIT', 'EXCHANGE', 'IMPORT'
  TextColumn get sourceId => text()(); // Reference to source record
  IntColumn get ghostAmount =>
      integer()(); // Amount in smallest unit (cents/fils)
  TextColumn get currency => text()(); // Currency code (e.g., 'USD', 'SAR')
  TextColumn get reason => text()(); // 'ROUNDING', 'DIVISION', 'EXCHANGE_RATE'
  BoolColumn get reconciled => boolean().withDefault(const Constant(false))();
  TextColumn get reconciledTransactionId => text().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.setNull,
  )();
}

// --- PHASE 3: FIXED ASSETS ---
@DataClassName('FixedAsset')
class FixedAssets extends MizanTable {
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get assetAccountId =>
      text().references(Accounts, #id, onDelete: KeyAction.restrict)();
  TextColumn get accumulatedDepreciationAccountId =>
      text().references(Accounts, #id, onDelete: KeyAction.restrict)();
  TextColumn get depreciationExpenseAccountId =>
      text().references(Accounts, #id, onDelete: KeyAction.restrict)();
  IntColumn get acquisitionCost => integer()(); // Original cost
  IntColumn get salvageValue => integer()(); // Residual value
  DateTimeColumn get acquisitionDate => dateTime()();
  DateTimeColumn get disposalDate => dateTime().nullable()();
  IntColumn get usefulLifeMonths => integer()(); // Useful life in months
  IntColumn get usefulLifeUnits =>
      integer().nullable()(); // For units-of-activity
  TextColumn get depreciationMethod =>
      text()(); // 'STRAIGHT_LINE', 'DECLINING_BALANCE', 'UNITS_OF_ACTIVITY'
  RealColumn get decliningBalanceRate =>
      real().nullable()(); // e.g., 2.0 for double declining
  IntColumn get totalDepreciation => integer().withDefault(const Constant(0))();
  IntColumn get currentPeriodDepreciation =>
      integer().withDefault(const Constant(0))();
  IntColumn get unitsUsed => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(
    const Constant('ACTIVE'),
  )(); // 'ACTIVE', 'DISPOSED', 'FULLY_DEPRECIATED'
}

// --- PHASE 8: ACCOUNTS RECEIVABLE ---
@DataClassName('Customer')
class Customers extends MizanTable {
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get taxId => text().nullable()(); // VAT/Tax number
  IntColumn get creditLimit => integer().withDefault(const Constant(0))();
  IntColumn get balance =>
      integer().withDefault(const Constant(0))(); // Outstanding balance
  TextColumn get receivableAccountId => text().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get notes => text().nullable()();
}

@DataClassName('Invoice')
class Invoices extends MizanTable {
  TextColumn get invoiceNumber => text()(); // INV-0001
  TextColumn get customerId =>
      text().references(Customers, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get invoiceDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  IntColumn get subtotal => integer()(); // Before tax
  IntColumn get taxAmount => integer().withDefault(const Constant(0))();
  IntColumn get totalAmount => integer()(); // subtotal + tax
  IntColumn get amountPaid => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(
    const Constant('draft'),
  )(); // draft, sent, partial, paid, overdue, void
  TextColumn get notes => text().nullable()();
  TextColumn get transactionId => text().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.setNull,
  )(); // Link to journal entry
}

@DataClassName('InvoiceItem')
class InvoiceItems extends MizanTable {
  TextColumn get invoiceId =>
      text().references(Invoices, #id, onDelete: KeyAction.cascade)();
  TextColumn get productId => text().nullable().references(
    Products,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get description => text()();
  RealColumn get quantity => real()();
  IntColumn get unitPrice => integer()();
  IntColumn get amount => integer()(); // quantity * unitPrice
  TextColumn get revenueAccountId => text().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.setNull,
  )();
}

@DataClassName('CustomerPayment')
class CustomerPayments extends MizanTable {
  TextColumn get customerId =>
      text().references(Customers, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get paymentDate => dateTime()();
  IntColumn get amount => integer()();
  TextColumn get paymentMethodId => text().nullable().references(
    PaymentMethods,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get reference => text().nullable()(); // Check number, transfer ref
  TextColumn get notes => text().nullable()();
  TextColumn get transactionId => text().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.setNull,
  )(); // Link to journal entry
}

// Link table for payment-to-invoice allocation
@DataClassName('PaymentAllocation')
class PaymentAllocations extends MizanTable {
  TextColumn get paymentId =>
      text().references(CustomerPayments, #id, onDelete: KeyAction.cascade)();
  TextColumn get invoiceId =>
      text().references(Invoices, #id, onDelete: KeyAction.cascade)();
  IntColumn get amount => integer()(); // Amount applied to this invoice
}

// --- PHASE 8C: ACCOUNTS PAYABLE ---
@DataClassName('Vendor')
class Vendors extends MizanTable {
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get taxId => text().nullable()(); // VAT/Tax number
  IntColumn get balance => integer().withDefault(
    const Constant(0),
  )(); // Outstanding balance (what we owe)
  TextColumn get payableAccountId => text().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get paymentTerms => text().nullable()(); // Net 30, Net 60, etc.
  TextColumn get notes => text().nullable()();
}

@DataClassName('Bill')
class Bills extends MizanTable {
  TextColumn get billNumber => text()(); // BILL-0001
  TextColumn get vendorId =>
      text().references(Vendors, #id, onDelete: KeyAction.restrict)();
  TextColumn get vendorBillNumber =>
      text().nullable()(); // Vendor's invoice reference
  DateTimeColumn get billDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  IntColumn get subtotal => integer()(); // Before tax
  IntColumn get taxAmount => integer().withDefault(const Constant(0))();
  IntColumn get totalAmount => integer()(); // subtotal + tax
  IntColumn get amountPaid => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // pending, partial, paid, overdue
  TextColumn get notes => text().nullable()();
  TextColumn get transactionId => text().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.setNull,
  )(); // Link to journal entry
}

@DataClassName('BillItem')
class BillItems extends MizanTable {
  TextColumn get billId =>
      text().references(Bills, #id, onDelete: KeyAction.cascade)();
  TextColumn get productId => text().nullable().references(
    Products,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get description => text()();
  RealColumn get quantity => real()();
  IntColumn get unitPrice => integer()();
  IntColumn get amount => integer()(); // quantity * unitPrice
  TextColumn get expenseAccountId => text().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.setNull,
  )();
}

@DataClassName('VendorPayment')
class VendorPayments extends MizanTable {
  TextColumn get vendorId =>
      text().references(Vendors, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get paymentDate => dateTime()();
  IntColumn get amount => integer()();
  TextColumn get paymentMethodId => text().nullable().references(
    PaymentMethods,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get reference => text().nullable()(); // Check number, transfer ref
  TextColumn get notes => text().nullable()();
  TextColumn get transactionId => text().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.setNull,
  )(); // Link to journal entry
}

// Link table for vendor payment-to-bill allocation
@DataClassName('BillPaymentAllocation')
class BillPaymentAllocations extends MizanTable {
  TextColumn get paymentId =>
      text().references(VendorPayments, #id, onDelete: KeyAction.cascade)();
  TextColumn get billId =>
      text().references(Bills, #id, onDelete: KeyAction.cascade)();
  IntColumn get amount => integer()(); // Amount applied to this bill
}

// --- PHASE BUDGET: BUDGETING & VARIANCE ANALYSIS ---
@DataClassName('Budget')
class Budgets extends MizanTable {
  TextColumn get name => text()(); // e.g., "Q1 2024 Operating Budget"
  TextColumn get description => text().nullable()();
  TextColumn get periodType =>
      text()(); // 'monthly', 'quarterly', 'annual', 'custom'
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get status => text().withDefault(
    const Constant('draft'),
  )(); // draft, active, closed, archived
  TextColumn get budgetType =>
      text().withDefault(const Constant('static'))(); // 'static' or 'flexible'
  // For flexible budgets: variable rate per unit of activity
  IntColumn get flexibleActivityLevel =>
      integer().nullable()(); // Planned activity level
}

@DataClassName('BudgetLine')
class BudgetLines extends MizanTable {
  TextColumn get budgetId =>
      text().references(Budgets, #id, onDelete: KeyAction.cascade)();
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.restrict)();
  IntColumn get budgetedAmount => integer()(); // Static budget amount
  // For flexible budgets:
  IntColumn get fixedPortion =>
      integer().withDefault(const Constant(0))(); // Fixed cost component
  IntColumn get variableRate =>
      integer().withDefault(const Constant(0))(); // Variable rate per activity
  TextColumn get notes => text().nullable()();
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
  IntColumn get price => integer()();
  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.restrict)();
  TextColumn get barcode => text().nullable().unique()();
  TextColumn get imagePath => text().nullable()();
  RealColumn get quantityOnHand => real().withDefault(const Constant(0.0))();
  IntColumn get averageCost => integer().withDefault(const Constant(0))();
  TextColumn get customAttributes => text().nullable()(); // Phase 5.1
}

@DataClassName('Account')
class Accounts extends MizanTable {
  TextColumn get name => text()();
  TextColumn get type => text()();
  IntColumn get initialBalance => integer()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get classificationId => text().nullable().references(
    Classifications,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get customAttributes => text().nullable()();
  // Phase 2: Account Hierarchy
  IntColumn get accountNumber => integer().nullable()(); // e.g., 1010, 2010
  TextColumn get parentAccountId => text().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get level =>
      integer().withDefault(const Constant(0))(); // Hierarchy depth
  BoolColumn get isHeader => boolean().withDefault(
    const Constant(false),
  )(); // Header vs posting account
}

@DataClassName('Transaction')
class Transactions extends MizanTable {
  TextColumn get description => text()();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get attachmentPath => text().nullable()();
  TextColumn get currencyCode => text().withDefault(const Constant('Local'))();
  TextColumn get relatedTransactionId => text().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.setNull,
  )();
  BoolColumn get isAdjustment => boolean().withDefault(const Constant(false))();
  TextColumn get customAttributes => text().nullable()();
  // Phase 2: Reversing Entries
  BoolColumn get isReversing => boolean().withDefault(const Constant(false))();
  TextColumn get reversedTransactionId => text().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get recurringSchedule =>
      text().nullable()(); // JSON for recurring entries
}

@DataClassName('TransactionEntry')
class TransactionEntries extends MizanTable {
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.restrict)();
  IntColumn get amount => integer()();
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
  TextColumn get transactionId => text().unique().references(
    Transactions,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get totalAmount => integer()();
}

@DataClassName('OrderItem')
class OrderItems extends MizanTable {
  TextColumn get orderId =>
      text().references(Orders, #id, onDelete: KeyAction.cascade)();
  TextColumn get productId =>
      text().references(Products, #id, onDelete: KeyAction.restrict)();
  TextColumn get productName => text()();
  RealColumn get quantity => real()();
  IntColumn get priceAtSale => integer()();
  RealColumn get quantityReturned => real().withDefault(const Constant(0.0))();
}

@DriftDatabase(
  tables: [
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
    LocalReportTemplates,
    GhostMoneyEntries,
    FixedAssets, // Phase 3 - Fixed Assets
    // Phase 8: Accounts Receivable
    Customers,
    Invoices,
    InvoiceItems,
    CustomerPayments,
    PaymentAllocations,
    // Phase 8C: Accounts Payable
    Vendors,
    Bills,
    BillItems,
    VendorPayments,
    BillPaymentAllocations,
    // Phase Budget: Budgeting & Variance Analysis
    Budgets,
    BudgetLines,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // ⭐️ BUMPED VERSION: 25 -> 26 (Budgeting)
  @override
  int get schemaVersion => 26;

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
      // [Previous Migrations]
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
      if (from < 18) {
        final tables = [
          categories,
          products,
          classifications,
          accounts,
          transactions,
          transactionEntries,
          currencies,
          paymentMethods,
          orders,
          orderItems,
          adjustingEntryTasks,
          bankReconciliations,
          reconciledTransactions,
          inventoryCostLayers,
        ];
        for (final table in tables) {
          await m.addColumn(
            table as TableInfo<Table, dynamic>,
            table.tenantId as GeneratedColumn<Object>,
          );
          await m.addColumn(
            table as TableInfo<Table, dynamic>,
            table.isDeleted as GeneratedColumn<Object>,
          );
        }
      }
      if (from < 19) {
        await m.addColumn(products, products.customAttributes);
        await m.addColumn(accounts, accounts.customAttributes);
        await m.addColumn(transactions, transactions.customAttributes);
      }

      // 🧩 PHASE 5.3 MIGRATION (Version 20)
      if (from < 20) {
        await m.createTable(localReportTemplates);
      }

      // 👻 PHASE 1C: Ghost Money Tracking (Version 21)
      if (from < 21) {
        await m.createTable(ghostMoneyEntries);
      }

      // 📊 PHASE 2: Account Hierarchy & Reversing Entries (Version 22)
      if (from < 22) {
        await m.addColumn(accounts, accounts.accountNumber);
        await m.addColumn(accounts, accounts.parentAccountId);
        await m.addColumn(accounts, accounts.level);
        await m.addColumn(accounts, accounts.isHeader);
        await m.addColumn(transactions, transactions.isReversing);
        await m.addColumn(transactions, transactions.reversedTransactionId);
        await m.addColumn(transactions, transactions.recurringSchedule);
      }

      // 🏭 PHASE 3: Fixed Assets (Version 23)
      if (from < 23) {
        await m.createTable(fixedAssets);
      }

      // 💰 PHASE 8: Accounts Receivable (Version 24)
      if (from < 24) {
        await m.createTable(customers);
        await m.createTable(invoices);
        await m.createTable(invoiceItems);
        await m.createTable(customerPayments);
        await m.createTable(paymentAllocations);
      }

      // 📝 PHASE 8C: Accounts Payable (Version 25)
      if (from < 25) {
        await m.createTable(vendors);
        await m.createTable(bills);
        await m.createTable(billItems);
        await m.createTable(vendorPayments);
        await m.createTable(billPaymentAllocations);
      }

      // 📊 PHASE BUDGET: Budgeting & Variance Analysis (Version 26)
      if (from < 26) {
        await m.createTable(budgets);
        await m.createTable(budgetLines);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _createInitialAccounts() async {
    final now = DateTime.now();
    final existing = await (select(
      accounts,
    )..where((t) => t.name.equals(kCashAccountName))).get();
    if (existing.isNotEmpty) return;

    await into(accounts).insert(
      AccountsCompanion.insert(
        name: kCashAccountName,
        type: 'asset',
        initialBalance: 0,
        createdAt: Value(now),
        lastUpdated: Value(now),
        phoneNumber: const Value(null),
      ),
    );
    await into(accounts).insert(
      AccountsCompanion.insert(
        name: kSalesRevenueAccountName,
        type: 'revenue',
        initialBalance: 0,
        createdAt: Value(now),
        lastUpdated: Value(now),
        phoneNumber: const Value(null),
      ),
    );
    await into(accounts).insert(
      AccountsCompanion.insert(
        name: kEquityAccountName,
        type: 'equity',
        initialBalance: 0,
        createdAt: Value(now),
        lastUpdated: Value(now),
        phoneNumber: const Value(null),
      ),
    );
    await into(accounts).insert(
      AccountsCompanion.insert(
        name: kInventoryAccountName,
        type: 'asset',
        initialBalance: 0,
        createdAt: Value(now),
        lastUpdated: Value(now),
        phoneNumber: const Value(null),
      ),
    );
    await into(accounts).insert(
      AccountsCompanion.insert(
        name: kCogsAccountName,
        type: 'expense',
        initialBalance: 0,
        createdAt: Value(now),
        lastUpdated: Value(now),
        phoneNumber: const Value(null),
      ),
    );
  }

  Future<void> _createInitialClassifications() async {
    final now = DateTime.now();
    await into(classifications).insert(
      ClassificationsCompanion.insert(
        name: kClassificationClients,
        createdAt: Value(now),
        lastUpdated: Value(now),
      ),
      mode: InsertMode.insertOrIgnore,
    );

    await into(classifications).insert(
      ClassificationsCompanion.insert(
        name: kClassificationSuppliers,
        createdAt: Value(now),
        lastUpdated: Value(now),
      ),
      mode: InsertMode.insertOrIgnore,
    );

    await into(classifications).insert(
      ClassificationsCompanion.insert(
        name: kClassificationGeneral,
        createdAt: Value(now),
        lastUpdated: Value(now),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> _createInitialCurrencies() async {
    final now = DateTime.now();
    await into(currencies).insert(
      CurrenciesCompanion.insert(
        code: 'Local',
        name: 'Local Currency',
        symbol: const Value(null),
        createdAt: Value(now),
        lastUpdated: Value(now),
      ),
      mode: InsertMode.insertOrIgnore,
    );

    await into(currencies).insert(
      CurrenciesCompanion.insert(
        code: 'USD',
        name: 'US Dollar',
        symbol: const Value('\$'),
        createdAt: Value(now),
        lastUpdated: Value(now),
      ),
      mode: InsertMode.insertOrIgnore,
    );

    await into(currencies).insert(
      CurrenciesCompanion.insert(
        code: 'SAR',
        name: 'Saudi Riyal',
        symbol: const Value('﷼'),
        createdAt: Value(now),
        lastUpdated: Value(now),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> _createInitialPaymentMethods() async {
    final cashAccount = await (select(
      accounts,
    )..where((tbl) => tbl.name.equals(kCashAccountName))).getSingleOrNull();

    if (cashAccount != null) {
      final now = DateTime.now();
      await into(paymentMethods).insert(
        PaymentMethodsCompanion.insert(
          name: 'Cash',
          accountId: cashAccount.id,
          createdAt: Value(now),
          lastUpdated: Value(now),
        ),
        mode: InsertMode.insertOrIgnore,
      );
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
