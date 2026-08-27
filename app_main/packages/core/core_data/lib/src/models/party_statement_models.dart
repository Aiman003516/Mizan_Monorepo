class PartyStatementEntry {
  const PartyStatementEntry({
    required this.entryDate,
    required this.sourceType,
    required this.sourceId,
    required this.reference,
    required this.description,
    required this.currencyCode,
    required this.debitMinor,
    required this.creditMinor,
    required this.balanceDeltaMinor,
    required this.runningBalanceMinor,
  });

  final DateTime entryDate;
  final String sourceType;
  final String sourceId;
  final String reference;
  final String description;
  final String currencyCode;
  final int debitMinor;
  final int creditMinor;
  final int balanceDeltaMinor;
  final int runningBalanceMinor;

  factory PartyStatementEntry.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['entry_date']?.toString() ?? '');
    if (date == null) {
      throw const FormatException('Statement entry date is invalid');
    }
    return PartyStatementEntry(
      entryDate: date,
      sourceType: json['source_type']?.toString() ?? '',
      sourceId: json['source_id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      currencyCode: json['currency_code']?.toString() ?? '',
      debitMinor: (json['debit_minor'] as num?)?.toInt() ?? 0,
      creditMinor: (json['credit_minor'] as num?)?.toInt() ?? 0,
      balanceDeltaMinor: (json['balance_delta_minor'] as num?)?.toInt() ?? 0,
      runningBalanceMinor:
          (json['running_balance_minor'] as num?)?.toInt() ?? 0,
    );
  }
}
