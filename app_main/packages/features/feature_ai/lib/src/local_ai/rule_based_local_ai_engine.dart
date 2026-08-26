import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_ai_engine.dart';
import 'local_ai_proposal.dart';
import 'local_ai_validator.dart';

/// A deterministic, model-free local assistant implementation.
///
/// This engine intentionally supports a narrow language surface. It extracts
/// only explicit values from the current request and never resolves records,
/// calculates accounting values, reads Drift/Supabase, or executes actions.
class RuleBasedLocalAiEngine implements LocalAiEngine {
  const RuleBasedLocalAiEngine({this.engineVersion = 'rules-v1'});

  final String engineVersion;

  @override
  String get engineId => 'rule-based-$engineVersion';

  @override
  LocalAiEngineStatus get status => LocalAiEngineStatus.ready;

  @override
  Future<LocalAiEngineResult> propose(LocalAiRequest request) async {
    final locale = _locale(request.locale);
    if (locale == null) {
      return const LocalAiEngineResult.failed(
        'Local AI supports Arabic (ar) and English (en) only.',
      );
    }

    final text = LocalAiTextNormalizer.normalize(request.text);
    final proposal = _buildProposal(text, locale);
    final validation = LocalAiProposalValidator.validate(proposal);
    if (!validation.isValid) {
      return LocalAiEngineResult.failed(validation.errors.join('; '));
    }
    return LocalAiEngineResult.ready(proposal);
  }

  LocalAiProposal _buildProposal(String text, String locale) {
    if (text.isEmpty) return _missing(locale, const ['request']);
    if (_containsUnsafeRequest(text)) return _unsupported(locale);
    if (_isExplanation(text)) return _explanation(text, locale);
    if (_isMissingInformationRequest(text)) {
      return _missing(locale, _missingFieldsFor(text));
    }

    final actionType = _detectAction(text);
    if (actionType == null)
      return _missing(locale, const ['supported_request']);

    return switch (actionType) {
      LocalAiActionTypes.customerUpdate => _partyUpdate(
        text,
        locale,
        isCustomer: true,
      ),
      LocalAiActionTypes.vendorUpdate => _partyUpdate(
        text,
        locale,
        isCustomer: false,
      ),
      LocalAiActionTypes.invoiceUpdate => _documentUpdate(
        text,
        locale,
        isInvoice: true,
      ),
      LocalAiActionTypes.billUpdate => _documentUpdate(
        text,
        locale,
        isInvoice: false,
      ),
      LocalAiActionTypes.customerArchive => _archiveOrVoid(
        text,
        locale,
        LocalAiActionTypes.customerArchive,
      ),
      LocalAiActionTypes.vendorArchive => _archiveOrVoid(
        text,
        locale,
        LocalAiActionTypes.vendorArchive,
      ),
      LocalAiActionTypes.invoiceVoid => _archiveOrVoid(
        text,
        locale,
        LocalAiActionTypes.invoiceVoid,
      ),
      LocalAiActionTypes.billVoid => _archiveOrVoid(
        text,
        locale,
        LocalAiActionTypes.billVoid,
      ),
      LocalAiActionTypes.balanceAdjustment => _missing(locale, const [
        'party_id_or_record_name',
        'amount_minor',
        'currency_code',
        'direction',
        'debit_account_id',
        'credit_account_id',
        'reason',
      ]),
      LocalAiActionTypes.journalEntryPost => _missing(locale, const [
        'description',
        'transaction_date',
        'currency_code',
        'lines',
      ]),
      _ => _unsupported(locale),
    };
  }

  LocalAiProposal _partyUpdate(
    String text,
    String locale, {
    required bool isCustomer,
  }) {
    final recordName = _extractRecordName(text);
    final email = _extractEmail(text);
    final phone = _extractPhone(text);
    final patch = <String, Object?>{};
    final entities = <LocalAiEntity>[];

    if (email != null) {
      patch['email'] = email;
      entities.add(_entity(LocalAiEntityType.email, email));
    }
    if (phone != null) {
      patch['phone'] = phone;
      entities.add(_entity(LocalAiEntityType.phone, phone));
    }

    if (recordName == null || patch.isEmpty) {
      final missing = <String>[];
      if (recordName == null) missing.add('record_name');
      if (patch.isEmpty) missing.add('patch');
      return _missing(locale, missing, entities: entities);
    }

    entities.insert(0, _entity(LocalAiEntityType.recordName, recordName));
    return _mutation(
      locale: locale,
      actionType: isCustomer
          ? LocalAiActionTypes.customerUpdate
          : LocalAiActionTypes.vendorUpdate,
      fields: {'record_name': recordName, 'patch': patch},
      entities: entities,
    );
  }

