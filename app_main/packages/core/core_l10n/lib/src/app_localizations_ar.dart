// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get allReportsAndTools => 'جميع التقارير والأدوات';

  @override
  String get businessInsights => 'رؤى الأعمال';

  @override
  String get setupBusinessCloud => 'إعداد سحابة الأعمال';

  @override
  String get manageRoles => 'إدارة الأدوار';

  @override
  String get settings => 'الإعدادات';

  @override
  String get accountTypeAsset => 'أصول';

  @override
  String get accountTypeLiability => 'التزامات';

  @override
  String get accountTypeEquity => 'حقوق ملكية';

  @override
  String get accountTypeRevenue => 'إيرادات';

  @override
  String get accountTypeExpense => 'مصروفات';

  @override
  String get mainDashboard => 'لوحة التحكم الرئيسية';

  @override
  String get newSalePOS => 'نقطة بيع / عملية جديدة';

  @override
  String get reports => 'التقارير';

  @override
  String get saving => 'جاري الحفظ';

  @override
  String get quickActions => 'إجراء سريع';

  @override
  String get transactionHistory => 'سجل العمليات';

  @override
  String get management => 'الإدارة';

  @override
  String get accounts => 'الحسابات';

  @override
  String get products => 'المنتجات';

  @override
  String get categories => 'التصنيفات';

  @override
  String get totalAmountsReport => 'تقرير الإجماليات';

  @override
  String get monthlyAmountsReport => 'تقرير الإجماليات الشهرية';

  @override
  String get accountActivity => 'حركة كشف حساب';

  @override
  String get manageAccounts => 'إدارة الحسابات';

  @override
  String get manageProducts => 'إدارة المنتجات';

  @override
  String get manageCategories => 'إدارة الأصناف';

  @override
  String get general => 'عام';

  @override
  String get clients => 'العملاء';

  @override
  String get suppliers => 'الموردون';

  @override
  String get language => 'اللغة';

  @override
  String get chooseLanguage => 'اختر اللغة';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get noAccountsYet => 'لا توجد حسابات بعد. أضف واحد!';

  @override
  String noResultsFound(String query) {
    return 'لا توجد نتائج بحث عن \"$query\".';
  }

  @override
  String get type => 'النوع:';

  @override
  String get balance => 'الرصيد';

  @override
  String get phone => 'الهاتف';

  @override
  String get errorLoadingAccounts => 'خطأ في تحميل الحسابات';

  @override
  String get errorLoadingBalances => 'خطأ في تحميل الأرصدة:';

  @override
  String get addNewAccount => 'إضافة حساب جديد';

  @override
  String get editAccount => 'تعديل الحساب';

  @override
  String get accountNameHint => 'اسم الحساب (مثال: \"الصندوق\"، \"العميل أ\")';

  @override
  String get pleaseEnterName => 'الرجاء إدخال اسمك';

  @override
  String get accountType => 'نوع الحساب';

  @override
  String get classificationOptional => 'التصنيف (اختياري)';

  @override
  String get errorLoadingClassifications => 'خطأ في تحميل التصنيفات:';

  @override
  String get phoneNumberOptional => 'رقم الهاتف (اختياري)';

  @override
  String get initialBalance => 'الرصيد الافتتاحي';

  @override
  String get pleaseEnterBalance => 'الرجاء إدخال رصيد (0 مقبول)';

  @override
  String get pleaseEnterValidNumber => 'الرجاء إدخال رقم صالح';

  @override
  String get failedToSaveAccount => 'فشل حفظ الحساب:';

  @override
  String get addAccount => 'إضافة حساب';

  @override
  String noAccountsClassified(String classification) {
    return 'لا توجد حسابات مصنفة كـ \"$classification\" بعد.\nأضف واحداً في قسم الحسابات.';
  }

  @override
  String get exportToPDF => 'تصدير إلى PDF';

  @override
  String get export => 'تصدير';

  @override
  String get exportToExcel => 'تصدير إلى Excel';

  @override
  String get excelExportSuccess => 'تم إنشاء ملف Excel بنجاح.';

  @override
  String accountBalances(String classification) {
    return 'أرصدة الحسابات - $classification';
  }

  @override
  String get errorLoadingSummaries => 'خطأ في تحميل الملخصات:';

  @override
  String get addNewTransaction => 'إضافة عملية جديدة';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get welcomeToMizan => 'أهلاً بك في ميزان';

  @override
  String get signInToSync => 'سجل الدخول لمزامنة بياناتك';

  @override
  String get signInWithGoogle => 'تسجيل الدخول عبر جوجل';

  @override
  String get offlineUnavailable => 'غير متصل: المزامنة غير متاحة';

  @override
  String get online => 'متصل';

  @override
  String get syncData => 'مزامنة البيانات';

  @override
  String get syncNotImplemented => 'المزامنة لم تنفذ بعد.';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get search => 'بحث...';

  @override
  String get openNavigationMenu => 'فتح قائمة التنقل';

  @override
  String get mizan => 'ميزان';

  @override
  String get mizanDashboard => 'لوحة تحكم ميزان';

  @override
  String get mizanUser => 'مستخدم ميزان';

  @override
  String get notSignedIn => 'لم يتم تسجيل \nالدخول';

  @override
  String get offlineMode => 'وضع عدم الاتصال';

  @override
  String get syncDisabled => 'المزامنة معطلة';

  @override
  String get totalAmountsSummary => 'ملخص الإجماليات';

  @override
  String get monthlyAmountsSummary => 'ملخص الإجماليات الشهرية';

  @override
  String get accountActivityLedger => 'كشف حساب ';

  @override
  String get dataSafetyWarning => 'تحذير أمان البيانات';

  @override
  String get dataSafetyMessage =>
      'بياناتك مخزنة حالياً على هذا الجهاز فقط.\nلمنع فقدان البيانات، يرجى تسجيل الدخول لتمكين النسخ الاحتياطي السحابي.';

  @override
  String get ok => 'موافق';

  @override
  String get addNewProduct => 'إضافة منتج جديد';

  @override
  String get editProduct => 'تعديل المنتج';

  @override
  String get pleaseSelectCategory => 'الرجاء اختيار فئة';

  @override
  String get failedToSaveProduct => 'فشل حفظ المنتج:';

  @override
  String get selectCategory => 'اختر صنف';

  @override
  String errorLoadingCategories(String error) {
    return 'خطأ في تحميل الأصناف:';
  }

  @override
  String get productName => 'اسم المنتج';

  @override
  String get price => 'السعر';

  @override
  String get pleaseEnterPrice => 'الرجاء إدخال سعر';

  @override
  String get noProductsSaved =>
      'لا توجد منتجات محفوظة.\nانقر \"+\" لإضافة واحد.';

  @override
  String get priceLabel => 'السعر';

  @override
  String get newCategory => 'صنف جديد';

  @override
  String get categoryName => 'اسم الفئة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get editCategory => 'تعديل الصنف';

  @override
  String get noCategoriesYet => 'لا توجد أصناف بعد.\nأضف واحد!';

  @override
  String get addCategory => 'إضافة صنف';

  @override
  String get noProductsYet => 'لا توجد منتجات بعد.\nأضف واحد!';

  @override
  String get error => 'خطأ:';

  @override
  String get all => 'الكل';

  @override
  String get posSales => 'مبيعات نقاط البيع';

  @override
  String get noTransactionEntries => 'لا توجد قيود مسجلة لهذا الفلتر.';

  @override
  String get date => 'التاريخ';

  @override
  String get account => 'الحساب';

  @override
  String get description => 'الوصف';

  @override
  String get debit => 'مدين';

  @override
  String get credit => 'دائن';

  @override
  String get currency => 'العملة';

  @override
  String monthlyAmounts(String classification) {
    return 'الإجماليات الشهرية - $classification';
  }

  @override
  String get noMonthlyTotals => 'لا توجد إجماليات شهرية لعرضها لهذا الفلتر.';

  @override
  String get month => 'الشهر';

  @override
  String get currencyLabel => 'العملة';

  @override
  String totalAmounts(String classification) {
    return 'الإجماليات - $classification';
  }

  @override
  String get noTotals => 'لا توجد إجماليات لعرضها لهذا الفلتر.';

  @override
  String get name => 'الاسم';

  @override
  String get totalClassifications => 'إجمالي التصنيفات';

  @override
  String get noClassificationTotals => 'لا توجد إجماليات تصنيفات لعرضها.';

  @override
  String get classification => 'التصنيف';

  @override
  String get total => 'الإجمالي';

  @override
  String get upgradeToPro => 'الترقية إلى Pro';

  @override
  String get unlockMizanPro => 'افتح ميزان Pro';

  @override
  String get proPrice => 'احصل على النسخة الكاملة مقابل \nدفعة لمرة واحدة';

  @override
  String get proFeatures =>
      'يشمل ذلك وصولاً غير محدود لجميع الميزات، والمزامنة السحابية، والتحديثات المستقبلية.';

  @override
  String get purchaseFullVersion => 'شراء النسخة الكاملة';

  @override
  String get couldNotOpenPurchasePage => 'تعذر فتح صفحة الشراء.';

  @override
  String get companyProfile => 'البيانات الشخصية والشركة';

  @override
  String get companyProfileReportHint =>
      'هذه المعلومات قد تستخدم في التقارير والفواتير المطبوعة.';

  @override
  String get companyName => 'الاسم التجاري';

  @override
  String get pleaseEnterCompanyName => 'الرجاء إدخال اسم الشركة';

  @override
  String get yourName => 'اسمك';

  @override
  String get companyAddress => 'عنوان الشركة';

  @override
  String get taxID => 'الرقم الضريبي';

  @override
  String get saveProfile => 'حفظ الملف الشخصي';

  @override
  String get profileSavedSuccess => 'تم حفظ الملف الشخصي بنجاح.';

  @override
  String get failedToSaveProfile => 'فشل حفظ الملف الشخصي:';

  @override
  String get currencyOptions => 'خيارات العملة';

  @override
  String get noCurrenciesFound => 'لا توجد عملات.\nانقر \"+\" لإضافة واحدة.';

  @override
  String get codeLabel => 'الرمز:';

  @override
  String get addNewCurrency => 'إضافة عملة جديدة';

  @override
  String get currencyCodeHint => 'الرمز (مثل \"USD\")';

  @override
  String get currencyCodeHelper => 'رمز فريد قصير (3-5 أحرف)';

  @override
  String get pleaseEnterCode => 'الرجاء إدخال رمز';

  @override
  String get codeTooLong => 'الرمز طويل جداً';

  @override
  String get currencyNameHint => 'الاسم (مثل \"دولار أمريكي\")';

  @override
  String get pleaseEnterCurrencyName => 'الرجاء إدخال اسم';

  @override
  String get currencySymbolHint => 'الرمز';

  @override
  String get failedToSave => 'فشل الحفظ:';

  @override
  String get securityOptions => 'خيارات الأمان';

  @override
  String get requirePasscode => 'طلب رمز الدخول عند الفتح';

  @override
  String get toggleSecurity => 'تفعيل طبقة أمان إضافية';

  @override
  String get passcodeRemoved => 'تمت إزالة رمز الدخول.';

  @override
  String get setChangePasscode => 'تعيين/تغيير رمز الدخول';

  @override
  String get notSet => 'غير معين';

  @override
  String get useBiometrics => 'استخدام البصمة لفتح القفل';

  @override
  String get useBiometricsHint =>
      'استخدام بصمة الإصبع، الوجه، أو قزحية \nالعين';

  @override
  String get setPasscode => 'تعيين رمز الدخول';

  @override
  String get setPasscodeHint =>
      'أنشئ رمز PIN من 4 أرقام لتطبيقك.\nسيكون مطلوباً عند الدخول.';

  @override
  String get newPin => 'رمز PIN جديد (4 أرقام)';

  @override
  String get pleaseEnterPin => 'الرجاء إدخال رمز PIN';

  @override
  String get pinMustBe4Digits => 'يجب أن يتكون الرمز من 4 أرقام';

  @override
  String get confirmPin => 'تأكيد رمز PIN';

  @override
  String get pinsDoNotMatch => 'الرمزان غير متطابقان';

  @override
  String get savePasscode => 'حفظ رمز الدخول';

  @override
  String get passcodeSetSuccess => 'تم تعيين رمز الدخول بنجاح.';

  @override
  String get failedToSavePasscode => 'فشل حفظ رمز الدخول:';

  @override
  String get dataAndSync => 'البيانات والمزامنة';

  @override
  String get backupNow => 'نسخ احتياطي للبيانات الآن';

  @override
  String get backupHint => 'يرفع بياناتك المحلية إلى Google Drive.';

  @override
  String get restoreFromBackup => 'استعادة من نسخة احتياطية';

  @override
  String get restoreWarning =>
      'تحذير خطير: سيؤدي هذا إلى الكتابة فوق جميع البيانات الحالية في التطبيق بالبيانات من ملف النسخ الاحتياطي الخاص بك. لا يمكن التراجع عن هذا الإجراء. هل أنت متأكد؟';

  @override
  String get buyFullVersion => 'شراء النسخة الكاملة';

  @override
  String get restoreBackupTitle => 'استعادة من ملف؟';

  @override
  String get restoreBackupMessage =>
      'سيؤدي هذا إلى الكتابة فوق جميع بياناتك المحلية بالبيانات من ملف النسخ الاحتياطي الذي اخترته.\n\nلا يمكن التراجع عن هذا الإجراء.';

  @override
  String get restore => 'استعادة';

  @override
  String get restoreSuccess =>
      'تمت الاستعادة بنجاح! يرجى إعادة تشغيل ميزان لتحميل البيانات الجديدة.';

  @override
  String restoreFailed(String error) {
    return 'فشلت الاستعادة. بياناتك الأصلية آمنة. خطأ: $error';
  }

  @override
  String get featureNotImplemented => 'الميزة لم تنفذ بعد.';

  @override
  String get chooseTheme => 'اختر المظهر';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get systemDefault => 'افتراضي النظام';

  @override
  String get selectAccount => 'اختر حساب';

  @override
  String get unknownAccount => 'حساب غير معروف';

  @override
  String get pleaseSelectCurrency => 'الرجاء اختيار عملة.';

  @override
  String get pleaseEnterAccountName => 'الرجاء إدخال أو اختيار اسم حساب.';

  @override
  String get criticalAccountError =>
      'خطأ فادح: الحسابات الافتراضية (مثل المخزون) مفقودة.';

  @override
  String get transactionSaved => 'تم حفظ العملية بنجاح.';

  @override
  String forAccount(String accountName) {
    return 'لـ $accountName';
  }

  @override
  String get loading => 'جار التحميل...';

  @override
  String get accountName => 'اسم الحساب';

  @override
  String get pleaseEnterOrSelectAccount => 'الرجاء إدخال أو اختيار حساب';

  @override
  String get amount => 'المبلغ';

  @override
  String get pleaseEnterAmount => 'الرجاء إدخال مبلغ';

  @override
  String get invalidAmount => 'مبلغ غير صالح';

  @override
  String exchangeRate(String currencyCode, String defaultCurrency) {
    return 'سعر الصرف (1 $currencyCode = ؟ $defaultCurrency)';
  }

  @override
  String get pleaseEnterRate => 'الرجاء إدخال سعر صرف';

  @override
  String get invalidRate => 'سعر صرف غير صالح';

  @override
  String get addAttachment => 'إضافة مرفق';

  @override
  String get details => 'التفاصيل';

  @override
  String get couldNotLoadCurrencies => 'تعذر تحميل العملات';

  @override
  String get paymentCredit => 'دفعة (دائن)';

  @override
  String get chargeDebit => 'عليه (مدين)';

  @override
  String get noHistory => 'لا يوجد سجل عمليات لهذا الحساب.';

  @override
  String get errorLoadingHistory => 'خطأ في تحميل السجل:';

  @override
  String get pleaseAddCategory => 'الرجاء إضافة صنف أولاً.';

  @override
  String get noProductsInCategory => 'لا توجد منتجات في هذه الفئة';

  @override
  String get quantity => 'الكمية';

  @override
  String get clear => 'مسح';

  @override
  String get printReceipt => 'طباعة إيصال';

  @override
  String get zeroTotalError => 'لا يمكن معالجة عملية بيع بإجمالي صفر.';

  @override
  String get criticalSetupError =>
      'خطأ فادح في الإعداد: لم يتم إنشاء الحسابات عند بدء التشغيل.\nحاول إعادة التثبيت.';

  @override
  String posSale(String timestamp) {
    return 'بيع نقطة بيع #$timestamp';
  }

  @override
  String saleRecorded(String total) {
    return 'تم تسجيل عملية بيع بمبلغ $total.';
  }

  @override
  String get transactionFailed => 'فشلت العملية:';

  @override
  String get noTransactionsYet => 'لا توجد عمليات بعد.\nأضف واحدة!';

  @override
  String get companyNameLegacy => 'الاسم التجاري';

  @override
  String get yourNameLegacy => 'اسمك';

  @override
  String get companyAddressLegacy => 'العنوان';

  @override
  String get taxIDLegacy => 'الرقم الضريبي';

  @override
  String get securityOptionsLegacy => 'خيارات الأمان';

  @override
  String get scanBarcode => 'مسح الباركود';

  @override
  String productNotFound(String barcode) {
    return 'المنتج غير موجود للباركود: $barcode';
  }

  @override
  String get scanProductBarcode => 'مسح باركود المنتج';

  @override
  String get barcodeOptional => 'الباركود (اختياري)';

  @override
  String get orderDetails => 'تفاصيل الطلب';

  @override
  String get cart => 'السلة';

  @override
  String get items => 'عنصر (عناصر)';

  @override
  String get clearOrder => 'مسح الطلب';

  @override
  String get printAndSave => 'طباعة وحفظ';

  @override
  String get orderHistory => 'سجل الطلبات';

  @override
  String get noSalesYet => 'لم يتم تسجيل أي مبيعات نقاط بيع بعد.';

  @override
  String get returnFor => 'إرجاع للطلب';

  @override
  String get returnSuccess => 'تم إرجاع الطلب بنجاح.';

  @override
  String get returnFailed => 'فشل معالجة الإرجاع';

  @override
  String get confirmReturn => 'إرجاع هذا الطلب؟';

  @override
  String get confirmReturnMessage =>
      'سيؤدي هذا إلى إنشاء معاملة جديدة معاكسة لإلغاء هذا البيع. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get returnOrder => 'إرجاع الطلب';

  @override
  String get noItemsInSale =>
      'لم يتم العثور على أصناف في هذا البيع (ربما قيد يومية مباشر).';

  @override
  String get done => 'تم';

  @override
  String get year => 'السنة';

  @override
  String get local => 'محلي';

  @override
  String get exchangeRateShort => 'السعر';

  @override
  String get uploadImage => 'تحميل صورة';

  @override
  String get changeImage => 'تغيير الصورة';

  @override
  String get removeImage => 'إزالة';

  @override
  String get pickFromGallery => 'اختر من المعرض';

  @override
  String get takePhoto => 'التقط صورة';

  @override
  String get change => 'تغيير';

  @override
  String get remove => 'إزالة';

  @override
  String get manageReturn => 'إدارة الإرجاع';

  @override
  String get orderFullyReturned => 'تم إرجاع هذا الطلب بالكامل.';

  @override
  String get purchased => 'المشترى';

  @override
  String get returned => 'مُرجع';

  @override
  String get returnQuantity => 'كمية الإرجاع';

  @override
  String get totalRefund => 'إجمالي المبلغ المسترد';

  @override
  String get processReturn => 'تنفيذ الإرجاع';

  @override
  String get noItemsSelected => 'لم يتم تحديد أي أصناف للإرجاع.';

  @override
  String partialReturnFor(String transactionId) {
    return 'إرجاع جزئي للطلب $transactionId';
  }

  @override
  String get orderReturned => 'تم إرجاع هذا الطلب.';

  @override
  String get noLineItemsSaved => 'لم يتم حفظ أصناف لهذا الطلب.';

  @override
  String get fieldRequired => 'الحقل مطلوب';

  @override
  String get selectPaymentMethod => 'اختر طريقة الدفع';

  @override
  String get backupAndRestore => 'النسخ الاحتياطي والاستعادة';

  @override
  String get upgradeToMizanPro => 'الترقية إلى ميزان برو';

  @override
  String get mizanProDescription =>
      'تفعيل المزامنة السحابية، والوصول متعدد الأجهزة، وأدوار المستخدمين. اعرف المزيد...';

  @override
  String get createLocalBackupTitle => 'إنشاء نسخة احتياطية محلية؟';

  @override
  String get createLocalBackupMessage =>
      'سيؤدي هذا إلى حفظ نسخة من قاعدة بياناتك في موقع تختاره (مثل التنزيلات، جوجل درايف).';

  @override
  String get yes => 'نعم';

  @override
  String get newPurchase => 'فاتورة مشتريات جديدة';

  @override
  String get purchaseScreenTitle => 'فاتورة شراء جديدة';

  @override
  String get pay => 'ادفع';

  @override
  String get profitAndLoss => 'الأرباح والخسائر';

  @override
  String get revenue => 'الإيرادات';

  @override
  String get totalRevenue => 'إجمالي الإيرادات';

  @override
  String get expenses => 'المصروفات';

  @override
  String get totalExpenses => 'إجمالي المصروفات';

  @override
  String get netIncome => 'صافي الدخل';

  @override
  String get balanceSheet => 'الميزانية العمومية';

  @override
  String get asOf => 'كما في';

  @override
  String get assets => 'الأصول';

  @override
  String get totalAssets => 'إجمالي الأصول';

  @override
  String get liabilities => 'الالتزامات';

  @override
  String get totalLiabilities => 'إجمالي الالتزامات';

  @override
  String get equity => 'حقوق الملكية';

  @override
  String get totalEquity => 'إجمالي حقوق الملكية';

  @override
  String get totalLiabilitiesAndEquity => 'إجمالي الالتزامات وحقوق الملكية';

  @override
  String get trialBalance => 'ميزان المراجعة';

  @override
  String get selectSupplier => 'اختر المورد';

  @override
  String get makePayment => 'سداد دفعة';

  @override
  String get payFromAccount => 'الدفع من حساب';

  @override
  String get payToAccount => 'الدفع إلى حساب';

  @override
  String get pleaseEnterValidAmount => 'الرجاء إدخال مبلغ صحيح أكبر من 0';

  @override
  String get supplier => 'المورد';

  @override
  String get pleaseSelectSupplier => 'الرجاء اختيار مورد.';

  @override
  String get profitAndLossReport => 'قائمة الدخل';

  @override
  String get balanceSheetReport => 'الميزانية العمومية';

  @override
  String get trialBalanceReport => 'ميزان المراجعة';

  @override
  String get addProduct => 'أضف منتج';

  @override
  String get product => 'المنتج';

  @override
  String get quantityShort => 'الكمية';

  @override
  String get cost => 'التكلفة';

  @override
  String get totalCost => 'التكلفة الإجمالية';

  @override
  String get costPerItem => 'التكلفة';

  @override
  String get totalPayable => 'إجمالي المستحقات';

  @override
  String get pleaseEnterCost => 'الرجاء إدخال التكلفة';

  @override
  String get pleaseEnterQuantity => 'الرجاء إدخال الكمية';

  @override
  String get purchaseSaved => 'تم حفظ فاتورة الشراء بنجاح.';

  @override
  String failedToSavePurchase(String error) {
    return 'فشل حفظ فاتورة الشراء: $error';
  }

  @override
  String purchaseFrom(String supplierName) {
    return 'شراء من $supplierName';
  }

  @override
  String get createLocalBackupPrompt =>
      'سيؤدي هذا إلى إنشاء ملف نسخ احتياطي محلي (mizan.db) في مجلد تختاره. يمكنك استخدام هذا الملف لاستعادة بياناتك على هذا الجهاز أو جهاز آخر.';

  @override
  String get backup => 'نسخ احتياطي';

  @override
  String get backupSuccessful => 'تم النسخ الاحتياطي';

  @override
  String get backupFailed => 'فشل النسخ الاحتياطي';

  @override
  String get restoreSuccessful => 'نجحت الاستعادة';

  @override
  String get restoreSuccessMessage =>
      'تمت استعادة بياناتك. يرجى إعادة تشغيل التطبيق الآن.';

  @override
  String get learnMore => 'اعرف المزيد';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get newSale => 'عملية بيع جديدة';

  @override
  String get totalReceivable => 'إجمالي المستحقات';

  @override
  String currencyFormat(double value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '$valueString';
  }

  @override
  String saveSuccessPrintFailed(String error) {
    return 'نجح الحفظ، لكن فشلت الطباعة: $error';
  }

  @override
  String errorLoadingPaymentMethods(String error) {
    return 'خطأ في تحميل طرق الدفع: $error';
  }

  @override
  String atPrice(String price) {
    return '@ $price';
  }

  @override
  String get dbFileNotFound => 'ملف قاعدة البيانات غير موجود.';

  @override
  String get noBackupFound =>
      'لم يتم العثور على ملف نسخ احتياطي على Google Drive.';

  @override
  String get mizanAccounting => 'ميزان للمحاسبة';

  @override
  String generatedOn(String date) {
    return 'تم إنشاؤه في: $date';
  }

  @override
  String get totalLocal => 'الإجمالي (محلي)';

  @override
  String couldNotLaunch(String url) {
    return 'تعذر فتح $url';
  }

  @override
  String get webNotSupported => 'منصة الويب غير مدعومة';

  @override
  String get signInCancelled => 'تم إلغاء تسجيل الدخول من قبل المستخدم.';

  @override
  String get updateWindowsClientId =>
      'يرجى تحديث Client ID الخاص بويندوز في auth_repository.dart';

  @override
  String get updateWindowsClientIdSecret =>
      'يرجى تحديث Client ID/Secret الخاص بويندوز في auth_repository.dart';

  @override
  String get authFailed => 'فشلت المصادقة. تعذر الحصول على عميل HTTP.';

  @override
  String get criticalInventoryError =>
      'خطأ فادح: حسابات المخزون أو تكلفة البضاعة المباعة غير موجودة.';

  @override
  String get drLabel => 'مدين:';

  @override
  String get crLabel => 'دائن:';

  @override
  String get fixedAssets => 'الأصول الثابتة';

  @override
  String get fixedAssetsDescription => 'إدارة المعدات والمركبات والعقارات';

  @override
  String get netBookValue => 'صافي القيمة الدفترية';

  @override
  String get totalAcquisitionCost => 'إجمالي تكلفة الاقتناء';

  @override
  String get accumulatedDepreciation => 'الإهلاك المتراكم';

  @override
  String get activeAssets => 'نشط';

  @override
  String get fullyDepreciated => 'مُهلك بالكامل';

  @override
  String get disposedAssets => 'مُستبعد';

  @override
  String get allAssets => 'جميع الأصول';

  @override
  String get byCategory => 'حسب الفئة';

  @override
  String get schedule => 'الجدول';

  @override
  String get addAsset => 'إضافة أصل';

  @override
  String get bookValue => 'القيمة الدفترية';

  @override
  String get depreciated => 'مُهلك';

  @override
  String get usefulLife => 'العمر الإنتاجي';

  @override
  String get months => 'أشهر';

  @override
  String get monthsLeft => 'شهر متبقي';

  @override
  String get acquisitionDate => 'تاريخ الاقتناء';

  @override
  String get salvageValue => 'القيمة المتبقية';

  @override
  String get depreciationMethod => 'طريقة الإهلاك';

  @override
  String get straightLine => 'القسط الثابت';

  @override
  String get decliningBalance => 'القسط المتناقص';

  @override
  String get unitsOfActivity => 'وحدات النشاط';

  @override
  String get runDepreciation => 'تشغيل الاستهلاك';

  @override
  String get disposeAsset => 'التخلص';

  @override
  String get assetDetails => 'تفاصيل الأصل';

  @override
  String get valueInformation => 'معلومات القيمة';

  @override
  String get depreciationSettings => 'إعدادات الإهلاك';

  @override
  String get depreciationProgress => 'تقدم الإهلاك';

  @override
  String get currentPeriod => 'الفترة الحالية';

  @override
  String get monthly => 'شهري';

  @override
  String get depreciation => 'الإهلاك';

  @override
  String get depreciationProcessing => 'معالجة الإهلاك';

  @override
  String get periodEndDate => 'تاريخ نهاية الفترة';

  @override
  String get runAll => 'تشغيل الكل';

  @override
  String get batchDepreciationComplete => 'اكتملت معالجة الإهلاك الدفعية';

  @override
  String assetsProcessed(int count) {
    return 'تمت معالجة $count أصول';
  }

  @override
  String get ghostMoney => 'الفروقات المالية';

  @override
  String get ghostMoneyDescription => 'تسوية فروقات التقريب';

  @override
  String get pendingReconciliation => 'في انتظار التسوية';

  @override
  String get recentEntries => 'الإدخالات الأخيرة';

  @override
  String get reconcile => 'تسوية';

  @override
  String get reconcileAll => 'تسوية الكل';

  @override
  String get reconciled => 'مُسوّى';

  @override
  String get notReconciled => 'غير مُسوّى';

  @override
  String entriesReconciled(int count) {
    return 'تم تسوية $count إدخالات';
  }

  @override
  String get whatIsGhostMoney => 'ما هي الأموال الشبحية؟';

  @override
  String get ghostMoneyExplanation =>
      'الفروقات المالية تمثل فروقات التقريب الصغيرة التي تحدث أثناء العمليات الحسابية مثل تقسيم الفواتير أو تحويل العملات أو حسابات النسب المئوية. هذه الفروقات طبيعية ومتوقعة في المحاسبة.';

  @override
  String get sourceTransaction => 'عملية';

  @override
  String get sourceSplit => 'تقسيم فاتورة';

  @override
  String get sourceExchange => 'صرف عملات';

  @override
  String get sourceImport => 'استيراد';

  @override
  String get accountCash => 'الصندوق';

  @override
  String get accountPettyCash => 'النثريات';

  @override
  String get accountBankAccount => 'الحساب البنكي';

  @override
  String get accountAccountsReceivable => 'الذمم المدينة';

  @override
  String get accountInventory => 'المخزون';

  @override
  String get accountPrepaidExpenses => 'المصروفات المدفوعة مقدماً';

  @override
  String get accountFixedAssetsHeader => 'الأصول الثابتة';

  @override
  String get accountFurnitureFixtures => 'الأثاث والتجهيزات';

  @override
  String get accountEquipment => 'المعدات';

  @override
  String get accountVehicles => 'المركبات';

  @override
  String get accountAccumulatedDepreciation => 'الإهلاك المتراكم';

  @override
  String get accountAccountsPayable => 'الذمم الدائنة';

  @override
  String get accountAccruedExpenses => 'المصروفات المستحقة';

  @override
  String get accountSalesTaxPayable => 'ضريبة المبيعات المستحقة';

  @override
  String get accountUnearnedRevenue => 'الإيرادات غير المكتسبة';

  @override
  String get accountLongTermLiabilities => 'الالتزامات طويلة الأجل';

  @override
  String get accountLoansPayable => 'القروض المستحقة';

  @override
  String get accountOwnerEquity => 'حقوق الملكية';

  @override
  String get accountRetainedEarnings => 'الأرباح المحتجزة';

  @override
  String get accountDrawings => 'المسحوبات';

  @override
  String get accountSalesRevenue => 'إيرادات المبيعات';

  @override
  String get accountServiceRevenue => 'إيرادات الخدمات';

  @override
  String get accountInterestIncome => 'إيرادات الفوائد';

  @override
  String get accountCostOfGoodsSold => 'تكلفة البضاعة المباعة';

  @override
  String get accountRentExpense => 'مصروفات الإيجار';

  @override
  String get accountUtilitiesExpense => 'مصروفات المرافق';

  @override
  String get accountSalariesExpense => 'مصروفات الرواتب';

  @override
  String get accountDepreciationExpense => 'مصروفات الإهلاك';

  @override
  String get accountInsuranceExpense => 'مصروفات التأمين';

  @override
  String get accountSuppliesExpense => 'مصروفات المستلزمات';

  @override
  String get accountMiscellaneousExpense => 'مصروفات متنوعة';

  @override
  String get joinOrganization => 'الانضمام للمنظمة';

  @override
  String get enterInviteCode => 'أدخل كود الدعوة من المسؤول';

  @override
  String get inviteCode => 'رمز الدعوة';

  @override
  String get validInviteCode => 'كود دعوة صالح!';

  @override
  String get invalidInviteCode => 'كود دعوة غير صالح أو منتهي الصلاحية';

  @override
  String get codeMustBe6Digits => 'يجب أن يكون الكود ٦ أرقام';

  @override
  String get pleaseEnterInviteCode => 'الرجاء إدخال كود الدعوة';

  @override
  String get enterDisplayName => 'أدخل اسم العرض';

  @override
  String get successfullyJoined => 'تم الانضمام للمؤسسة بنجاح!';

  @override
  String get inviteCodeUsed => 'تم استخدام كود الدعوة هذا بالفعل';

  @override
  String get inviteCodeExpired => 'انتهت صلاحية كود الدعوة هذا';

  @override
  String get pleaseSignInFirst => 'الرجاء تسجيل الدخول أولاً';

  @override
  String get createNewOrganization => 'إنشاء مؤسسة جديدة';

  @override
  String get role => 'الصلاحية';

  @override
  String get customers => 'العملاء';

  @override
  String get addCustomer => 'إضافة عميل';

  @override
  String get newCustomer => 'عميل جديد';

  @override
  String get editCustomer => 'تعديل العميل';

  @override
  String get customerName => 'اسم العميل';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get address => 'العنوان';

  @override
  String get taxId => 'الرقم الضريبي';

  @override
  String get creditLimit => 'الحد الائتماني';

  @override
  String get notes => 'ملاحظات';

  @override
  String get noCustomersYet => 'لا يوجد عملاء بعد';

  @override
  String get tapToAddFirstCustomer => 'اضغط على الزر أدناه لإضافة أول عميل';

  @override
  String get outstanding => 'المتبقي';

  @override
  String get owed => 'مستحق';

  @override
  String get invoices => 'الفواتير';

  @override
  String get newInvoice => 'فاتورة جديدة';

  @override
  String get invoiceDate => 'تاريخ الفاتورة';

  @override
  String get dueDate => 'تاريخ الاستحقاق';

  @override
  String get lineItems => 'عناصر الفاتورة';

  @override
  String get addItem => 'إضافة عنصر';

  @override
  String get unitPrice => 'سعر الوحدة';

  @override
  String get subtotal => 'المجموع الفرعي';

  @override
  String get createInvoice => 'إنشاء فاتورة';

  @override
  String get invoiceCreated => 'تم إنشاء الفاتورة بنجاح';

  @override
  String get noInvoicesYet => 'لا توجد فواتير بعد';

  @override
  String get paid => 'مدفوعة';

  @override
  String get partial => 'مدفوعة جزئياً';

  @override
  String get overdue => 'متأخرة';

  @override
  String get draft => 'مسودة';

  @override
  String get sent => 'مرسلة';

  @override
  String get arAgingReport => 'تقرير أعمار الذمم المدينة';

  @override
  String get totalReceivables => 'إجمالي الذمم المدينة';

  @override
  String get current => 'حالي';

  @override
  String get days31to60 => '٣١-٦٠ يوم';

  @override
  String get days61to90 => '٦١-٩٠ يوم';

  @override
  String get over90Days => 'أكثر من ٩٠ يوم';

  @override
  String get byCustomer => 'حسب العميل';

  @override
  String get noOutstandingReceivables => 'لا توجد ذمم مدينة غير مسددة';

  @override
  String get allInvoicesPaid => 'تم سداد جميع الفواتير!';

  @override
  String customersWithBalances(int count) {
    return '$count عملاء لديهم أرصدة';
  }

  @override
  String get vendors => 'الموردين';

  @override
  String get addVendor => 'إضافة مورد';

  @override
  String get newVendor => 'مورد جديد';

  @override
  String get editVendor => 'تعديل المورد';

  @override
  String get vendorName => 'اسم المورد';

  @override
  String get paymentTerms => 'شروط الدفع';

  @override
  String get noVendorsYet => 'لا يوجد موردين بعد';

  @override
  String get tapToAddFirstVendor => 'اضغط على الزر أدناه لإضافة أول مورد';

  @override
  String get weOwe => 'ندين';

  @override
  String get bills => 'فواتير المشتريات';

  @override
  String get newBill => 'فاتورة مشتريات جديدة';

  @override
  String get billDate => 'تاريخ الفاتورة';

  @override
  String get vendorInvoice => 'رقم فاتورة المورد';

  @override
  String get createBill => 'إنشاء فاتورة مشتريات';

  @override
  String get billCreated => 'تم إنشاء فاتورة المشتريات بنجاح';

  @override
  String get noBillsYet => 'لا توجد فواتير مشتريات بعد';

  @override
  String get pending => 'معلقة';

  @override
  String get apAgingReport => 'تقرير أعمار الديون (الذمم الدائنة)';

  @override
  String get totalPayables => 'إجمالي الذمم الدائنة';

  @override
  String get byVendor => 'حسب المورد';

  @override
  String get noOutstandingPayables => 'لا توجد ذمم دائنة غير مسددة';

  @override
  String get allBillsPaid => 'تم سداد جميع الفواتير!';

  @override
  String vendorsWithBalances(int count) {
    return '$count موردين لديهم أرصدة';
  }

  @override
  String get statementOfCashFlows => 'قائمة التدفقات النقدية';

  @override
  String get cashFlowsFromOperating => 'التدفقات النقدية من الأنشطة التشغيلية';

  @override
  String get cashFlowsFromInvesting =>
      'التدفقات النقدية من الأنشطة الاستثمارية';

  @override
  String get cashFlowsFromFinancing => 'التدفقات النقدية من الأنشطة التمويلية';

  @override
  String get addDepreciation => 'إضافة: مصروف الإهلاك';

  @override
  String get decreaseInReceivables => 'انخفاض في الذمم المدينة';

  @override
  String get increaseInReceivables => 'زيادة في الذمم المدينة';

  @override
  String get increaseInPayables => 'زيادة في الذمم الدائنة';

  @override
  String get decreaseInPayables => 'انخفاض في الذمم الدائنة';

  @override
  String get netCashFromOperating => 'صافي النقد من التشغيل';

  @override
  String get netCashFromInvesting => 'صافي النقد من الاستثمار';

  @override
  String get netCashFromFinancing => 'صافي النقد من التمويل';

  @override
  String get purchaseOfFixedAssets => 'شراء الأصول الثابتة';

  @override
  String get netChangeInCash => 'صافي التغير في النقد';

  @override
  String get beginningCashBalance => 'رصيد النقد في البداية';

  @override
  String get endingCashBalance => 'رصيد النقد في النهاية';

  @override
  String get noInvestingActivities => 'لا توجد أنشطة استثمارية';

  @override
  String get noFinancingActivities => 'لا توجد أنشطة تمويلية';

  @override
  String get financialRatios => 'النسب المالية';

  @override
  String get currentRatio => 'النسبة الجارية';

  @override
  String get quickRatio => 'النسبة السريعة';

  @override
  String get debtToEquity => 'الديون/حقوق الملكية';

  @override
  String get grossProfitMargin => 'هامش الربح الإجمالي';

  @override
  String get netProfitMargin => 'هامش صافي الربح';

  @override
  String get returnOnAssets => 'العائد على الأصول';

  @override
  String get workingCapital => 'رأس المال العامل';

  @override
  String get receivablesTurnover => 'معدل دوران الذمم المدينة';

  @override
  String get receivables => 'المستحقات';

  @override
  String get payables => 'المدفوعات';

  @override
  String get currentAmount => 'حالية';

  @override
  String get overdueAmount => 'متأخرة';

  @override
  String get bankReconciliations => 'التسويات البنكية';

  @override
  String get newReconciliation => 'تسوية جديدة';

  @override
  String get noReconciliationsYet => 'لا توجد تسويات حتى الآن';

  @override
  String get startReconciling => 'ابدأ بتسوية كشوف حساباتك البنكية';

  @override
  String get bankAccount => 'الحساب البنكي';

  @override
  String get statementDate => 'تاريخ الكشف';

  @override
  String get statementEndingBalance => 'الرصيد الختامي للكشف';

  @override
  String get statementBalance => 'رصيد الكشف';

  @override
  String get bookBalance => 'الرصيد الدفتري';

  @override
  String get selectedCleared => 'المحدد كمقاصة:';

  @override
  String get differenceAmount => 'الفرق';

  @override
  String get balanced => 'متوازن!';

  @override
  String get unclearedTransactions => 'المعاملات غير المقاصة';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get deselectAll => 'إلغاء تحديد الكل';

  @override
  String get allTransactionsReconciled => 'كل المعاملات تمت تسويتها!';

  @override
  String get completeReconciliation => 'إتمام التسوية';

  @override
  String get reconciliationCompleted => 'تمت التسوية بنجاح!';

  @override
  String get pleaseSelectTransactions => 'الرجاء تحديد المعاملات للتسوية';

  @override
  String get noBankAccountsFound => 'لم يتم العثور على حسابات بنكية';

  @override
  String get closeBooks => 'Close Books';

  @override
  String get currentLockDate => 'Current Lock Date';

  @override
  String get booksAreOpen => 'Books are OPEN';

  @override
  String get closingInstructionsTitle => 'Closing Instructions';

  @override
  String get closingInstructionsBody =>
      'This action will:\n1. Zero out all Revenue & Expenses for the period.\n2. Transfer Net Income to Retained Earnings.\n3. LOCK the period from future edits.';

  @override
  String get stepSelectDate => 'Step 1: Select Closing Date';

  @override
  String get stepSelectEquityAccount =>
      'Step 2: Select Retained Earnings Account';

  @override
  String get errorNoEquityAccount =>
      'Error: No Equity accounts found. Please create one in Accounts.';

  @override
  String get closePeriodAndLock => 'CLOSE PERIOD & LOCK';

  @override
  String get confirmPeriodCloseTitle => 'Confirm Period Close';

  @override
  String get confirmPeriodCloseMessage =>
      'Are you sure? This will lock all transactions on or before this date. This action cannot be easily undone.';

  @override
  String get periodClosedSuccessfully => 'Period Closed Successfully.';

  @override
  String get periodLockedError => 'Period is closed for edits.';

  @override
  String get cvpAnalysis => 'تحليل التكلفة-الحجم-الربح';

  @override
  String get calculator => 'Calculator';

  @override
  String get breakEven => 'Break-Even';

  @override
  String get marginOfSafety => 'Margin of Safety';

  @override
  String get whatIf => 'What-If';

  @override
  String get costStructure => 'هيكل التكاليف';

  @override
  String get fixedCostsTotal => 'التكاليف الثابتة (الإجمالي)';

  @override
  String get fixedCostsHelper => 'الإيجار، الرواتب، الاستهلاك، إلخ.';

  @override
  String get perUnitData => 'بيانات الوحدة';

  @override
  String get sellingPrice => 'سعر البيع';

  @override
  String get variableCost => 'التكلفة المتغيرة';

  @override
  String get contributionMargin => 'Contribution Margin';

  @override
  String get contributionMarginPerUnit => 'CM per Unit';

  @override
  String get actualExpectedSales => 'المبيعات الفعلية/المتوقعة';

  @override
  String get unitsSold => 'الوحدات المباعة';

  @override
  String get targetProfit => 'الربح المستهدف';

  @override
  String get desiredProfit => 'الربح المطلوب';

  @override
  String get desiredProfitHelper => 'كم من الربح تريد تحقيقه؟';

  @override
  String get analyzeAndViewResults => 'Analyze & View Results';

  @override
  String get enterDataFirst => 'Enter data in the Calculator tab first';

  @override
  String get breakEvenPoint => 'نقطة التعادل';

  @override
  String get units => 'Units';

  @override
  String get sales => 'Sales';

  @override
  String get targetProfitAnalysis => 'تحليل الربح المستهدف';

  @override
  String get requiredUnits => 'الوحدات المطلوبة';

  @override
  String get requiredSales => 'المبيعات المطلوبة';

  @override
  String get risk => 'RISK';

  @override
  String get mosRatio => 'نسبة هامش الأمان';

  @override
  String get financialSnapshot => 'نظرة مالية';

  @override
  String get quickAccess => 'وصول سريع';

  @override
  String get cashFlow => 'التدفق النقدي';

  @override
  String get operatingLeverage => 'الرافعة التشغيلية';

  @override
  String get degreeOfOperatingLeverage => 'درجة الرافعة التشغيلية';

  @override
  String get leverageLevel => 'مستوى الرافعة';

  @override
  String get leverageImpact => 'Impact';

  @override
  String get priceSensitivityAnalysis => 'تحليل حساسية السعر';

  @override
  String get priceSensitivityDescription =>
      'Shows how break-even changes when you adjust selling price';

  @override
  String currentBreakEven(String units) {
    return 'نقطة التعادل الحالية: $units وحدة';
  }

  @override
  String get depreciationProcessingTitle => 'معالجة الإهلاك';

  @override
  String get selectPeriodEndDate => 'اختر تاريخ نهاية الفترة';

  @override
  String get processing => 'جاري المعالجة...';

  @override
  String get noActiveAssets => 'لا توجد أصول نشطة';

  @override
  String get addFixedAssetsHint => 'أضف أصولاً ثابتة لتشغيل الإهلاك';

  @override
  String get bookValueLabel => 'القيمة الدفترية';

  @override
  String get monthlyLabel => 'شهري';

  @override
  String get remainingLabel => 'المتبقي';

  @override
  String depreciationRecordedFor(String amount, String assetName) {
    return 'تم تسجيل الإهلاك: $amount لـ $assetName';
  }

  @override
  String processedAssetsTotal(int count, String amount) {
    return 'تمت معالجة $count أصول. الإجمالي: $amount';
  }

  @override
  String assetsCount(int count) {
    return '$count أصول';
  }

  @override
  String get ghostMoneyTitle => 'فروقات التقريب';

  @override
  String get whatIsGhostMoneyTooltip => 'ما هي فروقات التقريب؟';

  @override
  String get allBalanced => 'متوازن بالكامل!';

  @override
  String get noGhostMoneyToReconcile => 'لا توجد فروقات تقريب للتسوية';

  @override
  String get entryLabel => 'إدخال';

  @override
  String get entriesLabel => 'إدخالات';

  @override
  String get noEntriesToDisplay => 'لا توجد قيود للعرض';

  @override
  String reconcileCurrency(String currency) {
    return 'تسوية $currency';
  }

  @override
  String writeOffConfirmation(String amount, int count, String entryText) {
    return 'شطب $amount من فروقات التقريب؟\n\nسيتم إنشاء قيد يومية لمسح $count $entryText.';
  }

  @override
  String get reconcileButton => 'تسوية';

  @override
  String reconciledEntries(int count, String currency) {
    return 'تمت تسوية $count قيود لـ $currency';
  }

  @override
  String get entryReconciledMessage => 'تم تسوية الإدخال';

  @override
  String get ghostMoneyDialogTitle => 'ما هي فروقات التقريب؟';

  @override
  String get ghostMoneyDialogContent =>
      'فروقات التقريب تمثل فروقات صغيرة تحدث أثناء العمليات الحسابية.\n\nأمثلة:\n• تقسيم فاتورة على 3 (100 ÷ 3)\n• تحويل أسعار صرف العملات\n• حسابات الضرائب النسبية\n\nهذه الفروقات الصغيرة تتراكم عادة لتصل لبضعة قروش ويمكن شطبها أو توزيعها دورياً.';

  @override
  String get gotIt => 'فهمت';

  @override
  String get fixedAssetsTitle => 'الأصول الثابتة';

  @override
  String get netBookValueLabel => 'صافي القيمة الدفترية';

  @override
  String get totalCostLabel => 'التكلفة الإجمالية';

  @override
  String get depreciatedLabel => 'المُهلَك';

  @override
  String get progressLabel => 'التقدم';

  @override
  String get activeLabel => 'نشط';

  @override
  String get fullDeprLabel => 'مُهلَك كلياً';

  @override
  String get disposedLabel => 'مُستبعَد';

  @override
  String get allAssetsTab => 'جميع الأصول';

  @override
  String get byCategoryTab => 'حسب الفئة';

  @override
  String get scheduleTab => 'الجدول';

  @override
  String get noFixedAssets => 'لا توجد أصول ثابتة';

  @override
  String get addFixedAssetsDescription =>
      'أضف معدات أو مركبات أو عقارات لتتبع الإهلاك';

  @override
  String get noScheduledDepreciation => 'لا يوجد إهلاك مجدول';

  @override
  String percentDepreciated(String percent) {
    return '$percent% مُهلَك';
  }

  @override
  String monthlyDepreciationInfo(String amount, int months) {
    return 'شهري: $amount • $months شهر متبقي';
  }

  @override
  String get valueInformationTitle => 'معلومات القيمة';

  @override
  String get depreciationSettingsTitle => 'إعدادات الإهلاك';

  @override
  String get acquisitionCostLabel => 'تكلفة الاقتناء';

  @override
  String get salvageValueLabel => 'القيمة المتبقية';

  @override
  String get accumulatedDepreciationLabel => 'الإهلاك المتراكم';

  @override
  String get methodLabel => 'الطريقة';

  @override
  String get usefulLifeLabel => 'العمر الإنتاجي';

  @override
  String usefulLifeMonths(int months) {
    return '$months شهر';
  }

  @override
  String get runDepreciationButton => 'تشغيل الإهلاك';

  @override
  String get disposeButton => 'استبعاد';

  @override
  String get addAssetName => 'اسم الأصل';

  @override
  String get addAssetDescription => 'الوصف (اختياري)';

  @override
  String get addAssetAcquisitionCost => 'تكلفة الاقتناء';

  @override
  String get addAssetSalvageValue => 'القيمة المتبقية';

  @override
  String get addAssetUsefulLife => 'العمر الإنتاجي (بالأشهر)';

  @override
  String get addAssetAcquisitionDate => 'تاريخ الاقتناء';

  @override
  String get addAssetDepreciationMethod => 'طريقة الإهلاك';

  @override
  String get addAssetDecliningRate => 'معدل القسط المتناقص';

  @override
  String get reportsAndAnalytics => 'التقارير والتحليلات';

  @override
  String get reportMarketplaceTooltip => 'سوق التقارير';

  @override
  String get financialStatementsSection => 'القوائم المالية';

  @override
  String get performanceSection => 'الأداء';

  @override
  String get analysisToolsSection => 'أدوات التحليل';

  @override
  String get inventoryOperationsSection => 'المخزون والعمليات (قريباً)';

  @override
  String get cvpAnalysisTitle => 'تحليل التكلفة-الحجم-الربح';

  @override
  String get capitalBudgetingTitle => 'موازنة رأس المال';

  @override
  String get budgetAnalysisTitle => 'تحليل الموازنة';

  @override
  String get fraudDetectionTitle => 'كشف الاحتيال';

  @override
  String get standardCostingTitle => 'التكلفة المعيارية';

  @override
  String get financialRatiosTitle => 'النسب المالية';

  @override
  String get stockVelocityTitle => 'سرعة دوران المخزون';

  @override
  String get lowStockAlertTitle => 'تنبيه نقص المخزون';

  @override
  String get salesByCashierTitle => 'المبيعات حسب الكاشير';

  @override
  String get taxLiabilityTitle => 'الالتزام الضريبي';

  @override
  String get reportHubTitle => 'مركز التقارير';

  @override
  String get myReportsTab => 'تقاريري';

  @override
  String get marketplaceTab => 'السوق';

  @override
  String get noInstalledReports => 'لا توجد تقارير مثبتة';

  @override
  String get goToMarketplaceHint => 'اذهب إلى السوق لتحميل التقارير القياسية.';

  @override
  String get marketplaceUnavailable => 'السوق غير متاح';

  @override
  String get noStandardReportsOnline => 'لم يتم العثور على تقارير قياسية.';

  @override
  String get installButton => 'تثبيت';

  @override
  String get includedLabel => 'مُضمَّن';

  @override
  String buyLabel(String price) {
    return 'شراء $price';
  }

  @override
  String get lockedLabel => 'مقفل';

  @override
  String get purchaseReportTitle => 'شراء التقرير';

  @override
  String buyReportConfirmation(String title, String price) {
    return 'شراء \'$title\' بسعر $price؟';
  }

  @override
  String get buyNowButton => 'اشترِ الآن';

  @override
  String get processingPayment => 'جاري معالجة الدفع...';

  @override
  String installedReport(String title) {
    return '✅ تم تثبيت $title';
  }

  @override
  String get premiumReportLocked =>
      '🔒 تقرير مميز. قم بالترقية إلى Pro أو Enterprise.';

  @override
  String get posTerminalTitle => 'نقطة البيع';

  @override
  String get searchProductTooltip => 'البحث عن منتج';

  @override
  String get recallOrderTooltip => 'استدعاء طلب';

  @override
  String get holdButton => 'تعليق';

  @override
  String get orderParkedMessage => 'تم تعليق الطلب';

  @override
  String get recallOrderTitle => 'استدعاء طلب';

  @override
  String get noParkedOrders => 'لا توجد طلبات معلقة';

  @override
  String orderNumberLabel(String orderId) {
    return 'طلب #$orderId';
  }

  @override
  String orderInfo(int itemCount, int minutes) {
    return '$itemCount عناصر • قبل $minutes دقيقة';
  }

  @override
  String get closeButton => 'إغلاق';

  @override
  String get cartIsEmpty => 'السلة فارغة';

  @override
  String payWithButton(String method) {
    return 'الدفع بـ $method';
  }

  @override
  String get editQtyMode => 'وضع تعديل الكمية';

  @override
  String get scanMode => 'وضع المسح';

  @override
  String get totalLabel => 'المجموع';

  @override
  String get payPrintButton => 'دفع / طباعة';

  @override
  String get importProductsTitle => 'استيراد المنتجات';

  @override
  String get selectDefaultCategoryHint => '١. اختر فئة افتراضية لهذه المنتجات:';

  @override
  String get pleaseCreateCategoryFirst => 'يرجى إنشاء فئة أولاً.';

  @override
  String get uploadFileHint =>
      '٢. ارفع ملف CSV أو Excel (الأعمدة: الاسم، الباركود، الفئة، السعر، التكلفة، الكمية)';

  @override
  String get selectFileButton => 'اختر ملف';

  @override
  String get noProductsFoundInFile => 'لم يتم العثور على منتجات في الملف.';

  @override
  String get noDataLoaded => 'لا توجد بيانات. ارفع ملفاً للمعاينة.';

  @override
  String importProductsButton(int count) {
    return 'استيراد $count منتج';
  }

  @override
  String importSuccessMessage(int count) {
    return 'تم استيراد $count منتج بنجاح!';
  }

  @override
  String importFailedMessage(String error) {
    return 'فشل الاستيراد: $error';
  }

  @override
  String get pleaseSelectDefaultCategory => 'يرجى اختيار فئة افتراضية';

  @override
  String get budgetAnalysis => 'تحليل الميزانية';

  @override
  String get summaryTab => 'ملخص';

  @override
  String get variancesTab => 'الانحرافات';

  @override
  String get flexibleBudgetTab => 'الميزانية المرنة';

  @override
  String get budgetedNetIncome => 'صافي الدخل المقدّر';

  @override
  String get actualNetIncome => 'صافي الدخل الفعلي';

  @override
  String get netIncomeVariance => 'انحراف صافي الدخل';

  @override
  String get revenueLabel => 'الإيرادات';

  @override
  String get expensesLabel => 'المصروفات';

  @override
  String get flexibleBudgetAnalysis => 'تحليل الميزانية المرنة';

  @override
  String get fixedCosts => 'التكاليف الثابتة';

  @override
  String get variableRateUnit => 'المعدل المتغير/الوحدة';

  @override
  String get plannedActivity => 'النشاط المخطط';

  @override
  String get actualActivity => 'النشاط الفعلي';

  @override
  String get actualTotalCost => 'التكلفة الفعلية الإجمالية';

  @override
  String get budgetedLabel => 'المقدّر';

  @override
  String get actualLabel => 'الفعلي';

  @override
  String get varianceLabel => 'الانحراف';

  @override
  String get favorableLabel => 'مواتٍ';

  @override
  String get unfavorableLabel => 'غير مواتٍ';

  @override
  String get onTarget => 'في الهدف';

  @override
  String get capitalBudgeting => 'الموازنة الرأسمالية';

  @override
  String get calculatorTab => 'الآلة الحاسبة';

  @override
  String get resultsTab => 'النتائج';

  @override
  String get sensitivityTab => 'الحساسية';

  @override
  String get initialInvestment => 'الاستثمار الأولي';

  @override
  String get investmentAmount => 'مبلغ الاستثمار';

  @override
  String get discountRateLabel => 'معدل الخصم';

  @override
  String get rateLabel => 'المعدل';

  @override
  String get requiredReturn => 'العائد المطلوب';

  @override
  String get expectedCashFlows => 'التدفقات النقدية المتوقعة';

  @override
  String get forArrCalculation => 'لحساب معدل العائد المحاسبي';

  @override
  String get annualNetIncome => 'صافي الدخل السنوي';

  @override
  String get residualValueLabel => 'القيمة المتبقية';

  @override
  String get calculateViewResults => 'احسب واعرض النتائج';

  @override
  String get netPresentValue => 'صافي القيمة الحالية';

  @override
  String get internalRateOfReturn => 'معدل العائد الداخلي';

  @override
  String get paybackPeriod => 'فترة الاسترداد';

  @override
  String get investmentRecovered => 'سيتم استرداد الاستثمار';

  @override
  String get investmentMayNotRecover => 'قد لا يتم استرداد الاستثمار';

  @override
  String get discountedPaybackPeriod => 'فترة الاسترداد المخصومة';

  @override
  String get accountsForTimeValue => 'يأخذ القيمة الزمنية للنقود في الاعتبار';

  @override
  String get profitabilityIndex => 'مؤشر الربحية';

  @override
  String get accountingRateOfReturn => 'معدل العائد المحاسبي';

  @override
  String get acceptDecision => 'قبول';

  @override
  String get rejectDecision => 'رفض';

  @override
  String get npvSensitivity => 'حساسية صافي القيمة الحالية لمعدل الخصم';

  @override
  String get discountRateColumn => 'معدل الخصم';

  @override
  String get npvColumn => 'صافي القيمة الحالية';

  @override
  String get decisionColumn => 'القرار';

  @override
  String get selectPeriodTooltip => 'اختر الفترة';

  @override
  String get refreshTooltip => 'تحديث';

  @override
  String get errorLoadingRatios => 'خطأ في تحميل النسب';

  @override
  String get analysisPeriod => 'فترة التحليل';

  @override
  String get liquidityRatios => 'نسب السيولة';

  @override
  String get activityRatios => 'نسب النشاط';

  @override
  String get profitabilityRatios => 'نسب الربحية';

  @override
  String get leverageRatios => 'نسب الرافعة المالية';

  @override
  String get cashRatio => 'نسبة النقد';

  @override
  String get workingCapitalLabel => 'رأس المال العامل';

  @override
  String get inventoryTurnover => 'معدل دوران المخزون';

  @override
  String get daysSalesInInventory => 'أيام المبيعات في المخزون';

  @override
  String get daysSalesOutstanding => 'أيام المبيعات المستحقة';

  @override
  String get cashConversionCycle => 'دورة التحويل النقدي';

  @override
  String get assetTurnover => 'معدل دوران الأصول';

  @override
  String get operatingProfitMargin => 'هامش الربح التشغيلي';

  @override
  String get returnOnEquity => 'العائد على حقوق الملكية';

  @override
  String get ebitdaMargin => 'هامش الأرباح قبل الفوائد والضرائب';

  @override
  String get debtToEquityRatio => 'نسبة الدين إلى حقوق الملكية';

  @override
  String get debtToAssetsRatio => 'نسبة الدين إلى الأصول';

  @override
  String get equityMultiplier => 'مضاعف حقوق الملكية';

  @override
  String get interestCoverage => 'تغطية الفائدة';

  @override
  String get timesInterestEarned => 'مرات تحقق الفائدة';

  @override
  String get cashFlowsOperating => 'التدفقات النقدية من الأنشطة التشغيلية';

  @override
  String get cashFlowsInvesting => 'التدفقات النقدية من الأنشطة الاستثمارية';

  @override
  String get cashFlowsFinancing => 'التدفقات النقدية من الأنشطة التمويلية';

  @override
  String get netCashOperating => 'صافي النقد من التشغيل';

  @override
  String get netCashInvesting => 'صافي النقد من الاستثمار';

  @override
  String get netCashFinancing => 'صافي النقد من التمويل';

  @override
  String get fraudDetection => 'كشف الاحتيال (M-Score)';

  @override
  String get inputTab => 'الإدخال';

  @override
  String get learnTab => 'تعلّم';

  @override
  String get currentPeriodLabel => 'الفترة الحالية';

  @override
  String get priorPeriod => 'الفترة السابقة';

  @override
  String get componentIndices => 'مؤشرات المكونات';

  @override
  String get redFlagsLabel => 'علامات التحذير';

  @override
  String get whatIsBeneish => 'ما هو مقياس بينيش M-Score؟';

  @override
  String get theFormula => 'الصيغة';

  @override
  String get indexExplanations => 'شرح المؤشرات';

  @override
  String get famousCases => 'حالات شهيرة';

  @override
  String get probableManipulator => 'تلاعب محتمل';

  @override
  String get standardCosting => 'التكاليف المعيارية';

  @override
  String get standardsTab => 'المعايير';

  @override
  String get materialsTab => 'المواد';

  @override
  String get laborTab => 'العمالة';

  @override
  String get overheadTab => 'النفقات العامة';

  @override
  String get importData => 'استيراد بيانات';

  @override
  String get selectFile => 'اختر ملف';

  @override
  String get chooseDataType => 'اختر نوع البيانات';

  @override
  String get mapColumns => 'ربط الأعمدة';

  @override
  String get chooseFile => 'اختر ملف';

  @override
  String get continueBtn => 'متابعة';

  @override
  String get importBtn => 'استيراد';

  @override
  String get backBtn => 'رجوع';

  @override
  String get doneBtn => 'تم';

  @override
  String get selectCsvFile => 'اختر ملف CSV أو Excel للاستيراد.';

  @override
  String get whatDataImporting => 'ما نوع البيانات التي تستوردها؟';

  @override
  String get mapEachColumn => 'ربط كل عمود بحقل:';

  @override
  String get errorsLabel => 'الأخطاء:';

  @override
  String get productsTitle => 'المنتجات';

  @override
  String get newProduct => 'منتج جديد';

  @override
  String get addProductTitle => 'إضافة منتج';

  @override
  String get editProductTitle => 'تعديل منتج';

  @override
  String get saveProduct => 'حفظ المنتج';

  @override
  String get vendorsTitle => 'الموردون';

  @override
  String get addVendorBtn => 'إضافة مورد';

  @override
  String get newVendorForm => 'مورد جديد';

  @override
  String get editVendorForm => 'تعديل مورد';

  @override
  String get vendorCreated => 'تم إنشاء المورد بنجاح';

  @override
  String get vendorUpdated => 'تم تحديث المورد بنجاح';

  @override
  String get vendorDetailTitle => 'المورد';

  @override
  String get customersTitle => 'العملاء';

  @override
  String get addCustomerBtn => 'إضافة عميل';

  @override
  String get newCustomerForm => 'عميل جديد';

  @override
  String get editCustomerForm => 'تعديل عميل';

  @override
  String get customerCreated => 'تم إنشاء العميل بنجاح';

  @override
  String get customerUpdated => 'تم تحديث العميل بنجاح';

  @override
  String get customerDetailTitle => 'العميل';

  @override
  String get putCustomerOnHold => 'تعليق العميل';

  @override
  String get preventsNewInvoices => 'يمنع إنشاء فواتير/طلبات جديدة';

  @override
  String get pleaseAddLineItem =>
      'الرجاء إضافة عنصر واحد على الأقل مع تحديد المبلغ.';

  @override
  String get saveBtn => 'حفظ';

  @override
  String get cancelBtn => 'إلغاء';

  @override
  String get createBtn => 'إنشاء';

  @override
  String get changeBtn => 'تغيير';

  @override
  String get reconcileBtn => 'تسوية';

  @override
  String get statementBalanceLabel => 'رصيد الكشف:';

  @override
  String get bookBalanceLabel => 'الرصيد الدفتري:';

  @override
  String get entryReconciled => 'تمت تسوية القيد';

  @override
  String get staffManagement => 'إدارة الموظفين';

  @override
  String get changeRole => 'تغيير الدور';

  @override
  String get removeAccess => 'إزالة الوصول';

  @override
  String get roleSaved => 'تم حفظ الدور بنجاح!';

  @override
  String get roleNameLabel => 'اسم الدور';

  @override
  String get selectPermission => 'الرجاء اختيار صلاحية واحدة على الأقل.';

  @override
  String get systemAdminReadonly => 'لا يمكن تعديل دور مدير النظام.';

  @override
  String get customFieldsProducts => 'حقول مخصصة (المنتجات)';

  @override
  String get enterDataCalculator =>
      'أدخل بيانات الاستثمار في تبويب الآلة الحاسبة';

  @override
  String get enterDataAnalysis => 'أدخل البيانات لعرض التحليل';

  @override
  String get enterFinancialData => 'أدخل البيانات المالية لعرض النتائج';

  @override
  String get iUnderstand => 'فهمت';

  @override
  String get gotItBtn => 'حسنًا';

  @override
  String get budgetVsActual => 'الميزانية مقابل الفعلي حسب الحساب';

  @override
  String get greenFavorable => 'أخضر = مواتٍ | أحمر = غير مواتٍ';

  @override
  String get budgetComparison => 'مقارنة الميزانية';

  @override
  String get staticBudget => 'الميزانية الثابتة';

  @override
  String get actualCost => 'التكلفة الفعلية';

  @override
  String get varianceAnalysis => 'تحليل الانحرافات';

  @override
  String get volumeVariance => 'انحراف الحجم';

  @override
  String get dueToActivityLevel => 'بسبب اختلاف مستوى النشاط';

  @override
  String get spendingVariance => 'انحراف الإنفاق';

  @override
  String get dueToEfficiency => 'بسبب الكفاءة/السعر';

  @override
  String get totalVariance => 'إجمالي الانحراف';

  @override
  String get actualMinusStatic => 'الفعلي - الميزانية الثابتة';

  @override
  String get separateVariances => 'فصل انحرافات الحجم عن انحرافات الإنفاق';

  @override
  String get formulasUsed => 'الصيغ المستخدمة';

  @override
  String get revenueInput => 'الإيرادات';

  @override
  String get receivablesInput => 'الذمم المدينة';

  @override
  String get grossProfitInput => 'إجمالي الربح';

  @override
  String get totalAssetsInput => 'إجمالي الأصول';

  @override
  String get currentAssetsInput => 'الأصول المتداولة';

  @override
  String get ppeInput => 'الممتلكات والمعدات';

  @override
  String get depreciationInput => 'الاستهلاك';

  @override
  String get sgaExpenseInput => 'مصاريف البيع والإدارة';

  @override
  String get netIncomeInput => 'صافي الدخل';

  @override
  String get cashFromOps => 'النقد من العمليات';

  @override
  String get longTermDebt => 'الديون طويلة الأجل';

  @override
  String get currentLiabilities => 'الالتزامات المتداولة';

  @override
  String get probableManipulatorLabel => 'تلاعب محتمل';

  @override
  String get vendorInvoiceOptional => 'رقم فاتورة المورد (اختياري)';

  @override
  String get customerNameRequired => 'اسم العميل *';

  @override
  String get vendorNameRequired => 'اسم المورد *';

  @override
  String get paymentTermsHint => 'شروط الدفع (مثال: صافي 30)';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get phoneLabel => 'الهاتف';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get addressLabel => 'العنوان';

  @override
  String get notesLabel => 'ملاحظات';

  @override
  String get descriptionLabel => 'الوصف';

  @override
  String get quantityLabel => 'الكمية';

  @override
  String get qtyLabel => 'الكمية';

  @override
  String get dateLabel => 'التاريخ';

  @override
  String get barcode => 'الباركود';

  @override
  String get joinedOrganization => 'تم الانضمام للمنظمة بنجاح!';

  @override
  String get roleNameHint => 'مثال: كاشير أول';

  @override
  String get mapTo => 'ربط بـ';

  @override
  String get addAssetComingSoon => 'ميزة إضافة الأصول قريبًا';

  @override
  String get assetDisposalComingSoon => 'ميزة التخلص من الأصول قريبًا';

  @override
  String get errorLoadingData => 'خطأ في تحميل البيانات';

  @override
  String get errorLoadingBills => 'خطأ في تحميل الفواتير';

  @override
  String get errorLoadingInvoices => 'خطأ في تحميل الفواتير';

  @override
  String get errorSavingRole => 'خطأ في حفظ الدور';

  @override
  String get selectTransactionsToReconcile => 'الرجاء اختيار المعاملات للتسوية';

  @override
  String reconcileAmount(String currency) {
    return 'تسوية $currency';
  }

  @override
  String get enterDataInCalculator =>
      'أدخل البيانات في تبويب الآلة الحاسبة أولاً';

  @override
  String get scenarioColumn => 'السيناريو';

  @override
  String get breakEvenColumn => 'التعادل';

  @override
  String get changeColumn => 'التغيير';

  @override
  String get impactColumn => 'التأثير';

  @override
  String get variableOverhead => 'التكاليف المتغيرة غير المباشرة';

  @override
  String get fixedOverhead => 'التكاليف الثابتة غير المباشرة';

  @override
  String get examplesLabel => 'أمثلة:';

  @override
  String get reconciliation => 'التسوية';

  @override
  String get letsSetUpCorrectly => 'دعنا نقوم بالإعداد بشكل صحيح.';

  @override
  String get addField => 'إضافة حقل';

  @override
  String get editField => 'تعديل حقل';

  @override
  String get editRole => 'تعديل الدور';

  @override
  String get createNewRole => 'إنشاء دور جديد';

  @override
  String get creatingBtn => 'جارِ الإنشاء...';

  @override
  String get allCategories => 'الكل';

  @override
  String inStock(int count) {
    return '$count في المخزون';
  }

  @override
  String cartSummary(int count, String total) {
    return 'السلة: $count منتجات — $total';
  }

  @override
  String get orderSummary => 'ملخص الطلب';

  @override
  String taxLabel(String rate) {
    return 'الضريبة ($rate%)';
  }

  @override
  String get discountLabel => 'الخصم';

  @override
  String get totalUppercase => 'الإجمالي';

  @override
  String get holdOrder => 'تعليق الطلب';

  @override
  String get noProducts => 'لا توجد منتجات';

  @override
  String get searchProducts => 'البحث عن منتجات...';

  @override
  String get outOfStock => 'غير متوفر';

  @override
  String get cartEmpty => 'سلتك فارغة';

  @override
  String get cartEmptyHint => 'اضغط على المنتجات لإضافتها إلى طلبك';

  @override
  String payWith(String method) {
    return 'الدفع بـ $method';
  }

  @override
  String get orderParked => 'تم تعليق الطلب';

  @override
  String get recallOrder => 'استرجاع الطلب';

  @override
  String orderNumber(String id) {
    return 'طلب #$id';
  }

  @override
  String itemsAndTime(int count, int time) {
    return '$count منتجات • منذ $time دقائق';
  }

  @override
  String get closeBtn => 'إغلاق';

  @override
  String get getStarted => 'البدء';

  @override
  String get selectPrimaryCurrency => 'اختر العملة الأساسية';

  @override
  String get currencyCodeLabel => 'الرمز (مثال: YER)';

  @override
  String get currencySymbolLabel => 'العلامة (﷼)';

  @override
  String benchmarkLabel(String value) {
    return 'المؤشر المرجعي: $value';
  }

  @override
  String get breakEvenTab => 'نقطة التعادل';

  @override
  String get marginOfSafetyTab => 'هامش الأمان';

  @override
  String get whatIfTab => 'ماذا لو';

  @override
  String get contributionMarginLabel => 'هامش المساهمة:';

  @override
  String get perUnitSuffix => 'لكل وحدة';

  @override
  String get unitsSuffix => 'وحدة';

  @override
  String get salesRevenueLabel => 'إيرادات المبيعات';

  @override
  String get analyzeViewResults => 'تحليل وعرض النتائج';

  @override
  String get enterDataCalculatorFirst =>
      'أدخل البيانات في تبويب الآلة الحاسبة أولاً';

  @override
  String get unitsLabel => 'الوحدات';

  @override
  String get salesLabel => 'المبيعات';

  @override
  String get contributionMarginTitle => 'هامش المساهمة';

  @override
  String get cmPerUnit => 'هامش المساهمة لكل وحدة';

  @override
  String get cmRatio => 'نسبة هامش المساهمة';

  @override
  String get marginOfSafetyTitle => 'هامش الأمان';

  @override
  String get riskSuffix => 'مخاطرة';

  @override
  String get mosDollar => 'هامش الأمان (\$)';

  @override
  String get mosUnits => 'هامش الأمان (وحدات)';

  @override
  String get impactLabel => 'التأثير';

  @override
  String leverageImpactDesc(String percent) {
    return 'تغيير 1% في المبيعات → تغيير $percent% في الربح';
  }

  @override
  String get priceSensitivityDesc =>
      'يوضح كيف تتغير نقطة التعادل عند تعديل سعر البيع';

  @override
  String get baseImpact => 'أساس';

  @override
  String get betterImpact => 'أفضل';

  @override
  String get worseImpact => 'أسوأ';

  @override
  String get keyInsights => 'رؤى رئيسية';

  @override
  String get projectedProfit => 'ربح متوقع';

  @override
  String get projectedLoss => 'خسارة متوقعة';

  @override
  String strongSafetyMargin(String percent) {
    return 'هامش أمان قوي. يمكن أن تنخفض المبيعات بنسبة $percent% قبل الوصول إلى نقطة التعادل.';
  }

  @override
  String get moderateSafetyMargin =>
      'هامش أمان معتدل. فكر في استراتيجيات لزيادة المبيعات أو تقليل التكاليف.';

  @override
  String get thinSafetyMargin =>
      'هامش أمان ضعيف. الأعمال قريبة من نقطة التعادل ومعرضة لانخفاض المبيعات.';

  @override
  String get belowBreakEven =>
      'تعمل تحت نقطة التعادل. يلزم اتخاذ إجراء فوري لزيادة الإيرادات أو تقليل التكاليف.';

  @override
  String get higherPricesInsight =>
      'أسعار أعلى = نقطة تعادل أقل (وحدات أقل مطلوبة)';

  @override
  String get lowerPricesInsight =>
      'أسعار أقل = نقطة تعادل أعلى (وحدات أكثر مطلوبة)';

  @override
  String priceIncreaseEffect(String units) {
    return 'زيادة السعر 10% تقلل نقطة التعادل بمقدار $units وحدة';
  }

  @override
  String priceDecreaseEffect(String units) {
    return 'انخفاض السعر 10% يزيد نقطة التعادل بمقدار $units وحدة';
  }

  @override
  String get formulaCurrentRatio => 'الأصول المتداولة ÷ الالتزامات المتداولة';

  @override
  String get formulaQuickRatio => '(النقد + المدينون) ÷ الالتزامات المتداولة';

  @override
  String get formulaCashRatio => 'النقد ÷ الالتزامات المتداولة';

  @override
  String get formulaWorkingCapital => 'الأصول المتداولة - الالتزامات المتداولة';

  @override
  String get formulaInventoryTurnover =>
      'تكلفة البضاعة المباعة ÷ متوسط المخزون';

  @override
  String get formulaDaysSalesInInventory => '365 ÷ معدل دوران المخزون';

  @override
  String get formulaReceivablesTurnover => 'صافي المبيعات ÷ متوسط المدينين';

  @override
  String get formulaDaysSalesOutstanding => '365 ÷ معدل دوران المدينين';

  @override
  String get formulaCashConversionCycle =>
      'أيام المخزون + أيام المدينين - أيام الدائنين';

  @override
  String get formulaAssetTurnover => 'صافي المبيعات ÷ متوسط إجمالي الأصول';

  @override
  String get formulaGrossProfitMargin =>
      '(الإيرادات - تكلفة البضاعة) ÷ الإيرادات';

  @override
  String get formulaOperatingProfitMargin => 'الدخل التشغيلي ÷ الإيرادات';

  @override
  String get formulaNetProfitMargin => 'صافي الدخل ÷ الإيرادات';

  @override
  String get formulaReturnOnAssets => 'صافي الدخل ÷ متوسط إجمالي الأصول';

  @override
  String get formulaReturnOnEquity => 'صافي الدخل ÷ متوسط حقوق الملكية';

  @override
  String get formulaEbitdaMargin =>
      'الأرباح قبل الفوائد والضرائب والاستهلاك ÷ الإيرادات';

  @override
  String get formulaDebtToEquity => 'إجمالي الالتزامات ÷ حقوق المساهمين';

  @override
  String get formulaDebtToAssets => 'إجمالي الالتزامات ÷ إجمالي الأصول';

  @override
  String get formulaEquityMultiplier => 'إجمالي الأصول ÷ حقوق المساهمين';

  @override
  String get formulaInterestCoverage =>
      'الأرباح قبل الفوائد والضرائب ÷ مصروف الفوائد';

  @override
  String get formulaTimesInterestEarned =>
      '(صافي الدخل + الفوائد + الضرائب) ÷ الفوائد';

  @override
  String get notAvailable => 'غ/م';

  @override
  String get daysSuffix => 'يوم';

  @override
  String get standardCostCard => 'بطاقة التكلفة المعيارية';

  @override
  String get materialQtyUnit => 'كمية المواد/الوحدة';

  @override
  String get materialPrice => 'سعر المواد';

  @override
  String get laborHoursUnit => 'ساعات العمل/الوحدة';

  @override
  String get laborRate => 'معدل الأجور';

  @override
  String get vohRate => 'معدل التكاليف المتغيرة غير المباشرة';

  @override
  String get budgetedFoh => 'التكاليف الثابتة غير المباشرة المخططة';

  @override
  String get normalCapacity => 'الطاقة العادية';

  @override
  String get actualProduction => 'الإنتاج الفعلي';

  @override
  String get unitsProduced => 'الوحدات المنتجة';

  @override
  String get materialUsed => 'المواد المستخدمة';

  @override
  String get laborHours => 'ساعات العمل';

  @override
  String get actualVoh => 'التكاليف المتغيرة غير المباشرة الفعلية';

  @override
  String get actualFoh => 'التكاليف الثابتة غير المباشرة الفعلية';

  @override
  String totalVarianceAmount(String amount) {
    return 'إجمالي الانحراف: $amount';
  }

  @override
  String get netFavorable => 'صافي ملائم';

  @override
  String get netUnfavorable => 'صافي غير ملائم';

  @override
  String get directMaterialsVariance => 'انحراف المواد المباشرة';

  @override
  String get standardCost => 'التكلفة المعيارية';

  @override
  String get actualCostLabel => 'التكلفة الفعلية';

  @override
  String get varianceBreakdown => 'تحليل الانحرافات';

  @override
  String get priceVariance => 'انحراف السعر';

  @override
  String get priceVarianceFormula =>
      '(السعر الفعلي - المعياري) × الكمية الفعلية';

  @override
  String get quantityVariance => 'انحراف الكمية';

  @override
  String get quantityVarianceFormula =>
      '(الكمية الفعلية - المعيارية) × السعر المعياري';

  @override
  String get materialsFormulas => 'معادلات المواد';

  @override
  String get priceVarianceFormulaFull =>
      'انحراف السعر = (السعر الفعلي - المعياري) × الكمية الفعلية';

  @override
  String get quantityVarianceFormulaFull =>
      'انحراف الكمية = (الكمية الفعلية - المعيارية) × السعر المعياري';

  @override
  String get directLaborVariance => 'انحراف العمالة المباشرة';

  @override
  String get rateVariance => 'انحراف المعدل';

  @override
  String get rateVarianceFormula =>
      '(المعدل الفعلي - المعياري) × الساعات الفعلية';

  @override
  String get efficiencyVariance => 'انحراف الكفاءة';

  @override
  String get efficiencyVarianceFormula =>
      '(الساعات الفعلية - المعيارية) × المعدل المعياري';

  @override
  String get laborFormulas => 'معادلات العمالة';

  @override
  String get rateVarianceFormulaFull =>
      'انحراف المعدل = (المعدل الفعلي - المعياري) × الساعات الفعلية';

  @override
  String get efficiencyVarianceFormulaFull =>
      'انحراف الكفاءة = (الساعات الفعلية - المعيارية) × المعدل المعياري';

  @override
  String get manufacturingOverheadVariance =>
      'انحراف التكاليف الصناعية غير المباشرة';

  @override
  String get appliedOverhead => 'التكاليف غير المباشرة المحملة';

  @override
  String get actualOverhead => 'التكاليف غير المباشرة الفعلية';

  @override
  String get overapplied => 'محملة بالزيادة';

  @override
  String get underapplied => 'محملة بالنقص';

  @override
  String get budgetVariance => 'انحراف الموازنة';

  @override
  String get actualFohMinusBudgeted => 'الفعلية - المخططة';

  @override
  String get budgetedFohMinusApplied => 'المخططة - المحملة';

  @override
  String get actualVohFormula => 'الفعلية - (الساعات × المعدل)';

  @override
  String get unitSuffix => 'وحدة';

  @override
  String get dollarPerUnit => '\$/وحدة';

  @override
  String get hrsSuffix => 'ساعة';

  @override
  String get dollarPerHr => '\$/ساعة';

  @override
  String get favorableBadge => 'م';

  @override
  String get unfavorableBadge => 'غ';

  @override
  String mScoreValue(String value) {
    return 'M-Score: $value';
  }

  @override
  String riskLevelLabel(String level) {
    return 'مخاطرة $level';
  }

  @override
  String riskOfEarningsManipulation(String level) {
    return 'مخاطرة $level للتلاعب بالأرباح';
  }

  @override
  String get thresholdNote => 'الحد: > -1.78 يشير إلى تلاعب';

  @override
  String get dsriAbbr => 'DSRI';

  @override
  String get dsriDesc => 'المدينين/المبيعات';

  @override
  String get gmiAbbr => 'GMI';

  @override
  String get gmiDesc => 'هامش الربح الإجمالي';

  @override
  String get aqiAbbr => 'AQI';

  @override
  String get aqiDesc => 'جودة الأصول';

  @override
  String get sgiAbbr => 'SGI';

  @override
  String get sgiDesc => 'نمو المبيعات';

  @override
  String get depiAbbr => 'DEPI';

  @override
  String get depiDesc => 'الاستهلاك';

  @override
  String get sgaiAbbr => 'SGAI';

  @override
  String get sgaiDesc => 'المصاريف الإدارية والعمومية';

  @override
  String get tataAbbr => 'TATA';

  @override
  String get tataDesc => 'المستحقات';

  @override
  String get lvgiAbbr => 'LVGI';

  @override
  String get lvgiDesc => 'الرافعة المالية';

  @override
  String redFlagsCount(int count) {
    return 'علامات تحذيرية ($count)';
  }

  @override
  String get whatIsBeneishMScore => 'ما هو نموذج بينيش M-Score؟';

  @override
  String get beneishDescription =>
      'نموذج M-Score هو نموذج رياضي يستخدم 8 نسب مالية لتحديد ما إذا كانت الشركة قد تلاعبت بأرباحها. طوره البروفيسور ميسود بينيش، ويستخدم على نطاق واسع من قبل المراجعين والمستثمرين والمحللين.';

  @override
  String get beneishFormula =>
      'M = -4.84 + 0.92×DSRI + 0.528×GMI\n+ 0.404×AQI + 0.892×SGI\n+ 0.115×DEPI - 0.172×SGAI\n+ 4.679×TATA - 0.327×LVGI';

  @override
  String get indexExplanationsTitle => 'شرح المؤشرات';

  @override
  String get dsriFullName => 'مؤشر أيام المبيعات في المدينين';

  @override
  String get dsriExplanation =>
      'يقيس ما إذا كانت المدينين نمت أسرع من المبيعات';

  @override
  String get gmiFullName => 'مؤشر هامش الربح الإجمالي';

  @override
  String get gmiExplanation => 'يكشف تدهور هوامش الربح الإجمالي';

  @override
  String get aqiFullName => 'مؤشر جودة الأصول';

  @override
  String get aqiExplanation => 'يحدد رسملة المصروفات';

  @override
  String get sgiFullName => 'مؤشر نمو المبيعات';

  @override
  String get sgiExplanation => 'النمو العالي يخلق ضغطاً للتلاعب';

  @override
  String get depiFullName => 'مؤشر الاستهلاك';

  @override
  String get depiExplanation => 'يكشف تباطؤ معدلات الاستهلاك';

  @override
  String get sgaiFullName => 'مؤشر المصاريف الإدارية';

  @override
  String get sgaiExplanation => 'يقيس الكفاءة الإدارية';

  @override
  String get tataFullName => 'إجمالي المستحقات إلى إجمالي الأصول';

  @override
  String get tataExplanation => 'مستحقات عالية مقابل النقد = جودة منخفضة';

  @override
  String get lvgiFullName => 'Leverage Index';

  @override
  String get lvgiExplanation => 'زيادة الديون تخلق ضغطاً';

  @override
  String get famousCasesTitle => 'حالات شهيرة';

  @override
  String get famousCasesContent =>
      '• إنرون (2001): كان سيكون لديها M-Score > -1.78\n• وورلدكوم (2002): أظهرت علامات تحذيرية متعددة\n• ساتيام (2009): كانت DSRI و AQI متطرفة\n• النموذج يحدد بشكل صحيح ~76% من المتلاعبين';

  @override
  String yearLabel(int number) {
    return 'السنة $number';
  }

  @override
  String pvOfCashFlows(String value) {
    return 'القيمة الحالية للتدفقات: $value';
  }

  @override
  String initialInvestmentDetail(String value) {
    return 'الاستثمار الأولي: $value';
  }

  @override
  String discountRateDetail(String value) {
    return 'معدل الخصم: $value';
  }

  @override
  String convergedLabel(String value) {
    return 'التقارب: $value';
  }

  @override
  String iterationsLabel(int value) {
    return 'التكرارات: $value';
  }

  @override
  String averageInvestment(String value) {
    return 'متوسط الاستثمار: $value';
  }

  @override
  String get acceptLabel => 'قبول';

  @override
  String get rejectLabel => 'رفض';

  @override
  String recommendationLabel(String value) {
    return 'التوصية: $value';
  }

  @override
  String criteriaMetLabel(int count) {
    return '$count من 4 معايير مستوفاة';
  }

  @override
  String get npvSensitivityDesc =>
      'يوضح كيف يتغير صافي القيمة الحالية مع تغير معدل الخصم';

  @override
  String irrApproxLabel(String min, String max) {
    return 'معدل العائد الداخلي (حيث صافي القيمة الحالية = 0) هو تقريباً $min% - $max%';
  }

  @override
  String get revenueSection => 'الإيرادات';

  @override
  String get expensesSection => 'المصروفات';

  @override
  String get formulasDescription =>
      '• الموازنة الثابتة = التكاليف الثابتة + (المتغيرة × النشاط المخطط)\n• الموازنة المرنة = التكاليف الثابتة + (المتغيرة × النشاط الفعلي)\n• انحراف الحجم = الموازنة المرنة - الموازنة الثابتة\n• انحراف الإنفاق = التكلفة الفعلية - الموازنة المرنة';

  @override
  String get addExchangeRate => 'إضافة سعر صرف';

  @override
  String get fromCurrency => 'من عملة';

  @override
  String get toCurrency => 'إلى عملة';

  @override
  String get pleaseEnterCurrency => 'الرجاء تحديد العملة';

  @override
  String get exchangeRateHelper => '1 من = X إلى';

  @override
  String get pleaseEnterValidRate => 'مطلوب سعر صحيح';

  @override
  String get accountCurrency => 'العملة';

  @override
  String get initialBalances => 'الأرصدة الافتتاحية';

  @override
  String get debitBalance => 'رصيد مدين';

  @override
  String get creditBalance => 'رصيد دائن';

  @override
  String get netBalance => 'صافي الرصيد';

  @override
  String get exchangeRates => 'أسعار الصرف';

  @override
  String get noExchangeRates => 'لم تتم إضافة أسعار صرف';

  @override
  String get saveAccount => 'حفظ الحساب';

  @override
  String get password => 'كلمة المرور';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟ تسجيل الدخول';

  @override
  String get needAccount => 'ليس لديك حساب؟ إنشاء حساب';

  @override
  String get enterEmailAndPassword =>
      'يرجى إدخال البريد الإلكتروني وكلمة المرور.';

  @override
  String get signUpSubtitle => 'قم بالتسجيل لإنشاء نشاطك التجاري';

  @override
  String get orSeparator => 'أو';

  @override
  String get paidFeatureTitle => 'ميزة مدفوعة';

  @override
  String get paidFeatureMessage =>
      'هذه الميزة تتطلب اشتراكاً نشطاً وتسجيل دخول. يرجى تسجيل الدخول والاشتراك للوصول إلى إدارة الموظفين والأدوار.';

  @override
  String get signInToAccess => 'تسجيل الدخول';

  @override
  String get nameIsRequired => 'الاسم مطلوب';

  @override
  String get permissionsLabel => 'الصلاحيات';

  @override
  String get permViewDashboard => 'عرض لوحة التحكم';

  @override
  String get permViewFinancialReports => 'عرض التقارير المالية';

  @override
  String get permPerformSale => 'إجراء المبيعات (نقطة البيع)';

  @override
  String get permVoidTransaction => 'إلغاء/حذف المعاملات';

  @override
  String get permProcessRefund => 'معالجة المسترجعات';

  @override
  String get permViewSalesHistory => 'عرض سجل المبيعات';

  @override
  String get permViewInventory => 'عرض المخزون';

  @override
  String get permManageProducts => 'إضافة/تعديل المنتجات';

  @override
  String get permAdjustInventory => 'تعديل المخزون';

  @override
  String get permManageStaff => 'إدارة الموظفين والأدوار';

  @override
  String get permManageSettings => 'إعدادات النظام';

  @override
  String get permSwitchTenant => 'تبديل فرع النشاط التجاري';

  @override
  String get manageSubscription => 'إدارة الاشتراك';

  @override
  String get availablePlans => 'الخطط المتاحة';

  @override
  String get enterpriseMonthlyPlan => 'خطة المؤسسات (شهري)';

  @override
  String get enterpriseMonthlyPrice => '30دولار / شهرياً';

  @override
  String get freeTierPlan => 'الخطة المجانية';

  @override
  String get freeTierPrice => 'مجاناً للأبد';

  @override
  String get featureCloudSync => 'مزامنة سحابية';

  @override
  String get featureMultiUser => 'متعدد المستخدمين';

  @override
  String get featureWebAccess => 'وصول عبر الإنترنت';

  @override
  String get featureLocalOnly => 'محلي فقط';

  @override
  String get featureManualBackup => 'نسخ احتياطي يدوي';

  @override
  String get currentPlanLabel => 'الخطة الحالية';

  @override
  String planStatusLabel(String status) {
    return 'الحالة: $status';
  }

  @override
  String planRenewsLabel(String date) {
    return 'التجديد: $date';
  }

  @override
  String get planNeverExpires => 'لا ينتهي';

  @override
  String get buyButton => 'شراء';

  @override
  String get subscriptionUnavailable =>
      'الاشتراكات غير متاحة دون اتصال بالإنترنت. يرجى تسجيل الدخول لإدارة اشتراكك.';

  @override
  String get confirmMockPurchase => 'تأكيد الشراء';

  @override
  String simulatePaymentFor(String planName) {
    return 'محاكاة الدفع لـ $planName؟';
  }

  @override
  String get payNowMock => 'دفع الآن (تجريبي)';

  @override
  String get mockPaymentSuccess => '✅ تم الدفع بنجاح!';

  @override
  String get noStaffFound => 'No staff found. Invite someone!';

  @override
  String get ownerRole => 'Owner';

  @override
  String staffRoleAndEmail(String roleId, String email) {
    return 'Role: $roleId • $email';
  }

  @override
  String removeStaffTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get removeStaffWarning =>
      'They will lose access to this business immediately.';

  @override
  String get inviteStaff => 'Invite Staff';

  @override
  String get stepSelectRole => '1. Select a Role';

  @override
  String get chooseRoleHint => 'Choose Role (e.g. Cashier)';

  @override
  String errorLoadingRoles(String error) {
    return 'Error loading roles: $error';
  }

  @override
  String get generateInviteCode => 'Generate Invite Code';

  @override
  String get stepShareCode => '2. Share Code';

  @override
  String get validFor24Hours => 'Valid for 24 hours';

  @override
  String get shareViaApp => 'Share via WhatsApp / Telegram';

  @override
  String inviteShareText(String code) {
    return 'Join my business on Mizan!\n\n1. Download the App\n2. Sign In\n3. Select \'Join Business\' and enter code: $code\n\n(Valid for 24 hours)';
  }

  @override
  String get validInviteCodeTitle => 'Valid Invite Code!';

  @override
  String roleLabel(String roleId) {
    return 'Role: $roleId';
  }

  @override
  String get pleaseEnterYourName => 'Please enter your name';

  @override
  String get orText => 'or';

  @override
  String appVersion(String version) {
    return 'Mizan App v$version';
  }

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get requiredField => 'هذا الحقل مطلوب';

  @override
  String get category => 'Category';

  @override
  String get redFlags => 'Red Flags';

  @override
  String get dsriDescription => 'Receivables/Sales';

  @override
  String get gmiDescription => 'Gross Margin';

  @override
  String get aqiDescription => 'Asset Quality';

  @override
  String get sgiDescription => 'Sales Growth';

  @override
  String get depiDescription => 'Depreciation';

  @override
  String get sgaiDescription => 'SG&A Expenses';

  @override
  String get tataDescription => 'Accruals';

  @override
  String get lvgiDescription => 'Leverage';

  @override
  String get whatIsMScore => 'What is the Beneish M-Score?';

  @override
  String get mScoreDescription =>
      'The M-Score is a mathematical model created by Professor Messod Beneish that uses financial ratios to detect whether a company has manipulated its earnings.\n\nAn M-Score greater than -1.78 suggests a HIGH probability (76%) that the company is an earnings manipulator.';

  @override
  String get dsriName => 'Days Sales in Receivables Index';

  @override
  String get dsriExpl => 'Measures if receivables grew faster than sales';

  @override
  String get gmiName => 'Gross Margin Index';

  @override
  String get gmiExpl => 'Detects deteriorating gross margins';

  @override
  String get aqiName => 'Asset Quality Index';

  @override
  String get aqiExpl => 'Identifies expense capitalization';

  @override
  String get sgiName => 'Sales Growth Index';

  @override
  String get sgiExpl => 'High growth creates manipulation pressure';

  @override
  String get depiName => 'Depreciation Index';

  @override
  String get depiExpl => 'Detects slowing depreciation rates';

  @override
  String get sgaiName => 'SG&A Index';

  @override
  String get sgaiExpl => 'Measures administrative efficiency';

  @override
  String get tataName => 'Total Accruals to Total Assets';

  @override
  String get tataExpl => 'High accruals vs cash = low quality';

  @override
  String get lvgiName => 'Leverage Index';

  @override
  String get lvgiExpl => 'Increasing debt creates pressure';

  @override
  String get famousCasesDesc =>
      '• Enron (2001): Would have had M-Score > -1.78\n• WorldCom (2002): High TATA due to expense capitalization\n• Satyam (2009): High DSRI from fictitious receivables\n\nThe M-Score correctly identified 76% of manipulators in backtesting studies.';

  @override
  String get mScoreThresholdLabel =>
      'Threshold: > -1.78 indicates manipulation';

  @override
  String get riskLevelHigh => 'HIGH';

  @override
  String get riskLevelModerate => 'MODERATE';

  @override
  String get riskLevelLow => 'LOW';

  @override
  String get unitsLowercase => 'units';

  @override
  String get flexibleBudgetResult => 'Flexible Budget';

  @override
  String get varianceFormulas =>
      '• Static Budget = Fixed + (Variable × Planned Activity)\n• Flexible Budget = Fixed + (Variable × Actual Activity)\n• Volume Variance = Flexible - Static\n• Spending Variance = Actual - Flexible';

  @override
  String get materialQtyPerUnit => 'Material Qty/Unit';

  @override
  String get laborHoursPerUnit => 'Labor Hours/Unit';

  @override
  String get perHrSuffix => '\$/hr';

  @override
  String totalVarianceValue(String amount) {
    return 'Total Variance: $amount';
  }

  @override
  String get actualCostResult => 'Actual Cost';

  @override
  String get priceVarianceResult => 'Price Variance';

  @override
  String get quantityVarianceResult => 'Quantity Variance';

  @override
  String get materialsFormulasTitle => 'Materials Formulas';

  @override
  String get materialsFormulasDesc =>
      '• Price Variance = (Actual Price - Standard Price) × Actual Qty\n• Quantity Variance = (Actual Qty - Standard Qty) × Standard Price';

  @override
  String get rateVarianceResult => 'Rate Variance';

  @override
  String get efficiencyVarianceResult => 'Efficiency Variance';

  @override
  String get laborFormulasTitle => 'Labor Formulas';

  @override
  String get laborFormulasDesc =>
      '• Rate Variance = (Actual Rate - Standard Rate) × Actual Hours\n• Efficiency Variance = (Actual Hours - Std Hours) × Std Rate';

  @override
  String get currentRatioTitle => 'Current Ratio';

  @override
  String get debtEquityTitle => 'Debt/Equity';

  @override
  String get netMarginTitle => 'Net Margin';

  @override
  String get roaTitle => 'ROA';

  @override
  String get ratioCol => 'Ratio';

  @override
  String get valueCol => 'Value';

  @override
  String get benchmarkCol => 'Benchmark';

  @override
  String get statusCol => 'Status';

  @override
  String get descriptionCol => 'الوصف';

  @override
  String get totalVarianceLabel => 'إجمالي الانحراف';

  @override
  String get enterpriseLicenseActive => 'رخصة المؤسسة نشطة';

  @override
  String get systemAdministrator => 'أنت مسؤول النظام';

  @override
  String get defineStaffPermissions => 'تحديد صلاحيات الموظفين';

  @override
  String get viewPlansBilling => 'عرض الخطط والفواتير';

  @override
  String get manageStaff => 'إدارة الموظفين';

  @override
  String get viewListInviteMembers => 'عرض القائمة ودعوة الأعضاء';

  @override
  String get activateBusinessLicense => 'تفعيل رخصة العمل';

  @override
  String get initializeSystemClaimOwnership =>
      'تهيئة النظام والمطالبة بالملكية';

  @override
  String get notLoggedInWarning =>
      '⚠️ أنت غير مسجل الدخول! الرجاء تسجيل الدخول أولاً.';

  @override
  String get systemActivatedWelcome =>
      '✅ تم تفعيل النظام! مرحباً بك، أيها المسؤول.';

  @override
  String activationFailed(String error) {
    return '❌ فشل التفعيل: $error';
  }

  @override
  String get premiumReportWarning =>
      '🔒 تقرير مميز. قم بالترقية إلى Pro أو Enterprise.';

  @override
  String buyReportPrompt(String reportTitle) {
    return 'شراء \'\'$reportTitle\'\' مقابل \$4.99؟';
  }

  @override
  String get buyNowAction => 'Buy Now';

  @override
  String installedSuccessfully(String reportTitle) {
    return '✅ Installed $reportTitle';
  }

  @override
  String get noStandardReportsFound => 'No standard reports found online.';

  @override
  String get installAction => 'Install';

  @override
  String get includedAction => 'Included';

  @override
  String get buyPriceAction => 'Buy \$4.99';

  @override
  String get lockedAction => 'Locked';

  @override
  String get retailBusinessTemplate => 'Retail Business';

  @override
  String get serviceBusinessTemplate => 'Service Business';

  @override
  String get customersAr => 'العملاء (AR)';

  @override
  String get vendorsAp => 'الموردين (AP)';

  @override
  String get openingBalanceHint =>
      'الرصيد الافتتاحي. أدخل 0 إذا لم يكن هناك رصيد.';

  @override
  String get openingBalanceHintVendor =>
      'الرصيد الافتتاحي. أدخل 0 إذا لم يكن هناك رصيد.';

  @override
  String get emailOptional => 'البريد الإلكتروني (اختياري)';

  @override
  String get phoneOptional => 'الهاتف (اختياري)';

  @override
  String get addressOptional => 'العنوان (اختياري)';

  @override
  String get taxIdOptional => 'الرقم الضريبي (اختياري)';

  @override
  String get paymentTermsOptional => 'شروط الدفع (اختياري)';

  @override
  String get creditLimitOptional => 'الحد الائتماني (اختياري)';

  @override
  String get notesOptional => 'ملاحظات (اختياري)';

  @override
  String get searchCustomers => 'البحث عن العملاء...';

  @override
  String get searchVendors => 'البحث عن الموردين...';

  @override
  String get customerDetails => 'تفاصيل العميل';

  @override
  String get vendorDetails => 'تفاصيل المورد';

  @override
  String get contactInfo => 'معلومات الاتصال';

  @override
  String get noAddressProvided => 'لم يتم توفير عنوان';

  @override
  String get noEmailProvided => 'لم يتم توفير بريد إلكتروني';

  @override
  String get noPhoneProvided => 'لم يتم توفير هاتف';

  @override
  String get noTaxIdProvided => 'لم يتم توفير رقم ضريبي';

  @override
  String get noNotesProvided => 'لا توجد ملاحظات';

  @override
  String get noPaymentTermsProvided => 'لم يتم توفير شروط دفع';

  @override
  String get financialOverview => 'نظرة مالية عامة';

  @override
  String get currentBalance => 'الرصيد الحالي';

  @override
  String get totalInvoiced => 'إجمالي الفواتير';

  @override
  String get totalPaid => 'إجمالي المدفوعات';

  @override
  String get recentInvoices => 'أحدث الفواتير';

  @override
  String get recentBills => 'أحدث فواتير المشتريات';

  @override
  String get noRecentInvoices => 'لا توجد فواتير حديثة.';

  @override
  String get noRecentBills => 'لا توجد فواتير مشتريات حديثة.';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get actions => 'الإجراءات';

  @override
  String get receivePayment => 'استلام دفعة';

  @override
  String get statement => 'كشف حساب';

  @override
  String get edit => 'تعديل';

  @override
  String get status => 'الحالة';

  @override
  String get unpaid => 'غير مدفوعة';

  @override
  String get partiallyPaid => 'مدفوعة جزئياً';

  @override
  String get vendor => 'مورد';

  @override
  String get addFirstCustomer => 'اضغط على الزر أدناه لإضافة أول عميل';

  @override
  String get noCustomersMatch => 'لا يوجد عملاء يطابقون بحثك.';

  @override
  String get customerBalances => 'أرصدة العملاء';

  @override
  String get contact => 'جهة الاتصال';

  @override
  String get addFirstVendor => 'اضغط على الزر أدناه لإضافة أول مورد';

  @override
  String get noVendorsMatch => 'لا يوجد موردين يطابقون بحثك.';

  @override
  String get vendorBalances => 'أرصدة الموردين';

  @override
  String get outstandingBalance => 'الرصيد المعلق';

  @override
  String get quickLedgerAdjustment => 'تعديل سريع للرصيد';

  @override
  String get creating => 'جاري الإنشاء...';

  @override
  String get qty => 'الكمية';

  @override
  String get pleaseAddLineItemBill =>
      'الرجاء إضافة عنصر واحد على الأقل مع تحديد المبلغ.';

  @override
  String get vendorInvoiceNumberOptional => 'رقم فاتورة المورد (اختياري)';

  @override
  String get current0To30 => 'حالي\n(0-30)';

  @override
  String get days31To60 => '31-60\nيوم';

  @override
  String get days61To90 => '61-90\nيوم';

  @override
  String get days90Plus => '90+\nيوم';

  @override
  String get days31To60Short => '31-60';

  @override
  String get days61To90Short => '61-90';

  @override
  String get days90PlusShort => '90+';

  @override
  String adjustBalance(String name) {
    return 'تعديل الرصيد: $name';
  }

  @override
  String get charge => 'زيادة الدين (+)';

  @override
  String get receive => 'استلام دفعة (-)';

  @override
  String get increasesDebt => 'يزيد من دينهم لك';

  @override
  String get decreasesDebt => 'يقلل من دينهم (يُضاف إلى النقدية)';

  @override
  String get saveAdjustment => 'حفظ التعديل';
}
