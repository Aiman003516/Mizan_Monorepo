// FILE: packages/features/feature_reports/lib/src/data/report_models.dart

import 'package:core_database/core_database.dart' as c; // UPDATED import
import 'package:equatable/equatable.dart';

// ==========================================
// 📊 SECTION 1: EXISTING ANALYTICS MODELS
// (Preserved exactly as requested)
// ==========================================

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

// ==========================================
// 🚀 SECTION 2: NEW DYNAMIC REPORT MODELS (PHASE 5)
// (Added for the SQL-to-Widget Engine)
// ==========================================

/// 📊 COLUMN DEFINITION
/// Tells the UI how to format a specific SQL column.
class ReportColumn {
  final String key; // Matches SQL column name (e.g. 'total_sales')
  final String label; // Header text (e.g. 'Total Sales')
  final String type; // 'text', 'currency', 'date', 'number'

  const ReportColumn({
    required this.key,
    required this.label,
    this.type = 'text',
  });

  factory ReportColumn.fromJson(Map<String, dynamic> json) {
    return ReportColumn(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'type': type,
  };
}

/// 🎛️ PARAMETER DEFINITION
/// Tells the UI what inputs to ask the user for (e.g., Date Range).
class ReportParameter {
  final String key; // The placeholder in SQL (e.g., '@startDate')
  final String label; // UI Label
  final String type; // 'date', 'text'

  const ReportParameter({
    required this.key,
    required this.label,
    this.type = 'date',
  });

  factory ReportParameter.fromJson(Map<String, dynamic> json) {
    return ReportParameter(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      type: json['type'] as String? ?? 'date',
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'type': type,
  };
}

/// 📜 THE REPORT TEMPLATE
/// This is what we download from Firestore.
class ReportTemplate {
  final String id;
  final String title;
  final String description;
  final String sqlQuery; // The RAW SQL (Drift compatible)
  final List<ReportColumn> columns;
  final List<ReportParameter> parameters;
  final bool isPremium; // Locked for Pro/Enterprise?

  const ReportTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.sqlQuery,
    required this.columns,
    this.parameters = const [],
    this.isPremium = false,
  });

  factory ReportTemplate.fromJson(Map<String, dynamic> json, String id) {
    return ReportTemplate(
      id: id,
      title: json['title'] as String? ?? 'Untitled Report',
      description: json['description'] as String? ?? '',
      sqlQuery: json['sqlQuery'] as String? ?? '',
      isPremium: json['isPremium'] as bool? ?? false,
      columns: (json['columns'] as List<dynamic>? ?? [])
          .map((e) => ReportColumn.fromJson(e as Map<String, dynamic>))
          .toList(),
      parameters: (json['parameters'] as List<dynamic>? ?? [])
          .map((e) => ReportParameter.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'sqlQuery': sqlQuery,
    'isPremium': isPremium,
    'columns': columns.map((e) => e.toJson()).toList(),
    'parameters': parameters.map((e) => e.toJson()).toList(),
  };
}