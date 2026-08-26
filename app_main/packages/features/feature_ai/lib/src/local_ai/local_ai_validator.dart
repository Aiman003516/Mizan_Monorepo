import 'local_ai_proposal.dart';

class LocalAiValidationResult {
  const LocalAiValidationResult(this.errors);

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

abstract final class LocalAiTextNormalizer {
  static String normalize(String value) {
    return normalizeArabicDigits(
      value,
    ).replaceAll('\u0640', '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String normalizeArabicDigits(String value) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const easternArabic = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final character in value.runes) {
      final text = String.fromCharCode(character);
      final arabicIndex = arabic.indexOf(text);
      if (arabicIndex >= 0) {
        buffer.write(arabicIndex);
        continue;
      }
      final easternIndex = easternArabic.indexOf(text);
      if (easternIndex >= 0) {
        buffer.write(easternIndex);
        continue;
      }
      buffer.write(text);
    }
    return buffer.toString();
  }
}

abstract final class LocalAiProposalValidator {
  static const _minimumMutationConfidence = 0.70;
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _currencyPattern = RegExp(r'^[A-Z]{3,5}$');
  static final _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static LocalAiValidationResult validate(LocalAiProposal proposal) {
    final errors = <String>[];
    if (proposal.schemaVersion != localAiProposalSchemaVersion) {
      errors.add('schema_version is unsupported');
    }
    if (proposal.locale != 'ar' && proposal.locale != 'en') {
      errors.add('locale must be ar or en');
    }
    if (proposal.source != 'local') {
      errors.add('source must be local');
    }
    if (proposal.confidence < 0 || proposal.confidence > 1) {
      errors.add('confidence must be between 0 and 1');
    }

    final isMutation = proposal.isMutation;
    if (isMutation && proposal.confidence < _minimumMutationConfidence) {
      errors.add('mutation confidence is below the local safety threshold');
    }
    if (isMutation && !proposal.requiresConfirmation) {
      errors.add('mutations always require confirmation');
    }
    if (proposal.actionType == LocalAiActionTypes.unsupported &&
        proposal.intent != LocalAiIntent.unsupported) {
      errors.add('unsupported action must use unsupported intent');
    }
    if (proposal.intent == LocalAiIntent.proposeMutation && !isMutation) {
      errors.add('propose_mutation requires a supported mutation action');
    }
    if (proposal.intent != LocalAiIntent.proposeMutation && isMutation) {
      errors.add('supported mutations require propose_mutation intent');
    }

    switch (proposal.actionType) {
      case LocalAiActionTypes.customerUpdate:
        _validatePartyUpdate(proposal.fields, errors, isCustomer: true);
      case LocalAiActionTypes.vendorUpdate:
        _validatePartyUpdate(proposal.fields, errors, isCustomer: false);
      case LocalAiActionTypes.invoiceUpdate:
        _validateDocumentUpdate(proposal.fields, errors, isInvoice: true);
      case LocalAiActionTypes.billUpdate:
        _validateDocumentUpdate(proposal.fields, errors, isInvoice: false);
      case LocalAiActionTypes.balanceAdjustment:
        _validateBalanceAdjustment(proposal.fields, errors);
      case LocalAiActionTypes.journalEntryPost:
        _validateJournal(proposal.fields, errors);
      case LocalAiActionTypes.customerArchive:
      case LocalAiActionTypes.vendorArchive:
      case LocalAiActionTypes.invoiceVoid:
      case LocalAiActionTypes.billVoid:
        _validateArchiveOrVoid(proposal.fields, errors);
    }
    return LocalAiValidationResult(List.unmodifiable(errors));
  }

  static void _validatePartyUpdate(
    Map<String, Object?> fields,
    List<String> errors, {
    required bool isCustomer,
  }) {
    _requireRecordIdentity(fields, errors);
    final patch = _map(fields['patch']);
    if (patch == null || patch.isEmpty) {
      errors.add('patch must contain at least one field');
      return;
    }
    final allowed = isCustomer
        ? {
            'name',
            'email',
            'phone',
            'address',
            'tax_id',
            'credit_limit',
            'notes',
            'is_on_hold',
          }
        : {
            'name',
            'email',
            'phone',
            'address',
            'tax_id',
            'payment_terms',
            'notes',
          };
    if (patch.keys.any((key) => !allowed.contains(key))) {
      errors.add('patch contains an unsupported field');
    }
    if (patch['name'] != null && _text(patch['name'], 200) == null) {
      errors.add('name is invalid');
    }
    if (patch.containsKey('email') && !_validOptionalEmail(patch['email'])) {
      errors.add('email is invalid');
    }
    if (isCustomer &&
        patch.containsKey('credit_limit') &&
        _minorAmount(patch['credit_limit'], allowZero: true) == null) {
      errors.add('credit_limit is invalid');
    }
    if (isCustomer &&
        patch.containsKey('is_on_hold') &&
        patch['is_on_hold'] is! bool) {
      errors.add('is_on_hold must be boolean');
    }
    for (final key in allowed.difference({
      'name',
      'email',
      'credit_limit',
      'is_on_hold',
    })) {
      if (patch.containsKey(key) &&
          patch[key] != null &&
          _text(patch[key], key == 'address' ? 500 : 2000) == null) {
        errors.add('$key is invalid');
      }
    }
  }