  LocalAiProposal _documentUpdate(
    String text,
    String locale, {
    required bool isInvoice,
  }) {
    final recordNumber = _extractRecordNumber(text);
    final dueDate = _extractDate(text, _dueDateMarkers);
    final documentDate = _extractDate(text, _documentDateMarkers);
    final currency = _extractCurrency(text);
    final patch = <String, Object?>{};
    final entities = <LocalAiEntity>[];

    if (dueDate != null) {
      patch['due_date'] = dueDate;
      entities.add(_entity(LocalAiEntityType.date, dueDate));
    }
    if (documentDate != null) {
      patch[isInvoice ? 'invoice_date' : 'bill_date'] = documentDate;
      entities.add(_entity(LocalAiEntityType.date, documentDate));
    }
    if (currency != null) {
      patch['currency_code'] = currency;
      entities.add(_entity(LocalAiEntityType.currencyCode, currency));
    }

    if (recordNumber == null || patch.isEmpty) {
      final missing = <String>[];
      if (recordNumber == null) {
        missing.add(isInvoice ? 'record_number' : 'record_number');
      }
      if (patch.isEmpty) missing.add('patch');
      return _missing(locale, missing, entities: entities);
    }

    entities.insert(0, _entity(LocalAiEntityType.recordNumber, recordNumber));
    return _mutation(
      locale: locale,
      actionType: isInvoice
          ? LocalAiActionTypes.invoiceUpdate
          : LocalAiActionTypes.billUpdate,
      fields: {'record_number': recordNumber, 'patch': patch},
      entities: entities,
    );
  }

  LocalAiProposal _archiveOrVoid(
    String text,
    String locale,
    String actionType,
  ) {
    final recordName = _extractRecordName(text);
    final recordNumber = _extractRecordNumber(text);
    final reason = _extractReason(text);
    final entities = <LocalAiEntity>[];
    final fields = <String, Object?>{};

    if (recordNumber != null) {
      fields['record_number'] = recordNumber;
      entities.add(_entity(LocalAiEntityType.recordNumber, recordNumber));
    } else if (recordName != null) {
      fields['record_name'] = recordName;
      entities.add(_entity(LocalAiEntityType.recordName, recordName));
    }
    if (reason != null) fields['reason'] = reason;

    if (fields['record_name'] == null && fields['record_number'] == null ||
        reason == null) {
      final missing = <String>[];
      if (fields['record_name'] == null && fields['record_number'] == null) {
        missing.add('record_name_or_record_number');
      }
      if (reason == null) missing.add('reason');
      return _missing(locale, missing, entities: entities);
    }

    return _mutation(
      locale: locale,
      actionType: actionType,
      fields: fields,
      entities: entities,
    );
  }

  LocalAiProposal _mutation({
    required String locale,
    required String actionType,
    required Map<String, Object?> fields,
    required List<LocalAiEntity> entities,
  }) {
    return LocalAiProposal(
      intent: LocalAiIntent.proposeMutation,
      actionType: actionType,
      fields: fields,
      entities: entities,
      missingFields: const [],
      confidence: 0.94,
      requiresConfirmation: true,
      locale: locale,
    );
  }

  LocalAiProposal _explanation(String text, String locale) {
    return LocalAiProposal(
      intent: LocalAiIntent.explain,
      actionType: LocalAiActionTypes.none,
      fields: {'query': text},
      entities: const [],
      missingFields: const [],
      confidence: 0.99,
      requiresConfirmation: false,
      locale: locale,
    );
  }

  LocalAiProposal _missing(
    String locale,
    List<String> fields, {
    List<LocalAiEntity> entities = const [],
  }) {
    return LocalAiProposal(
      intent: LocalAiIntent.requestMissingInformation,
      actionType: LocalAiActionTypes.none,
      fields: const {},
      entities: entities,
      missingFields: fields,
      confidence: 0.98,
      requiresConfirmation: false,
      locale: locale,
    );
  }

