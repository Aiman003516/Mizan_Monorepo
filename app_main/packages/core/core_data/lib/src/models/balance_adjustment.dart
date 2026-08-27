enum BalancePartyType { customer, vendor }

enum BalanceAdjustmentDirection { increase, decrease }

class BalanceAdjustmentInput {
  const BalanceAdjustmentInput({
    required this.partyType,
    required this.partyId,
    required this.amountMinor,
    required this.direction,
    required this.currencyCode,
    required this.reason,
    this.reference,
    required this.effectiveDate,
    this.debitAccountId,
    this.creditAccountId,
  });

  final BalancePartyType partyType;
  final String partyId;
  final int amountMinor;
  final BalanceAdjustmentDirection direction;
  final String currencyCode;
  final String reason;
  final String? reference;
  final DateTime effectiveDate;
  final String? debitAccountId;
  final String? creditAccountId;
}

extension BalancePartyTypeWire on BalancePartyType {
  String get wireName => switch (this) {
    BalancePartyType.customer => 'customer',
    BalancePartyType.vendor => 'vendor',
  };
}

extension BalanceAdjustmentDirectionWire on BalanceAdjustmentDirection {
  String get wireName => switch (this) {
    BalanceAdjustmentDirection.increase => 'increase',
    BalanceAdjustmentDirection.decrease => 'decrease',
  };
}
