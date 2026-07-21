// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get balance => 'Balance:';

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
  String get errorLoadingCategories => 'Error loading categories:';

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
  String get pleaseEnterValidAmount =>
      'Please enter a valid amount greater than zero';

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
  String get taxId => 'Tax ID / VAT Number';

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
  String get invoiceCreated => 'Invoice created';

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
  String get customersWithBalances => 'customers with balances';

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
  String get paymentTerms => 'Payment Terms';

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
  String get createBill => 'Create Bill';

  @override
  String get billCreated => 'Bill created';

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
  String get vendorsWithBalances => 'vendors with balances';

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
  String get selectedCleared => 'Selected Cleared:';

  @override
  String get differenceAmount => 'Difference';

  @override
  String get balanced => 'Balanced!';

  @override
  String get unclearedTransactions => 'Uncleared Transactions';

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
  String get addAssetAcquisitionDate => 'Acquisition Date';

  @override
  String get addAssetDepreciationMethod => 'Depreciation Method';

  @override
  String get addAssetDecliningRate => 'Declining Balance Rate';

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
  String get vendorCreated => 'Vendor created';

  @override
  String get vendorUpdated => 'Vendor updated';

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
  String get customerCreated => 'Customer created';

  @override
  String get customerUpdated => 'Customer updated';

  @override
  String get customerDetailTitle => 'Customer';

  @override
  String get putCustomerOnHold => 'Put Customer On Hold';

  @override
  String get preventsNewInvoices => 'Prevents new invoices/orders';

  @override
  String get pleaseAddLineItem => 'Please add at least one line item';

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
  String get manageRoles => 'Manage Roles';

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
  String get searchProducts => 'Search products...';

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
}