  static void _validateDocumentUpdate(
    Map<String, Object?> fields,
    List<String> errors, {
    required bool isInvoice,
  }) {
    _requireRecordIdentity(fields, errors);
    final patch = _map(fields['patch']);
    if (patch == null || patch.isEmpty) {
      errors.add('patch must contain at least one field');
      return;
    }
    final allowed = isInvoice
        ? {'invoice_date', 'due_date', 'currency_code', 'notes', 'items'}
        : {
            'bill_date',
            'due_date',
            'currency_code',
            'vendor_bill_number',
            'notes',
            'items',
          };
    if (patch.keys.any((key) => !allowed.contains(key))) {
      errors.add('patch contains an unsupported field');
    }
    final dateKey = isInvoice ? 'invoice_date' : 'bill_date';
    final start = patch[dateKey] == null ? null : _date(patch[dateKey]);
    final due = patch['due_date'] == null ? null : _date(patch['due_date']);
    if (patch.containsKey(dateKey) && start == null)
      errors.add('$dateKey is invalid');
    if (patch.containsKey('due_date') && due == null)
      errors.add('due_date is invalid');
    if (start != null && due != null && due.compareTo(start) < 0) {
      errors.add('due_date cannot be before the document date');
    }
    if (patch.containsKey('currency_code') &&
        !_currency(patch['currency_code'])) {
      errors.add('currency_code is invalid');
    }
    if (patch.containsKey('notes') &&
        patch['notes'] != null &&
        _text(patch['notes'], 2000) == null) {
      errors.add('notes is invalid');
    }
    if (!isInvoice &&
        patch.containsKey('vendor_bill_number') &&
        patch['vendor_bill_number'] != null &&
        _text(patch['vendor_bill_number'], 120) == null) {
      errors.add('vendor_bill_number is invalid');
    }
    if (patch.containsKey('items')) _validateItems(patch['items'], errors);
  }

  static void _validateBalanceAdjustment(
    Map<String, Object?> fields,
    List<String> errors,
  ) {
    final partyType = _text(fields['party_type'], 20);
    if (partyType != 'customer' && partyType != 'vendor') {
      errors.add('party_type must be customer or vendor');
    }
    if (_recordIdOrName(fields['party_id'], fields['record_name']) == null) {
      errors.add('party identity is required');
    }
    if (_minorAmount(fields['amount_minor']) == null)
      errors.add('amount_minor is invalid');
    if (_text(fields['direction'], 20) != 'increase' &&
        _text(fields['direction'], 20) != 'decrease') {
      errors.add('direction is invalid');
    }
    if (!_currency(fields['currency_code']))
      errors.add('currency_code is invalid');
    if (_accountIdOrName(
              fields['debit_account_id'],
              fields['debit_account_name'],
            ) ==
            null ||
        _accountIdOrName(
              fields['credit_account_id'],
              fields['credit_account_name'],
            ) ==
            null) {
      errors.add('debit and credit accounts are required');
    }
    if (fields['debit_account_id'] != null &&
        fields['debit_account_id'] == fields['credit_account_id']) {
      errors.add('debit and credit accounts must differ');
    }
    if (_text(fields['description'] ?? fields['reason'], 500) == null) {
      errors.add('a reason is required');
    }
  }

