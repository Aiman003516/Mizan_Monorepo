import 'package:core_database/core_database.dart' as c; // UPDATED import
import 'package:equatable/equatable.dart';

enum ReportFilter { ALL, POS_ONLY, ACCOUNTS_ONLY }

class TotalAmountsFilter extends Equatable {
  final ReportFilter reportFilter;
  final String? classificationName;

  const TotalAmountsFilter({
    required this.reportFilter,
    required this.classificationName,
  });

  static const String generalClassification = c.kClassificationGeneral;

  TotalAmountsFilter copyWith({
    ReportFilter? reportFilter,
    String? classificationName,
  }) {
    return TotalAmountsFilter(
      reportFilter: reportFilter ?? this.reportFilter,
      classificationName: classificationName ?? this.classificationName,
    );
  }

  @override
  List<Object?> get props => [reportFilter, classificationName];
}

class TransactionDetail {
  TransactionDetail({
    required this.transactionId,
    required this.transactionDescription,
    required this.transactionDate,
    required this.entryAmount,
    required this.accountId,
    required this.accountName,
    required this.accountType,
    this.classificationName,
    required this.currencyCode,
    required this.currencyRate,
  });

  final String transactionId;
  final String transactionDescription;
  final DateTime transactionDate;
  final double entryAmount;
  final String accountId;
  final String accountName;
  final String accountType;
  final String? classificationName;
  final String currencyCode;
  final double currencyRate;
}

class AccountSummary {
  AccountSummary({
    required this.accountId,
    required this.accountName,
    required this.currencyCode,
    required this.totalDebit,
    required this.totalCredit,
    required this.netBalance,
  });

  final String accountId;
  final String accountName;
  final String currencyCode;
  final double totalDebit;
  final double totalCredit;
  final double netBalance;
}

class MonthlySummary {
  MonthlySummary({
    required this.year,
    required this.month,
    required this.currencyCode,
    required this.totalDebit,
    required this.totalCredit,
    required this.netBalance,
  });

  final int year;
  final int month;
  final String currencyCode;
  final double totalDebit;
  final double totalCredit;
  final double netBalance;
}

class ClassificationSummary {
  ClassificationSummary({
    required this.name,
    required this.currencyCode,
    required this.totalDebit,
    required this.totalCredit,
    required this.netBalance,
  });

  final String name;
  final String currencyCode;
  final double totalDebit;
  final double totalCredit;
  final double netBalance;
}