  LocalAiProposal _unsupported(String locale) {
    return LocalAiProposal(
      intent: LocalAiIntent.unsupported,
      actionType: LocalAiActionTypes.unsupported,
      fields: const {},
      entities: const [],
      missingFields: const [],
      confidence: 1,
      requiresConfirmation: false,
      locale: locale,
    );
  }

  String? _detectAction(String text) {
    final lower = text.toLowerCase();
    final mutation = _containsAny(lower, const [
      'edit',
      'update',
      'change',
      'modify',
      'set',
      'adjust',
      'post',
      'archive',
      'void',
      'تعديل',
      'تحديث',
      'عدل',
      'عدّل',
      'حدّث',
      'حدث',
      'غير',
      'غيّر',
      'اضبط',
      'رحّل',
      'أرشف',
      'ابطل',
      'أبطل',
    ]);
    if (!mutation) return null;

    if (_containsAny(lower, const ['journal', 'قيد', 'سند يومية'])) {
      return LocalAiActionTypes.journalEntryPost;
    }
    if (_containsAny(lower, const ['balance', 'رصيد'])) {
      return LocalAiActionTypes.balanceAdjustment;
    }
    if (_containsAny(lower, const ['archive', 'أرشف'])) {
      if (_containsAny(lower, const ['vendor', 'supplier', 'مورد'])) {
        return LocalAiActionTypes.vendorArchive;
      }
      return LocalAiActionTypes.customerArchive;
    }
    if (_containsAny(lower, const ['void', 'ابطل', 'أبطل'])) {
      if (_containsAny(lower, const ['bill', 'purchase', 'مشتريات'])) {
        return LocalAiActionTypes.billVoid;
      }
      return LocalAiActionTypes.invoiceVoid;
    }
    if (_containsAny(lower, const ['bill', 'purchase bill', 'فاتورة شراء'])) {
      return LocalAiActionTypes.billUpdate;
    }
    if (_containsAny(lower, const ['invoice', 'فاتورة مبيعات', 'فاتورة'])) {
      return LocalAiActionTypes.invoiceUpdate;
    }
    if (_containsAny(lower, const ['vendor', 'supplier', 'مورد'])) {
      return LocalAiActionTypes.vendorUpdate;
    }
    if (_containsAny(lower, const ['customer', 'client', 'عميل', 'زبون'])) {
      return LocalAiActionTypes.customerUpdate;
    }
    return null;
  }

  bool _isExplanation(String text) {
    final lower = text.toLowerCase();
    return _containsAny(lower, const [
      'explain',
      'what is',
      'how does',
      'why does',
      'اشرح',
      'ما هو',
      'ما هي',
      'كيف يعمل',
      'لماذا',
    ]);
  }

  bool _isMissingInformationRequest(String text) {
    final lower = text.toLowerCase();
    return _containsAny(lower, const [
      'what information is missing',
      'what details do you need',
      'missing information',
      'معلومات ناقصة',
      'ما المعلومات المطلوبة',
      'ما المطلوب',
    ]);
  }

  bool _containsUnsafeRequest(String text) {
    final lower = text.toLowerCase();
    return RegExp(
          r'\b(delete|remove|drop|truncate|sql|database|source code|source files?|edit files?|execute automatically|without confirmation)\b',
          caseSensitive: false,
        ).hasMatch(lower) ||
        _containsAny(lower, const [
          'احذف',
          'حذف',
          'امسح',
          'الكود المصدري',
          'الشفرة المصدرية',
          'ملفات التطبيق',
          'قاعدة البيانات',
          'استعلام sql',
          'نفذ تلقائيا',
          'نفذ تلقائيًا',
          'بدون تأكيد',
        ]);
  }

  List<String> _missingFieldsFor(String text) {
    final lower = text.toLowerCase();
    if (_containsAny(lower, const ['journal', 'قيد'])) {
      return const [
        'description',
        'transaction_date',
        'currency_code',
        'lines',
      ];
    }
    if (_containsAny(lower, const ['balance', 'رصيد'])) {
      return const ['party_id_or_record_name', 'amount_minor', 'direction'];
    }
    if (_containsAny(lower, const ['invoice', 'bill', 'فاتورة'])) {
      return const ['record_number', 'patch'];
    }
    if (_containsAny(lower, const [
      'customer',
      'client',
      'vendor',
      'supplier',
      'عميل',
      'مورد',
    ])) {
      return const ['record_name', 'patch'];
    }
    return const ['request_details'];
  }

