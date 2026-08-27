class LocalAiKnowledgeChunk {
  const LocalAiKnowledgeChunk({
    required this.id,
    required this.englishTitle,
    required this.arabicTitle,
    required this.englishBody,
    required this.arabicBody,
    required this.englishKeywords,
    required this.arabicKeywords,
  });

  final String id;
  final String englishTitle;
  final String arabicTitle;
  final String englishBody;
  final String arabicBody;
  final List<String> englishKeywords;
  final List<String> arabicKeywords;

  String titleFor(String locale) => locale == 'ar' ? arabicTitle : englishTitle;

  String bodyFor(String locale) => locale == 'ar' ? arabicBody : englishBody;
}

/// Static, privacy-safe workflow guidance. It intentionally contains no
/// tenant records, balances, credentials, or cloud responses.
abstract final class LocalAiKnowledgeBase {
  static const chunks = <LocalAiKnowledgeChunk>[
    LocalAiKnowledgeChunk(
      id: 'journal-basics',
      englishTitle: 'Journal entries',
      arabicTitle: 'قيود اليومية',
      englishBody:
          'A journal entry records equal debit and credit totals. Drafts should be reviewed before posting, and posted facts are corrected with an approved reversal or void workflow.',
      arabicBody:
          'يسجل قيد اليومية إجمالي مدين ودائن متساويين. يجب مراجعة المسودات قبل الترحيل، وتصحيح القيود المرحلة من خلال إجراء عكسي أو إلغاء معتمد.',
      englishKeywords: ['journal', 'debit', 'credit', 'posting', 'ledger'],
      arabicKeywords: ['قيد', 'مدين', 'دائن', 'ترحيل', 'دفتر الأستاذ'],
    ),
    LocalAiKnowledgeChunk(
      id: 'invoice-workflow',
      englishTitle: 'Customer invoices',
      arabicTitle: 'فواتير العملاء',
      englishBody:
          'Create an invoice with a customer, date, currency, and validated line items. Confirm totals and tax before saving; posting and later corrections remain governed by accounting permissions.',
      arabicBody:
          'أنشئ الفاتورة مع العميل والتاريخ والعملة وبنود صحيحة. تحقق من الإجماليات والضريبة قبل الحفظ؛ ويظل الترحيل والتصحيح اللاحق خاضعاً لصلاحيات المحاسبة.',
      englishKeywords: ['invoice', 'customer invoice', 'sales invoice', 'tax'],
      arabicKeywords: ['فاتورة', 'فاتورة مبيعات', 'العميل', 'ضريبة'],
    ),
    LocalAiKnowledgeChunk(
      id: 'supplier-workflow',
      englishTitle: 'Suppliers and bills',
      arabicTitle: 'الموردون والفواتير',
      englishBody:
          'A supplier bill should be matched to procurement evidence where applicable. Variances require a reasoned approval; a local assistant may prepare a proposal but cannot approve or post it.',
      arabicBody:
          'ينبغي مطابقة فاتورة المورد مع أدلة المشتريات عند انطباق ذلك. تتطلب الفروقات موافقة مبررة؛ ويمكن للمساعد المحلي إعداد اقتراح فقط ولا يستطيع الموافقة أو الترحيل.',
      englishKeywords: [
        'supplier',
        'vendor',
        'bill',
        'purchase',
        'three-way match',
      ],
      arabicKeywords: ['المورد', 'فاتورة شراء', 'المشتريات', 'المطابقة'],
    ),
    LocalAiKnowledgeChunk(
      id: 'bank-reconciliation',
      englishTitle: 'Bank reconciliation',
      arabicTitle: 'التسوية البنكية',
      englishBody:
          'Reconciliation compares a bank statement with ledger activity. Investigate unmatched items and preserve evidence; do not silently edit posted accounting facts.',
      arabicBody:
          'تقارن التسوية البنكية كشف الحساب بحركة دفتر الأستاذ. تحقق من البنود غير المطابقة واحتفظ بالأدلة؛ ولا تعدل القيود المرحلة بصمت.',
      englishKeywords: ['bank', 'reconciliation', 'statement', 'unmatched'],
      arabicKeywords: ['البنك', 'التسوية', 'كشف الحساب', 'غير مطابق'],
    ),
    LocalAiKnowledgeChunk(
      id: 'inventory-basics',
      englishTitle: 'Inventory movement',
      arabicTitle: 'حركة المخزون',
      englishBody:
          'Inventory changes should use a governed receipt, return, sale, reservation, or transfer workflow. The local assistant can explain or prepare a proposal, but authoritative stock changes occur through approved server commands.',
      arabicBody:
          'يجب أن تستخدم تغييرات المخزون إجراء استلام أو إرجاع أو بيع أو حجز أو تحويل معتمداً. يستطيع المساعد المحلي الشرح أو إعداد اقتراح، بينما تتم تغييرات المخزون المعتمدة عبر أوامر الخادم.',
      englishKeywords: [
        'inventory',
        'stock',
        'reservation',
        'transfer',
        'warehouse',
      ],
      arabicKeywords: ['المخزون', 'المستودع', 'الحجز', 'التحويل'],
    ),
    LocalAiKnowledgeChunk(
      id: 'crm-pipeline',
      englishTitle: 'CRM pipeline',
      arabicTitle: 'مسار CRM',
      englishBody:
          'A CRM pipeline tracks leads and opportunities through controlled stages. Record interactions with a date, channel, and summary while keeping tenant data private.',
      arabicBody:
          'يتابع مسار CRM العملاء المحتملين والفرص عبر مراحل منضبطة. سجل التفاعلات مع التاريخ والقناة والملخص مع الحفاظ على خصوصية بيانات المستأجر.',
      englishKeywords: [
        'crm',
        'pipeline',
        'lead',
        'opportunity',
        'interaction',
      ],
      arabicKeywords: ['crm', 'المسار', 'عميل محتمل', 'فرصة', 'تفاعل'],
    ),
    LocalAiKnowledgeChunk(
      id: 'reports-basics',
      englishTitle: 'Financial reports',
      arabicTitle: 'التقارير المالية',
      englishBody:
          'Trial balance, profit and loss, and balance sheet reports should use posted, tenant-scoped accounting facts and respect fiscal-period and permission rules.',
      arabicBody:
          'يجب أن تستخدم تقارير ميزان المراجعة والأرباح والخسائر والميزانية العمومية قيوداً محاسبية مرحلة ومقيدة بالمستأجر وتحترم الفترات والصلاحيات.',
      englishKeywords: [
        'report',
        'trial balance',
        'profit and loss',
        'balance sheet',
      ],
      arabicKeywords: [
        'تقرير',
        'ميزان المراجعة',
        'الأرباح والخسائر',
        'الميزانية',
      ],
    ),
  ];

  static List<LocalAiKnowledgeChunk> search(
    String query, {
    required String locale,
    int limit = 3,
  }) {
    final normalized = query.toLowerCase();
    final scored = <({LocalAiKnowledgeChunk chunk, int score})>[];
    for (final chunk in chunks) {
      final keywords = locale == 'ar'
          ? chunk.arabicKeywords
          : chunk.englishKeywords;
      var score = 0;
      for (final keyword in keywords) {
        if (normalized.contains(keyword.toLowerCase())) score += keyword.length;
      }
      if (score > 0) scored.add((chunk: chunk, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((item) => item.chunk).toList(growable: false);
  }
}
