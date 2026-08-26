import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tenant_context.dart';
import '../models/erp_domain_contracts.dart';

final accountingLedgerRepositoryProvider = Provider<AccountingLedgerRepository>(
  (ref) => AccountingLedgerRepository(
    Supabase.instance.client,
    ref.watch(tenantContextProvider),
  ),
);

class AccountingBook {
  const AccountingBook({
    required this.id,
    required this.code,
    required this.name,
    required this.bookType,
    required this.baseBookId,
    required this.status,
  });

  final String id;
  final String code;
  final String name;
  final LedgerBookType bookType;
  final String? baseBookId;
  final String status;

  bool get isActive => status == 'active';

  factory AccountingBook.fromJson(Map<String, dynamic> json) {
    return AccountingBook(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bookType: LedgerBookTypeCodec.fromWire(json['book_type']?.toString()),
      baseBookId: json['base_book_id']?.toString(),
      status: json['status']?.toString() ?? 'active',
    );
  }
}

class AccountingDimension {
  const AccountingDimension({
    required this.id,
    required this.dimensionType,
    required this.code,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String dimensionType;
  final String code;
  final String name;
  final bool isActive;

  factory AccountingDimension.fromJson(Map<String, dynamic> json) {
    return AccountingDimension(
      id: json['id']?.toString() ?? '',
      dimensionType: json['dimension_type']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isActive: json['is_active'] != false,
    );
  }
}

class AccountingPeriod {
  const AccountingPeriod({
    required this.id,
    required this.name,
    required this.startsOn,
    required this.endsOn,
    required this.status,
  });

  final String id;
  final String name;
  final DateTime startsOn;
  final DateTime endsOn;
  final String status;

  bool get isLocked => status == 'locked' || status == 'closed';

  factory AccountingPeriod.fromJson(Map<String, dynamic> json) {
    return AccountingPeriod(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      startsOn:
          DateTime.tryParse(json['starts_on']?.toString() ?? '') ??
          DateTime(1970),
      endsOn:
          DateTime.tryParse(json['ends_on']?.toString() ?? '') ??
          DateTime(1970),
      status: json['status']?.toString() ?? 'open',
    );
  }
}

class TaxCode {
  const TaxCode({
    required this.id,
    required this.code,
    required this.name,
    required this.ratePercent,
    required this.isInclusive,
    required this.isActive,
  });

  final String id;
  final String code;
  final String name;
  final double ratePercent;
  final bool isInclusive;
  final bool isActive;

  factory TaxCode.fromJson(Map<String, dynamic> json) {
    return TaxCode(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      ratePercent: (json['rate_percent'] as num?)?.toDouble() ?? 0,
      isInclusive: json['is_inclusive'] == true,
      isActive: json['is_active'] != false,
    );
  }
}

class ChartAccount {
  const ChartAccount({
    required this.id,
    required this.code,
    required this.name,
    required this.accountType,
    required this.normalBalance,
    required this.currencyCode,
    required this.parentId,
    required this.isActive,
  });

  final String id;
  final String code;
  final String name;
  final String accountType;
  final String normalBalance;
  final String currencyCode;
  final String? parentId;
  final bool isActive;

  factory ChartAccount.fromJson(Map<String, dynamic> json) {
    return ChartAccount(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      accountType: json['account_type']?.toString() ?? 'asset',
      normalBalance: json['normal_balance']?.toString() ?? 'debit',
      currencyCode: json['currency_code']?.toString() ?? 'USD',
      parentId: json['parent_id']?.toString(),
      isActive: json['is_active'] != false,
    );
  }
}

class JournalLineInput {
  const JournalLineInput({
    required this.accountId,
    required this.debitMinor,
    required this.creditMinor,
    this.description,
    this.currencyCode,
    this.foreignDebitMinor = 0,
    this.foreignCreditMinor = 0,
    this.taxCodeId,
    this.lineNumber,
  });

  final String accountId;
  final int debitMinor;
  final int creditMinor;
  final String? description;
  final String? currencyCode;
  final int foreignDebitMinor;
  final int foreignCreditMinor;
  final String? taxCodeId;
  final int? lineNumber;

  Map<String, dynamic> toJson() => {
    'account_id': accountId,
    'debit_minor': debitMinor,
    'credit_minor': creditMinor,
    if (description?.trim().isNotEmpty == true)
      'description': description!.trim(),
    if (currencyCode?.trim().isNotEmpty == true)
      'currency_code': currencyCode!.trim().toUpperCase(),
    'foreign_debit_minor': foreignDebitMinor,
    'foreign_credit_minor': foreignCreditMinor,
    if (taxCodeId?.trim().isNotEmpty == true) 'tax_code_id': taxCodeId,
    if (lineNumber != null) 'line_number': lineNumber,
  };
}

class JournalDraftResult {
  const JournalDraftResult({
    required this.id,
    required this.entryNumber,
    required this.status,
    required this.lineCount,
  });

  final String id;
  final String entryNumber;
  final String status;
  final int lineCount;

  factory JournalDraftResult.fromJson(Map<String, dynamic> json) {
    return JournalDraftResult(
      id: json['id']?.toString() ?? '',
      entryNumber: json['entry_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      lineCount: (json['line_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AccountingReportLine {
  const AccountingReportLine({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    required this.balanceMinor,
  });

  final String accountId;
  final String accountCode;
  final String accountName;
  final String accountType;
  final int balanceMinor;

  factory AccountingReportLine.fromJson(Map<String, dynamic> json) {
    return AccountingReportLine(
      accountId: json['account_id']?.toString() ?? '',
      accountCode: json['account_code']?.toString() ?? '',
      accountName: json['account_name']?.toString() ?? '',
      accountType: json['account_type']?.toString() ?? '',
      balanceMinor: (json['balance_minor'] as num?)?.toInt() ?? 0,
    );
  }
}

class TrialBalanceLine {
  const TrialBalanceLine({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    required this.debitMinor,
    required this.creditMinor,
    required this.balanceMinor,
  });

  final String accountId;
  final String accountCode;
  final String accountName;
  final String accountType;
  final int debitMinor;
  final int creditMinor;
  final int balanceMinor;

  factory TrialBalanceLine.fromJson(Map<String, dynamic> json) {
    return TrialBalanceLine(
      accountId: json['account_id']?.toString() ?? '',
      accountCode: json['account_code']?.toString() ?? '',
      accountName: json['account_name']?.toString() ?? '',
      accountType: json['account_type']?.toString() ?? '',
      debitMinor: (json['debit_minor'] as num?)?.toInt() ?? 0,
      creditMinor: (json['credit_minor'] as num?)?.toInt() ?? 0,
      balanceMinor: (json['balance_minor'] as num?)?.toInt() ?? 0,
    );
  }
}

class AccountingLedgerRepository {
  AccountingLedgerRepository(this._supabase, this._tenantContext);

  final SupabaseClient _supabase;
  final TenantContext _tenantContext;

  Future<String> _tenantId() => _tenantContext.currentTenantId();

  Future<List<AccountingBook>> listBooks() async {
    final result = await _supabase.rpc('list_accounting_books');
    if (result is! List) {
      throw const PostgrestException(
        message: 'Accounting books returned no result.',
        code: 'MIZAN_BOOKS_INVALID_RESPONSE',
      );
    }
    return result
        .whereType<Map>()
        .map((row) => AccountingBook.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<AccountingDimension>> listDimensions({
    String? dimensionType,
  }) async {
    final result = await _supabase.rpc(
      'list_accounting_dimensions',
      params: {'p_dimension_type': dimensionType},
    );
    if (result is! List) {
      throw const PostgrestException(
        message: 'Accounting dimensions returned no result.',
        code: 'MIZAN_DIMENSIONS_INVALID_RESPONSE',
      );
    }
    return result
        .whereType<Map>()
        .map(
          (row) => AccountingDimension.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  Future<List<AccountingPeriod>> listPeriods() async {
    final tenantId = await _tenantId();
    final rows = await _supabase
        .from('accounting_periods')
        .select()
        .eq('tenant_id', tenantId)
        .order('starts_on', ascending: false);
    return rows
        .whereType<Map>()
        .map((row) => AccountingPeriod.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<TaxCode>> listTaxCodes({bool activeOnly = true}) async {
    final tenantId = await _tenantId();
    var query = _supabase.from('tax_codes').select().eq('tenant_id', tenantId);
    if (activeOnly) query = query.eq('is_active', true);
    final rows = await query.order('code');
    return rows
        .whereType<Map>()
        .map((row) => TaxCode.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<ChartAccount>> listAccounts({bool activeOnly = true}) async {
    final tenantId = await _tenantId();
    var query = _supabase
        .from('chart_of_accounts')
        .select()
        .eq('tenant_id', tenantId);
    if (activeOnly) query = query.eq('is_active', true);
    final rows = await query.order('code');
    return rows
        .whereType<Map>()
        .map((row) => ChartAccount.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<JournalDraftResult> createJournalDraft({
    required String entryNumber,
    required DateTime entryDate,
    required String description,
    required String currencyCode,
    required double exchangeRate,
    required List<JournalLineInput> lines,
  }) async {
    if (lines.length < 2) {
      throw const PostgrestException(
        message: 'A journal entry requires at least two lines.',
        code: 'MIZAN_JOURNAL_MIN_LINES',
      );
    }
    final debitTotal = lines.fold<int>(0, (sum, line) => sum + line.debitMinor);
    final creditTotal = lines.fold<int>(
      0,
      (sum, line) => sum + line.creditMinor,
    );
    if (debitTotal <= 0 || debitTotal != creditTotal) {
      throw const PostgrestException(
        message: 'Journal debits and credits must balance.',
        code: 'MIZAN_JOURNAL_UNBALANCED',
      );
    }
    final result = await _supabase.rpc(
      'create_journal_draft',
      params: {
        'p_entry_number': entryNumber.trim(),
        'p_entry_date': entryDate.toIso8601String().substring(0, 10),
        'p_description': description.trim(),
        'p_currency_code': currencyCode.trim().toUpperCase(),
        'p_exchange_rate': exchangeRate,
        'p_lines': lines.map((line) => line.toJson()).toList(),
      },
    );
    if (result is! Map) {
      throw const PostgrestException(
        message: 'Journal draft creation returned no result.',
        code: 'MIZAN_JOURNAL_INVALID_RESPONSE',
      );
    }
    return JournalDraftResult.fromJson(Map<String, dynamic>.from(result));
  }

  Future<Map<String, dynamic>> postJournalEntry(String journalEntryId) async {
    final result = await _supabase.rpc(
      'post_journal_entry',
      params: {'p_journal_entry_id': journalEntryId},
    );
    if (result is! Map) {
      throw const PostgrestException(
        message: 'Journal posting returned no result.',
        code: 'MIZAN_JOURNAL_INVALID_RESPONSE',
      );
    }
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> closePeriod(String periodId) async {
    final result = await _supabase.rpc(
      'close_accounting_period',
      params: {'p_period_id': periodId},
    );
    if (result is! Map) {
      throw const PostgrestException(
        message: 'Period closing returned no result.',
        code: 'MIZAN_PERIOD_INVALID_RESPONSE',
      );
    }
    return Map<String, dynamic>.from(result);
  }

  Future<List<AccountingReportLine>> profitAndLoss({
    required DateTime startsOn,
    required DateTime endsOn,
  }) async {
    final result = await _supabase.rpc(
      'profit_and_loss',
      params: {
        'p_starts_on': startsOn.toIso8601String().substring(0, 10),
        'p_ends_on': endsOn.toIso8601String().substring(0, 10),
      },
    );
    return _parseReportLines(result, 'MIZAN_PNL_INVALID_RESPONSE');
  }

  Future<List<AccountingReportLine>> balanceSheet({
    required DateTime asOfDate,
  }) async {
    final result = await _supabase.rpc(
      'balance_sheet',
      params: {'p_as_of': asOfDate.toIso8601String().substring(0, 10)},
    );
    return _parseReportLines(result, 'MIZAN_BALANCE_SHEET_INVALID_RESPONSE');
  }

  List<AccountingReportLine> _parseReportLines(
    dynamic result,
    String errorCode,
  ) {
    if (result is! List) {
      throw PostgrestException(
        message: 'Accounting report returned no result.',
        code: errorCode,
      );
    }
    return result
        .whereType<Map>()
        .map(
          (row) =>
              AccountingReportLine.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  Future<List<TrialBalanceLine>> trialBalance({
    required DateTime startsOn,
    required DateTime endsOn,
  }) async {
    final result = await _supabase.rpc(
      'trial_balance',
      params: {
        'p_starts_on': startsOn.toIso8601String().substring(0, 10),
        'p_ends_on': endsOn.toIso8601String().substring(0, 10),
      },
    );
    if (result is! List) {
      throw const PostgrestException(
        message: 'Trial balance returned no result.',
        code: 'MIZAN_TRIAL_BALANCE_INVALID_RESPONSE',
      );
    }
    return result
        .whereType<Map>()
        .map((row) => TrialBalanceLine.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }
}