  String? _extractRecordName(String text) {
    final quoted = RegExp(
      r"""["“”«»']([^"“”«»']{2,200})["“”«»']""",
    ).firstMatch(text);
    if (quoted != null)
      return LocalAiTextNormalizer.normalize(quoted.group(1)!);

    final named = RegExp(
      r'(?:named|called|for|باسم|لدى|للعميل|للزبون|للمورد)\s+([\p{L}][\p{L}0-9 .&_-]{1,100})',
      unicode: true,
    ).firstMatch(text);
    if (named != null) {
      final value = named.group(1);
      if (value != null) return _trimTrailingWords(value);
    }
    return null;
  }

  String? _extractRecordNumber(String text) {
    final match = RegExp(
      r'(?<![A-Za-z0-9])(?:INV|BILL|فاتورة)\b\s*[-#]?\s*[0-9A-Za-z-]{2,40}(?![A-Za-z0-9])',
      caseSensitive: false,
    ).firstMatch(LocalAiTextNormalizer.normalize(text));
    if (match == null) return null;
    return match.group(0)!.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _extractEmail(String text) {
    return RegExp(
      r'[^\s@]+@[^\s@]+\.[^\s@]+',
    ).firstMatch(text)?.group(0)?.toLowerCase();
  }

  String? _extractPhone(String text) {
    final matches = RegExp(
      r'(?<![0-9])[+]?\d[\d ()-]{7,}\d',
    ).allMatches(LocalAiTextNormalizer.normalizeArabicDigits(text));
    for (final match in matches) {
      final candidate = match.group(0)!.trim();
      if (candidate.replaceAll(RegExp(r'\D'), '').length >= 8) {
        return candidate.replaceAll(RegExp(r'\s+'), ' ');
      }
    }
    return null;
  }

  String? _extractDate(String text, List<String> markers) {
    final normalized = LocalAiTextNormalizer.normalizeArabicDigits(text);
    final markerPattern = markers.join('|');
    final match = RegExp(
      '(?:$markerPattern)[^0-9]{0,20}(\\d{4}-\\d{2}-\\d{2})',
      caseSensitive: false,
    ).firstMatch(normalized);
    return match?.group(1);
  }

  String? _extractCurrency(String text) {
    final match = RegExp(
      r'\b(USD|SAR|YER|EUR|AED|GBP)\b',
      caseSensitive: false,
    ).firstMatch(LocalAiTextNormalizer.normalize(text));
    return match?.group(1)?.toUpperCase();
  }

  String? _extractReason(String text) {
    final match = RegExp(
      r'(?:because|reason|لأن|بسبب|السبب)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(text);
    return match == null
        ? null
        : LocalAiTextNormalizer.normalize(match.group(1)!);
  }

  LocalAiEntity _entity(LocalAiEntityType type, String value) {
    final normalized = LocalAiTextNormalizer.normalize(value);
    return LocalAiEntity(
      type: type,
      text: value,
      normalized: normalized,
      confidence: 0.98,
    );
  }

  String? _locale(String value) {
    final normalized = value.trim().toLowerCase().split('-').first;
    return normalized == 'ar' || normalized == 'en' ? normalized : null;
  }

  String _trimTrailingWords(String value) {
    return value
        .replaceFirst(
          RegExp(
            r'\s+(?:with|email|phone|and|بريد|هاتف|و)\b.*$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  bool _containsAny(String value, List<String> candidates) {
    return candidates.any((candidate) {
      if (RegExp(r'^[A-Za-z0-9 ._-]+$').hasMatch(candidate)) {
        return RegExp(
          '(?<![A-Za-z0-9])${RegExp.escape(candidate)}(?![A-Za-z0-9])',
          caseSensitive: false,
        ).hasMatch(value);
      }
      return value.contains(candidate);
    });
  }

  static const _dueDateMarkers = [
    r'due date',
    r'due',
    r'تاريخ الاستحقاق',
    r'استحقاق',
  ];

  static const _documentDateMarkers = [
    r'invoice date',
    r'bill date',
    r'document date',
    r'تاريخ الفاتورة',
    r'تاريخ المستند',
  ];
}

/// Explicit opt-in provider for local-only previews and development tests.
final ruleBasedLocalAiEngineProvider = Provider<LocalAiEngine>((ref) {
  return const RuleBasedLocalAiEngine();
});
