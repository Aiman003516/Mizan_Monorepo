// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get allReportsAndTools => 'All Reports & Tools';

  @override
  String get businessInsights => 'Business Insights';

  @override
  String get setupBusinessCloud => 'Setup Business Cloud';

  @override
  String get manageRoles => 'Manage roles';

  @override
  String get settings => 'Settings';

  @override
  String get accountTypeAsset => 'Asset';

  @override
  String get accountTypeLiability => 'Liability';

  @override
  String get accountTypeEquity => 'Equity';

  @override
  String get accountTypeRevenue => 'Revenue';

  @override
  String get accountTypeExpense => 'Expense';

  @override
  String get mainDashboard => 'Main Dashboard';

  @override
  String get newSalePOS => 'New Sale / POS';

  @override
  String get reports => 'Reports';

  @override
  String get saving => 'Saving';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get management => 'Management';

  @override
  String get accounts => 'Accounts';

  @override
  String get products => 'Products';

  @override
  String get categories => 'Categories';

  @override
  String get totalAmountsReport => 'Total Amounts Report';

  @override
  String get monthlyAmountsReport => 'Monthly Amounts Report';

  @override
  String get accountActivity => 'Account Activity';

  @override
  String get manageAccounts => 'Manage Accounts';

  @override
  String get manageProducts => 'Manage Products';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get general => 'General';

  @override
  String get clients => 'Clients';

  @override
  String get suppliers => 'Suppliers';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get noAccountsYet => 'No accounts yet. \nAdd one!';

  @override
  String noResultsFound(String query) {
    return 'No results found for \"$query\".';
  }

  @override
  String get type => 'Type:';

  @override
  String get balance => 'Balance';

  @override
  String get phone => 'Phone';

  @override
  String get errorLoadingAccounts => 'Error loading accounts';

  @override
  String get errorLoadingBalances => 'Error loading balances:';

  @override
  String get addNewAccount => 'Add New Account';

  @override
  String get editAccount => 'Edit Account';

  @override
  String get accountNameHint => 'Account Name (e.g., \"Cash\", \"Customer A\")';

  @override
  String get pleaseEnterName => 'Please enter your name';

  @override
  String get accountType => 'Account Type';

  @override
  String get classificationOptional => 'Classification (Optional)';

  @override
  String get errorLoadingClassifications => 'Error loading classifications:';

  @override
  String get phoneNumberOptional => 'Phone Number (Optional)';

  @override
  String get initialBalance => 'Initial Balance';

  @override
  String get pleaseEnterBalance => 'Please enter a balance (0 is okay)';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get invalidPhone => 'Please enter a valid phone number';

  @override
  String get invalidCurrencyCode => 'Use 3-5 uppercase letters';

  @override
  String get mustBeNonNegative => 'Please enter a non-negative number';

  @override
  String get mustBePositive => 'Please enter a number greater than zero';

  @override
  String get failedToSaveAccount => 'Failed to save account:';

  @override
  String get addAccount => 'Add Account';

  @override
  String noAccountsClassified(String classification) {
    return 'No accounts classified as \"$classification\" yet.\nAdd one in the Accounts section.';
  }

  @override
  String get exportToPDF => 'Export to PDF';

  @override
  String get export => 'Export';

  @override
  String get exportToExcel => 'Export to Excel';

  @override
  String get excelExportSuccess => 'Excel export successfully generated.';

  @override
  String accountBalances(String classification) {
    return 'Account Balances - $classification';
  }

  @override
  String get errorLoadingSummaries => 'Error loading summaries:';

  @override
  String get addNewTransaction => 'Add New Transaction';

  @override
  String get signIn => 'Sign In';

  @override
  String get welcomeToMizan => 'Welcome to Mizan';

  @override
  String get signInToSync => 'Sign in to sync your data';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get offlineUnavailable => 'Offline: Sync is unavailable';

  @override
  String get online => 'Online';

  @override
  String get syncData => 'Sync Data';

  @override
  String get syncNotImplemented => 'Sync not implemented yet.';

  @override
  String get signOut => 'Sign Out';

  @override
  String get search => 'Search...';

  @override
  String get openNavigationMenu => 'Open navigation menu';

  @override
  String get mizan => 'Mizan';

  @override
  String get mizanDashboard => 'Mizan Dashboard';

  @override
  String get mizanUser => 'Mizan User';

  @override
  String get notSignedIn => 'Not Signed In';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get syncDisabled => 'Sync is disabled';

  @override
  String get totalAmountsSummary => 'Total Amounts (Summary)';

  @override
  String get monthlyAmountsSummary => 'Monthly Amounts (Summary)';

  @override
  String get accountActivityLedger => 'Account Activity / Ledger';

  @override
  String get dataSafetyWarning => 'Data Safety Warning';

  @override
  String get dataSafetyMessage =>
      'Your data is currently stored only on this device.\nTo prevent data loss, please sign in to enable cloud backup.';

  @override
  String get ok => 'OK';

  @override
  String get addNewProduct => 'Add New Product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get failedToSaveProduct => 'Failed to save product:';

  @override
  String get selectCategory => 'Select a Category';

  @override
  String errorLoadingCategories(String error) {
    return 'Error loading categories:';
  }

  @override
  String get productName => 'Product Name';

  @override
  String get price => 'Price';

  @override
  String get pleaseEnterPrice => 'Please enter a price';

  @override
  String get noProductsSaved => 'No products saved.\nTap \"+\" to add one.';

  @override
  String get priceLabel => 'Price';

  @override
  String get newCategory => 'New Category';

  @override
  String get categoryName => 'Category Name';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get noCategoriesYet => 'No categories yet.\nAdd one!';

  @override
  String get addCategory => 'Add Category';

  @override
  String get noProductsYet => 'No products yet.\nAdd one!';

  @override
  String get error => 'Error:';

  @override
  String get all => 'All';

  @override
  String get posSales => 'POS Sales';

  @override
  String get noTransactionEntries =>
      'No transaction entries recorded for this filter.';

  @override
  String get date => 'Date';

  @override
  String get account => 'Account';

  @override
  String get description => 'Description';

  @override
  String get debit => 'Debit';

  @override
  String get credit => 'Credit';

  @override
  String get currency => 'Currency';

  @override
  String monthlyAmounts(String classification) {
    return 'Monthly Amounts - $classification';
  }

  @override
  String get noMonthlyTotals => 'No monthly totals to display for this filter.';

  @override
  String get month => 'Month';

  @override
  String get currencyLabel => 'Currency';

  @override
  String totalAmounts(String classification) {
    return 'Total Amounts - $classification';
  }

  @override
  String get noTotals => 'No totals to display for this filter.';

  @override
  String get name => 'Name';

  @override
  String get totalClassifications => 'Total Classifications';

  @override
  String get noClassificationTotals => 'No classification totals to display.';

  @override
  String get classification => 'Classification';

  @override
  String get total => 'Total';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String get unlockMizanPro => 'Unlock Mizan Pro';

  @override
  String get proPrice => 'Get the \nfull version for a one-time payment of';

  @override
  String get proFeatures =>
      'This includes unlimited access to all features, cloud sync, and future updates.';

  @override
  String get purchaseFullVersion => 'Purchase Full Version';

  @override
  String get couldNotOpenPurchasePage => 'Could not open purchase page.';

  @override
  String get companyProfile => 'Personal & Company Data';

  @override
  String get companyProfileReportHint =>
      'This information may be used on printed reports and invoices.';

  @override
  String get companyName => 'Company Name';

  @override
  String get pleaseEnterCompanyName => 'Please enter a company name';

  @override
  String get yourName => 'Your Name';

  @override
  String get companyAddress => 'Company Address';

  @override
  String get taxID => 'Tax ID / VAT Number';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get profileSavedSuccess => 'Profile saved successfully.';

  @override
  String get failedToSaveProfile => 'Failed to save profile:';

  @override
  String get currencyOptions => 'Currency Options';

  @override
  String get noCurrenciesFound =>
      'No currencies \nfound. Tap \"+\" to add one.';

  @override
  String get codeLabel => 'Code:';

  @override
  String get addNewCurrency => 'Add New Currency';

  @override
  String get currencyCodeHint => 'Code (e.g., \"EUR\")';

  @override
  String get currencyCodeHelper => 'Short, unique code (3-5 letters)';

  @override
  String get pleaseEnterCode => 'Please enter a code';

  @override
  String get codeTooLong => 'Code is too long';

  @override
  String get currencyNameHint => 'Name (e.g., \"Euro\")';

  @override
  String get pleaseEnterCurrencyName => 'Please enter a name';

  @override
  String get currencySymbolHint => 'Symbol (e.g., \"€\")';

  @override
  String get failedToSave => 'Failed to save:';

  @override
  String get securityOptions => 'Security Options';

  @override
  String get requirePasscode => 'Require Passcode on Entry';

  @override
  String get toggleSecurity => 'Toggle additional security layer';

  @override
  String get passcodeRemoved => 'Passcode removed.';

  @override
  String get setChangePasscode => 'Set/Change Passcode';

  @override
  String get notSet => 'Not set';

  @override
  String get useBiometrics => 'Use Biometrics to Unlock';

  @override
  String get useBiometricsHint => 'Use fingerprint, face, or iris';

  @override
  String get setPasscode => 'Set Passcode';

  @override
  String get setPasscodeHint =>
      'Create a 4-digit PIN for your app.\nThis will be required on entry.';

  @override
  String get newPin => 'New 4-Digit PIN';

  @override
  String get pleaseEnterPin => 'Please enter a PIN';

  @override
  String get pinMustBe4Digits => 'PIN must be 4 digits';

  @override
  String get confirmPin => 'Confirm 4-Digit PIN';

  @override
  String get pinsDoNotMatch => 'PINs do not match';

  @override
  String get savePasscode => 'Save Passcode';

  @override
  String get passcodeSetSuccess => 'Passcode set successfully.';

  @override
  String get failedToSavePasscode => 'Failed to save passcode:';

  @override
  String get dataAndSync => 'Data & Sync';

  @override
  String get backupNow => 'Backup Data Now';

  @override
  String get backupHint => 'Uploads your local data to Google Drive.';

  @override
  String get restoreFromBackup => 'Restore from Backup';

  @override
  String get restoreWarning =>
      'CRITICAL: This will overwrite ALL current data in the app with the data from your backup file. This action cannot be undone. Are you sure?';

  @override
  String get buyFullVersion => 'Buy The Full Version';

  @override
  String get restoreBackupTitle => 'Restore From File?';

  @override
  String get restoreBackupMessage =>
      'This will overwrite all current data with the data from your selected backup file.\n\nTHIS CANNOT BE UNDONE.';

  @override
  String get restore => 'Restore';

  @override
  String get restoreSuccess =>
      'Restore successful! Please restart Mizan to load the new data.';

  @override
  String restoreFailed(String error) {
    return 'Restore failed. Your original data is safe. Error: $error';
  }

  @override
  String get featureNotImplemented => 'Feature not yet implemented.';

  @override
  String get chooseTheme => 'Choose Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get systemDefault => 'System Default';

  @override
  String get selectAccount => 'Select Account';

  @override
  String get unknownAccount => 'Unknown Account';

  @override
  String get pleaseSelectCurrency => 'Please select a currency.';

  @override
  String get pleaseEnterAccountName =>
      'Please enter or select an account name.';

  @override
  String get criticalAccountError =>
      'Critical Error: Default accounts (like Inventory) are missing.';

  @override
  String get transactionSaved => 'Transaction saved successfully.';

  @override
  String forAccount(String accountName) {
    return 'For $accountName';
  }

  @override
  String get loading => 'Loading...';

  @override
  String get accountName => 'Account Name';

  @override
  String get pleaseEnterOrSelectAccount => 'Please enter or select an account';

  @override
  String get amount => 'Amount';

  @override
  String get pleaseEnterAmount => 'Please enter an amount';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String exchangeRate(String currencyCode, String defaultCurrency) {
    return 'Exchange Rate (1 $currencyCode = ? $defaultCurrency)';
  }

  @override
  String get pleaseEnterRate => 'Please enter a rate';

  @override
  String get invalidRate => 'Invalid rate';

  @override
  String get addAttachment => 'Add Attachment';

  @override
  String get details => 'Details';

  @override
  String get couldNotLoadCurrencies => 'Could not load currencies';

  @override
  String get paymentCredit => 'Payment (Credit)';

  @override
  String get chargeDebit => 'Charge (Debit)';

  @override
  String get noHistory => 'No history for this account.';

  @override
  String get errorLoadingHistory => 'Error loading history:';

  @override
  String get pleaseAddCategory => 'Please add a category first.';

  @override
  String get noProductsInCategory => 'No products in this category';

  @override
  String get quantity => 'Qty';

  @override
  String get clear => 'Clear';

  @override
  String get printReceipt => 'Print Receipt';

  @override
  String get zeroTotalError => 'Cannot process sale with zero total.';

  @override
  String get criticalSetupError =>
      'CRITICAL SETUP ERROR: Accounts were not created on startup.\nTry reinstalling.';

  @override
  String posSale(String timestamp) {
    return 'POS Sale #$timestamp';
  }

  @override
  String saleRecorded(String total) {
    return 'Sale of $total recorded.';
  }

  @override
  String get transactionFailed => 'Transaction failed:';

  @override
  String get noTransactionsYet => 'No transactions yet.\nAdd one!';

  @override
  String get companyNameLegacy => 'Company Name';

  @override
  String get yourNameLegacy => 'Your Name';

  @override
  String get companyAddressLegacy => 'Company Address';

  @override
  String get taxIDLegacy => 'Tax ID / VAT Number';

  @override
  String get securityOptionsLegacy => 'Security Options';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String productNotFound(String barcode) {
    return 'Product not found for barcode: $barcode';
  }

  @override
  String get scanProductBarcode => 'Scan Product Barcode';

  @override
  String get barcodeOptional => 'Barcode (Optional)';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get cart => 'Cart';

  @override
  String get items => 'Item(s)';

  @override
  String get clearOrder => 'Clear Order';

  @override
  String get printAndSave => 'Print & Save';

  @override
  String get orderHistory => 'Order History';

  @override
  String get noSalesYet => 'No POS sales have been recorded yet.';

  @override
  String get returnFor => 'Return for';

  @override
  String get returnSuccess => 'Order returned successfully.';

  @override
  String get returnFailed => 'Failed to process return';

  @override
  String get confirmReturn => 'Return this Order?';

  @override
  String get confirmReturnMessage =>
      'This will create a new, opposite transaction to reverse this sale. This cannot be undone.';

  @override
  String get returnOrder => 'Return Order';

  @override
  String get noItemsInSale =>
      'No items found for this sale (likely a direct journal entry).';

  @override
  String get done => 'Done';

  @override
  String get year => 'Year';

  @override
  String get local => 'Local';

  @override
  String get exchangeRateShort => 'Rate';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get changeImage => 'Change Image';

  @override
  String get removeImage => 'Remove';

  @override
  String get pickFromGallery => 'Pick From Gallery';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get change => 'Change';

  @override
  String get remove => 'Remove';

  @override
  String get manageReturn => 'Manage Return';

  @override
  String get orderFullyReturned => 'This order has been fully returned.';

  @override
  String get purchased => 'Purchased';

  @override
  String get returned => 'Returned';

  @override
  String get returnQuantity => 'Return Quantity';

  @override
  String get totalRefund => 'Total Refund';

  @override
  String get processReturn => 'Process Return';

  @override
  String get noItemsSelected => 'No items selected for return.';

  @override
  String partialReturnFor(String transactionId) {
    return 'Partial Return for Order $transactionId';
  }

  @override
  String get orderReturned => 'This order has been returned.';

  @override
  String get noLineItemsSaved => 'No line items were saved for this order.';

  @override
  String get fieldRequired => 'field Required';

  @override
  String get selectPaymentMethod => 'select Payment Method';

  @override
  String get backupAndRestore => 'Backup & Restore';

  @override
  String get upgradeToMizanPro => 'Upgrade to Mizan Pro';

  @override
  String get mizanProDescription =>
      'Enable automatic cloud sync, multi-device access, and user roles. Learn more...';

  @override
  String get createLocalBackupTitle => 'Create Local Backup?';

  @override
  String get createLocalBackupMessage =>
      'This will save a copy of your database to a location you choose (e.g., Downloads, Google Drive).';

  @override
  String get yes => 'Yes';

  @override
  String get newPurchase => 'New Purchase / Bill';

  @override
  String get purchaseScreenTitle => 'New Purchase / Bill';

  @override
  String get pay => 'Pay';

  @override
  String get profitAndLoss => 'Profit & Loss';

  @override
  String get revenue => 'Revenue';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get expenses => 'Expenses';

  @override
  String get totalExpenses => 'Total Expenses';

  @override
  String get netIncome => 'Net Income';

  @override
  String get balanceSheet => 'Balance Sheet';

  @override
  String get asOf => 'As of';

  @override
  String get assets => 'Assets';

  @override
  String get totalAssets => 'Total Assets';

  @override
  String get liabilities => 'Liabilities';

  @override
  String get totalLiabilities => 'Total Liabilities';

  @override
  String get equity => 'Equity';

  @override
  String get totalEquity => 'Total Equity';

  @override
  String get totalLiabilitiesAndEquity => 'Total Liabilities & Equity';

  @override
  String get trialBalance => 'Trial Balance';

  @override
  String get selectSupplier => 'Select a Supplier';

  @override
  String get makePayment => 'Make Payment';

  @override
  String get payFromAccount => 'Pay From Account';

  @override
  String get payToAccount => 'Pay To Account';

  @override
  String get pleaseEnterValidAmount => 'Please enter a valid amount > 0';

  @override
  String get supplier => 'Supplier';

  @override
  String get pleaseSelectSupplier => 'Please select a supplier';

  @override
  String get profitAndLossReport => 'Profit & Loss Statement';

  @override
  String get balanceSheetReport => 'Balance Sheet';

  @override
  String get trialBalanceReport => 'Trial Balance';

  @override
  String get trialBalanceLoadFailed => 'Could not load the trial balance.';

  @override
  String get trialBalanceServerSource => 'Cloud ledger data';

  @override
  String get trialBalanceLocalSource => 'This device’s local data';

  @override
  String get ledgerControl => 'Ledger Control';

  @override
  String get schemaHealth => 'Schema health';

  @override
  String get schemaHealthLoadFailed => 'Could not load schema health checks.';

  @override
  String get schemaHealthNeedsAttention => 'Attention required';

  @override
  String get schemaHealthHealthy => 'Schema health looks good';

  @override
  String get schemaHealthChecksPassed => 'checks passed';

  @override
  String get requiredTable => 'Required table';

  @override
  String get rowLevelSecurity => 'Row-Level Security';

  @override
  String get tenantReferences => 'Tenant references';

  @override
  String get tenantIndex => 'Tenant-leading index';

  @override
  String get tenantContext => 'Tenant context';

  @override
  String get postedJournalBalance => 'Posted journal balance';

  @override
  String get currencyCodeFormat => 'Currency-code format';

  @override
  String get preflightComplete => 'Preflight complete';

  @override
  String get schemaHealthCheck => 'Schema health check';

  @override
  String get ledgerControlIntro =>
      'Review cloud accounting periods, tax codes, and the chart of accounts. Posting and closing are server-authorized.';

  @override
  String get ledgerLoadFailed => 'Could not load the accounting controls.';

  @override
  String get accountingPeriods => 'Accounting periods';

  @override
  String get accountingBooks => 'Accounting books';

  @override
  String get accountingDimensions => 'Accounting dimensions';

  @override
  String get noBooks => 'No accounting books configured.';

  @override
  String get noDimensions => 'No accounting dimensions configured.';

  @override
  String get chartOfAccounts => 'Chart of accounts';

  @override
  String get taxCodes => 'Tax codes';

  @override
  String get noPeriods => 'No accounting periods are configured.';

  @override
  String get noAccounts => 'No cloud chart-of-accounts records are configured.';

  @override
  String get noTaxCodes => 'No active tax codes are configured.';

  @override
  String get closePeriod => 'Close period';

  @override
  String get periodClosed => 'Accounting period closed.';

  @override
  String get periodCloseFailed => 'Could not close the accounting period.';

  @override
  String get taxInclusive => 'tax inclusive';

  @override
  String get taxExclusive => 'tax exclusive';

  @override
  String get addProduct => 'Add Product';

  @override
  String get product => 'Product';

  @override
  String get quantityShort => 'Qty';

  @override
  String get cost => 'Cost';

  @override
  String get totalCost => 'Total Cost';

  @override
  String get costPerItem => 'Cost per item';

  @override
  String get totalPayable => 'Total Payable';

  @override
  String get pleaseEnterCost => 'Please enter a cost';

  @override
  String get pleaseEnterQuantity => 'Please enter a quantity';

  @override
  String get purchaseSaved => 'Purchase saved successfully.';

  @override
  String failedToSavePurchase(String error) {
    return 'Failed to save purchase: $error';
  }

  @override
  String purchaseFrom(String supplierName) {
    return 'Purchase from $supplierName';
  }

  @override
  String get createLocalBackupPrompt =>
      'This will create a local backup file (mizan.db) in a folder you choose. You can use this file to restore your data on this or another device.';

  @override
  String get backup => 'Backup';

  @override
  String get backupSuccessful => 'Backup successful';

  @override
  String get backupFailed => 'Backup failed';

  @override
  String get restoreSuccessful => 'Restore Successful';

  @override
  String get restoreSuccessMessage =>
      'Your data has been restored. Please restart the app now.';

  @override
  String get learnMore => 'Learn More';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get newSale => 'New Sale';

  @override
  String get totalReceivable => 'Total Receivable';

  @override
  String currencyFormat(double value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '$valueString';
  }

  @override
  String saveSuccessPrintFailed(String error) {
    return 'Save success, but print failed: $error';
  }

  @override
  String errorLoadingPaymentMethods(String error) {
    return 'Error loading payment methods: $error';
  }

  @override
  String atPrice(String price) {
    return '@ $price';
  }

  @override
  String get dbFileNotFound => 'Database file not found.';

  @override
  String get noBackupFound => 'No backup file found on Google Drive.';

  @override
  String get mizanAccounting => 'Mizan Accounting';

  @override
  String generatedOn(String date) {
    return 'Generated on: $date';
  }

  @override
  String get totalLocal => 'Total (Local)';

  @override
  String couldNotLaunch(String url) {
    return 'Could not launch $url';
  }

  @override
  String get webNotSupported => 'Web platform is not supported';

  @override
  String get signInCancelled => 'Sign-in cancelled by user.';

  @override
  String get updateWindowsClientId =>
      'Please update the Windows Client ID in auth_repository.dart';

  @override
  String get updateWindowsClientIdSecret =>
      'Please update Windows Client ID/Secret in auth_repository.dart';

  @override
  String get authFailed => 'Authentication failed. Unable to get HTTP client.';

  @override
  String get criticalInventoryError =>
      'Critical Error: Inventory or COGS accounts not found.';

  @override
  String get drLabel => 'Dr:';

  @override
  String get crLabel => 'Cr:';

  @override
  String get fixedAssets => 'Fixed Assets';

  @override
  String get fixedAssetsDescription =>
      'Manage equipment, vehicles, and property';

  @override
  String get netBookValue => 'Net Book Value';

  @override
  String get totalAcquisitionCost => 'Total Acquisition Cost';

  @override
  String get accumulatedDepreciation => 'Accumulated Depreciation';

  @override
  String get activeAssets => 'Active';

  @override
  String get fullyDepreciated => 'Fully Depreciated';

  @override
  String get disposedAssets => 'Disposed';

  @override
  String get allAssets => 'All Assets';

  @override
  String get byCategory => 'By Category';

  @override
  String get schedule => 'Schedule';

  @override
  String get addAsset => 'Add Asset';

  @override
  String get editAsset => 'Edit Asset';

  @override
  String get bookValue => 'Book Value';

  @override
  String get depreciated => 'depreciated';

  @override
  String get usefulLife => 'Useful Life';

  @override
  String get months => 'months';

  @override
  String get monthsLeft => 'months left';

  @override
  String get acquisitionDate => 'Acquisition Date';

  @override
  String get salvageValue => 'Salvage Value';

  @override
  String get depreciationMethod => 'Depreciation Method';

  @override
  String get straightLine => 'Straight-Line';

  @override
  String get decliningBalance => 'Declining Balance';

  @override
  String get unitsOfActivity => 'Units of Activity';

  @override
  String get runDepreciation => 'Run Depreciation';

  @override
  String get disposeAsset => 'Dispose';

  @override
  String get assetDetails => 'Asset Details';

  @override
  String get valueInformation => 'Value Information';

  @override
  String get depreciationSettings => 'Depreciation Settings';

  @override
  String get depreciationProgress => 'Depreciation Progress';

  @override
  String get currentPeriod => 'Current Period';

  @override
  String get monthly => 'Monthly';

  @override
  String get depreciation => 'Depreciation';

  @override
  String get depreciationProcessing => 'Depreciation Processing';

  @override
  String get periodEndDate => 'Period End Date';

  @override
  String get runAll => 'Run All';

  @override
  String get batchDepreciationComplete => 'Batch depreciation complete';

  @override
  String assetsProcessed(int count) {
    return '$count assets processed';
  }

  @override
  String get ghostMoney => 'Ghost Money';

  @override
  String get ghostMoneyDescription => 'Reconcile rounding differences';

  @override
  String get pendingReconciliation => 'Pending Reconciliation';

  @override
  String get recentEntries => 'Recent Entries';

  @override
  String get reconcile => 'Reconcile';

  @override
  String get reconcileAll => 'Reconcile All';

  @override
  String get reconciled => 'Reconciled';

  @override
  String get notReconciled => 'Not Reconciled';

  @override
  String entriesReconciled(int count) {
    return '$count entries reconciled';
  }

  @override
  String get whatIsGhostMoney => 'What is Ghost Money?';

  @override
  String get ghostMoneyExplanation =>
      'Ghost money represents tiny rounding differences that occur during calculations like bill splitting, currency conversion, or percentage calculations. These are normal and expected in accounting.';

  @override
  String get sourceTransaction => 'Transaction';

  @override
  String get sourceSplit => 'Bill Split';

  @override
  String get sourceExchange => 'Exchange';

  @override
  String get sourceImport => 'Import';

  @override
  String get accountCash => 'Cash';

  @override
  String get accountPettyCash => 'Petty Cash';

  @override
  String get accountBankAccount => 'Bank Account';

  @override
  String get accountAccountsReceivable => 'Accounts Receivable';

  @override
  String get accountInventory => 'Inventory';

  @override
  String get accountPrepaidExpenses => 'Prepaid Expenses';

  @override
  String get accountFixedAssetsHeader => 'Fixed Assets';

  @override
  String get accountFurnitureFixtures => 'Furniture & Fixtures';

  @override
  String get accountEquipment => 'Equipment';

  @override
  String get accountVehicles => 'Vehicles';

  @override
  String get accountAccumulatedDepreciation => 'Accumulated Depreciation';

  @override
  String get accountAccountsPayable => 'Accounts Payable';

  @override
  String get accountAccruedExpenses => 'Accrued Expenses';

  @override
  String get accountSalesTaxPayable => 'Sales Tax Payable';

  @override
  String get accountUnearnedRevenue => 'Unearned Revenue';

  @override
  String get accountLongTermLiabilities => 'Long-Term Liabilities';

  @override
  String get accountLoansPayable => 'Loans Payable';

  @override
  String get accountOwnerEquity => 'Owner\'s Equity';

  @override
  String get accountRetainedEarnings => 'Retained Earnings';

  @override
  String get accountDrawings => 'Drawings';

  @override
  String get accountSalesRevenue => 'Sales Revenue';

  @override
  String get accountServiceRevenue => 'Service Revenue';

  @override
  String get accountInterestIncome => 'Interest Income';

  @override
  String get accountCostOfGoodsSold => 'Cost of Goods Sold';

  @override
  String get accountRentExpense => 'Rent Expense';

  @override
  String get accountUtilitiesExpense => 'Utilities Expense';

  @override
  String get accountSalariesExpense => 'Salaries Expense';

  @override
  String get accountDepreciationExpense => 'Depreciation Expense';

  @override
  String get accountInsuranceExpense => 'Insurance Expense';

  @override
  String get accountSuppliesExpense => 'Supplies Expense';

  @override
  String get accountMiscellaneousExpense => 'Miscellaneous Expense';

  @override
  String get joinOrganization => 'Join Organization';

  @override
  String get enterInviteCode => 'Enter the invite code from your administrator';

  @override
  String get inviteCode => 'Invite Code';

  @override
  String get validInviteCode => 'Valid Invite Code!';

  @override
  String get invalidInviteCode => 'Invalid or expired invite code';

  @override
  String get codeMustBe6Digits => 'Code must be 6 digits';

  @override
  String get pleaseEnterInviteCode => 'Please enter the invite code';

  @override
  String get enterDisplayName => 'Enter your display name';

  @override
  String get successfullyJoined => 'Successfully joined organization!';

  @override
  String get inviteCodeUsed => 'This invite code has already been used';

  @override
  String get inviteCodeExpired => 'This invite code has expired';

  @override
  String get pleaseSignInFirst => 'Please sign in first';

  @override
  String get createNewOrganization => 'Create New Organization';

  @override
  String get createOrganizationTitle => 'Create your Organization';

  @override
  String get createOrganizationDescription =>
      'This will enable Sync, Staff Management, and Advanced Reports.';

  @override
  String get businessNameLabel => 'Business Name';

  @override
  String get businessPhoneLabel => 'Business Phone';

  @override
  String get createBusinessUpgrade => 'Create Business & Upgrade';

  @override
  String get businessCloudActivated => 'Business Cloud Activated!';

  @override
  String get role => 'Role';

  @override
  String get customers => 'Customers';

  @override
  String get addCustomer => 'Add Customer';

  @override
  String get newCustomer => 'New Customer';

  @override
  String get editCustomer => 'Edit Customer';

  @override
  String get customerName => 'Customer Name';

  @override
  String get email => 'Email';

  @override
  String get address => 'Address';

  @override
  String get taxId => 'Tax ID';

  @override
  String get creditLimit => 'Credit Limit';

  @override
  String get notes => 'Notes';

  @override
  String get noCustomersYet => 'No customers yet';

  @override
  String get tapToAddFirstCustomer =>
      'Tap the button below to add your first customer';

  @override
  String get outstanding => 'Outstanding';

  @override
  String get owed => 'Owed';

  @override
  String get invoices => 'Invoices';

  @override
  String get newInvoice => 'New Invoice';

  @override
  String get invoiceDate => 'Invoice Date';

  @override
  String get dueDate => 'Due Date';

  @override
  String get lineItems => 'Line Items';

  @override
  String get addItem => 'Add Item';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get createInvoice => 'Create Invoice';

  @override
  String get invoiceCreated => 'Invoice created successfully';

  @override
  String get noInvoicesYet => 'No invoices yet';

  @override
  String get paid => 'Paid';

  @override
  String get partial => 'Partial';

  @override
  String get overdue => 'Overdue';

  @override
  String get draft => 'Draft';

  @override
  String get sent => 'Sent';

  @override
  String get arAgingReport => 'AR Aging Report';

  @override
  String get totalReceivables => 'Total Receivables';

  @override
  String get current => 'Current';

  @override
  String get days31to60 => '31-60 Days';

  @override
  String get days61to90 => '61-90 Days';

  @override
  String get over90Days => '90+ Days';

  @override
  String get byCustomer => 'By Customer';

  @override
  String get noOutstandingReceivables => 'No Outstanding Receivables';

  @override
  String get allInvoicesPaid => 'All invoices are paid!';

  @override
  String customersWithBalances(int count) {
    return '$count customers with balances';
  }

  @override
  String get vendors => 'Vendors';

  @override
  String get addVendor => 'Add Vendor';

  @override
  String get newVendor => 'New Vendor';

  @override
  String get editVendor => 'Edit Vendor';

  @override
  String get vendorName => 'Vendor Name';

  @override
  String get paymentTerms => 'Payment Terms (e.g., Net 30)';

  @override
  String get noVendorsYet => 'No vendors yet';

  @override
  String get tapToAddFirstVendor =>
      'Tap the button below to add your first vendor';

  @override
  String get weOwe => 'We Owe';

  @override
  String get bills => 'Bills';

  @override
  String get newBill => 'New Bill';

  @override
  String get billDate => 'Bill Date';

  @override
  String get vendorInvoice => 'Vendor Invoice #';

  @override
  String get optional => 'Optional';

  @override
  String get createBill => 'Create Bill';

  @override
  String get billCreated => 'Bill created successfully';

  @override
  String get noBillsYet => 'No bills yet';

  @override
  String get pending => 'Pending';

  @override
  String get apAgingReport => 'AP Aging Report';

  @override
  String get totalPayables => 'Total Payables';

  @override
  String get byVendor => 'By Vendor';

  @override
  String get noOutstandingPayables => 'No Outstanding Payables';

  @override
  String get allBillsPaid => 'All bills are paid!';

  @override
  String vendorsWithBalances(int count) {
    return '$count vendors with balances';
  }

  @override
  String get statementOfCashFlows => 'Statement of Cash Flows';

  @override
  String get cashFlowsFromOperating => 'Cash Flows from Operating Activities';

  @override
  String get cashFlowsFromInvesting => 'Cash Flows from Investing Activities';

  @override
  String get cashFlowsFromFinancing => 'Cash Flows from Financing Activities';

  @override
  String get addDepreciation => 'Add: Depreciation Expense';

  @override
  String get decreaseInReceivables => 'Decrease in Accounts Receivable';

  @override
  String get increaseInReceivables => 'Increase in Accounts Receivable';

  @override
  String get increaseInPayables => 'Increase in Accounts Payable';

  @override
  String get decreaseInPayables => 'Decrease in Accounts Payable';

  @override
  String get netCashFromOperating => 'Net Cash from Operating';

  @override
  String get netCashFromInvesting => 'Net Cash from Investing';

  @override
  String get netCashFromFinancing => 'Net Cash from Financing';

  @override
  String get purchaseOfFixedAssets => 'Purchase of Fixed Assets';

  @override
  String get netChangeInCash => 'Net Change in Cash';

  @override
  String get beginningCashBalance => 'Beginning Cash Balance';

  @override
  String get endingCashBalance => 'Ending Cash Balance';

  @override
  String get noInvestingActivities => 'No investing activities';

  @override
  String get noFinancingActivities => 'No financing activities';

  @override
  String get financialRatios => 'Financial Ratios';

  @override
  String get currentRatio => 'Current Ratio';

  @override
  String get quickRatio => 'Quick Ratio';

  @override
  String get debtToEquity => 'Debt/Equity';

  @override
  String get grossProfitMargin => 'Gross Profit Margin';

  @override
  String get netProfitMargin => 'Net Profit Margin';

  @override
  String get returnOnAssets => 'Return on Assets (ROA)';

  @override
  String get workingCapital => 'Working Capital';

  @override
  String get receivablesTurnover => 'Receivables Turnover';

  @override
  String get receivables => 'Receivables';

  @override
  String get payables => 'Payables';

  @override
  String get currentAmount => 'Current';

  @override
  String get overdueAmount => 'Overdue';

  @override
  String get bankReconciliations => 'Bank Reconciliations';

  @override
  String get statementDetails => 'Statement Details';

  @override
  String get selectBankAccount => 'Select Bank Account';

  @override
  String get statementEnding => 'Statement Ending';

  @override
  String get clearedBalance => 'Cleared Balance';

  @override
  String get difference => 'Difference';

  @override
  String get selectTransactionsUntilBalanced =>
      'Select transactions until the difference is zero';

  @override
  String get deposit => 'Deposit';

  @override
  String get payment => 'Payment';

  @override
  String get idLabel => 'ID';

  @override
  String get bankFeeInterestComingSoon =>
      'Bank fee/interest adjustments are coming soon.';

  @override
  String get addAdjustment => 'Add Adjustment';

  @override
  String get finish => 'Finish';

  @override
  String get reconciliationComplete => 'Reconciliation complete!';

  @override
  String get newReconciliation => 'New Reconciliation';

  @override
  String get noReconciliationsYet => 'No reconciliations yet';

  @override
  String get startReconciling => 'Start reconciling your bank statements';

  @override
  String get bankAccount => 'Bank Account';

  @override
  String get statementDate => 'Statement Date';

  @override
  String get statementEndingBalance => 'Statement Ending Balance';

  @override
  String get statementBalance => 'Statement Balance';

  @override
  String get bookBalance => 'Book Balance';

  @override
  String get selectedCleared => 'Selected cleared';

  @override
  String get differenceAmount => 'Difference';

  @override
  String get balanced => 'Balanced!';

  @override
  String get unclearedTransactions => 'Uncleared Transactions';

  @override
  String get noUnreconciledTransactions =>
      'No unreconciled transactions found.';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get allTransactionsReconciled => 'All transactions reconciled!';

  @override
  String get completeReconciliation => 'Complete Reconciliation';

  @override
  String get reconciliationCompleted => 'Reconciliation completed!';

  @override
  String get pleaseSelectTransactions =>
      'Please select transactions to reconcile';

  @override
  String get noBankAccountsFound => 'No bank accounts found';

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
  String get cvpAnalysis => 'CVP Analysis';

  @override
  String get calculator => 'Calculator';

  @override
  String get breakEven => 'Break-Even';

  @override
  String get marginOfSafety => 'Margin of Safety';

  @override
  String get whatIf => 'What-If';

  @override
  String get costStructure => 'Cost Structure';

  @override
  String get fixedCostsTotal => 'Fixed Costs (Total)';

  @override
  String get fixedCostsHelper => 'Rent, salaries, depreciation, etc.';

  @override
  String get perUnitData => 'Per-Unit Data';

  @override
  String get sellingPrice => 'Selling Price';

  @override
  String get variableCost => 'Variable Cost';

  @override
  String get contributionMargin => 'Contribution Margin';

  @override
  String get contributionMarginPerUnit => 'CM per Unit';

  @override
  String get actualExpectedSales => 'Actual/Expected Sales';

  @override
  String get unitsSold => 'Units Sold';

  @override
  String get targetProfit => 'Target Profit';

  @override
  String get desiredProfit => 'Desired Profit';

  @override
  String get desiredProfitHelper => 'How much profit do you want to earn?';

  @override
  String get analyzeAndViewResults => 'Analyze & View Results';

  @override
  String get enterDataFirst => 'Enter data in the Calculator tab first';

  @override
  String get breakEvenPoint => 'Break-Even Point';

  @override
  String get units => 'Units';

  @override
  String get sales => 'Sales';

  @override
  String get targetProfitAnalysis => 'Target Profit Analysis';

  @override
  String get requiredUnits => 'Required Units';

  @override
  String get requiredSales => 'Required Sales';

  @override
  String get risk => 'RISK';

  @override
  String get mosRatio => 'MOS Ratio';

  @override
  String get financialSnapshot => 'Financial Snapshot';

  @override
  String get quickAccess => 'Quick Access';

  @override
  String get cashFlow => 'Cash Flow';

  @override
  String get operatingLeverage => 'Operating Leverage';

  @override
  String get degreeOfOperatingLeverage => 'Degree of Operating Leverage';

  @override
  String get leverageLevel => 'Leverage Level';

  @override
  String get leverageImpact => 'Impact';

  @override
  String get priceSensitivityAnalysis => 'Price Sensitivity Analysis';

  @override
  String get priceSensitivityDescription =>
      'Shows how break-even changes when you adjust selling price';

  @override
  String currentBreakEven(String units) {
    return 'Current Break-Even: $units units';
  }

  @override
  String get depreciationProcessingTitle => 'Depreciation Processing';

  @override
  String get selectPeriodEndDate => 'Select Period End Date';

  @override
  String get processing => 'Processing...';

  @override
  String get noActiveAssets => 'No Active Assets';

  @override
  String get addFixedAssetsHint => 'Add fixed assets to run depreciation';

  @override
  String get bookValueLabel => 'Book Value';

  @override
  String get monthlyLabel => 'Monthly';

  @override
  String get remainingLabel => 'Remaining';

  @override
  String depreciationRecordedFor(String amount, String assetName) {
    return 'Depreciation recorded: $amount for $assetName';
  }

  @override
  String processedAssetsTotal(int count, String amount) {
    return 'Processed $count assets. Total: $amount';
  }

  @override
  String assetsCount(int count) {
    return '$count assets';
  }

  @override
  String get ghostMoneyTitle => 'Ghost Money';

  @override
  String get whatIsGhostMoneyTooltip => 'What is Ghost Money?';

  @override
  String get allBalanced => 'All Balanced!';

  @override
  String get noGhostMoneyToReconcile => 'No ghost money to reconcile';

  @override
  String get entryLabel => 'entry';

  @override
  String get entriesLabel => 'entries';

  @override
  String get noEntriesToDisplay => 'No entries to display';

  @override
  String reconcileCurrency(String currency) {
    return 'Reconcile $currency';
  }

  @override
  String writeOffConfirmation(String amount, int count, String entryText) {
    return 'Write off $amount in ghost money?\n\nThis will create a journal entry to clear $count $entryText.';
  }

  @override
  String get reconcileButton => 'Reconcile';

  @override
  String reconciledEntries(int count, String currency) {
    return 'Reconciled $count entries for $currency';
  }

  @override
  String get entryReconciledMessage => 'Entry reconciled';

  @override
  String get ghostMoneyDialogTitle => 'What is Ghost Money?';

  @override
  String get ghostMoneyDialogContent =>
      'Ghost money represents tiny rounding differences that occur during financial calculations.\n\nExamples:\n• Splitting a bill 3 ways (100 ÷ 3)\n• Currency exchange rate conversions\n• Percentage-based tax calculations\n\nThese small differences typically accumulate to just a few cents and can be periodically written off or allocated.';

  @override
  String get gotIt => 'Got it';

  @override
  String get fixedAssetsTitle => 'Fixed Assets';

  @override
  String get netBookValueLabel => 'Net Book Value';

  @override
  String get totalCostLabel => 'Total Cost';

  @override
  String get depreciatedLabel => 'Depreciated';

  @override
  String get progressLabel => 'Progress';

  @override
  String get activeLabel => 'Active';

  @override
  String get fullDeprLabel => 'Full Depr.';

  @override
  String get disposedLabel => 'Disposed';

  @override
  String get allAssetsTab => 'All Assets';

  @override
  String get byCategoryTab => 'By Category';

  @override
  String get scheduleTab => 'Schedule';

  @override
  String get noFixedAssets => 'No Fixed Assets';

  @override
  String get addFixedAssetsDescription =>
      'Add equipment, vehicles, or property to track depreciation';

  @override
  String get noScheduledDepreciation => 'No Scheduled Depreciation';

  @override
  String percentDepreciated(String percent) {
    return '$percent% depreciated';
  }

  @override
  String monthlyDepreciationInfo(String amount, int months) {
    return 'Monthly: $amount • $months months left';
  }

  @override
  String get valueInformationTitle => 'Value Information';

  @override
  String get depreciationSettingsTitle => 'Depreciation Settings';

  @override
  String get acquisitionCostLabel => 'Acquisition Cost';

  @override
  String get salvageValueLabel => 'Salvage Value';

  @override
  String get accumulatedDepreciationLabel => 'Accumulated Depreciation';

  @override
  String get methodLabel => 'Method';

  @override
  String get usefulLifeLabel => 'Useful Life';

  @override
  String usefulLifeMonths(int months) {
    return '$months months';
  }

  @override
  String get runDepreciationButton => 'Run Depreciation';

  @override
  String get disposeButton => 'Dispose';

  @override
  String get addAssetName => 'Asset Name';

  @override
  String get addAssetDescription => 'Description (Optional)';

  @override
  String get addAssetAcquisitionCost => 'Acquisition Cost';

  @override
  String get addAssetSalvageValue => 'Salvage Value';

  @override
  String get addAssetUsefulLife => 'Useful Life (Months)';

  @override
  String get usefulLifeUnitsLabel => 'Useful Life (Units)';

  @override
  String get addAssetAcquisitionDate => 'Acquisition Date';

  @override
  String get addAssetDepreciationMethod => 'Depreciation Method';

  @override
  String get addAssetDecliningRate => 'Declining Balance Rate';

  @override
  String get assetAccountLabel => 'Asset Account';

  @override
  String get accumulatedDepreciationAccountLabel =>
      'Accumulated Depreciation Account';

  @override
  String get depreciationExpenseAccountLabel => 'Depreciation Expense Account';

  @override
  String get selectAssetAccount => 'Select an asset account';

  @override
  String get selectAccumulatedDepreciationAccount =>
      'Select an accumulated depreciation account';

  @override
  String get selectDepreciationExpenseAccount =>
      'Select a depreciation expense account';

  @override
  String get assetSavedSuccess => 'Asset saved successfully.';

  @override
  String get assetDisposedSuccess => 'Asset disposed successfully.';

  @override
  String get disposeAssetTitle => 'Dispose Asset';

  @override
  String disposeAssetMessage(String assetName) {
    return 'Mark $assetName as disposed? This records the disposal date and removes it from active assets.';
  }

  @override
  String get assetDisposalDate => 'Disposal Date';

  @override
  String get salvageExceedsCost =>
      'Salvage value cannot exceed acquisition cost.';

  @override
  String get invalidUsefulLife => 'Useful life must be greater than zero.';

  @override
  String get invalidDecliningRate =>
      'Declining-balance rate must be greater than zero.';

  @override
  String get reportsAndAnalytics => 'Reports & Analytics';

  @override
  String get reportMarketplaceTooltip => 'Report Marketplace';

  @override
  String get financialStatementsSection => 'Financial Statements';

  @override
  String get performanceSection => 'Performance';

  @override
  String get analysisToolsSection => 'Analysis Tools';

  @override
  String get inventoryOperationsSection =>
      'Inventory & Operations (Coming Soon)';

  @override
  String get cvpAnalysisTitle => 'CVP Analysis';

  @override
  String get capitalBudgetingTitle => 'Capital Budgeting';

  @override
  String get budgetAnalysisTitle => 'Budget Analysis';

  @override
  String get fraudDetectionTitle => 'Fraud Detection';

  @override
  String get standardCostingTitle => 'Standard Costing';

  @override
  String get financialRatiosTitle => 'Financial Ratios';

  @override
  String get stockVelocityTitle => 'Stock Velocity';

  @override
  String get lowStockAlertTitle => 'Low Stock Alert';

  @override
  String get salesByCashierTitle => 'Sales by Cashier';

  @override
  String get taxLiabilityTitle => 'Tax Liability';

  @override
  String get revenueRecognition => 'Revenue Recognition';

  @override
  String get arApAging => 'AR/AP Aging';

  @override
  String get createSettlementDraft => 'Create settlement draft';

  @override
  String get settlementDraftCreated =>
      'Settlement draft created. Review and post it through the accounting workflow.';

  @override
  String get settlementAccountsLoadFailed =>
      'Could not load accounting accounts.';

  @override
  String get settlementAmount => 'Settlement amount';

  @override
  String get settlementAmountHint =>
      'Enter an amount no greater than the outstanding balance.';

  @override
  String get cashAccount => 'Cash or bank account';

  @override
  String get receivableAccount => 'Receivable account';

  @override
  String get payableAccount => 'Payable account';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get reference => 'Reference';

  @override
  String get settlementAmountInvalid =>
      'Enter a positive amount within the outstanding balance.';

  @override
  String get settlementFieldsRequired =>
      'Complete the amount, accounts, payment method, and journal number.';

  @override
  String get settlementDraftFailed => 'Could not create the settlement draft.';

  @override
  String get arApAgingLoadFailed => 'Could not load the aging report.';

  @override
  String get arApAgingNoOutstanding =>
      'No outstanding documents are available.';

  @override
  String get aging1To30 => '1–30 days';

  @override
  String get aging31To60 => '31–60 days';

  @override
  String get aging61To90 => '61–90 days';

  @override
  String get agingOver90 => 'Over 90 days';

  @override
  String get daysOverdue => 'days overdue';

  @override
  String get revenueRecognitionIntro =>
      'Review planned recognition amounts. Creating a draft does not post it; posting remains a separately authorized accounting action.';

  @override
  String get revenueRecognitionLoadFailed =>
      'Could not load the revenue schedule.';

  @override
  String get revenueRecognitionNoSchedules =>
      'No revenue-recognition schedules are available.';

  @override
  String get revenueRecognitionCreateDraft => 'Create draft';

  @override
  String get revenueRecognitionDraftCreated =>
      'Recognition draft created. Review and post it through the accounting workflow.';

  @override
  String get revenueRecognitionDraftFailed =>
      'Could not create the recognition draft.';

  @override
  String get revenueRecognitionPlannedStatus => 'Planned';

  @override
  String get revenueRecognitionDraftStatus => 'Draft created';

  @override
  String get revenueRecognitionRecognizedStatus => 'Recognized';

  @override
  String get journalEntryNumber => 'Journal entry number';

  @override
  String get createDraft => 'Create draft';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get reportNoData => 'No data for this period.';

  @override
  String get dateRange => 'Date range';

  @override
  String get fromDate => 'From';

  @override
  String get toDate => 'To';

  @override
  String get cashier => 'Cashier';

  @override
  String get unassigned => 'Unassigned';

  @override
  String ordersCount(Object count) {
    return '$count orders';
  }

  @override
  String get soldQuantity => 'Sold quantity';

  @override
  String get reorderPoint => 'Reorder point';

  @override
  String get salesTaxCollected => 'Sales tax collected';

  @override
  String get purchaseTaxPaid => 'Purchase tax';

  @override
  String get netTaxDue => 'Net tax due';

  @override
  String reportInvoicesCount(Object count) {
    return '$count invoices';
  }

  @override
  String reportBillsCount(Object count) {
    return '$count bills';
  }

  @override
  String get reportHubTitle => 'Report Hub';

  @override
  String get myReportsTab => 'My Reports';

  @override
  String get marketplaceTab => 'Marketplace';

  @override
  String get noInstalledReports => 'No Installed Reports';

  @override
  String get goToMarketplaceHint =>
      'Go to the Marketplace to download standard reports.';

  @override
  String get marketplaceUnavailable => 'Marketplace Unavailable';

  @override
  String get noStandardReportsOnline => 'No standard reports found online.';

  @override
  String get installButton => 'Install';

  @override
  String get includedLabel => 'Included';

  @override
  String buyLabel(String price) {
    return 'Buy $price';
  }

  @override
  String get lockedLabel => 'Locked';

  @override
  String get purchaseReportTitle => 'Purchase Report';

  @override
  String buyReportConfirmation(String title, String price) {
    return 'Buy \'$title\' for $price?';
  }

  @override
  String get buyNowButton => 'Buy Now';

  @override
  String get processingPayment => 'Processing Payment...';

  @override
  String installedReport(String title) {
    return '✅ Installed $title';
  }

  @override
  String get premiumReportLocked =>
      '🔒 Premium Report. Upgrade to Pro or Enterprise.';

  @override
  String get posTerminalTitle => 'POS Terminal';

  @override
  String get searchProductTooltip => 'Search Product';

  @override
  String get recallOrderTooltip => 'Recall Order';

  @override
  String get holdButton => 'HOLD';

  @override
  String get orderParkedMessage => 'Order Parked';

  @override
  String get recallOrderTitle => 'Recall Order';

  @override
  String get noParkedOrders => 'No parked orders';

  @override
  String orderNumberLabel(String orderId) {
    return 'Order #$orderId';
  }

  @override
  String orderInfo(int itemCount, int minutes) {
    return '$itemCount items • $minutes mins ago';
  }

  @override
  String get closeButton => 'Close';

  @override
  String get cartIsEmpty => 'Cart is empty';

  @override
  String payWithButton(String method) {
    return 'Pay with $method';
  }

  @override
  String get editQtyMode => 'EDIT QTY MODE';

  @override
  String get scanMode => 'SCAN MODE';

  @override
  String get totalLabel => 'TOTAL';

  @override
  String get payPrintButton => 'PAY / PRINT';

  @override
  String get importProductsTitle => 'Import Products';

  @override
  String get selectDefaultCategoryHint =>
      '1. Select a default category for these products:';

  @override
  String get pleaseCreateCategoryFirst => 'Please create a category first.';

  @override
  String get uploadFileHint =>
      '2. Upload CSV or Excel file (Cols: Name, Barcode, Cat, Price, Cost, Qty)';

  @override
  String get selectFileButton => 'Select File';

  @override
  String get noProductsFoundInFile => 'No products found in file.';

  @override
  String get noDataLoaded => 'No data loaded. Upload a file to preview.';

  @override
  String importProductsButton(int count) {
    return 'Import $count Products';
  }

  @override
  String importSuccessMessage(int count) {
    return 'Successfully imported $count products!';
  }

  @override
  String importFailedMessage(String error) {
    return 'Import Failed: $error';
  }

  @override
  String get pleaseSelectDefaultCategory => 'Please select a Default Category';

  @override
  String get budgetAnalysis => 'Budget Analysis';

  @override
  String get addBudget => 'Add budget';

  @override
  String get budgetName => 'Budget name';

  @override
  String get periodStartDate => 'Period start date';

  @override
  String get addLineItem => 'Add account line';

  @override
  String get calculate => 'Calculate';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get budgetLineAccount => 'Budget account';

  @override
  String get plannedAmount => 'Planned amount';

  @override
  String get budgetSaved => 'Budget saved';

  @override
  String get budgetDeleted => 'Budget deleted';

  @override
  String get noBudgets =>
      'No budgets yet. Add a budget to compare planned amounts with ledger activity.';

  @override
  String get summaryTab => 'Summary';

  @override
  String get variancesTab => 'Variances';

  @override
  String get flexibleBudgetTab => 'Flexible Budget';

  @override
  String get budgetedNetIncome => 'Budgeted Net Income';

  @override
  String get actualNetIncome => 'Actual Net Income';

  @override
  String get netIncomeVariance => 'Net Income Variance';

  @override
  String get revenueLabel => 'Revenue';

  @override
  String get expensesLabel => 'Expenses';

  @override
  String get flexibleBudgetAnalysis => 'Flexible Budget Analysis';

  @override
  String get fixedCosts => 'Fixed Costs';

  @override
  String get variableRateUnit => 'Variable Rate/Unit';

  @override
  String get plannedActivity => 'Planned Activity';

  @override
  String get actualActivity => 'Actual Activity';

  @override
  String get actualTotalCost => 'Actual Total Cost';

  @override
  String get budgetedLabel => 'Budgeted';

  @override
  String get actualLabel => 'Actual';

  @override
  String get varianceLabel => 'Variance';

  @override
  String get favorableLabel => 'Favorable';

  @override
  String get unfavorableLabel => 'Unfavorable';

  @override
  String get onTarget => 'On Target';

  @override
  String get capitalBudgeting => 'Capital Budgeting';

  @override
  String get calculatorTab => 'Calculator';

  @override
  String get resultsTab => 'Results';

  @override
  String get sensitivityTab => 'Sensitivity';

  @override
  String get initialInvestment => 'Initial Investment';

  @override
  String get investmentAmount => 'Investment Amount';

  @override
  String get discountRateLabel => 'Discount Rate';

  @override
  String get rateLabel => 'Rate';

  @override
  String get requiredReturn => 'Required Return';

  @override
  String get expectedCashFlows => 'Expected Cash Flows';

  @override
  String get forArrCalculation => 'For ARR Calculation';

  @override
  String get annualNetIncome => 'Annual Net Income';

  @override
  String get residualValueLabel => 'Residual Value';

  @override
  String get calculateViewResults => 'Calculate & View Results';

  @override
  String get netPresentValue => 'Net Present Value (NPV)';

  @override
  String get internalRateOfReturn => 'Internal Rate of Return (IRR)';

  @override
  String get paybackPeriod => 'Payback Period';

  @override
  String get investmentRecovered => 'Investment will be recovered';

  @override
  String get investmentMayNotRecover => 'Investment may not be recovered';

  @override
  String get discountedPaybackPeriod => 'Discounted Payback Period';

  @override
  String get accountsForTimeValue => 'Accounts for time value of money';

  @override
  String get profitabilityIndex => 'Profitability Index (PI)';

  @override
  String get accountingRateOfReturn => 'Accounting Rate of Return (ARR)';

  @override
  String get acceptDecision => 'Accept';

  @override
  String get rejectDecision => 'Reject';

  @override
  String get npvSensitivity => 'NPV Sensitivity to Discount Rate';

  @override
  String get discountRateColumn => 'Discount Rate';

  @override
  String get npvColumn => 'NPV';

  @override
  String get decisionColumn => 'Decision';

  @override
  String get selectPeriodTooltip => 'Select Period';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get errorLoadingRatios => 'Error loading ratios';

  @override
  String get analysisPeriod => 'Analysis Period';

  @override
  String get liquidityRatios => 'Liquidity Ratios';

  @override
  String get activityRatios => 'Activity Ratios';

  @override
  String get profitabilityRatios => 'Profitability Ratios';

  @override
  String get leverageRatios => 'Leverage Ratios';

  @override
  String get cashRatio => 'Cash Ratio';

  @override
  String get workingCapitalLabel => 'Working Capital';

  @override
  String get inventoryTurnover => 'Inventory Turnover';

  @override
  String get daysSalesInInventory => 'Days Sales in Inventory';

  @override
  String get daysSalesOutstanding => 'Days Sales Outstanding';

  @override
  String get cashConversionCycle => 'Cash Conversion Cycle';

  @override
  String get assetTurnover => 'Asset Turnover';

  @override
  String get operatingProfitMargin => 'Operating Profit Margin';

  @override
  String get returnOnEquity => 'Return on Equity (ROE)';

  @override
  String get ebitdaMargin => 'EBITDA Margin';

  @override
  String get debtToEquityRatio => 'Debt-to-Equity Ratio';

  @override
  String get debtToAssetsRatio => 'Debt-to-Assets Ratio';

  @override
  String get equityMultiplier => 'Equity Multiplier';

  @override
  String get interestCoverage => 'Interest Coverage';

  @override
  String get timesInterestEarned => 'Times Interest Earned';

  @override
  String get cashFlowsOperating => 'Cash Flows from Operating Activities';

  @override
  String get cashFlowsInvesting => 'Cash Flows from Investing Activities';

  @override
  String get cashFlowsFinancing => 'Cash Flows from Financing Activities';

  @override
  String get netCashOperating => 'Net Cash from Operating';

  @override
  String get netCashInvesting => 'Net Cash from Investing';

  @override
  String get netCashFinancing => 'Net Cash from Financing';

  @override
  String get fraudDetection => 'Fraud Detection (M-Score)';

  @override
  String get inputTab => 'Input';

  @override
  String get learnTab => 'Learn';

  @override
  String get currentPeriodLabel => 'Current Period';

  @override
  String get priorPeriod => 'Prior Period';

  @override
  String get componentIndices => 'Component Indices';

  @override
  String get redFlagsLabel => 'Red Flags';

  @override
  String get whatIsBeneish => 'What is the Beneish M-Score?';

  @override
  String get theFormula => 'The Formula';

  @override
  String get indexExplanations => 'Index Explanations';

  @override
  String get famousCases => 'Famous Cases';

  @override
  String get probableManipulator => 'Probable Manipulator';

  @override
  String get standardCosting => 'Standard Costing';

  @override
  String get standardsTab => 'Standards';

  @override
  String get materialsTab => 'Materials';

  @override
  String get laborTab => 'Labor';

  @override
  String get overheadTab => 'Overhead';

  @override
  String get importData => 'Import Data';

  @override
  String get selectFile => 'Select File';

  @override
  String get chooseDataType => 'Choose Data Type';

  @override
  String get mapColumns => 'Map Columns';

  @override
  String get chooseFile => 'Choose File';

  @override
  String get continueBtn => 'Continue';

  @override
  String get importBtn => 'Import';

  @override
  String get backBtn => 'Back';

  @override
  String get doneBtn => 'Done';

  @override
  String get selectCsvFile => 'Select a CSV or Excel file to import.';

  @override
  String get whatDataImporting => 'What type of data are you importing?';

  @override
  String get mapEachColumn => 'Map each column to a field:';

  @override
  String get errorsLabel => 'Errors:';

  @override
  String get productsTitle => 'Products';

  @override
  String get newProduct => 'New Product';

  @override
  String get addProductTitle => 'Add Product';

  @override
  String get editProductTitle => 'Edit Product';

  @override
  String get saveProduct => 'Save Product';

  @override
  String get vendorsTitle => 'Vendors';

  @override
  String get addVendorBtn => 'Add Vendor';

  @override
  String get newVendorForm => 'New Vendor';

  @override
  String get editVendorForm => 'Edit Vendor';

  @override
  String get vendorCreated => 'Vendor created successfully';

  @override
  String get vendorUpdated => 'Vendor updated successfully';

  @override
  String get vendorDetailTitle => 'Vendor';

  @override
  String get customersTitle => 'Customers';

  @override
  String get addCustomerBtn => 'Add Customer';

  @override
  String get newCustomerForm => 'New Customer';

  @override
  String get editCustomerForm => 'Edit Customer';

  @override
  String get customerCreated => 'Customer created successfully';

  @override
  String get customerUpdated => 'Customer updated successfully';

  @override
  String get customerDetailTitle => 'Customer';

  @override
  String get putCustomerOnHold => 'Put Customer On Hold';

  @override
  String get preventsNewInvoices => 'Prevents new invoices/orders';

  @override
  String get pleaseAddLineItem =>
      'Please add at least one line item with an amount.';

  @override
  String get saveBtn => 'Save';

  @override
  String get cancelBtn => 'Cancel';

  @override
  String get createBtn => 'Create';

  @override
  String get changeBtn => 'Change';

  @override
  String get reconcileBtn => 'Reconcile';

  @override
  String get statementBalanceLabel => 'Statement Balance:';

  @override
  String get bookBalanceLabel => 'Book Balance:';

  @override
  String get entryReconciled => 'Entry reconciled';

  @override
  String get staffManagement => 'Staff Management';

  @override
  String get activeStaff => 'Active';

  @override
  String get suspendStaff => 'Suspend access';

  @override
  String get reactivateStaff => 'Reactivate access';

  @override
  String get revokeInvitation => 'Revoke invitation';

  @override
  String get pendingStaff => 'Pending invitations';

  @override
  String get suspendedStaff => 'Suspended';

  @override
  String get expiredStaff => 'Expired invitations';

  @override
  String get revokedStaff => 'Revoked invitations';

  @override
  String get searchStaff => 'Search employees';

  @override
  String get changeRole => 'Change Role';

  @override
  String get removeAccess => 'Remove Access';

  @override
  String get roleSaved => 'Role saved successfully!';

  @override
  String get roleNameLabel => 'Role Name';

  @override
  String get selectPermission => 'Please select at least one permission.';

  @override
  String get systemAdminReadonly => 'System Admin role cannot be edited.';

  @override
  String get noRolesDefined =>
      'No roles defined yet. Create one to assign permissions.';

  @override
  String get fullSystemAccess => 'Full system access';

  @override
  String permissionsCount(int count) {
    return '$count permissions';
  }

  @override
  String get customFieldsProducts => 'Custom Fields (Products)';

  @override
  String get enterDataCalculator =>
      'Enter investment data in the Calculator tab';

  @override
  String get enterDataAnalysis => 'Enter data to see analysis';

  @override
  String get enterFinancialData => 'Enter financial data to see results';

  @override
  String get iUnderstand => 'I Understand';

  @override
  String get gotItBtn => 'Got it';

  @override
  String get budgetVsActual => 'Budget vs Actual by Account';

  @override
  String get greenFavorable => 'Green = Favorable | Red = Unfavorable';

  @override
  String get budgetComparison => 'Budget Comparison';

  @override
  String get staticBudget => 'Static Budget';

  @override
  String get actualCost => 'Actual Cost';

  @override
  String get varianceAnalysis => 'Variance Analysis';

  @override
  String get volumeVariance => 'Volume Variance';

  @override
  String get dueToActivityLevel => 'Due to activity level difference';

  @override
  String get spendingVariance => 'Spending Variance';

  @override
  String get dueToEfficiency => 'Due to efficiency/price';

  @override
  String get totalVariance => 'Total Variance';

  @override
  String get actualMinusStatic => 'Actual - Static Budget';

  @override
  String get separateVariances =>
      'Separate volume variances from spending variances';

  @override
  String get formulasUsed => 'Formulas Used';

  @override
  String get revenueInput => 'Revenue';

  @override
  String get receivablesInput => 'Receivables';

  @override
  String get grossProfitInput => 'Gross Profit';

  @override
  String get totalAssetsInput => 'Total Assets';

  @override
  String get currentAssetsInput => 'Current Assets';

  @override
  String get ppeInput => 'PP&E';

  @override
  String get depreciationInput => 'Depreciation';

  @override
  String get sgaExpenseInput => 'SG&A Expense';

  @override
  String get netIncomeInput => 'Net Income';

  @override
  String get cashFromOps => 'Cash from Ops';

  @override
  String get longTermDebt => 'Long-Term Debt';

  @override
  String get currentLiabilities => 'Current Liabilities';

  @override
  String get probableManipulatorLabel => 'PROBABLE MANIPULATOR';

  @override
  String get vendorInvoiceOptional => 'Vendor Invoice # (Optional)';

  @override
  String get customerNameRequired => 'Customer Name *';

  @override
  String get vendorNameRequired => 'Vendor Name *';

  @override
  String get paymentTermsHint => 'Payment Terms (e.g., Net 30)';

  @override
  String get emailLabel => 'Email';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get addressLabel => 'Address';

  @override
  String get notesLabel => 'Notes';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get qtyLabel => 'Qty';

  @override
  String get dateLabel => 'Date';

  @override
  String get barcode => 'Barcode';

  @override
  String get joinedOrganization => 'Successfully joined organization!';

  @override
  String get roleNameHint => 'e.g., Senior Cashier';

  @override
  String get mapTo => 'Map to';

  @override
  String get addAssetComingSoon => 'Add Asset feature coming soon';

  @override
  String get assetDisposalComingSoon => 'Asset disposal feature coming soon';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get retry => 'Try again';

  @override
  String get errorLoadingBills => 'Error loading bills';

  @override
  String get errorLoadingInvoices => 'Error loading invoices';

  @override
  String get errorSavingRole => 'Error saving role';

  @override
  String get selectTransactionsToReconcile =>
      'Please select transactions to reconcile';

  @override
  String reconcileAmount(String currency) {
    return 'Reconcile $currency';
  }

  @override
  String get enterDataInCalculator => 'Enter data in the Calculator tab first';

  @override
  String get scenarioColumn => 'Scenario';

  @override
  String get breakEvenColumn => 'Break-Even';

  @override
  String get changeColumn => 'Change';

  @override
  String get impactColumn => 'Impact';

  @override
  String get variableOverhead => 'Variable Overhead';

  @override
  String get fixedOverhead => 'Fixed Overhead';

  @override
  String get examplesLabel => 'Examples:';

  @override
  String get reconciliation => 'Reconciliation';

  @override
  String get letsSetUpCorrectly => 'Let\'s set things up correctly.';

  @override
  String get addField => 'Add Field';

  @override
  String get editField => 'Edit Field';

  @override
  String get noCustomFieldsDefined => 'No custom fields defined.';

  @override
  String customFieldTypeAndKey(String type, String key) {
    return 'Type: $type | Key: $key';
  }

  @override
  String get customFieldDisplayLabelHint =>
      'Display label (for example, Color)';

  @override
  String get customFieldInternalKeyHint => 'Internal key (for example, color)';

  @override
  String get customFieldDataType => 'Data Type';

  @override
  String get customFieldText => 'Text';

  @override
  String get customFieldNumber => 'Number';

  @override
  String get customFieldBoolean => 'Yes/No';

  @override
  String get customFieldDate => 'Date';

  @override
  String get customFieldKeyInvalid =>
      'Use lowercase snake_case letters, numbers, and underscores.';

  @override
  String get customFieldLabelRequired => 'Display label is required';

  @override
  String get editRole => 'Edit Role';

  @override
  String get createNewRole => 'Create New Role';

  @override
  String get creatingBtn => 'Creating...';

  @override
  String get allCategories => 'All';

  @override
  String inStock(int count) {
    return '$count in stock';
  }

  @override
  String cartSummary(int count, String total) {
    return 'Cart: $count items — $total';
  }

  @override
  String get orderSummary => 'Order Summary';

  @override
  String taxLabel(String rate) {
    return 'Tax ($rate%)';
  }

  @override
  String get discountLabel => 'Discount';

  @override
  String get totalUppercase => 'TOTAL';

  @override
  String get holdOrder => 'Hold Order';

  @override
  String get noProducts => 'No products found';

  @override
  String get noProductsInFile => 'No products found in file.';

  @override
  String get importButton => 'Import';

  @override
  String importProductsCount(int count) {
    return 'Import $count Products';
  }

  @override
  String recordsImported(int count) {
    return '$count products imported successfully';
  }

  @override
  String get searchProducts => 'Search products...';

  @override
  String get adjustStock => 'Adjust stock';

  @override
  String get addStock => 'Add stock';

  @override
  String get removeStock => 'Remove stock';

  @override
  String get quantityToAdd => 'Quantity to add';

  @override
  String get quantityToRemove => 'Quantity to remove';

  @override
  String get currentStock => 'Current stock';

  @override
  String get lowStock => 'Low stock';

  @override
  String get stockUpdated => 'Stock updated successfully';

  @override
  String get stockUpdateFailed => 'Could not update stock';

  @override
  String get invalidQuantity => 'Enter a valid positive quantity';

  @override
  String productsCount(int count) {
    return '$count products';
  }

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartEmptyHint => 'Tap products to add them to your order';

  @override
  String payWith(String method) {
    return 'Pay with $method';
  }

  @override
  String get orderParked => 'Order Parked';

  @override
  String get recallOrder => 'Recall Order';

  @override
  String orderNumber(String id) {
    return 'Order #$id';
  }

  @override
  String itemsAndTime(int count, int time) {
    return '$count items • $time mins ago';
  }

  @override
  String get closeBtn => 'Close';

  @override
  String get getStarted => 'Get Started';

  @override
  String get selectPrimaryCurrency => 'Select Primary Currency';

  @override
  String get currencyCodeLabel => 'Code (e.g. YER)';

  @override
  String get currencySymbolLabel => 'Symbol (﷼)';

  @override
  String benchmarkLabel(String value) {
    return 'Benchmark: $value';
  }

  @override
  String get breakEvenTab => 'Break-Even';

  @override
  String get marginOfSafetyTab => 'Margin of Safety';

  @override
  String get whatIfTab => 'What-If';

  @override
  String get contributionMarginLabel => 'Contribution Margin:';

  @override
  String get perUnitSuffix => 'per unit';

  @override
  String get unitsSuffix => 'units';

  @override
  String get salesRevenueLabel => 'Sales Revenue';

  @override
  String get analyzeViewResults => 'Analyze & View Results';

  @override
  String get enterDataCalculatorFirst =>
      'Enter data in the Calculator tab first';

  @override
  String get unitsLabel => 'UNITS';

  @override
  String get salesLabel => 'SALES';

  @override
  String get contributionMarginTitle => 'Contribution Margin';

  @override
  String get cmPerUnit => 'CM per Unit';

  @override
  String get cmRatio => 'CM Ratio';

  @override
  String get marginOfSafetyTitle => 'Margin of Safety';

  @override
  String get riskSuffix => 'RISK';

  @override
  String get mosDollar => 'MOS (\$)';

  @override
  String get mosUnits => 'MOS (Units)';

  @override
  String get impactLabel => 'Impact';

  @override
  String leverageImpactDesc(String percent) {
    return '1% sales change → $percent% profit change';
  }

  @override
  String get priceSensitivityDesc =>
      'Shows how break-even changes when you adjust selling price';

  @override
  String get baseImpact => 'Base';

  @override
  String get betterImpact => 'Better';

  @override
  String get worseImpact => 'Worse';

  @override
  String get keyInsights => 'Key Insights';

  @override
  String get projectedProfit => 'PROJECTED PROFIT';

  @override
  String get projectedLoss => 'PROJECTED LOSS';

  @override
  String strongSafetyMargin(String percent) {
    return 'Strong safety margin. Sales can drop $percent% before reaching break-even.';
  }

  @override
  String get moderateSafetyMargin =>
      'Moderate safety margin. Consider strategies to increase sales or reduce costs.';

  @override
  String get thinSafetyMargin =>
      'Thin safety margin. The business is close to break-even and vulnerable to sales declines.';

  @override
  String get belowBreakEven =>
      'Operating below break-even. Immediate action needed to increase revenue or reduce costs.';

  @override
  String get higherPricesInsight =>
      'Higher prices = Lower break-even (fewer units needed)';

  @override
  String get lowerPricesInsight =>
      'Lower prices = Higher break-even (more units needed)';

  @override
  String priceIncreaseEffect(String units) {
    return 'A 10% price increase reduces break-even by $units units';
  }

  @override
  String priceDecreaseEffect(String units) {
    return 'A 10% price decrease increases break-even by $units units';
  }

  @override
  String get formulaCurrentRatio => 'Current Assets ÷ Current Liabilities';

  @override
  String get formulaQuickRatio => '(Cash + Receivables) ÷ Current Liabilities';

  @override
  String get formulaCashRatio => 'Cash ÷ Current Liabilities';

  @override
  String get formulaWorkingCapital => 'Current Assets - Current Liabilities';

  @override
  String get formulaInventoryTurnover => 'COGS ÷ Average Inventory';

  @override
  String get formulaDaysSalesInInventory => '365 ÷ Inventory Turnover';

  @override
  String get formulaReceivablesTurnover => 'Net Sales ÷ Average Receivables';

  @override
  String get formulaDaysSalesOutstanding => '365 ÷ Receivables Turnover';

  @override
  String get formulaCashConversionCycle => 'DSI + DSO - DPO';

  @override
  String get formulaAssetTurnover => 'Net Sales ÷ Average Total Assets';

  @override
  String get formulaGrossProfitMargin => '(Revenue - COGS) ÷ Revenue';

  @override
  String get formulaOperatingProfitMargin => 'Operating Income ÷ Revenue';

  @override
  String get formulaNetProfitMargin => 'Net Income ÷ Revenue';

  @override
  String get formulaReturnOnAssets => 'Net Income ÷ Average Total Assets';

  @override
  String get formulaReturnOnEquity => 'Net Income ÷ Average Equity';

  @override
  String get formulaEbitdaMargin => 'EBITDA ÷ Revenue';

  @override
  String get formulaDebtToEquity => 'Total Liabilities ÷ Shareholders\' Equity';

  @override
  String get formulaDebtToAssets => 'Total Liabilities ÷ Total Assets';

  @override
  String get formulaEquityMultiplier => 'Total Assets ÷ Shareholders\' Equity';

  @override
  String get formulaInterestCoverage => 'EBIT ÷ Interest Expense';

  @override
  String get formulaTimesInterestEarned =>
      '(Net Income + Interest + Tax) ÷ Interest';

  @override
  String get notAvailable => 'N/A';

  @override
  String get daysSuffix => 'days';

  @override
  String get standardCostCard => 'Standard Cost Card';

  @override
  String get materialQtyUnit => 'Material Qty/Unit';

  @override
  String get materialPrice => 'Material Price';

  @override
  String get laborHoursUnit => 'Labor Hours/Unit';

  @override
  String get laborRate => 'Labor Rate';

  @override
  String get vohRate => 'VOH Rate';

  @override
  String get budgetedFoh => 'Budgeted FOH';

  @override
  String get normalCapacity => 'Normal Capacity';

  @override
  String get actualProduction => 'Actual Production';

  @override
  String get unitsProduced => 'Units Produced';

  @override
  String get materialUsed => 'Material Used';

  @override
  String get laborHours => 'Labor Hours';

  @override
  String get actualVoh => 'Actual VOH';

  @override
  String get actualFoh => 'Actual FOH';

  @override
  String totalVarianceAmount(String amount) {
    return 'Total Variance: $amount';
  }

  @override
  String get netFavorable => 'Net Favorable';

  @override
  String get netUnfavorable => 'Net Unfavorable';

  @override
  String get directMaterialsVariance => 'Direct Materials Variance';

  @override
  String get standardCost => 'Standard Cost';

  @override
  String get actualCostLabel => 'Actual Cost';

  @override
  String get varianceBreakdown => 'Variance Breakdown';

  @override
  String get priceVariance => 'Price Variance';

  @override
  String get priceVarianceFormula => '(AP - SP) × AQ';

  @override
  String get quantityVariance => 'Quantity Variance';

  @override
  String get quantityVarianceFormula => '(AQ - SQ) × SP';

  @override
  String get materialsFormulas => 'Materials Formulas';

  @override
  String get priceVarianceFormulaFull =>
      'Price Variance = (Actual Price - Standard Price) × Actual Qty';

  @override
  String get quantityVarianceFormulaFull =>
      'Quantity Variance = (Actual Qty - Standard Qty) × Standard Price';

  @override
  String get directLaborVariance => 'Direct Labor Variance';

  @override
  String get rateVariance => 'Rate Variance';

  @override
  String get rateVarianceFormula => '(AR - SR) × AH';

  @override
  String get efficiencyVariance => 'Efficiency Variance';

  @override
  String get efficiencyVarianceFormula => '(AH - SH) × SR';

  @override
  String get laborFormulas => 'Labor Formulas';

  @override
  String get rateVarianceFormulaFull =>
      'Rate Variance = (Actual Rate - Standard Rate) × Actual Hours';

  @override
  String get efficiencyVarianceFormulaFull =>
      'Efficiency Variance = (Actual Hours - Std Hours) × Std Rate';

  @override
  String get manufacturingOverheadVariance => 'Manufacturing Overhead Variance';

  @override
  String get appliedOverhead => 'Applied Overhead';

  @override
  String get actualOverhead => 'Actual Overhead';

  @override
  String get overapplied => 'Overapplied';

  @override
  String get underapplied => 'Underapplied';

  @override
  String get budgetVariance => 'Budget Variance';

  @override
  String get actualFohMinusBudgeted => 'Actual FOH - Budgeted FOH';

  @override
  String get budgetedFohMinusApplied => 'Budgeted FOH - Applied FOH';

  @override
  String get actualVohFormula => 'Actual VOH - (AH × SR)';

  @override
  String get unitSuffix => 'units';

  @override
  String get dollarPerUnit => '\$/unit';

  @override
  String get hrsSuffix => 'hrs';

  @override
  String get dollarPerHr => '\$/hr';

  @override
  String get favorableBadge => 'F';

  @override
  String get unfavorableBadge => 'U';

  @override
  String mScoreValue(String value) {
    return 'M-Score: $value';
  }

  @override
  String riskLevelLabel(String level) {
    return '$level Risk';
  }

  @override
  String riskOfEarningsManipulation(String level) {
    return '$level Risk of Earnings Manipulation';
  }

  @override
  String get thresholdNote => 'Threshold: > -1.78 indicates manipulation';

  @override
  String get dsriAbbr => 'DSRI';

  @override
  String get dsriDesc => 'Receivables/Sales';

  @override
  String get gmiAbbr => 'GMI';

  @override
  String get gmiDesc => 'Gross Margin';

  @override
  String get aqiAbbr => 'AQI';

  @override
  String get aqiDesc => 'Asset Quality';

  @override
  String get sgiAbbr => 'SGI';

  @override
  String get sgiDesc => 'Sales Growth';

  @override
  String get depiAbbr => 'DEPI';

  @override
  String get depiDesc => 'Depreciation';

  @override
  String get sgaiAbbr => 'SGAI';

  @override
  String get sgaiDesc => 'SG&A Expenses';

  @override
  String get tataAbbr => 'TATA';

  @override
  String get tataDesc => 'Accruals';

  @override
  String get lvgiAbbr => 'LVGI';

  @override
  String get lvgiDesc => 'Leverage';

  @override
  String redFlagsCount(int count) {
    return 'Red Flags ($count)';
  }

  @override
  String get whatIsBeneishMScore => 'What is the Beneish M-Score?';

  @override
  String get beneishDescription =>
      'The M-Score is a mathematical model that uses 8 financial ratios to identify whether a company has manipulated its earnings. Developed by Professor Messod Beneish, it is widely used by auditors, investors, and analysts.';

  @override
  String get beneishFormula =>
      'M = -4.84 + 0.92×DSRI + 0.528×GMI\n+ 0.404×AQI + 0.892×SGI\n+ 0.115×DEPI - 0.172×SGAI\n+ 4.679×TATA - 0.327×LVGI';

  @override
  String get indexExplanationsTitle => 'Index Explanations';

  @override
  String get dsriFullName => 'Days Sales in Receivables Index';

  @override
  String get dsriExplanation =>
      'Measures if receivables grew faster than sales';

  @override
  String get gmiFullName => 'Gross Margin Index';

  @override
  String get gmiExplanation => 'Detects deteriorating gross margins';

  @override
  String get aqiFullName => 'Asset Quality Index';

  @override
  String get aqiExplanation => 'Identifies expense capitalization';

  @override
  String get sgiFullName => 'Sales Growth Index';

  @override
  String get sgiExplanation => 'High growth creates manipulation pressure';

  @override
  String get depiFullName => 'Depreciation Index';

  @override
  String get depiExplanation => 'Detects slowing depreciation rates';

  @override
  String get sgaiFullName => 'SG&A Index';

  @override
  String get sgaiExplanation => 'Measures administrative efficiency';

  @override
  String get tataFullName => 'Total Accruals to Total Assets';

  @override
  String get tataExplanation => 'High accruals vs cash = low quality';

  @override
  String get lvgiFullName => 'Leverage Index';

  @override
  String get lvgiExplanation => 'Increasing debt creates pressure';

  @override
  String get famousCasesTitle => 'Famous Cases';

  @override
  String get famousCasesContent =>
      '• Enron (2001): Would have had M-Score > -1.78\n• WorldCom (2002): Showed multiple red flags\n• Satyam (2009): DSRI and AQI were extreme\n• The model correctly identifies ~76% of manipulators';

  @override
  String yearLabel(int number) {
    return 'Year $number';
  }

  @override
  String pvOfCashFlows(String value) {
    return 'PV of Cash Flows: $value';
  }

  @override
  String initialInvestmentDetail(String value) {
    return 'Initial Investment: $value';
  }

  @override
  String discountRateDetail(String value) {
    return 'Discount Rate: $value';
  }

  @override
  String convergedLabel(String value) {
    return 'Converged: $value';
  }

  @override
  String iterationsLabel(int value) {
    return 'Iterations: $value';
  }

  @override
  String averageInvestment(String value) {
    return 'Average Investment: $value';
  }

  @override
  String get acceptLabel => 'ACCEPT';

  @override
  String get rejectLabel => 'REJECT';

  @override
  String recommendationLabel(String value) {
    return 'RECOMMENDATION: $value';
  }

  @override
  String criteriaMetLabel(int count) {
    return '$count of 4 criteria met';
  }

  @override
  String get npvSensitivityDesc =>
      'Shows how NPV changes as the discount rate varies';

  @override
  String irrApproxLabel(String min, String max) {
    return 'The IRR (where NPV = 0) is approximately $min% - $max%';
  }

  @override
  String get revenueSection => 'REVENUE';

  @override
  String get expensesSection => 'EXPENSES';

  @override
  String get formulasDescription =>
      '• Static Budget = Fixed + (Variable × Planned Activity)\n• Flexible Budget = Fixed + (Variable × Actual Activity)\n• Volume Variance = Flexible Budget - Static Budget\n• Spending Variance = Actual Cost - Flexible Budget';

  @override
  String get addExchangeRate => 'Add Exchange Rate';

  @override
  String get fromCurrency => 'From';

  @override
  String get toCurrency => 'To';

  @override
  String get pleaseEnterCurrency => 'Please select currency';

  @override
  String get exchangeRateHelper => '1 From = X To';

  @override
  String get pleaseEnterValidRate => 'Valid rate required';

  @override
  String get accountCurrency => 'Currency';

  @override
  String get initialBalances => 'Initial Balances';

  @override
  String get debitBalance => 'Debit Balance';

  @override
  String get creditBalance => 'Credit Balance';

  @override
  String get netBalance => 'Net Balance';

  @override
  String get exchangeRates => 'Exchange Rates';

  @override
  String get noExchangeRates => 'No rates added';

  @override
  String get saveAccount => 'Save Account';

  @override
  String get password => 'Password';

  @override
  String get createAccount => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign In';

  @override
  String get needAccount => 'Need an account? Sign Up';

  @override
  String get enterEmailAndPassword => 'Please enter both email and password.';

  @override
  String get signUpSubtitle => 'Sign up to create your business';

  @override
  String get emailConfirmationRequired =>
      'Check your email to confirm your account before signing in.';

  @override
  String get authenticationRequired => 'Please sign in to continue.';

  @override
  String get invalidCredentials => 'The email or password is incorrect.';

  @override
  String get emailAlreadyRegistered =>
      'An account with this email already exists.';

  @override
  String get authRateLimited => 'Too many attempts. Please try again later.';

  @override
  String get networkAuthenticationError =>
      'The network is unavailable. Please try again.';

  @override
  String get unknownAuthenticationError =>
      'Authentication could not be completed.';

  @override
  String get passwordMinLength =>
      'Password must contain at least 8 characters.';

  @override
  String get orSeparator => 'OR';

  @override
  String get paidFeatureTitle => 'Paid Feature';

  @override
  String get paidFeatureMessage =>
      'This feature requires an active subscription and account login. Please sign in and subscribe to access staff and roles management.';

  @override
  String get signInToAccess => 'Sign In';

  @override
  String get nameIsRequired => 'Name is required';

  @override
  String get permissionsLabel => 'Permissions';

  @override
  String get permViewDashboard => 'View Dashboard';

  @override
  String get permViewFinancialReports => 'View Financial Reports';

  @override
  String get permPerformSale => 'Perform Sales (POS)';

  @override
  String get permVoidTransaction => 'Void/Delete Transactions';

  @override
  String get permProcessRefund => 'Process Refunds';

  @override
  String get permViewSalesHistory => 'View Sales History';

  @override
  String get permViewInventory => 'View Inventory';

  @override
  String get permManageProducts => 'Add/Edit Products';

  @override
  String get permAdjustInventory => 'Stock Adjustments';

  @override
  String get permManageStaff => 'Manage Staff & Roles';

  @override
  String get permManageSettings => 'System Settings';

  @override
  String get permManageBranches => 'Manage Branches';

  @override
  String get permApproveRequests => 'Approve Requests';

  @override
  String get permManageCrm => 'Manage CRM';

  @override
  String get permManageCustomers => 'Manage Customers';

  @override
  String get permManageVendors => 'Manage Vendors';

  @override
  String get permCreateInvoices => 'Create Invoices';

  @override
  String get permManageInvoices => 'Manage Invoices';

  @override
  String get permCreateBills => 'Create Bills';

  @override
  String get permManageBills => 'Manage Bills';

  @override
  String get permManageAccounting => 'Manage Accounting';

  @override
  String get permPostJournalEntries => 'Post Journal Entries';

  @override
  String get permSwitchTenant => 'Switch Business Branch';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get availablePlans => 'Available Plans';

  @override
  String get enterpriseMonthlyPlan => 'Enterprise (Monthly)';

  @override
  String get enterpriseMonthlyPrice => '\$30 / month';

  @override
  String get freeTierPlan => 'Free Tier';

  @override
  String get freeTierPrice => '\$0 / forever';

  @override
  String get featureCloudSync => 'Cloud Sync';

  @override
  String get featureMultiUser => 'Multi-User';

  @override
  String get featureWebAccess => 'Web Access';

  @override
  String get featureLocalOnly => 'Local Only';

  @override
  String get featureManualBackup => 'Manual Backup';

  @override
  String get currentPlanLabel => 'CURRENT PLAN';

  @override
  String planStatusLabel(String status) {
    return 'Status: $status';
  }

  @override
  String planRenewsLabel(String date) {
    return 'Renews: $date';
  }

  @override
  String get planNeverExpires => 'Never';

  @override
  String get buyButton => 'Buy';

  @override
  String get subscriptionUnavailable =>
      'Subscriptions are not available while offline. Please sign in to manage your subscription.';

  @override
  String get confirmMockPurchase => 'Confirm Purchase';

  @override
  String simulatePaymentFor(String planName) {
    return 'Simulate payment for $planName?';
  }

  @override
  String get payNowMock => 'Pay Now (Demo)';

  @override
  String get mockPaymentSuccess => '✅ Demo Payment Successful!';

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
  String get bulkInviteStaff => 'Bulk invite employees';

  @override
  String get bulkInviteHint => 'Enter one email per line, up to 100 employees';

  @override
  String bulkInviteCount(int count) {
    return 'Recipients: $count';
  }

  @override
  String bulkInviteCreated(int count) {
    return 'Created $count invitations';
  }

  @override
  String bulkInvitePartial(int success, int failed) {
    return '$success created, $failed failed';
  }

  @override
  String get bulkInviteNoEmails => 'Enter at least one valid email address';

  @override
  String get bulkInviteLimit =>
      'A batch can contain no more than 100 employees';

  @override
  String get bulkInviteResults => 'Invitation results';

  @override
  String get invitationSetupRequired =>
      'Invitation setup is incomplete. Apply the latest Supabase invitation migration and try again.';

  @override
  String get invitationAlreadyPending =>
      'An active invitation already exists for this email.';

  @override
  String get invitationPermissionDenied =>
      'You do not have permission to invite employees.';

  @override
  String get invitationNetworkError =>
      'Could not reach the invitation service. Check your connection and try again.';

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
  String get copyInviteCode => 'Copy invite code';

  @override
  String get inviteCodeCopied => 'Invite code copied';

  @override
  String inviteShareText(String code) {
    return 'You are invited to join my business on Mizan!\n\n1. Download or open the app\n2. Tap Sign In / Create Account\n3. Tap Join Organization and enter code: $code\n\nDo not forward this invitation. It is valid for 24 hours.';
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
  String get requiredField => 'Required';

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
  String get descriptionCol => 'Description';

  @override
  String get totalVarianceLabel => 'Total Variance';

  @override
  String get enterpriseLicenseActive => 'Enterprise License Active';

  @override
  String get systemAdministrator => 'You are the System Administrator';

  @override
  String get defineStaffPermissions => 'Define staff permissions';

  @override
  String get viewPlansBilling => 'View plans & billing';

  @override
  String get manageStaff => 'Manage Staff';

  @override
  String get viewListInviteMembers => 'View list & invite members';

  @override
  String get activateBusinessLicense => 'Activate Business License';

  @override
  String get initializeSystemClaimOwnership =>
      'Initialize system & claim ownership';

  @override
  String get notLoggedInWarning =>
      '⚠️ You are not logged in! Please Sign In first.';

  @override
  String get systemActivatedWelcome => '✅ System Activated! Welcome, Admin.';

  @override
  String activationFailed(String error) {
    return '❌ Activation Failed: $error';
  }

  @override
  String get premiumReportWarning =>
      '🔒 Premium Report. Upgrade to Pro or Enterprise.';

  @override
  String buyReportPrompt(String reportTitle) {
    return 'Buy \'\'$reportTitle\'\' for \$4.99?';
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
  String get customersAr => 'Customers (AR)';

  @override
  String get vendorsAp => 'Vendors (AP)';

  @override
  String get openingBalanceHint =>
      'Opening Balance (Owes You). Input 0 if no balance.';

  @override
  String get openingBalanceHintVendor =>
      'Opening Balance (You Owe). Input 0 if no balance.';

  @override
  String get emailOptional => 'Email (Optional)';

  @override
  String get phoneOptional => 'Phone (Optional)';

  @override
  String get addressOptional => 'Address (Optional)';

  @override
  String get taxIdOptional => 'Tax ID / VAT Number (Optional)';

  @override
  String get paymentTermsOptional => 'Payment Terms (Optional)';

  @override
  String get creditLimitOptional => 'Credit Limit (Optional)';

  @override
  String get notesOptional => 'Notes (Optional)';

  @override
  String get searchCustomers => 'Search Customers...';

  @override
  String get searchVendors => 'Search Vendors...';

  @override
  String get customerDetails => 'Customer Details';

  @override
  String get vendorDetails => 'Vendor Details';

  @override
  String get contactInfo => 'Contact Information';

  @override
  String get noAddressProvided => 'No address provided';

  @override
  String get noEmailProvided => 'No email provided';

  @override
  String get noPhoneProvided => 'No phone provided';

  @override
  String get noTaxIdProvided => 'No Tax ID provided';

  @override
  String get noNotesProvided => 'No notes provided';

  @override
  String get noPaymentTermsProvided => 'No payment terms provided';

  @override
  String get financialOverview => 'Financial Overview';

  @override
  String get currentBalance => 'Current Balance';

  @override
  String get totalInvoiced => 'Total Invoiced';

  @override
  String get totalPaid => 'Total Paid';

  @override
  String get recentInvoices => 'Recent Invoices';

  @override
  String get recentBills => 'Recent Bills';

  @override
  String get noRecentInvoices => 'No recent invoices.';

  @override
  String get noRecentBills => 'No recent bills.';

  @override
  String get viewAll => 'View All';

  @override
  String get actions => 'Actions';

  @override
  String get receivePayment => 'Receive Payment';

  @override
  String get statement => 'Statement';

  @override
  String get partyStatement => 'Account Statement';

  @override
  String get statementNoEntries =>
      'No statement entries for the selected contact.';

  @override
  String get statementLoadFailed =>
      'The account statement could not be loaded.';

  @override
  String get statementRunningBalance => 'Running balance';

  @override
  String get statementInvoice => 'Invoice';

  @override
  String get statementBill => 'Bill';

  @override
  String get statementSettlement => 'Settlement';

  @override
  String get statementBalanceAdjustment => 'Balance adjustment';

  @override
  String get edit => 'Edit';

  @override
  String get status => 'Status';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get partiallyPaid => 'Partially Paid';

  @override
  String get vendor => 'Vendor';

  @override
  String get addFirstCustomer =>
      'Tap the button below to add your first customer';

  @override
  String get noCustomersMatch => 'No customers match your search.';

  @override
  String get customerBalances => 'Customer Balances';

  @override
  String get contact => 'Contact';

  @override
  String get addFirstVendor => 'Tap the button below to add your first vendor';

  @override
  String get noVendorsMatch => 'No vendors match your search.';

  @override
  String get vendorBalances => 'Vendor Balances';

  @override
  String get outstandingBalance => 'Outstanding Balance';

  @override
  String get quickLedgerAdjustment => 'Quick Ledger Adjustment';

  @override
  String get creating => 'Creating...';

  @override
  String get qty => 'Qty';

  @override
  String get pleaseAddLineItemBill =>
      'Please add at least one line item with an amount.';

  @override
  String get vendorInvoiceNumberOptional => 'Vendor Invoice # (Optional)';

  @override
  String get current0To30 => 'Current\n(0-30)';

  @override
  String get days31To60 => '31-60\nDays';

  @override
  String get days61To90 => '61-90\nDays';

  @override
  String get days90Plus => '90+\nDays';

  @override
  String get days31To60Short => '31-60';

  @override
  String get days61To90Short => '61-90';

  @override
  String get days90PlusShort => '90+';

  @override
  String adjustBalance(String name) {
    return 'Adjust Balance: $name';
  }

  @override
  String get charge => 'Charge (+)';

  @override
  String get receive => 'Receive (-)';

  @override
  String get increasesDebt => 'Increases their debt to you';

  @override
  String get decreasesDebt => 'Decreases their debt (routes to Cash)';

  @override
  String get saveAdjustment => 'Save Adjustment';

  @override
  String get increasePayable => 'Increase payable (+)';

  @override
  String get decreasePayable => 'Reduce payable (-)';

  @override
  String get increasesPayable => 'Increases the amount owed to this supplier';

  @override
  String get decreasesPayable => 'Decreases the amount owed to this supplier';

  @override
  String get supplierAdjustmentFailed =>
      'Could not update the supplier balance';

  @override
  String get adjustmentReason => 'Reason';

  @override
  String get adjustmentReasonHint =>
      'Explain why this balance is being adjusted';

  @override
  String get adjustmentReasonRequired =>
      'Enter a reason of at least 3 characters.';

  @override
  String get adjustmentReferenceOptional => 'Reference (optional)';

  @override
  String get effectiveDate => 'Effective date';

  @override
  String get reviewAdjustment => 'Review adjustment';

  @override
  String get confirmAdjustment => 'Confirm adjustment';

  @override
  String reviewBalanceAdjustment(
    String amount,
    String name,
    String newBalance,
  ) {
    return 'Apply $amount to $name? The resulting balance will be $newBalance. This creates a posted journal entry.';
  }

  @override
  String get resultingBalance => 'Resulting balance';

  @override
  String get balanceAdjustmentPreview =>
      'This adjustment will be recorded in the register and linked to a journal entry.';

  @override
  String get balanceAdjustmentCannotBeNegative =>
      'The resulting balance cannot be negative.';

  @override
  String get balanceAdjustmentFailed =>
      'The balance adjustment could not be posted.';

  @override
  String get balanceAdjustmentHistoryFailed =>
      'Could not load balance adjustment history.';

  @override
  String get adjustmentHistory => 'Adjustment history';

  @override
  String get noBalanceAdjustments =>
      'No manual balance adjustments have been posted.';

  @override
  String get adjustmentIncrease => 'Increase';

  @override
  String get adjustmentDecrease => 'Decrease';

  @override
  String get posted => 'Posted';

  @override
  String get crmSectionTitle => 'Customer & Vendor Management';

  @override
  String get crmPipeline => 'Sales Pipeline';

  @override
  String get crmPipelineIntro =>
      'Track leads, opportunities, next actions, and stage progress in one place.';

  @override
  String get crmPipelineLoadFailed => 'Could not load the CRM pipeline.';

  @override
  String get crmPipelineEmpty => 'No opportunities yet.';

  @override
  String get crmPipelineNoStages =>
      'Create an active pipeline stage before moving opportunities.';

  @override
  String get crmStage => 'Stage';

  @override
  String get crmAmount => 'Amount';

  @override
  String get crmProbability => 'Probability';

  @override
  String get crmExpectedClose => 'Expected close';

  @override
  String get crmMoveOpportunity => 'Move opportunity';

  @override
  String get crmTransitionNote => 'Transition note (optional)';

  @override
  String get crmTransitionSaved => 'Opportunity stage updated.';

  @override
  String get crmTransitionFailed => 'Could not update the opportunity stage.';

  @override
  String get crmOpen => 'Open';

  @override
  String get crmWon => 'Won';

  @override
  String get crmLost => 'Lost';

  @override
  String get crmCancelled => 'Cancelled';

  @override
  String get crmNoDate => 'No date';

  @override
  String get aiAssistantTitle => 'Mizan AI Copilot';

  @override
  String get aiAssistantIntro =>
      'Ask about your tenant’s financial and CRM data. The first release is read-only and does not post or modify records.';

  @override
  String get aiAssistantGuestMode =>
      'Connect an authenticated tenant account to use the AI Copilot with cloud data. Guest data stays on this device.';

  @override
  String get aiAssistantConnectAccount => 'Connect account';

  @override
  String get aiAssistantReadOnly => 'Read-only assistance';

  @override
  String get aiAssistantInputHint =>
      'Ask about reports, customers, vendors, invoices, or staff…';

  @override
  String get aiAssistantSend => 'Send';

  @override
  String get aiAssistantThinking => 'Mizan is analyzing…';

  @override
  String get aiAssistantError =>
      'The AI assistant could not complete this request.';

  @override
  String get aiAssistantNoData => 'No matching tenant data was found.';

  @override
  String get aiAssistantMutationBlocked =>
      'This pilot can analyze data but cannot modify records or send messages.';

  @override
  String get aiAssistantSignInRequired =>
      'Sign in to use tenant-aware AI assistance.';

  @override
  String get aiAssistantRetry => 'Try again';

  @override
  String get aiActionPreview => 'Action preview';

  @override
  String get aiActionDraftCreated => 'Draft prepared for your review.';

  @override
  String get aiActionDraftPending => 'Pending confirmation';

  @override
  String get aiActionDraftConfirmed => 'Confirmed for future execution';

  @override
  String get aiActionDraftCancelled => 'Cancelled';

  @override
  String get aiActionCancelDraft => 'Cancel draft';

  @override
  String get aiActionConfirmDraft => 'Confirm action';

  @override
  String get aiActionExecutionDisabled =>
      'Execution is not enabled yet. The draft has not changed any records.';

  @override
  String get aiActionCancelled => 'Draft cancelled.';

  @override
  String get aiActionInvalid => 'The action draft is invalid or expired.';

  @override
  String get aiActionPermissionDenied =>
      'You do not have permission to prepare this action.';

  @override
  String get aiActionTypeInvoice => 'Invoice draft';

  @override
  String get aiActionTypeBill => 'Bill draft';

  @override
  String get aiActionTypeCustomer => 'Customer draft';

  @override
  String get aiActionTypeVendor => 'Vendor draft';

  @override
  String get aiActionTypeStaffInvitation => 'Staff invitation draft';

  @override
  String get aiActionPrepareDraft => 'Prepare draft';

  @override
  String get aiActionPayloadHint => 'Enter the validated draft payload as JSON';

  @override
  String get aiActionDraftPayload => 'Draft payload';

  @override
  String get aiActionDraftForReview =>
      'This draft has not changed any records. Review it before any future execution.';

  @override
  String get aiActionInvalidPayload =>
      'Enter a valid JSON object for the selected action.';

  @override
  String get aiActionDraftStatus => 'Status';

  @override
  String get aiActionExecuted => 'Action executed successfully and audited.';

  @override
  String get aiActionExecutionFailed =>
      'Execution failed safely. No partial business change was kept.';

  @override
  String get aiActionConfirmationRequired =>
      'A valid confirmation token is required.';

  @override
  String get aiActionTypeCustomerUpdate => 'Edit customer';

  @override
  String get aiActionTypeVendorUpdate => 'Edit vendor';

  @override
  String get aiActionTypeInvoiceUpdate => 'Edit invoice';

  @override
  String get aiActionTypeBillUpdate => 'Edit bill';

  @override
  String get aiActionTypeBalanceAdjustment => 'Balance adjustment';

  @override
  String get aiActionTypeJournalPost => 'Post journal entry';

  @override
  String get aiActionTypeCustomerArchive => 'Archive customer';

  @override
  String get aiActionTypeVendorArchive => 'Archive vendor';

  @override
  String get aiActionTypeInvoiceVoid => 'Void invoice';

  @override
  String get aiActionTypeBillVoid => 'Void bill';

  @override
  String get aiActionFinancialWarning =>
      'This action changes accounting data and will be revalidated before execution.';

  @override
  String get aiActionCannotDeletePosted =>
      'Posted accounting records cannot be deleted; use void or reversal instead.';

  @override
  String get ownerControlCenter => 'Owner Control Center';

  @override
  String get ownerControlCenterIntro =>
      'Configure company-wide rules, access, workflows, and privacy without changing source code.';

  @override
  String get companyAndBranches => 'Company and branches';

  @override
  String get accountingAndPeriods => 'Accounting and fiscal periods';

  @override
  String get currenciesAndExchangeRates => 'Currencies and exchange rates';

  @override
  String get taxSettings => 'Tax settings';

  @override
  String get documentsAndNumbering => 'Documents and numbering';

  @override
  String get employeesRolesInvitations => 'Employees, roles, and invitations';

  @override
  String get approvalWorkflows => 'Approval workflows';

  @override
  String get crmConfiguration => 'CRM configuration';

  @override
  String get productsInventoryWarehouses =>
      'Products, inventory, and warehouses';

  @override
  String get posAndCashControl => 'POS and cash control';

  @override
  String get paymentMethodsSettings => 'Payment methods';

  @override
  String get notificationsSettings => 'Notifications';

  @override
  String get backupAndSyncSettings => 'Backup and synchronization';

  @override
  String get privacyAndLocalAiSettings => 'Privacy and local AI';

  @override
  String get securityAndAuditSettings => 'Security and audit';

  @override
  String get languageRegionAppearance => 'Language, region, and appearance';

  @override
  String get integrationsSettings => 'Integrations';

  @override
  String configuredCount(Object configured, Object total) {
    return '$configured of $total configured';
  }

  @override
  String get guestSettingsLocalOnly =>
      'Guest settings are saved on this device. Sign in later to synchronize company data.';

  @override
  String get ownerSettingsSaved => 'Settings saved on this device.';

  @override
  String get ownerSettingsComingNext =>
      'This control is defined in the Owner Control Center contract and will be connected to its module in the next implementation phase.';

  @override
  String get setupWizardTitle => 'Company setup';

  @override
  String get setupWizardDescription =>
      'Set up the local company profile first. You can connect an account later to synchronize company data.';

  @override
  String get setupWizardCompanyStep => 'Company identity';

  @override
  String get setupWizardAccountingStep => 'Accounting defaults';

  @override
  String get setupWizardBranchStep => 'First branch';

  @override
  String get businessIndustry => 'Industry';

  @override
  String get fiscalYearStartMonth => 'Fiscal year starts in month';

  @override
  String get defaultBranchName => 'Default branch name';

  @override
  String get selectCurrency => 'Select base currency';

  @override
  String get selectIndustry => 'Select industry';

  @override
  String get finishSetup => 'Finish setup';

  @override
  String get setupSaved => 'Company setup saved on this device.';

  @override
  String get setupRequiredForOwner =>
      'Complete company setup before configuring owner controls.';

  @override
  String get continueText => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get professionalServices => 'Professional services';

  @override
  String get roundingMode => 'Rounding mode';

  @override
  String get periodCloseRequiresOwner =>
      'Period closing requires owner approval';

  @override
  String get openingBalanceStatus => 'Opening balance status';

  @override
  String get exchangeRateSource => 'Exchange-rate source';

  @override
  String get manualRateRequiresOwner => 'Manual rates require owner approval';

  @override
  String get revaluationEnabled => 'Foreign-currency revaluation enabled';

  @override
  String get enabledCurrencies => 'Enabled currencies';

  @override
  String get defaultTaxCode => 'Default tax code';

  @override
  String get taxInclusivePricing => 'Prices include tax';

  @override
  String get taxNumberRequired => 'Tax number required';

  @override
  String get taxPeriod => 'Tax reporting period';

  @override
  String get documentPrefix => 'Document prefix';

  @override
  String get nextNumber => 'Next number';

  @override
  String get saveSettings => 'Save settings';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get settingsInvalid => 'Please correct the highlighted settings.';

  @override
  String get selectOption => 'Select an option';

  @override
  String get roundingHalfUp => 'Half up';

  @override
  String get roundingBankers => 'Banker’s rounding';

  @override
  String get exchangeRateManual => 'Manual';

  @override
  String get exchangeRateProvider => 'Provider';

  @override
  String get taxPeriodMonthly => 'Monthly';

  @override
  String get taxPeriodQuarterly => 'Quarterly';

  @override
  String get taxPeriodAnnual => 'Annual';

  @override
  String get statusNotStarted => 'Not started';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get setupWizardOperationsStep => 'Operations and onboarding';

  @override
  String get defaultPaymentMethods => 'Default payment methods';

  @override
  String get firstEmployeeEmail => 'First employee email (optional)';

  @override
  String get inviteAfterConnect =>
      'The invitation will be sent after the owner connects an account.';

  @override
  String get invitationContactRequired =>
      'Enter at least one valid email address or phone number.';

  @override
  String get invitationCreationFailed =>
      'The invitation could not be created. Check the role and recipient details, then try again.';

  @override
  String get invitationRecipientDetails => 'Recipient details';

  @override
  String get invitationDeliveryIntent => 'Delivery preference';

  @override
  String get deliveryChannel => 'Delivery channel';

  @override
  String get manualDelivery => 'Manual sharing';

  @override
  String get emailDelivery => 'Email intent';

  @override
  String get smsDelivery => 'SMS intent';

  @override
  String get deliveryIntentDisclaimer =>
      'This records how you intend to deliver the code. Automatic email or SMS requires a configured and approved provider.';

  @override
  String get deliveryIntentRecorded =>
      'The delivery preference is recorded as an intent. Share the code manually until a provider is configured.';

  @override
  String invitationCreatedFor(Object recipient) {
    return 'Invitation created for $recipient';
  }

  @override
  String inviteShareTextWithRecipient(
    Object recipient,
    Object contact,
    Object code,
  ) {
    return 'You are invited to join my business on Mizan.\n\nRecipient: $recipient\nContact: $contact\n\nOpen the app, choose Join Organization, and enter this code: $code\n\nDo not forward this invitation. It is valid for 24 hours.';
  }

  @override
  String get approvalExpenseThreshold => 'Expense approval threshold';

  @override
  String get approvalInvoiceThreshold => 'Invoice approval threshold';

  @override
  String get approvalBillThreshold => 'Bill approval threshold';

  @override
  String get journalSecondApprover => 'Journal requires a second approver';

  @override
  String get balanceAdjustmentOwner =>
      'Balance adjustment requires owner approval';

  @override
  String get refundApprovalRequired => 'Refund requires approval';

  @override
  String get discountApprovalLimit => 'Discount allowed without approval (%)';

  @override
  String get crmSettings => 'CRM configuration';

  @override
  String get customerCategories => 'Customer categories';

  @override
  String get crmLeadStages => 'Lead stages';

  @override
  String get crmPipelineStages => 'Pipeline stages';

  @override
  String get crmInteractionTypes => 'Interaction types';

  @override
  String get followUpDays => 'Default follow-up days';

  @override
  String get stockValuationMethod => 'Stock valuation method';

  @override
  String get negativeStockPolicy => 'Negative-stock policy';

  @override
  String get lowStockThreshold => 'Default low-stock threshold';

  @override
  String get defaultWarehouse => 'Default warehouse';

  @override
  String get paymentInstructions => 'Merchant payment instructions';

  @override
  String get proofReviewRequired => 'Payment proof requires review';

  @override
  String get creditTermsEnabled => 'Credit terms enabled';

  @override
  String get notificationInvoiceDue => 'Invoice due reminders';

  @override
  String get notificationLowStock => 'Low-stock alerts';

  @override
  String get notificationApprovals => 'Approval alerts';

  @override
  String get notificationSyncFailures => 'Synchronization failure alerts';

  @override
  String get notificationInvitations => 'Invitation alerts';

  @override
  String get notificationBackups => 'Backup alerts';

  @override
  String get notificationSuspiciousLogin => 'Suspicious-login alerts';

  @override
  String get syncEnabled => 'Synchronization enabled';

  @override
  String get wifiOnlyBackup => 'Back up only on Wi-Fi';

  @override
  String get backupFrequencyHours => 'Backup frequency (hours)';

  @override
  String get restoreRequiresOwner => 'Restore requires owner approval';

  @override
  String get conflictPolicy => 'Conflict policy';

  @override
  String get aiMode => 'AI mode';

  @override
  String get localModelEnabled => 'Local model enabled';

  @override
  String get promptRetention => 'Prompt retention';

  @override
  String get employeeAiAccess => 'Allow employee AI access';

  @override
  String get sessionDurationHours => 'Session duration (hours)';

  @override
  String get auditRetentionDays => 'Audit retention (days)';

  @override
  String get exportRequiresOwner => 'Exports require owner approval';

  @override
  String get mfaPolicy => 'Multi-factor authentication policy';

  @override
  String get documentLanguage => 'Document language';

  @override
  String get rtlEnabled => 'Arabic RTL layout enabled';

  @override
  String get timezone => 'Timezone';

  @override
  String get emailIntegration => 'Email integration';

  @override
  String get smsIntegration => 'SMS integration';

  @override
  String get bankImportFormat => 'Bank import format';

  @override
  String get barcodeScanner => 'Barcode scanner';

  @override
  String get printerIntegration => 'Receipt printer';

  @override
  String get driveIntegration => 'Google Drive integration';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get policyStrict => 'Strict';

  @override
  String get policyWarn => 'Warn';

  @override
  String get policyAllow => 'Allow';

  @override
  String get aiDisabled => 'AI disabled';

  @override
  String get aiLocalOnly => 'Local-only AI';

  @override
  String get aiCloudOptIn => 'Cloud AI by explicit opt-in';

  @override
  String get retentionNone => 'Do not retain';

  @override
  String get retentionLocal => 'Retain locally';

  @override
  String get mfaOptional => 'Optional';

  @override
  String get mfaRequired => 'Required';

  @override
  String get conflictNewest => 'Newest revision wins';

  @override
  String get conflictReview => 'Require manual review';

  @override
  String get duplicateDetection => 'Duplicate matching fields';

  @override
  String get posTerminals => 'POS terminals';

  @override
  String get receiptTemplate => 'Receipt template';

  @override
  String get cashDrawer => 'Cash drawers';

  @override
  String get shiftCloseRequiresOwner => 'Shift closing requires owner approval';

  @override
  String get suspendSale => 'Allow suspended sales';

  @override
  String get defaultPaymentMethod => 'Default payment method';

  @override
  String get minimizeCloudAiIdentifiers =>
      'Minimize identifiers sent to cloud AI';

  @override
  String get defaultCountry => 'Default country';

  @override
  String get bilingual => 'Bilingual';

  @override
  String get employeeGovernance => 'Employee governance';

  @override
  String get defaultRole => 'Default role';

  @override
  String get invitationExpiryHours => 'Invitation expiry (hours)';

  @override
  String get maxActiveStaff => 'Maximum active employees';

  @override
  String get requireMfaForStaff => 'Require MFA for employees';

  @override
  String get allowSelfServiceProfileEdit =>
      'Allow employees to edit their profile';

  @override
  String get defaultBranchAssignment => 'Default branch assignment';

  @override
  String get manageEmployees => 'Manage employees';

  @override
  String get branchManagement => 'Branch management';

  @override
  String get addBranch => 'Add branch';

  @override
  String get editBranch => 'Edit branch';

  @override
  String get branchName => 'Branch name';

  @override
  String get branchCode => 'Branch code';

  @override
  String get branchAddress => 'Branch address';

  @override
  String get branchSaved => 'Branch saved';

  @override
  String get branchDeleted => 'Branch deleted';

  @override
  String get activeBranch => 'Active branch';

  @override
  String get noBranchesYet => 'No branches have been configured yet.';

  @override
  String get approvalCenter => 'Approval center';

  @override
  String get noPendingApprovals => 'No pending approval requests.';

  @override
  String get warehouseManagement => 'Warehouse management';

  @override
  String get addWarehouse => 'Add warehouse';

  @override
  String get warehouseName => 'Warehouse name';

  @override
  String get warehouseAddress => 'Warehouse address';

  @override
  String get warehouseCreated => 'Warehouse created';

  @override
  String get noWarehousesYet => 'No warehouses have been configured yet.';

  @override
  String get approvalStatusPending => 'Pending';

  @override
  String get approvalStatusApproved => 'Approved';

  @override
  String get approvalStatusRejected => 'Rejected';

  @override
  String get approveRequest => 'Approve';

  @override
  String get rejectRequest => 'Reject';

  @override
  String get approvalActionLocalOnly =>
      'This local preview records the decision only. Authenticated business changes require server-side approval and audit validation.';

  @override
  String get requester => 'Requester';

  @override
  String get approvalAmount => 'Amount';

  @override
  String get approvalReason => 'Reason';

  @override
  String get approvalRequestDemo =>
      'No production approval request is created in guest mode.';

  @override
  String get approvalServerOnly =>
      'Approval decisions are validated and audited by the server.';

  @override
  String get approvalLoadError => 'Approval requests could not be loaded.';

  @override
  String get approvalDecisionFailed =>
      'The approval decision could not be saved.';

  @override
  String get approvalDecisionSaved => 'Approval decision saved.';

  @override
  String get approvalRequestTypeExpense => 'Expense';

  @override
  String get approvalRequestTypeInvoice => 'Invoice';

  @override
  String get approvalRequestTypeBill => 'Bill';

  @override
  String get approvalRequestTypeJournal => 'Journal';

  @override
  String get approvalRequestTypeBalanceAdjustment => 'Balance adjustment';

  @override
  String get approvalRequestTypeRefund => 'Refund';

  @override
  String get approvalRequestTypeDiscount => 'Discount';

  @override
  String get approvalRequestTypePeriodReopen => 'Period reopen';

  @override
  String get cashPayment => 'Cash';

  @override
  String get bankTransferPayment => 'Bank transfer';

  @override
  String get jaibPayment => 'Jaib';

  @override
  String get alKuraimiPayment => 'Al Kuraimi';

  @override
  String get yemenWalletPayment => 'Yemen Wallet';

  @override
  String get cardPayment => 'Card';

  @override
  String get creditPayment => 'Credit terms';

  @override
  String get paymentMethodCatalog => 'Payment method catalog';

  @override
  String get merchantInstructionHint =>
      'Provide the merchant number and payment instructions without storing secrets.';

  @override
  String get merchantPaymentInstructions => 'Merchant payment instructions';

  @override
  String get paymentProofReview => 'Require manual payment-proof review';

  @override
  String get settingsAuditHistory => 'Settings audit history';

  @override
  String get noSettingsAuditEntries =>
      'No settings changes have been recorded on this device.';

  @override
  String get localAuditScope =>
      'This local log records setting sections and revisions only; it never stores sensitive setting values.';

  @override
  String get openSecuritySettings => 'Open security settings';

  @override
  String get expenseSettings => 'Expenses and reimbursements';

  @override
  String get defaultExpenseAccount => 'Default expense account';

  @override
  String get expenseCategories => 'Expense categories';

  @override
  String get receiptRequired => 'Receipt required';

  @override
  String get reimbursementApprovalRequired => 'Reimbursement requires approval';

  @override
  String get mileageEnabled => 'Mileage tracking enabled';

  @override
  String get bankingAndReconciliation => 'Banking and reconciliation';

  @override
  String get bankAccountIds => 'Bank account identifiers';

  @override
  String get statementImportFormat => 'Statement import format';

  @override
  String get reconciliationRequiresOwner =>
      'Reconciliation requires owner approval';

  @override
  String get autoMatchEnabled => 'Automatic transaction matching';

  @override
  String get bankingCurrencies => 'Banking currencies';

  @override
  String get reportsSettings => 'Reports and analytics';

  @override
  String get defaultReportPeriod => 'Default report period';

  @override
  String get reportExportRequiresOwner =>
      'Report exports require owner approval';

  @override
  String get dashboardMetrics => 'Dashboard metrics';

  @override
  String get scheduledReports => 'Scheduled reports';

  @override
  String get closeManagement => 'Month-end close management';

  @override
  String get closeChecklist => 'Close checklist';

  @override
  String get closeThroughDate => 'Close through date';

  @override
  String get invalidDate => 'Enter a valid date in YYYY-MM-DD format.';

  @override
  String get closeNotExecutedGuest =>
      'Guest mode records the checklist only. It does not lock accounting periods or post closing entries.';

  @override
  String get closeChecklistSaved => 'Close checklist saved';

  @override
  String get closeRequiresReconciliation => 'Closing requires reconciliation';

  @override
  String get closeRequiresBackup => 'Closing requires a successful backup';

  @override
  String get reopenRequiresOwner => 'Reopening requires owner approval';

  @override
  String get reportPeriodMonthly => 'Current month';

  @override
  String get reportPeriodQuarterly => 'Current quarter';

  @override
  String get reportPeriodAnnual => 'Current year';

  @override
  String get chooseImportFile => 'Choose CSV or Excel file';

  @override
  String get fileImportFailed => 'The file could not be imported.';

  @override
  String get mapImportColumns => 'Map recipient columns';

  @override
  String get emailColumn => 'Email column (optional)';

  @override
  String get phoneColumn => 'Phone column (optional)';

  @override
  String get nameColumn => 'Name column (optional)';

  @override
  String get importMappingConfirmation =>
      'Confirm the columns before creating invitations. Each row needs a valid email or phone number.';

  @override
  String get duplicateImportRow => 'Duplicate recipient';

  @override
  String importRowsRejected(int count) {
    return '$count rows were rejected';
  }

  @override
  String get invitationStatusPending => 'Pending';

  @override
  String get invitationStatusExpired => 'Expired';

  @override
  String get invitationStatusRevoked => 'Revoked';

  @override
  String get invitationStatusAccepted => 'Accepted';

  @override
  String invitationExpiresAt(Object date) {
    return 'Expires $date';
  }

  @override
  String get resendInvitation => 'Resend code';

  @override
  String get invitationResentAndCopied =>
      'A new invitation code was generated and copied.';

  @override
  String get paste => 'Paste';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get inviteEmailCodeIntro =>
      'Enter the email address assigned to the invitation and the six-digit code.';

  @override
  String get setPasswordAndJoin => 'Set password and join';

  @override
  String get accountSetupFailed =>
      'The account could not be set up. Please check your details and try again.';

  @override
  String get accountAlreadyExistsUseSignIn =>
      'This email already has an account. Sign in with that account, then return to join.';

  @override
  String get passwordSetupFailed =>
      'The password could not be set. Please try again.';

  @override
  String get googleInviteAndroidOnly =>
      'Google invitation continuation is currently supported on Android. Use password setup on this platform.';

  @override
  String get invitationEmailMismatch =>
      'This invitation is assigned to a different email address.';

  @override
  String get confirmInviteCode => 'Verify invitation code';

  @override
  String get aiAssistantUnavailable =>
      'The AI service is not deployed or is currently unavailable. Ask an administrator to deploy the approved service, then try again.';

  @override
  String get aiAssistantPermissionDenied =>
      'You do not have permission to use this AI operation.';

  @override
  String get aiAssistantRetryLater =>
      'The AI assistant is temporarily unavailable. Please try again later.';

  @override
  String get aiAssistantRequestUnsupported =>
      'This AI request is not supported yet. You can use the read-only assistant or prepare a confirmed draft instead.';

  @override
  String errorWithDetails(Object details, Object message) {
    return '$message $details';
  }

  @override
  String get salesTrendLast30Days => 'Sales trend (last 30 days)';

  @override
  String get salesByCategory => 'Sales by category';

  @override
  String get topFiveProducts => 'Top 5 products';

  @override
  String get noCategoryData => 'No category data.';

  @override
  String soldQuantityValue(Object quantity) {
    return '$quantity sold';
  }

  @override
  String get skipThisColumn => '(Skip this column)';

  @override
  String requiredFieldMarker(Object label) {
    return '$label *';
  }

  @override
  String get createCustomField => 'Create custom field';

  @override
  String recordsImportedSuccessfully(Object count) {
    return '$count records imported successfully';
  }

  @override
  String importDuration(Object seconds) {
    return 'Duration: ${seconds}s';
  }

  @override
  String importRowError(Object row) {
    return 'Row $row';
  }

  @override
  String moreImportErrors(Object count) {
    return '... and $count more errors';
  }

  @override
  String get adjustmentsAndClosing => 'Adjustments & closing';

  @override
  String get allAdjustmentsApproved => 'All adjustments approved!';

  @override
  String get whatNeedToRecord => 'What do you need to record?';

  @override
  String get accrueExpenseLabel => 'Accrue expense\\n(Unpaid wages)';

  @override
  String get usePrepaidAssetLabel => 'Use prepaid asset\\n(Rent/insurance)';

  @override
  String get errorLoadingAccountsShort => 'Error loading accounts';

  @override
  String get bankReconciliationTitle => 'Bank reconciliation';

  @override
  String get allCaughtUpNoTransactions =>
      'All caught up! No transactions to reconcile.';

  @override
  String get bankMatchingTitle => 'Bank matching';

  @override
  String get pleaseEnterCurrencyDetails => 'Please enter currency details';

  @override
  String failedToPickImage(Object details) {
    return 'Failed to pick image: $details';
  }

  @override
  String get englishLanguage => 'English';

  @override
  String get arabicLanguage => 'Arabic';

  @override
  String get syncWarningTitle => 'Sync warning';

  @override
  String get syncWarningAcknowledge => 'I understand';

  @override
  String revisionNumber(Object number) {
    return 'Revision $number';
  }

  @override
  String deliveryChannelValue(Object channel) {
    return '$channel';
  }

  @override
  String get dateFormatYyyyMmDd => 'YYYY-MM-DD';

  @override
  String get paymentMethodsExample => 'cash, bank transfer, Jaib';

  @override
  String get localAiNotEnabled => 'Local AI is not enabled on this device.';

  @override
  String get localAiModelUnavailable => 'The local AI model is unavailable.';

  @override
  String get localAiRuntimeFailed => 'The Android local AI runtime failed.';

  @override
  String reconciledTransactionsCount(Object count) {
    return '$count transactions';
  }

  @override
  String get noBankAccountsCreateHint =>
      'No bank accounts found. Create a bank or cash account first.';

  @override
  String importRowCount(Object count) {
    return '$count rows';
  }

  @override
  String importMappingSummary(Object columns, Object rows) {
    return 'Found $rows rows with $columns columns.';
  }

  @override
  String importErrorCount(Object count) {
    return '$count errors';
  }

  @override
  String get recordAssetUsage => 'Record asset usage';

  @override
  String get accrueUnpaidExpense => 'Accrue unpaid expense';

  @override
  String get expenseAccountWhereValueWent =>
      'Expense account (where did the value go?)';

  @override
  String get expenseAccountWhatCost => 'Expense account (what is the cost?)';

  @override
  String get assetAccountWhatWasUsed => 'Asset account (what was used?)';

  @override
  String get liabilityAccountWhoOwed => 'Liability account (who do we owe?)';

  @override
  String get runReport => 'Run report';

  @override
  String get setParametersAndRunReport => 'Set parameters and run the report.';

  @override
  String get noDataForCriteria => 'No data found for these criteria.';

  @override
  String get selectPeriodAction => 'Select period';

  @override
  String get refreshData => 'Refresh';

  @override
  String get analysisPeriodLabel => 'Analysis period';

  @override
  String get changePeriod => 'Change';

  @override
  String get createRecord => 'Create';

  @override
  String get syncWarningMessage =>
      'We saved your data locally, but could not confirm it with the cloud.\n\nReason: This device may be offline.\n\nYour data is safe, but other devices will not see it until you reconnect.';

  @override
  String get exchangeRateFieldLabel => 'Exchange rate';

  @override
  String get confirmAction => 'Confirm';

  @override
  String get swipeMatchSkip => 'Swipe right to match, left to skip';

  @override
  String get proposeAdjustment => 'Propose adjustment';

  @override
  String get approveAction => 'Approve';

  @override
  String get importCompleted => 'Import complete';

  @override
  String get rejectAction => 'Reject';

  @override
  String depreciationConfirmMessage(Object assetName) {
    return 'Calculate and record depreciation for \"$assetName\"?';
  }

  @override
  String depreciationRecordedForAsset(Object amount, Object assetName) {
    return 'Depreciation recorded: $amount for $assetName';
  }

  @override
  String depreciationBatchProcessed(Object count, Object total) {
    return 'Processed $count assets. Total: $total';
  }

  @override
  String labelValue(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String optionalFieldLabel(Object label) {
    return '$label (optional)';
  }

  @override
  String get createCustomFieldAction => '+ Create custom field';

  @override
  String exchangeRateSummary(Object from, Object to) {
    return '1 $from = $to';
  }

  @override
  String get exchangeRateHelperText => '1 From = X To';

  @override
  String yearNumber(Object year) {
    return 'Year $year';
  }

  @override
  String roleStatusValue(Object role, Object status) {
    return '$role • $status';
  }

  @override
  String labelWithColon(Object label) {
    return '$label:';
  }

  @override
  String get unexpectedImportError => 'Unexpected import error';

  @override
  String importFieldRequired(Object field) {
    return '$field is required';
  }

  @override
  String get localAiDisabled => 'Local AI is not enabled on this device.';

  @override
  String get localAiRuntimeNotPackaged =>
      'No Android local AI runtime is packaged.';

  @override
  String get localAiInvalidRuntimeResponse =>
      'The local AI runtime returned an invalid response.';

  @override
  String get localAiUnsupportedLocale =>
      'Local AI supports Arabic and English only.';

  @override
  String get localAiLocaleNotSupported =>
      'The packaged local model does not support this language.';

  @override
  String get localAiModelLoadFailed =>
      'The local AI model could not be loaded.';

  @override
  String get localAiInferenceFailed => 'Local AI inference failed.';

  @override
  String get localAiGenericFailure =>
      'The local AI assistant could not complete this request.';
}
