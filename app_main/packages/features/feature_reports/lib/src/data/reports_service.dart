import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feature_reports/src/data/report_models.dart';
import 'package:feature_accounts/feature_accounts.dart';
import 'package:core_database/core_database.dart';
import 'package:collection/collection.dart';
import 'package:core_database/src/initial_constants.dart' as c;
import 'dart:async';
import 'package:async/async.dart'; 
import 'package:drift/drift.dart' as d;

/// The placeholder database provider for this feature.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden in main.dart');
});

final reportsServiceProvider = Provider<ReportsService>((ref) {
  return ReportsService(ref);
});

final totalAmountsSummaryProvider =
    StreamProvider.family<List<AccountSummary>, TotalAmountsFilter>((ref, filter) {
  final service = ref.watch(reportsServiceProvider);
  return service.watchTotalAmountsSummary(filter: filter);
});

final monthlyAmountsSummaryProvider =
    StreamProvider.family<List<MonthlySummary>, TotalAmountsFilter>((ref, filter) {
  final service = ref.watch(reportsServiceProvider);
  return service.watchMonthlyAmountsSummary(filter: filter);
});

final totalClassificationsSummaryProvider =
    StreamProvider<List<ClassificationSummary>>((ref) {
  final service = ref.watch(reportsServiceProvider);
  return service.watchTotalClassificationsSummary();
});

final filteredTransactionDetailsProvider =
    StreamProvider.family<List<TransactionDetail>, TotalAmountsFilter>((ref, filter) {
  final service = ref.watch(reportsServiceProvider);
  return service.watchTransactionDetailsFiltered(filter: filter);
});

final allAccountSummariesProvider =
    StreamProvider<Map<String, AccountSummary>>((ref) {
  final service = ref.watch(reportsServiceProvider);
  return service.watchAllAccountSummaries().map((summaries) {
    final localCurrencySummaries =
        summaries.where((s) => s.currencyCode == 'Local');
    return {for (var summary in localCurrencySummaries) summary.accountId: summary};
  });
});

class PnlLine {
  final String accountType;
  final String accountName;
  final double balance;
  PnlLine(
      {required this.accountType,
      required this.accountName,
      required this.balance});
}

class PnlData {
  final List<PnlLine> revenueLines;
  final List<PnlLine> expenseLines;
  final double totalRevenue;
  final double totalExpenses;
  final double netIncome;
  PnlData({
    required this.revenueLines,
    required this.expenseLines,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netIncome,
  });
  static PnlData empty() => PnlData(
      revenueLines: [],
      expenseLines: [],
      totalRevenue: 0,
      totalExpenses: 0,
      netIncome: 0);
}

class BalanceSheetLine {
  final String accountType;
  final String accountName;
  final double balance;
  BalanceSheetLine(
      {required this.accountType,
      required this.accountName,
      required this.balance});
}

class BalanceSheetData {
  final List<BalanceSheetLine> assetLines;
  final List<BalanceSheetLine> liabilityLines;
  final List<BalanceSheetLine> equityLines;
  final double totalAssets;
  final double totalLiabilities;
  final double totalEquity;
  BalanceSheetData({
    required this.assetLines,
    required this.liabilityLines,
    required this.equityLines,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.totalEquity,
  });
  double get balanceCheck => totalAssets - (totalLiabilities + totalEquity);
  static BalanceSheetData empty() => BalanceSheetData(
      assetLines: [],
      liabilityLines: [],
      equityLines: [],
      totalAssets: 0,
      totalLiabilities: 0,
      totalEquity: 0);
}

class TrialBalanceLine {
  final String accountName;
  final double debit;
  final double credit;
  TrialBalanceLine(
      {required this.accountName, required this.debit, required this.credit});
}

final pnlDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(
    start: DateTime(now.year, 1, 1),
    end: DateTime(now.year, 12, 31),
  );
});
final balanceSheetDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});
final profitAndLossProvider = StreamProvider<PnlData>((ref) {
  final service = ref.watch(reportsServiceProvider);
  final dateRange = ref.watch(pnlDateRangeProvider);
  return service.watchProfitAndLoss(dateRange);
});
final balanceSheetProvider = StreamProvider<BalanceSheetData>((ref) {
  final service = ref.watch(reportsServiceProvider);
  final asOfDate = ref.watch(balanceSheetDateProvider);
  return service.watchBalanceSheet(asOfDate);
});
final trialBalanceProvider = StreamProvider<List<TrialBalanceLine>>((ref) {
  final service = ref.watch(reportsServiceProvider);
  return service.watchTrialBalance();
});

class ReportsService {
  ReportsService(this._ref);
  final Ref _ref;

  // Dependencies are now correct: Database and AccountsRepository
  AppDatabase get _db => _ref.read(databaseProvider);
  AccountsRepository get _accountsRepo =>
      _ref.read(accountsRepositoryProvider);

  // --- LOGIC MOVED FROM TransactionsRepository ---
  Stream<List<TransactionDetail>> watchTransactionDetails() {
    final query = _db.select(_db.transactions).join([
      d.innerJoin(
        _db.transactionEntries,
        _db.transactionEntries.transactionId.equalsExp(_db.transactions.id),
      ),
      d.innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.transactionEntries.accountId),
      ),
      d.leftOuterJoin(
        _db.classifications,
        _db.classifications.id.equalsExp(_db.accounts.classificationId),
      ),
    ]);

    query.orderBy([d.OrderingTerm.desc(_db.transactions.transactionDate)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final t = row.readTable(_db.transactions);
        final e = row.readTable(_db.transactionEntries);
        final a = row.readTable(_db.accounts);
        final cTable = row.readTableOrNull(_db.classifications);

        return TransactionDetail(
          transactionId: t.id,
          transactionDescription: t.description,
          transactionDate: t.transactionDate,
          entryAmount: e.amount,
          accountId: a.id,
          accountName: a.name,
          accountType: a.type,
          classificationName: cTable?.name ?? c.kClassificationGeneral,
          currencyCode: t.currencyCode,
          currencyRate: e.currencyRate,
        );
      }).toList();
    });
  }

  Stream<List<TransactionDetail>> watchTransactionDetailsByTransactionId(
      String transactionId) {
    return watchTransactionDetails().map((allDetails) =>
        allDetails.where((d) => d.transactionId == transactionId).toList());
  }
  // --- END OF MOVED LOGIC ---

  Future<double> getTotalRevenue() async {
    final query = _db.select(_db.transactionEntries).join([
      d.innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.transactionEntries.accountId),
      ),
    ])
      ..where(_db.accounts.type.equals('revenue'));
    final results = await query.get();
    double total = 0.0;
    for (final row in results) {
      final entry = row.readTable(_db.transactionEntries);
      total -= entry.amount;
    }
    return total;
  }

  Future<double> getTotalExpenses() async {
    final query = _db.select(_db.transactionEntries).join([
      d.innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.transactionEntries.accountId),
      ),
    ])
      ..where(_db.accounts.type.equals('expense'));
    final results = await query.get();
    double total = 0.0;
    for (final row in results) {
      final entry = row.readTable(_db.transactionEntries);
      total += entry.amount;
    }
    return total;
  }

  Future<double> getTotalReceivable() async {
    final classification = await (_db.select(_db.classifications)
          ..where((tbl) => tbl.name.equals(c.kClassificationClients)))
        .getSingleOrNull();
    if (classification == null) return 0.0;
    final clientAccounts = await (_db.select(_db.accounts)
          ..where((a) => a.classificationId.equals(classification.id)))
        .get();
    double totalReceivable = 0.0;
    for (final account in clientAccounts) {
      totalReceivable += await _accountsRepo.getAccountBalance(account.id);
    }
    return totalReceivable;
  }

  Future<double> getTotalPayable() async {
    final classification = await (_db.select(_db.classifications)
          ..where((tbl) => tbl.name.equals(c.kClassificationSuppliers)))
        .getSingleOrNull();
    if (classification == null) return 0.0;
    final supplierAccounts = await (_db.select(_db.accounts)
          ..where((a) => a.classificationId.equals(classification.id)))
        .get();
    double totalPayable = 0.0;
    for (final account in supplierAccounts) {
      totalPayable += await _accountsRepo.getAccountBalance(account.id);
    }
    return -totalPayable;
  }

  Stream<List<AccountSummary>> watchAllAccountSummaries() {
    // UPDATED: Now calls local method
    return watchTransactionDetails().map((details) {
      final groupedByAccount = groupBy(details, (detail) => detail.accountId);
      final List<AccountSummary> summaries = [];
      for (final accountEntry in groupedByAccount.entries) {
        final accountId = accountEntry.key;
        final accountDetails = accountEntry.value;
        final accountName = accountDetails.first.accountName;
        final groupedByCurrency =
            groupBy(accountDetails, (detail) => detail.currencyCode);
        for (final currencyEntry in groupedByCurrency.entries) {
          final currencyCode = currencyEntry.key;
          final currencyDetails = currencyEntry.value;
          double totalDebit = 0.0, totalCredit = 0.0;
          for (final detail in currencyDetails) {
            if (detail.entryAmount > 0) {
              totalDebit += detail.entryAmount;
            } else {
              totalCredit += detail.entryAmount.abs();
            }
          }
          final netBalance = totalDebit - totalCredit;
          summaries.add(AccountSummary(
            accountId: accountId,
            accountName: accountName,
            currencyCode: currencyCode,
            totalDebit: totalDebit,
            totalCredit: totalCredit,
            netBalance: netBalance,
          ));
        }
      }
      summaries.sort((a, b) {
        if (a.accountName != b.accountName)
          return a.accountName.compareTo(b.accountName);
        return a.currencyCode.compareTo(b.currencyCode);
      });
      return summaries;
    });
  }

  Stream<List<TransactionDetail>> _watchFilteredDetails(
      String? classificationNameFilter) {
    // UPDATED: Calls local method
    final rawStream = watchTransactionDetails();
    if (classificationNameFilter == null) return rawStream;
    return rawStream.map((details) =>
        details.where((d) => d.classificationName == classificationNameFilter).toList());
  }

  Stream<List<AccountSummary>> watchTotalAmountsSummary(
      {required TotalAmountsFilter filter}) {
    // UPDATED: Calls local method
    return watchTransactionDetails().map((details) {
      final classificationFilteredDetails = details
          .where((d) =>
              (d.classificationName ?? c.kClassificationGeneral) ==
              filter.classificationName)
          .toList();
      List<TransactionDetail> finalFilteredDetails;
      switch (filter.reportFilter) {
        case ReportFilter.POS_ONLY:
          finalFilteredDetails = classificationFilteredDetails
              .where((d) =>
                  d.accountName == c.kCashAccountName ||
                  d.accountName == c.kSalesRevenueAccountName)
              .toList();
          break;
        case ReportFilter.ACCOUNTS_ONLY:
          finalFilteredDetails = classificationFilteredDetails
              .where((d) =>
                  d.accountName != c.kCashAccountName &&
                  d.accountName != c.kSalesRevenueAccountName &&
                  d.accountName != c.kEquityAccountName)
              .toList();
          break;
        case ReportFilter.ALL:
        default:
          finalFilteredDetails = classificationFilteredDetails;
          break;
      }
      finalFilteredDetails.removeWhere((detail) =>
          detail.accountName == c.kEquityAccountName ||
          detail.accountName == c.kSalesRevenueAccountName);
      final groupedByAccount =
          groupBy(finalFilteredDetails, (detail) => detail.accountName);
      final List<AccountSummary> summaries = [];
      for (final accountEntry in groupedByAccount.entries) {
        final accountName = accountEntry.key;
        final accountDetails = accountEntry.value;
        final accountId = accountDetails.first.accountId;
        final groupedByCurrency =
            groupBy(accountDetails, (detail) => detail.currencyCode);
        for (final currencyEntry in groupedByCurrency.entries) {
          final currencyCode = currencyEntry.key;
          final currencyDetails = currencyEntry.value;
          double totalDebit = 0.0, totalCredit = 0.0;
          for (final detail in currencyDetails) {
            if (detail.entryAmount > 0) {
              totalDebit += detail.entryAmount;
            } else {
              totalCredit += detail.entryAmount.abs();
            }
          }
          final netBalance = totalDebit - totalCredit;
          summaries.add(AccountSummary(
            accountId: accountId,
            accountName: accountName,
            currencyCode: currencyCode,
            totalDebit: totalDebit,
            totalCredit: totalCredit,
            netBalance: netBalance,
          ));
        }
      }
      summaries.sort((a, b) {
        if (a.accountName != b.accountName)
          return a.accountName.compareTo(b.accountName);
        return a.currencyCode.compareTo(b.currencyCode);
      });
      return summaries;
    });
  }

  Stream<List<MonthlySummary>> watchMonthlyAmountsSummary(
      {required TotalAmountsFilter filter}) {
    // UPDATED: Calls local method
    return watchTransactionDetails().map((details) {
      final classificationFilteredDetails = details
          .where((d) =>
              (d.classificationName ?? c.kClassificationGeneral) ==
              filter.classificationName)
          .toList();
      List<TransactionDetail> finalFilteredDetails;
      switch (filter.reportFilter) {
        case ReportFilter.POS_ONLY:
          finalFilteredDetails = classificationFilteredDetails
              .where((d) =>
                  d.accountName == c.kCashAccountName ||
                  d.accountName == c.kSalesRevenueAccountName)
              .toList();
          break;
        case ReportFilter.ACCOUNTS_ONLY:
          finalFilteredDetails = classificationFilteredDetails
              .where((d) =>
                  d.accountName != c.kCashAccountName &&
                  d.accountName != c.kSalesRevenueAccountName &&
                  d.accountName != c.kEquityAccountName)
              .toList();
          break;
        case ReportFilter.ALL:
        default:
          finalFilteredDetails = classificationFilteredDetails;
          break;
      }
      finalFilteredDetails.removeWhere((detail) =>
          detail.accountName == c.kEquityAccountName ||
          detail.accountName == c.kSalesRevenueAccountName);
      final groupedByMonth = groupBy(
          finalFilteredDetails,
          (detail) =>
              '${detail.transactionDate.year}-${detail.transactionDate.month.toString().padLeft(2, '0')}');
      final List<MonthlySummary> summaries = [];
      for (final monthEntry in groupedByMonth.entries) {
        final parts = monthEntry.key.split('-');
        final year = int.parse(parts[0]), month = int.parse(parts[1]);
        final monthDetails = monthEntry.value;
        final groupedByCurrency =
            groupBy(monthDetails, (detail) => detail.currencyCode);
        for (final currencyEntry in groupedByCurrency.entries) {
          final currencyCode = currencyEntry.key;
          final currencyDetails = currencyEntry.value;
          double totalDebit = 0.0, totalCredit = 0.0;
          for (final detail in currencyDetails) {
            if (detail.entryAmount > 0) {
              totalDebit += detail.entryAmount;
            } else {
              totalCredit += detail.entryAmount.abs();
            }
          }
          final netBalance = totalDebit - totalCredit;
          summaries.add(MonthlySummary(
            year: year,
            month: month,
            currencyCode: currencyCode,
            totalDebit: totalDebit,
            totalCredit: totalCredit,
            netBalance: netBalance,
          ));
        }
      }
      summaries.sort((a, b) {
        if (a.year != b.year) return b.year.compareTo(a.year);
        if (a.month != b.month) return b.month.compareTo(a.month);
        return a.currencyCode.compareTo(b.currencyCode);
      });
      return summaries;
    });
  }

  Stream<List<TransactionDetail>> watchTransactionDetailsFiltered(
      {required TotalAmountsFilter filter}) {
    // UPDATED: Calls local method
    return watchTransactionDetails().map((details) {
      final classificationFilteredDetails = details
          .where((d) =>
              (d.classificationName ?? c.kClassificationGeneral) ==
              filter.classificationName)
          .toList();
      List<TransactionDetail> finalFilteredDetails;
      switch (filter.reportFilter) {
        case ReportFilter.POS_ONLY:
          finalFilteredDetails = classificationFilteredDetails
              .where((d) =>
                  d.accountName == c.kCashAccountName ||
                  d.accountName == c.kSalesRevenueAccountName)
              .toList();
          break;
        case ReportFilter.ACCOUNTS_ONLY:
          finalFilteredDetails = classificationFilteredDetails
              .where((d) =>
                  d.accountName != c.kCashAccountName &&
                  d.accountName != c.kSalesRevenueAccountName &&
                  d.accountName != c.kEquityAccountName)
              .toList();
          break;
        case ReportFilter.ALL:
        default:
          finalFilteredDetails = classificationFilteredDetails;
          break;
      }
      finalFilteredDetails.removeWhere((detail) =>
          detail.accountName == c.kEquityAccountName ||
          detail.accountName == c.kSalesRevenueAccountName);
      finalFilteredDetails
          .sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return finalFilteredDetails;
    });
  }

  Stream<List<ClassificationSummary>> watchTotalClassificationsSummary() {
    // UPDATED: Calls local method
    return watchTransactionDetails().map((details) {
      final groupedByClassification = groupBy(
          details, (detail) => detail.classificationName ?? c.kClassificationGeneral);
      final List<ClassificationSummary> summaries = [];
      for (final classEntry in groupedByClassification.entries) {
        final classificationName = classEntry.key;
        final classificationDetails = classEntry.value;
        final groupedByCurrency =
            groupBy(classificationDetails, (detail) => detail.currencyCode);
        for (final currencyEntry in groupedByCurrency.entries) {
          final currencyCode = currencyEntry.key;
          final currencyDetails = currencyEntry.value;
          double totalDebit = 0.0, totalCredit = 0.0;
          for (final detail in currencyDetails) {
            if (detail.accountName == c.kEquityAccountName ||
                detail.accountName == c.kSalesRevenueAccountName) continue;
            if (detail.entryAmount > 0) {
              totalDebit += detail.entryAmount;
            } else {
              totalCredit += detail.entryAmount.abs();
            }
          }
          final netBalance = totalDebit - totalCredit;
          summaries.add(ClassificationSummary(
            name: classificationName,
            currencyCode: currencyCode,
            totalDebit: totalDebit,
            totalCredit: totalCredit,
            netBalance: netBalance,
          ));
        }
      }
      summaries.sort((a, b) {
        if (a.name != b.name) return a.name.compareTo(b.name);
        return a.currencyCode.compareTo(b.currencyCode);
      });
      return summaries;
    });
  }
  
  Stream<PnlData> watchProfitAndLoss(DateTimeRange range) {
    final query = _db.select(_db.transactionEntries).join([
      d.innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.transactionEntries.accountId),
      ),
      d.innerJoin(
        _db.transactions,
        _db.transactions.id.equalsExp(_db.transactionEntries.transactionId),
      ),
    ])
      ..where(_db.accounts.type.isIn(['revenue', 'expense']))
      ..where(_db.transactions.transactionDate.isBetween(
        d.Variable(range.start),
        d.Variable(range.end),
      ));

    return query.watch().map((rows) {
      final revenueLines = <PnlLine>[];
      final expenseLines = <PnlLine>[];
      double totalRevenue = 0.0;
      double totalExpenses = 0.0;

      final groupedByAccount = groupBy(rows, (row) {
        return row.readTable(_db.accounts);
      });

      for (var account in groupedByAccount.keys.whereNotNull()) {
        final entries = groupedByAccount[account]!;
        double accountBalance = 0.0;

        for (final entryRow in entries) {
          final entry = entryRow.readTable(_db.transactionEntries);
          if (entry != null) {
            accountBalance += entry.amount;
          }
        }

        if (account.type == 'revenue') {
          final balance = -accountBalance;
          revenueLines
              .add(PnlLine(accountType: 'revenue', accountName: account.name, balance: balance));
          totalRevenue += balance;
        } else if (account.type == 'expense') {
          expenseLines
              .add(PnlLine(accountType: 'expense', accountName: account.name, balance: accountBalance));
          totalExpenses += accountBalance;
        }
      }

      final netIncome = totalRevenue - totalExpenses;

      return PnlData(
        revenueLines: revenueLines,
        expenseLines: expenseLines,
        totalRevenue: totalRevenue,
        totalExpenses: totalExpenses,
        netIncome: netIncome,
      );
    });
  }

  Stream<BalanceSheetData> watchBalanceSheet(DateTime asOfDate) {
    final pnlRange = DateTimeRange(
      start: DateTime(asOfDate.year, 1, 1),
      end: asOfDate,
    );
    final pnlStream = watchProfitAndLoss(pnlRange).map((pnl) => pnl.netIncome);

    final accountsStream = (_db.select(_db.accounts)
          ..where((a) => a.type.isIn(['asset', 'liability', 'equity'])))
        .watch();

    final entriesStream = (_db.select(_db.transactionEntries).join([
      d.innerJoin(
        _db.transactions,
        _db.transactions.id.equalsExp(_db.transactionEntries.transactionId),
      ),
    ])
          ..where(_db.transactions.transactionDate.isSmallerOrEqualValue(d.Variable(asOfDate) as DateTime)))
        .watch()
        .map((rows) => rows.map((r) => r.readTable(_db.transactionEntries)).toList());

    return StreamZip([pnlStream, accountsStream, entriesStream]).map((values) {
      final netIncome = values[0] as double;
      final accounts = values[1] as List<Account>;
      final entries = values[2] as List<TransactionEntry?>;

      final assetLines = <BalanceSheetLine>[];
      final liabilityLines = <BalanceSheetLine>[];
      final equityLines = <BalanceSheetLine>[];
      double totalAssets = 0.0;
      double totalLiabilities = 0.0;
      double totalEquity = 0.0;

      final validEntries = entries.whereNotNull().toList();
      final entriesByAccount = groupBy(validEntries, (e) => e.accountId);

      for (final account in accounts) {
        double balance = account.initialBalance;
        final accountEntries = entriesByAccount[account.id] ?? [];
        for (final entry in accountEntries) {
          balance += entry.amount;
        }
        if (account.name == c.kEquityAccountName) {
          balance += netIncome;
        }

        if (account.type == 'asset') {
          assetLines.add(BalanceSheetLine(
              accountType: 'asset', accountName: account.name, balance: balance));
          totalAssets += balance;
        } else if (account.type == 'liability') {
          final displayBalance = -balance;
          liabilityLines.add(BalanceSheetLine(
              accountType: 'liability', accountName: account.name, balance: displayBalance));
          totalLiabilities += displayBalance;
        } else if (account.type == 'equity') {
          final displayBalance = -balance;
          equityLines.add(BalanceSheetLine(
              accountType: 'equity', accountName: account.name, balance: displayBalance));
          totalEquity += displayBalance;
        }
      }

      return BalanceSheetData(
        assetLines: assetLines,
        liabilityLines: liabilityLines,
        equityLines: equityLines,
        totalAssets: totalAssets,
        totalLiabilities: totalLiabilities,
        totalEquity: totalEquity,
      );
    });
  }

  Stream<List<TrialBalanceLine>> watchTrialBalance() {
    final accountsStream = _db.select(_db.accounts).watch();
    final entriesStream = _db.select(_db.transactionEntries).watch();

    return StreamZip([accountsStream, entriesStream]).map((values) {
      final accounts = values[0] as List<Account>;
      final entries = values[1] as List<TransactionEntry>;

      final lines = <TrialBalanceLine>[];
      
      final entriesByAccount = groupBy(entries, (e) => e.accountId);

      for (final account in accounts) {
        double balance = account.initialBalance;
        final accountEntries = entriesByAccount[account.id] ?? [];
        for (final entry in accountEntries) {
          balance += entry.amount;
        }
        if (balance.abs() < 0.001) continue;

        if (balance > 0) {
          lines.add(TrialBalanceLine(
            accountName: account.name,
            debit: balance,
            credit: 0.0,
          ));
        } else {
          lines.add(TrialBalanceLine(
            accountName: account.name,
            debit: 0.0,
            credit: -balance,
          ));
        }
      }

      lines.sort((a, b) => a.accountName.compareTo(b.accountName));
      return lines;
    });
  }
}