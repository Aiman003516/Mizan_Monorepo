/// A feature-neutral navigation target emitted by the local assistant.
///
/// The AI package never imports the dashboard package or performs navigation
/// itself. The application shell owns the mapping from [id] to its actual
/// page state and may reject a target that is unavailable in the current
/// build.
class LocalAiNavigationTarget {
  const LocalAiNavigationTarget({
    required this.id,
    required this.englishLabel,
    required this.arabicLabel,
    required this.englishKeywords,
    required this.arabicKeywords,
  });

  final String id;
  final String englishLabel;
  final String arabicLabel;
  final List<String> englishKeywords;
  final List<String> arabicKeywords;

  String labelFor(String locale) => locale == 'ar' ? arabicLabel : englishLabel;
}

abstract final class LocalAiNavigationCatalog {
  static const destinations = <LocalAiNavigationTarget>[
    LocalAiNavigationTarget(
      id: 'dashboard',
      englishLabel: 'Dashboard',
      arabicLabel: 'لوحة التحكم',
      englishKeywords: ['dashboard', 'home', 'overview'],
      arabicKeywords: ['لوحة التحكم', 'الرئيسية', 'نظرة عامة'],
    ),
    LocalAiNavigationTarget(
      id: 'pos',
      englishLabel: 'Point of Sale',
      arabicLabel: 'نقطة البيع',
      englishKeywords: ['pos', 'point of sale', 'sales terminal'],
      arabicKeywords: ['نقطة البيع', 'المبيعات'],
    ),
    LocalAiNavigationTarget(
      id: 'reportsHub',
      englishLabel: 'Reports',
      arabicLabel: 'التقارير',
      englishKeywords: ['reports', 'reporting', 'financial reports'],
      arabicKeywords: ['التقارير', 'تقرير', 'التقارير المالية'],
    ),
    LocalAiNavigationTarget(
      id: 'reportProfitAndLoss',
      englishLabel: 'Profit and Loss',
      arabicLabel: 'الأرباح والخسائر',
      englishKeywords: ['profit and loss', 'p&l', 'income statement'],
      arabicKeywords: ['الأرباح والخسائر', 'قائمة الدخل'],
    ),
    LocalAiNavigationTarget(
      id: 'reportBalanceSheet',
      englishLabel: 'Balance Sheet',
      arabicLabel: 'الميزانية العمومية',
      englishKeywords: ['balance sheet', 'financial position'],
      arabicKeywords: ['الميزانية العمومية', 'المركز المالي'],
    ),
    LocalAiNavigationTarget(
      id: 'reportTrialBalance',
      englishLabel: 'Trial Balance',
      arabicLabel: 'ميزان المراجعة',
      englishKeywords: ['trial balance'],
      arabicKeywords: ['ميزان المراجعة'],
    ),
    LocalAiNavigationTarget(
      id: 'manageAccounts',
      englishLabel: 'Accounts',
      arabicLabel: 'الحسابات',
      englishKeywords: ['accounts', 'chart of accounts', 'ledger accounts'],
      arabicKeywords: ['الحسابات', 'دليل الحسابات'],
    ),
    LocalAiNavigationTarget(
      id: 'manageProducts',
      englishLabel: 'Products',
      arabicLabel: 'المنتجات',
      englishKeywords: ['products', 'items', 'inventory items'],
      arabicKeywords: ['المنتجات', 'الأصناف'],
    ),
    LocalAiNavigationTarget(
      id: 'manageCategories',
      englishLabel: 'Categories',
      arabicLabel: 'التصنيفات',
      englishKeywords: ['categories', 'product categories'],
      arabicKeywords: ['التصنيفات', 'تصنيفات المنتجات'],
    ),
    LocalAiNavigationTarget(
      id: 'customers',
      englishLabel: 'Customers',
      arabicLabel: 'العملاء',
      englishKeywords: ['customers', 'customer', 'clients', 'client'],
      arabicKeywords: [
        'العملاء',
        'العميل',
        'عملاء',
        'عميل',
        'الزبائن',
        'الزبون',
      ],
    ),
    LocalAiNavigationTarget(
      id: 'vendors',
      englishLabel: 'Suppliers',
      arabicLabel: 'الموردون',
      englishKeywords: ['suppliers', 'supplier', 'vendors', 'vendor'],
      arabicKeywords: ['الموردون', 'المورد', 'الموردين', 'مورد', 'مورد جديد'],
    ),
    LocalAiNavigationTarget(
      id: 'crmPipeline',
      englishLabel: 'CRM Pipeline',
      arabicLabel: 'مسار CRM',
      englishKeywords: ['crm pipeline', 'sales pipeline', 'opportunities'],
      arabicKeywords: ['مسار العملاء', 'مسار المبيعات', 'الفرص'],
    ),
    LocalAiNavigationTarget(
      id: 'crm360',
      englishLabel: 'CRM 360',
      arabicLabel: 'عرض CRM 360',
      englishKeywords: ['crm 360', 'customer 360', 'customer profile'],
      arabicKeywords: ['crm 360', 'ملف العميل', 'عرض العميل'],
    ),
    LocalAiNavigationTarget(
      id: 'procurement',
      englishLabel: 'Procurement',
      arabicLabel: 'المشتريات',
      englishKeywords: ['procurement', 'purchasing', 'purchase orders'],
      arabicKeywords: ['المشتريات', 'أوامر الشراء'],
    ),
    LocalAiNavigationTarget(
      id: 'orderHistory',
      englishLabel: 'Order History',
      arabicLabel: 'سجل الطلبات',
      englishKeywords: ['order history', 'orders'],
      arabicKeywords: ['سجل الطلبات', 'الطلبات'],
    ),
    LocalAiNavigationTarget(
      id: 'settings',
      englishLabel: 'Settings',
      arabicLabel: 'الإعدادات',
      englishKeywords: ['settings', 'configuration', 'preferences'],
      arabicKeywords: ['الإعدادات', 'التهيئة', 'التفضيلات'],
    ),
  ];

  static LocalAiNavigationTarget? resolve(String text, String locale) {
    final normalized = text.toLowerCase();
    final candidates = locale == 'ar'
        ? destinations.map((item) => (item: item, words: item.arabicKeywords))
        : destinations.map((item) => (item: item, words: item.englishKeywords));

    LocalAiNavigationTarget? best;
    var bestLength = 0;
    for (final candidate in candidates) {
      for (final keyword in candidate.words) {
        if (normalized.contains(keyword.toLowerCase()) &&
            keyword.length > bestLength) {
          best = candidate.item;
          bestLength = keyword.length;
        }
      }
    }
    return best;
  }

  static bool isAllowed(String id) => destinations.any((item) => item.id == id);
}