  static void _validateJournal(
    Map<String, Object?> fields,
    List<String> errors,
  ) {
    if (_text(fields['description'], 500) == null)
      errors.add('description is required');
    if (_date(fields['transaction_date']) == null)
      errors.add('transaction_date is invalid');
    if (!_currency(fields['currency_code']))
      errors.add('currency_code is invalid');
    final lines = fields['lines'];
    if (lines is! List || lines.length < 2 || lines.length > 100) {
      errors.add('journal must have between 2 and 100 lines');
      return;
    }
    var total = 0;
    for (final line in lines) {
      final map = _map(line);
      final accountId = _text(map?['account_id'], 128);
      final amount = _signedMinorAmount(map?['amount']);
      if (map == null || accountId == null || amount == null || amount == 0) {
        errors.add('journal line is invalid');
        continue;
      }
      total += amount;
    }
    if (total != 0) errors.add('journal is unbalanced');
  }

  static void _validateArchiveOrVoid(
    Map<String, Object?> fields,
    List<String> errors,
  ) {
    if (_recordIdOrName(
          fields['customer_id'] ??
              fields['vendor_id'] ??
              fields['invoice_id'] ??
              fields['bill_id'],
          fields['record_name'] ?? fields['record_number'],
        ) ==
        null) {
      errors.add('target record is required');
    }
    if (_text(fields['reason'], 500) == null) errors.add('reason is required');
  }

  static void _validateItems(Object? value, List<String> errors) {
    if (value is! List || value.isEmpty || value.length > 100) {
      errors.add('items must contain between 1 and 100 rows');
      return;
    }
    for (final item in value) {
      final map = _map(item);
      if (map == null ||
          _text(map['description'], 500) == null ||
          _positiveNumber(map['quantity']) == null ||
          _minorAmount(map['unit_price'], allowZero: true) == null) {
        errors.add('document item is invalid');
      }
    }
  }

  static void _requireRecordIdentity(
    Map<String, Object?> fields,
    List<String> errors,
  ) {
    final id =
        fields['customer_id'] ??
        fields['vendor_id'] ??
        fields['invoice_id'] ??
        fields['bill_id'];
    if (_recordIdOrName(id, fields['record_name'] ?? fields['record_number']) ==
        null) {
      errors.add('target record identity is required');
    }
    if (fields['expected_updated_at'] != null &&
        _dateTime(fields['expected_updated_at']) == null) {
      errors.add('expected_updated_at is invalid');
    }
  }

  static String? _recordIdOrName(Object? id, Object? name) {
    if (id is String &&
        (_uuidPattern.hasMatch(id.trim()) || id.trim().isNotEmpty)) {
      return id.trim();
    }
    return _text(name, 200);
  }

  static String? _accountIdOrName(Object? id, Object? name) =>
      _text(id, 128) ?? _text(name, 200);

  static Map<String, Object?>? _map(Object? value) {
    if (value is! Map) return null;
    return Map<String, Object?>.from(value);
  }

  static String? _text(Object? value, int maxLength) {
    if (value is! String) return null;
    final normalized = LocalAiTextNormalizer.normalize(value);
    return normalized.isNotEmpty && normalized.length <= maxLength
        ? normalized
        : null;
  }

  static bool _validOptionalEmail(Object? value) {
    if (value == null || value == '') return true;
    final normalized = _text(value, 320)?.toLowerCase();
    return normalized != null && _emailPattern.hasMatch(normalized);
  }

  static bool _currency(Object? value) {
    final normalized = _text(value, 5)?.toUpperCase();
    return normalized != null && _currencyPattern.hasMatch(normalized);
  }

  static int? _minorAmount(Object? value, {bool allowZero = false}) {
    final parsed = _exactInteger(value);
    if (parsed == null ||
        parsed < (allowZero ? 0 : 1) ||
        parsed > 9000000000000000) {
      return null;
    }
    return parsed;
  }

  static int? _signedMinorAmount(Object? value) {
    final parsed = _exactInteger(value);
    if (parsed == null ||
        parsed < -9000000000000000 ||
        parsed > 9000000000000000)
      return null;
    return parsed;
  }

  static int? _exactInteger(Object? value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.truncate())
      return value.toInt();
    if (value is String) {
      final normalized = LocalAiTextNormalizer.normalize(
        value,
      ).replaceAll(',', '');
      return int.tryParse(normalized);
    }
    return null;
  }

  static double? _positiveNumber(Object? value) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    return number != null &&
            number.isFinite &&
            number > 0 &&
            number <= 1000000000
        ? number
        : null;
  }

  static DateTime? _date(Object? value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }
    final parts = value.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.any((part) => part == null)) return null;
    final result = DateTime.utc(parts[0]!, parts[1]!, parts[2]!);
    return result.year == parts[0] &&
            result.month == parts[1] &&
            result.day == parts[2]
        ? result
        : null;
  }

  static DateTime? _dateTime(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
