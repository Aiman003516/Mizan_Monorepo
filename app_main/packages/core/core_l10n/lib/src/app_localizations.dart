import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'src/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @allReportsAndTools.
  ///
  /// In en, this message translates to:
  /// **'All Reports & Tools'**
  String get allReportsAndTools;

  /// No description provided for @businessInsights.
  ///
  /// In en, this message translates to:
  /// **'Business Insights'**
  String get businessInsights;

  /// No description provided for @setupBusinessCloud.
  ///
  /// In en, this message translates to:
  /// **'Setup Business Cloud'**
  String get setupBusinessCloud;

  /// No description provided for @manageRoles.
  ///
  /// In en, this message translates to:
  /// **'Manage Roles'**
  String get manageRoles;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @accountTypeAsset.
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get accountTypeAsset;

  /// No description provided for @accountTypeLiability.
  ///
  /// In en, this message translates to:
  /// **'Liability'**
  String get accountTypeLiability;

  /// No description provided for @accountTypeEquity.
  ///
  /// In en, this message translates to:
  /// **'Equity'**
  String get accountTypeEquity;

  /// No description provided for @accountTypeRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get accountTypeRevenue;

  /// No description provided for @accountTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get accountTypeExpense;

  /// No description provided for @mainDashboard.
  ///
  /// In en, this message translates to:
  /// **'Main Dashboard'**
  String get mainDashboard;

  /// No description provided for @newSalePOS.
  ///
  /// In en, this message translates to:
  /// **'New Sale / POS'**
  String get newSalePOS;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get saving;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @management.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get management;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @totalAmountsReport.
  ///
  /// In en, this message translates to:
  /// **'Total Amounts Report'**
  String get totalAmountsReport;

  /// No description provided for @monthlyAmountsReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly Amounts Report'**
  String get monthlyAmountsReport;

  /// No description provided for @accountActivity.
  ///
  /// In en, this message translates to:
  /// **'Account Activity'**
  String get accountActivity;

  /// No description provided for @manageAccounts.
  ///
  /// In en, this message translates to:
  /// **'Manage Accounts'**
  String get manageAccounts;

  /// No description provided for @manageProducts.
  ///
  /// In en, this message translates to:
  /// **'Manage Products'**
  String get manageProducts;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliers;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @noAccountsYet.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet. \nAdd one!'**
  String get noAccountsYet;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\".'**
  String noResultsFound(String query);

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type:'**
  String get type;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @errorLoadingAccounts.
  ///
  /// In en, this message translates to:
  /// **'Error loading accounts'**
  String get errorLoadingAccounts;

  /// No description provided for @errorLoadingBalances.
  ///
  /// In en, this message translates to:
  /// **'Error loading balances:'**
  String get errorLoadingBalances;

  /// No description provided for @addNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Add New Account'**
  String get addNewAccount;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get editAccount;

  /// No description provided for @accountNameHint.
  ///
  /// In en, this message translates to:
  /// **'Account Name (e.g., \"Cash\", \"Customer A\")'**
  String get accountNameHint;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @classificationOptional.
  ///
  /// In en, this message translates to:
  /// **'Classification (Optional)'**
  String get classificationOptional;

  /// No description provided for @errorLoadingClassifications.
  ///
  /// In en, this message translates to:
  /// **'Error loading classifications:'**
  String get errorLoadingClassifications;

  /// No description provided for @phoneNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (Optional)'**
  String get phoneNumberOptional;

  /// No description provided for @initialBalance.
  ///
  /// In en, this message translates to:
  /// **'Initial Balance'**
  String get initialBalance;

  /// No description provided for @pleaseEnterBalance.
  ///
  /// In en, this message translates to:
  /// **'Please enter a balance (0 is okay)'**
  String get pleaseEnterBalance;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// No description provided for @failedToSaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to save account:'**
  String get failedToSaveAccount;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @noAccountsClassified.
  ///
  /// In en, this message translates to:
  /// **'No accounts classified as \"{classification}\" yet.\nAdd one in the Accounts section.'**
  String noAccountsClassified(String classification);

  /// No description provided for @exportToPDF.
  ///
  /// In en, this message translates to:
  /// **'Export to PDF'**
  String get exportToPDF;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @exportToExcel.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get exportToExcel;

  /// No description provided for @excelExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Excel export successfully generated.'**
  String get excelExportSuccess;

  /// No description provided for @accountBalances.
  ///
  /// In en, this message translates to:
  /// **'Account Balances - {classification}'**
  String accountBalances(String classification);

  /// No description provided for @errorLoadingSummaries.
  ///
  /// In en, this message translates to:
  /// **'Error loading summaries:'**
  String get errorLoadingSummaries;

  /// No description provided for @addNewTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add New Transaction'**
  String get addNewTransaction;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @welcomeToMizan.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Mizan'**
  String get welcomeToMizan;

  /// No description provided for @signInToSync.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data'**
  String get signInToSync;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @offlineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Offline: Sync is unavailable'**
  String get offlineUnavailable;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @syncData.
  ///
  /// In en, this message translates to:
  /// **'Sync Data'**
  String get syncData;

  /// No description provided for @syncNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Sync not implemented yet.'**
  String get syncNotImplemented;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @openNavigationMenu.
  ///
  /// In en, this message translates to:
  /// **'Open navigation menu'**
  String get openNavigationMenu;

  /// No description provided for @mizan.
  ///
  /// In en, this message translates to:
  /// **'Mizan'**
  String get mizan;

  /// No description provided for @mizanDashboard.
  ///
  /// In en, this message translates to:
  /// **'Mizan Dashboard'**
  String get mizanDashboard;

  /// No description provided for @mizanUser.
  ///
  /// In en, this message translates to:
  /// **'Mizan User'**
  String get mizanUser;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not Signed In'**
  String get notSignedIn;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @syncDisabled.
  ///
  /// In en, this message translates to:
  /// **'Sync is disabled'**
  String get syncDisabled;

  /// No description provided for @totalAmountsSummary.
  ///
  /// In en, this message translates to:
  /// **'Total Amounts (Summary)'**
  String get totalAmountsSummary;

  /// No description provided for @monthlyAmountsSummary.
  ///
  /// In en, this message translates to:
  /// **'Monthly Amounts (Summary)'**
  String get monthlyAmountsSummary;

  /// No description provided for @accountActivityLedger.
  ///
  /// In en, this message translates to:
  /// **'Account Activity / Ledger'**
  String get accountActivityLedger;

  /// No description provided for @dataSafetyWarning.
  ///
  /// In en, this message translates to:
  /// **'Data Safety Warning'**
  String get dataSafetyWarning;

  /// No description provided for @dataSafetyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your data is currently stored only on this device.\nTo prevent data loss, please sign in to enable cloud backup.'**
  String get dataSafetyMessage;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @addNewProduct.
  ///
  /// In en, this message translates to:
  /// **'Add New Product'**
  String get addNewProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @failedToSaveProduct.
  ///
  /// In en, this message translates to:
  /// **'Failed to save product:'**
  String get failedToSaveProduct;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a Category'**
  String get selectCategory;

  /// No description provided for @errorLoadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Error loading categories:'**
  String errorLoadingCategories(String error);

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @pleaseEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a price'**
  String get pleaseEnterPrice;

  /// No description provided for @noProductsSaved.
  ///
  /// In en, this message translates to:
  /// **'No products saved.\nTap \"+\" to add one.'**
  String get noProductsSaved;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @noCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet.\nAdd one!'**
  String get noCategoriesYet;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @noProductsYet.
  ///
  /// In en, this message translates to:
  /// **'No products yet.\nAdd one!'**
  String get noProductsYet;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get error;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @posSales.
  ///
  /// In en, this message translates to:
  /// **'POS Sales'**
  String get posSales;

  /// No description provided for @noTransactionEntries.
  ///
  /// In en, this message translates to:
  /// **'No transaction entries recorded for this filter.'**
  String get noTransactionEntries;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @debit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get debit;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @monthlyAmounts.
  ///
  /// In en, this message translates to:
  /// **'Monthly Amounts - {classification}'**
  String monthlyAmounts(String classification);

  /// No description provided for @noMonthlyTotals.
  ///
  /// In en, this message translates to:
  /// **'No monthly totals to display for this filter.'**
  String get noMonthlyTotals;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @totalAmounts.
  ///
  /// In en, this message translates to:
  /// **'Total Amounts - {classification}'**
  String totalAmounts(String classification);

  /// No description provided for @noTotals.
  ///
  /// In en, this message translates to:
  /// **'No totals to display for this filter.'**
  String get noTotals;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @totalClassifications.
  ///
  /// In en, this message translates to:
  /// **'Total Classifications'**
  String get totalClassifications;

  /// No description provided for @noClassificationTotals.
  ///
  /// In en, this message translates to:
  /// **'No classification totals to display.'**
  String get noClassificationTotals;

  /// No description provided for @classification.
  ///
  /// In en, this message translates to:
  /// **'Classification'**
  String get classification;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @unlockMizanPro.
  ///
  /// In en, this message translates to:
  /// **'Unlock Mizan Pro'**
  String get unlockMizanPro;

  /// No description provided for @proPrice.
  ///
  /// In en, this message translates to:
  /// **'Get the \nfull version for a one-time payment of'**
  String get proPrice;

  /// No description provided for @proFeatures.
  ///
  /// In en, this message translates to:
  /// **'This includes unlimited access to all features, cloud sync, and future updates.'**
  String get proFeatures;

  /// No description provided for @purchaseFullVersion.
  ///
  /// In en, this message translates to:
  /// **'Purchase Full Version'**
  String get purchaseFullVersion;

  /// No description provided for @couldNotOpenPurchasePage.
  ///
  /// In en, this message translates to:
  /// **'Could not open purchase page.'**
  String get couldNotOpenPurchasePage;

  /// No description provided for @companyProfile.
  ///
  /// In en, this message translates to:
  /// **'Personal & Company Data'**
  String get companyProfile;

  /// No description provided for @companyProfileReportHint.
  ///
  /// In en, this message translates to:
  /// **'This information may be used on printed reports and invoices.'**
  String get companyProfileReportHint;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyName;

  /// No description provided for @pleaseEnterCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a company name'**
  String get pleaseEnterCompanyName;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourName;

  /// No description provided for @companyAddress.
  ///
  /// In en, this message translates to:
  /// **'Company Address'**
  String get companyAddress;

  /// No description provided for @taxID.
  ///
  /// In en, this message translates to:
  /// **'Tax ID / VAT Number'**
  String get taxID;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @profileSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully.'**
  String get profileSavedSuccess;

  /// No description provided for @failedToSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile:'**
  String get failedToSaveProfile;

  /// No description provided for @currencyOptions.
  ///
  /// In en, this message translates to:
  /// **'Currency Options'**
  String get currencyOptions;

  /// No description provided for @noCurrenciesFound.
  ///
  /// In en, this message translates to:
  /// **'No currencies \nfound. Tap \"+\" to add one.'**
  String get noCurrenciesFound;

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code:'**
  String get codeLabel;

  /// No description provided for @addNewCurrency.
  ///
  /// In en, this message translates to:
  /// **'Add New Currency'**
  String get addNewCurrency;

  /// No description provided for @currencyCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Code (e.g., \"EUR\")'**
  String get currencyCodeHint;

  /// No description provided for @currencyCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Short, unique code (3-5 letters)'**
  String get currencyCodeHelper;

  /// No description provided for @pleaseEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a code'**
  String get pleaseEnterCode;

  /// No description provided for @codeTooLong.
  ///
  /// In en, this message translates to:
  /// **'Code is too long'**
  String get codeTooLong;

  /// No description provided for @currencyNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g., \"Euro\")'**
  String get currencyNameHint;

  /// No description provided for @pleaseEnterCurrencyName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterCurrencyName;

  /// No description provided for @currencySymbolHint.
  ///
  /// In en, this message translates to:
  /// **'Symbol (e.g., \"€\")'**
  String get currencySymbolHint;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save:'**
  String get failedToSave;

  /// No description provided for @securityOptions.
  ///
  /// In en, this message translates to:
  /// **'Security Options'**
  String get securityOptions;

  /// No description provided for @requirePasscode.
  ///
  /// In en, this message translates to:
  /// **'Require Passcode on Entry'**
  String get requirePasscode;

  /// No description provided for @toggleSecurity.
  ///
  /// In en, this message translates to:
  /// **'Toggle additional security layer'**
  String get toggleSecurity;

  /// No description provided for @passcodeRemoved.
  ///
  /// In en, this message translates to:
  /// **'Passcode removed.'**
  String get passcodeRemoved;

  /// No description provided for @setChangePasscode.
  ///
  /// In en, this message translates to:
  /// **'Set/Change Passcode'**
  String get setChangePasscode;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @useBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use Biometrics to Unlock'**
  String get useBiometrics;

  /// No description provided for @useBiometricsHint.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint, face, or iris'**
  String get useBiometricsHint;

  /// No description provided for @setPasscode.
  ///
  /// In en, this message translates to:
  /// **'Set Passcode'**
  String get setPasscode;

  /// No description provided for @setPasscodeHint.
  ///
  /// In en, this message translates to:
  /// **'Create a 4-digit PIN for your app.\nThis will be required on entry.'**
  String get setPasscodeHint;

  /// No description provided for @newPin.
  ///
  /// In en, this message translates to:
  /// **'New 4-Digit PIN'**
  String get newPin;

  /// No description provided for @pleaseEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Please enter a PIN'**
  String get pleaseEnterPin;

  /// No description provided for @pinMustBe4Digits.
  ///
  /// In en, this message translates to:
  /// **'PIN must be 4 digits'**
  String get pinMustBe4Digits;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm 4-Digit PIN'**
  String get confirmPin;

  /// No description provided for @pinsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pinsDoNotMatch;

  /// No description provided for @savePasscode.
  ///
  /// In en, this message translates to:
  /// **'Save Passcode'**
  String get savePasscode;

  /// No description provided for @passcodeSetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Passcode set successfully.'**
  String get passcodeSetSuccess;

  /// No description provided for @failedToSavePasscode.
  ///
  /// In en, this message translates to:
  /// **'Failed to save passcode:'**
  String get failedToSavePasscode;

  /// No description provided for @dataAndSync.
  ///
  /// In en, this message translates to:
  /// **'Data & Sync'**
  String get dataAndSync;

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'Backup Data Now'**
  String get backupNow;

  /// No description provided for @backupHint.
  ///
  /// In en, this message translates to:
  /// **'Uploads your local data to Google Drive.'**
  String get backupHint;

  /// No description provided for @restoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get restoreFromBackup;

  /// No description provided for @restoreWarning.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL: This will overwrite ALL current data in the app with the data from your backup file. This action cannot be undone. Are you sure?'**
  String get restoreWarning;

  /// No description provided for @buyFullVersion.
  ///
  /// In en, this message translates to:
  /// **'Buy The Full Version'**
  String get buyFullVersion;

  /// No description provided for @restoreBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore From File?'**
  String get restoreBackupTitle;

  /// No description provided for @restoreBackupMessage.
  ///
  /// In en, this message translates to:
  /// **'This will overwrite all current data with the data from your selected backup file.\n\nTHIS CANNOT BE UNDONE.'**
  String get restoreBackupMessage;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restore successful! Please restart Mizan to load the new data.'**
  String get restoreSuccess;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed. Your original data is safe. Error: {error}'**
  String restoreFailed(String error);

  /// No description provided for @featureNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Feature not yet implemented.'**
  String get featureNotImplemented;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @selectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select Account'**
  String get selectAccount;

  /// No description provided for @unknownAccount.
  ///
  /// In en, this message translates to:
  /// **'Unknown Account'**
  String get unknownAccount;

  /// No description provided for @pleaseSelectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Please select a currency.'**
  String get pleaseSelectCurrency;

  /// No description provided for @pleaseEnterAccountName.
  ///
  /// In en, this message translates to:
  /// **'Please enter or select an account name.'**
  String get pleaseEnterAccountName;

  /// No description provided for @criticalAccountError.
  ///
  /// In en, this message translates to:
  /// **'Critical Error: Default accounts (like Inventory) are missing.'**
  String get criticalAccountError;

  /// No description provided for @transactionSaved.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved successfully.'**
  String get transactionSaved;

  /// No description provided for @forAccount.
  ///
  /// In en, this message translates to:
  /// **'For {accountName}'**
  String forAccount(String accountName);

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// No description provided for @pleaseEnterOrSelectAccount.
  ///
  /// In en, this message translates to:
  /// **'Please enter or select an account'**
  String get pleaseEnterOrSelectAccount;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get pleaseEnterAmount;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @exchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate (1 {currencyCode} = ? {defaultCurrency})'**
  String exchangeRate(String currencyCode, String defaultCurrency);

  /// No description provided for @pleaseEnterRate.
  ///
  /// In en, this message translates to:
  /// **'Please enter a rate'**
  String get pleaseEnterRate;

  /// No description provided for @invalidRate.
  ///
  /// In en, this message translates to:
  /// **'Invalid rate'**
  String get invalidRate;

  /// No description provided for @addAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add Attachment'**
  String get addAttachment;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @couldNotLoadCurrencies.
  ///
  /// In en, this message translates to:
  /// **'Could not load currencies'**
  String get couldNotLoadCurrencies;

  /// No description provided for @paymentCredit.
  ///
  /// In en, this message translates to:
  /// **'Payment (Credit)'**
  String get paymentCredit;

  /// No description provided for @chargeDebit.
  ///
  /// In en, this message translates to:
  /// **'Charge (Debit)'**
  String get chargeDebit;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history for this account.'**
  String get noHistory;

  /// No description provided for @errorLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Error loading history:'**
  String get errorLoadingHistory;

  /// No description provided for @pleaseAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Please add a category first.'**
  String get pleaseAddCategory;

  /// No description provided for @noProductsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No products in this category'**
  String get noProductsInCategory;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get quantity;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print Receipt'**
  String get printReceipt;

  /// No description provided for @zeroTotalError.
  ///
  /// In en, this message translates to:
  /// **'Cannot process sale with zero total.'**
  String get zeroTotalError;

  /// No description provided for @criticalSetupError.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL SETUP ERROR: Accounts were not created on startup.\nTry reinstalling.'**
  String get criticalSetupError;

  /// No description provided for @posSale.
  ///
  /// In en, this message translates to:
  /// **'POS Sale #{timestamp}'**
  String posSale(String timestamp);

  /// No description provided for @saleRecorded.
  ///
  /// In en, this message translates to:
  /// **'Sale of {total} recorded.'**
  String saleRecorded(String total);

  /// No description provided for @transactionFailed.
  ///
  /// In en, this message translates to:
  /// **'Transaction failed:'**
  String get transactionFailed;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet.\nAdd one!'**
  String get noTransactionsYet;

  /// No description provided for @companyNameLegacy.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyNameLegacy;

  /// No description provided for @yourNameLegacy.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourNameLegacy;

  /// No description provided for @companyAddressLegacy.
  ///
  /// In en, this message translates to:
  /// **'Company Address'**
  String get companyAddressLegacy;

  /// No description provided for @taxIDLegacy.
  ///
  /// In en, this message translates to:
  /// **'Tax ID / VAT Number'**
  String get taxIDLegacy;

  /// No description provided for @securityOptionsLegacy.
  ///
  /// In en, this message translates to:
  /// **'Security Options'**
  String get securityOptionsLegacy;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found for barcode: {barcode}'**
  String productNotFound(String barcode);

  /// No description provided for @scanProductBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Product Barcode'**
  String get scanProductBarcode;

  /// No description provided for @barcodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Barcode (Optional)'**
  String get barcodeOptional;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Item(s)'**
  String get items;

  /// No description provided for @clearOrder.
  ///
  /// In en, this message translates to:
  /// **'Clear Order'**
  String get clearOrder;

  /// No description provided for @printAndSave.
  ///
  /// In en, this message translates to:
  /// **'Print & Save'**
  String get printAndSave;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// No description provided for @noSalesYet.
  ///
  /// In en, this message translates to:
  /// **'No POS sales have been recorded yet.'**
  String get noSalesYet;

  /// No description provided for @returnFor.
  ///
  /// In en, this message translates to:
  /// **'Return for'**
  String get returnFor;

  /// No description provided for @returnSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order returned successfully.'**
  String get returnSuccess;

  /// No description provided for @returnFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to process return'**
  String get returnFailed;

  /// No description provided for @confirmReturn.
  ///
  /// In en, this message translates to:
  /// **'Return this Order?'**
  String get confirmReturn;

  /// No description provided for @confirmReturnMessage.
  ///
  /// In en, this message translates to:
  /// **'This will create a new, opposite transaction to reverse this sale. This cannot be undone.'**
  String get confirmReturnMessage;

  /// No description provided for @returnOrder.
  ///
  /// In en, this message translates to:
  /// **'Return Order'**
  String get returnOrder;

  /// No description provided for @noItemsInSale.
  ///
  /// In en, this message translates to:
  /// **'No items found for this sale (likely a direct journal entry).'**
  String get noItemsInSale;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @local.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get local;

  /// No description provided for @exchangeRateShort.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get exchangeRateShort;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeImage;

  /// No description provided for @pickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Pick From Gallery'**
  String get pickFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @manageReturn.
  ///
  /// In en, this message translates to:
  /// **'Manage Return'**
  String get manageReturn;

  /// No description provided for @orderFullyReturned.
  ///
  /// In en, this message translates to:
  /// **'This order has been fully returned.'**
  String get orderFullyReturned;

  /// No description provided for @purchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get purchased;

  /// No description provided for @returned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get returned;

  /// No description provided for @returnQuantity.
  ///
  /// In en, this message translates to:
  /// **'Return Quantity'**
  String get returnQuantity;

  /// No description provided for @totalRefund.
  ///
  /// In en, this message translates to:
  /// **'Total Refund'**
  String get totalRefund;

  /// No description provided for @processReturn.
  ///
  /// In en, this message translates to:
  /// **'Process Return'**
  String get processReturn;

  /// No description provided for @noItemsSelected.
  ///
  /// In en, this message translates to:
  /// **'No items selected for return.'**
  String get noItemsSelected;

  /// Description for a partial return transaction
  ///
  /// In en, this message translates to:
  /// **'Partial Return for Order {transactionId}'**
  String partialReturnFor(String transactionId);

  /// No description provided for @orderReturned.
  ///
  /// In en, this message translates to:
  /// **'This order has been returned.'**
  String get orderReturned;

  /// No description provided for @noLineItemsSaved.
  ///
  /// In en, this message translates to:
  /// **'No line items were saved for this order.'**
  String get noLineItemsSaved;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'field Required'**
  String get fieldRequired;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'select Payment Method'**
  String get selectPaymentMethod;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// No description provided for @upgradeToMizanPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Mizan Pro'**
  String get upgradeToMizanPro;

  /// No description provided for @mizanProDescription.
  ///
  /// In en, this message translates to:
  /// **'Enable automatic cloud sync, multi-device access, and user roles. Learn more...'**
  String get mizanProDescription;

  /// No description provided for @createLocalBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Local Backup?'**
  String get createLocalBackupTitle;

  /// No description provided for @createLocalBackupMessage.
  ///
  /// In en, this message translates to:
  /// **'This will save a copy of your database to a location you choose (e.g., Downloads, Google Drive).'**
  String get createLocalBackupMessage;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @newPurchase.
  ///
  /// In en, this message translates to:
  /// **'New Purchase / Bill'**
  String get newPurchase;

  /// No description provided for @purchaseScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'New Purchase / Bill'**
  String get purchaseScreenTitle;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @profitAndLoss.
  ///
  /// In en, this message translates to:
  /// **'Profit & Loss'**
  String get profitAndLoss;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @netIncome.
  ///
  /// In en, this message translates to:
  /// **'Net Income'**
  String get netIncome;

  /// No description provided for @balanceSheet.
  ///
  /// In en, this message translates to:
  /// **'Balance Sheet'**
  String get balanceSheet;

  /// No description provided for @asOf.
  ///
  /// In en, this message translates to:
  /// **'As of'**
  String get asOf;

  /// No description provided for @assets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get assets;

  /// No description provided for @totalAssets.
  ///
  /// In en, this message translates to:
  /// **'Total Assets'**
  String get totalAssets;

  /// No description provided for @liabilities.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get liabilities;

  /// No description provided for @totalLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Total Liabilities'**
  String get totalLiabilities;

  /// No description provided for @equity.
  ///
  /// In en, this message translates to:
  /// **'Equity'**
  String get equity;

  /// No description provided for @totalEquity.
  ///
  /// In en, this message translates to:
  /// **'Total Equity'**
  String get totalEquity;

  /// No description provided for @totalLiabilitiesAndEquity.
  ///
  /// In en, this message translates to:
  /// **'Total Liabilities & Equity'**
  String get totalLiabilitiesAndEquity;

  /// No description provided for @trialBalance.
  ///
  /// In en, this message translates to:
  /// **'Trial Balance'**
  String get trialBalance;

  /// No description provided for @selectSupplier.
  ///
  /// In en, this message translates to:
  /// **'Select a Supplier'**
  String get selectSupplier;

  /// No description provided for @makePayment.
  ///
  /// In en, this message translates to:
  /// **'Make Payment'**
  String get makePayment;

  /// No description provided for @payFromAccount.
  ///
  /// In en, this message translates to:
  /// **'Pay From Account'**
  String get payFromAccount;

  /// No description provided for @payToAccount.
  ///
  /// In en, this message translates to:
  /// **'Pay To Account'**
  String get payToAccount;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount > 0'**
  String get pleaseEnterValidAmount;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @pleaseSelectSupplier.
  ///
  /// In en, this message translates to:
  /// **'Please select a supplier'**
  String get pleaseSelectSupplier;

  /// No description provided for @profitAndLossReport.
  ///
  /// In en, this message translates to:
  /// **'Profit & Loss Statement'**
  String get profitAndLossReport;

  /// No description provided for @balanceSheetReport.
  ///
  /// In en, this message translates to:
  /// **'Balance Sheet'**
  String get balanceSheetReport;

  /// No description provided for @trialBalanceReport.
  ///
  /// In en, this message translates to:
  /// **'Trial Balance'**
  String get trialBalanceReport;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @quantityShort.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get quantityShort;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCost;

  /// No description provided for @costPerItem.
  ///
  /// In en, this message translates to:
  /// **'Cost per item'**
  String get costPerItem;

  /// No description provided for @totalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total Payable'**
  String get totalPayable;

  /// No description provided for @pleaseEnterCost.
  ///
  /// In en, this message translates to:
  /// **'Please enter a cost'**
  String get pleaseEnterCost;

  /// No description provided for @pleaseEnterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please enter a quantity'**
  String get pleaseEnterQuantity;

  /// No description provided for @purchaseSaved.
  ///
  /// In en, this message translates to:
  /// **'Purchase saved successfully.'**
  String get purchaseSaved;

  /// No description provided for @failedToSavePurchase.
  ///
  /// In en, this message translates to:
  /// **'Failed to save purchase: {error}'**
  String failedToSavePurchase(String error);

  /// No description provided for @purchaseFrom.
  ///
  /// In en, this message translates to:
  /// **'Purchase from {supplierName}'**
  String purchaseFrom(String supplierName);

  /// No description provided for @createLocalBackupPrompt.
  ///
  /// In en, this message translates to:
  /// **'This will create a local backup file (mizan.db) in a folder you choose. You can use this file to restore your data on this or another device.'**
  String get createLocalBackupPrompt;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @backupSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Backup successful'**
  String get backupSuccessful;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed'**
  String get backupFailed;

  /// No description provided for @restoreSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Restore Successful'**
  String get restoreSuccessful;

  /// No description provided for @restoreSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your data has been restored. Please restart the app now.'**
  String get restoreSuccessMessage;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMore;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get newSale;

  /// No description provided for @totalReceivable.
  ///
  /// In en, this message translates to:
  /// **'Total Receivable'**
  String get totalReceivable;

  /// Formats a number as a decimal value without currency symbol
  ///
  /// In en, this message translates to:
  /// **'{value}'**
  String currencyFormat(double value);

  /// No description provided for @saveSuccessPrintFailed.
  ///
  /// In en, this message translates to:
  /// **'Save success, but print failed: {error}'**
  String saveSuccessPrintFailed(String error);

  /// No description provided for @errorLoadingPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Error loading payment methods: {error}'**
  String errorLoadingPaymentMethods(String error);

  /// No description provided for @atPrice.
  ///
  /// In en, this message translates to:
  /// **'@ {price}'**
  String atPrice(String price);

  /// No description provided for @dbFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Database file not found.'**
  String get dbFileNotFound;

  /// No description provided for @noBackupFound.
  ///
  /// In en, this message translates to:
  /// **'No backup file found on Google Drive.'**
  String get noBackupFound;

  /// No description provided for @mizanAccounting.
  ///
  /// In en, this message translates to:
  /// **'Mizan Accounting'**
  String get mizanAccounting;

  /// No description provided for @generatedOn.
  ///
  /// In en, this message translates to:
  /// **'Generated on: {date}'**
  String generatedOn(String date);

  /// No description provided for @totalLocal.
  ///
  /// In en, this message translates to:
  /// **'Total (Local)'**
  String get totalLocal;

  /// No description provided for @couldNotLaunch.
  ///
  /// In en, this message translates to:
  /// **'Could not launch {url}'**
  String couldNotLaunch(String url);

  /// No description provided for @webNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Web platform is not supported'**
  String get webNotSupported;

  /// No description provided for @signInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in cancelled by user.'**
  String get signInCancelled;

  /// No description provided for @updateWindowsClientId.
  ///
  /// In en, this message translates to:
  /// **'Please update the Windows Client ID in auth_repository.dart'**
  String get updateWindowsClientId;

  /// No description provided for @updateWindowsClientIdSecret.
  ///
  /// In en, this message translates to:
  /// **'Please update Windows Client ID/Secret in auth_repository.dart'**
  String get updateWindowsClientIdSecret;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Unable to get HTTP client.'**
  String get authFailed;

  /// No description provided for @criticalInventoryError.
  ///
  /// In en, this message translates to:
  /// **'Critical Error: Inventory or COGS accounts not found.'**
  String get criticalInventoryError;

  /// No description provided for @drLabel.
  ///
  /// In en, this message translates to:
  /// **'Dr:'**
  String get drLabel;

  /// No description provided for @crLabel.
  ///
  /// In en, this message translates to:
  /// **'Cr:'**
  String get crLabel;

  /// No description provided for @fixedAssets.
  ///
  /// In en, this message translates to:
  /// **'Fixed Assets'**
  String get fixedAssets;

  /// No description provided for @fixedAssetsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage equipment, vehicles, and property'**
  String get fixedAssetsDescription;

  /// No description provided for @netBookValue.
  ///
  /// In en, this message translates to:
  /// **'Net Book Value'**
  String get netBookValue;

  /// No description provided for @totalAcquisitionCost.
  ///
  /// In en, this message translates to:
  /// **'Total Acquisition Cost'**
  String get totalAcquisitionCost;

  /// No description provided for @accumulatedDepreciation.
  ///
  /// In en, this message translates to:
  /// **'Accumulated Depreciation'**
  String get accumulatedDepreciation;

  /// No description provided for @activeAssets.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeAssets;

  /// No description provided for @fullyDepreciated.
  ///
  /// In en, this message translates to:
  /// **'Fully Depreciated'**
  String get fullyDepreciated;

  /// No description provided for @disposedAssets.
  ///
  /// In en, this message translates to:
  /// **'Disposed'**
  String get disposedAssets;

  /// No description provided for @allAssets.
  ///
  /// In en, this message translates to:
  /// **'All Assets'**
  String get allAssets;

  /// No description provided for @byCategory.
  ///
  /// In en, this message translates to:
  /// **'By Category'**
  String get byCategory;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @addAsset.
  ///
  /// In en, this message translates to:
  /// **'Add Asset'**
  String get addAsset;

  /// No description provided for @bookValue.
  ///
  /// In en, this message translates to:
  /// **'Book Value'**
  String get bookValue;

  /// No description provided for @depreciated.
  ///
  /// In en, this message translates to:
  /// **'depreciated'**
  String get depreciated;

  /// No description provided for @usefulLife.
  ///
  /// In en, this message translates to:
  /// **'Useful Life'**
  String get usefulLife;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @monthsLeft.
  ///
  /// In en, this message translates to:
  /// **'months left'**
  String get monthsLeft;

  /// No description provided for @acquisitionDate.
  ///
  /// In en, this message translates to:
  /// **'Acquisition Date'**
  String get acquisitionDate;

  /// No description provided for @salvageValue.
  ///
  /// In en, this message translates to:
  /// **'Salvage Value'**
  String get salvageValue;

  /// No description provided for @depreciationMethod.
  ///
  /// In en, this message translates to:
  /// **'Depreciation Method'**
  String get depreciationMethod;

  /// No description provided for @straightLine.
  ///
  /// In en, this message translates to:
  /// **'Straight-Line'**
  String get straightLine;

  /// No description provided for @decliningBalance.
  ///
  /// In en, this message translates to:
  /// **'Declining Balance'**
  String get decliningBalance;

  /// No description provided for @unitsOfActivity.
  ///
  /// In en, this message translates to:
  /// **'Units of Activity'**
  String get unitsOfActivity;

  /// No description provided for @runDepreciation.
  ///
  /// In en, this message translates to:
  /// **'Run Depreciation'**
  String get runDepreciation;

  /// No description provided for @disposeAsset.
  ///
  /// In en, this message translates to:
  /// **'Dispose'**
  String get disposeAsset;

  /// No description provided for @assetDetails.
  ///
  /// In en, this message translates to:
  /// **'Asset Details'**
  String get assetDetails;

  /// No description provided for @valueInformation.
  ///
  /// In en, this message translates to:
  /// **'Value Information'**
  String get valueInformation;

  /// No description provided for @depreciationSettings.
  ///
  /// In en, this message translates to:
  /// **'Depreciation Settings'**
  String get depreciationSettings;

  /// No description provided for @depreciationProgress.
  ///
  /// In en, this message translates to:
  /// **'Depreciation Progress'**
  String get depreciationProgress;

  /// No description provided for @currentPeriod.
  ///
  /// In en, this message translates to:
  /// **'Current Period'**
  String get currentPeriod;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @depreciation.
  ///
  /// In en, this message translates to:
  /// **'Depreciation'**
  String get depreciation;

  /// No description provided for @depreciationProcessing.
  ///
  /// In en, this message translates to:
  /// **'Depreciation Processing'**
  String get depreciationProcessing;

  /// No description provided for @periodEndDate.
  ///
  /// In en, this message translates to:
  /// **'Period End Date'**
  String get periodEndDate;

  /// No description provided for @runAll.
  ///
  /// In en, this message translates to:
  /// **'Run All'**
  String get runAll;

  /// No description provided for @batchDepreciationComplete.
  ///
  /// In en, this message translates to:
  /// **'Batch depreciation complete'**
  String get batchDepreciationComplete;

  /// No description provided for @assetsProcessed.
  ///
  /// In en, this message translates to:
  /// **'{count} assets processed'**
  String assetsProcessed(int count);

  /// No description provided for @ghostMoney.
  ///
  /// In en, this message translates to:
  /// **'Ghost Money'**
  String get ghostMoney;

  /// No description provided for @ghostMoneyDescription.
  ///
  /// In en, this message translates to:
  /// **'Reconcile rounding differences'**
  String get ghostMoneyDescription;

  /// No description provided for @pendingReconciliation.
  ///
  /// In en, this message translates to:
  /// **'Pending Reconciliation'**
  String get pendingReconciliation;

  /// No description provided for @recentEntries.
  ///
  /// In en, this message translates to:
  /// **'Recent Entries'**
  String get recentEntries;

  /// No description provided for @reconcile.
  ///
  /// In en, this message translates to:
  /// **'Reconcile'**
  String get reconcile;

  /// No description provided for @reconcileAll.
  ///
  /// In en, this message translates to:
  /// **'Reconcile All'**
  String get reconcileAll;

  /// No description provided for @reconciled.
  ///
  /// In en, this message translates to:
  /// **'Reconciled'**
  String get reconciled;

  /// No description provided for @notReconciled.
  ///
  /// In en, this message translates to:
  /// **'Not Reconciled'**
  String get notReconciled;

  /// No description provided for @entriesReconciled.
  ///
  /// In en, this message translates to:
  /// **'{count} entries reconciled'**
  String entriesReconciled(int count);

  /// No description provided for @whatIsGhostMoney.
  ///
  /// In en, this message translates to:
  /// **'What is Ghost Money?'**
  String get whatIsGhostMoney;

  /// No description provided for @ghostMoneyExplanation.
  ///
  /// In en, this message translates to:
  /// **'Ghost money represents tiny rounding differences that occur during calculations like bill splitting, currency conversion, or percentage calculations. These are normal and expected in accounting.'**
  String get ghostMoneyExplanation;

  /// No description provided for @sourceTransaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get sourceTransaction;

  /// No description provided for @sourceSplit.
  ///
  /// In en, this message translates to:
  /// **'Bill Split'**
  String get sourceSplit;

  /// No description provided for @sourceExchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get sourceExchange;

  /// No description provided for @sourceImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get sourceImport;

  /// No description provided for @accountCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountCash;

  /// No description provided for @accountPettyCash.
  ///
  /// In en, this message translates to:
  /// **'Petty Cash'**
  String get accountPettyCash;

  /// No description provided for @accountBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get accountBankAccount;

  /// No description provided for @accountAccountsReceivable.
  ///
  /// In en, this message translates to:
  /// **'Accounts Receivable'**
  String get accountAccountsReceivable;

  /// No description provided for @accountInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get accountInventory;

  /// No description provided for @accountPrepaidExpenses.
  ///
  /// In en, this message translates to:
  /// **'Prepaid Expenses'**
  String get accountPrepaidExpenses;

  /// No description provided for @accountFixedAssetsHeader.
  ///
  /// In en, this message translates to:
  /// **'Fixed Assets'**
  String get accountFixedAssetsHeader;

  /// No description provided for @accountFurnitureFixtures.
  ///
  /// In en, this message translates to:
  /// **'Furniture & Fixtures'**
  String get accountFurnitureFixtures;

  /// No description provided for @accountEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get accountEquipment;

  /// No description provided for @accountVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get accountVehicles;

  /// No description provided for @accountAccumulatedDepreciation.
  ///
  /// In en, this message translates to:
  /// **'Accumulated Depreciation'**
  String get accountAccumulatedDepreciation;

  /// No description provided for @accountAccountsPayable.
  ///
  /// In en, this message translates to:
  /// **'Accounts Payable'**
  String get accountAccountsPayable;

  /// No description provided for @accountAccruedExpenses.
  ///
  /// In en, this message translates to:
  /// **'Accrued Expenses'**
  String get accountAccruedExpenses;

  /// No description provided for @accountSalesTaxPayable.
  ///
  /// In en, this message translates to:
  /// **'Sales Tax Payable'**
  String get accountSalesTaxPayable;

  /// No description provided for @accountUnearnedRevenue.
  ///
  /// In en, this message translates to:
  /// **'Unearned Revenue'**
  String get accountUnearnedRevenue;

  /// No description provided for @accountLongTermLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Long-Term Liabilities'**
  String get accountLongTermLiabilities;

  /// No description provided for @accountLoansPayable.
  ///
  /// In en, this message translates to:
  /// **'Loans Payable'**
  String get accountLoansPayable;

  /// No description provided for @accountOwnerEquity.
  ///
  /// In en, this message translates to:
  /// **'Owner\'s Equity'**
  String get accountOwnerEquity;

  /// No description provided for @accountRetainedEarnings.
  ///
  /// In en, this message translates to:
  /// **'Retained Earnings'**
  String get accountRetainedEarnings;

  /// No description provided for @accountDrawings.
  ///
  /// In en, this message translates to:
  /// **'Drawings'**
  String get accountDrawings;

  /// No description provided for @accountSalesRevenue.
  ///
  /// In en, this message translates to:
  /// **'Sales Revenue'**
  String get accountSalesRevenue;

  /// No description provided for @accountServiceRevenue.
  ///
  /// In en, this message translates to:
  /// **'Service Revenue'**
  String get accountServiceRevenue;

  /// No description provided for @accountInterestIncome.
  ///
  /// In en, this message translates to:
  /// **'Interest Income'**
  String get accountInterestIncome;

  /// No description provided for @accountCostOfGoodsSold.
  ///
  /// In en, this message translates to:
  /// **'Cost of Goods Sold'**
  String get accountCostOfGoodsSold;

  /// No description provided for @accountRentExpense.
  ///
  /// In en, this message translates to:
  /// **'Rent Expense'**
  String get accountRentExpense;

  /// No description provided for @accountUtilitiesExpense.
  ///
  /// In en, this message translates to:
  /// **'Utilities Expense'**
  String get accountUtilitiesExpense;

  /// No description provided for @accountSalariesExpense.
  ///
  /// In en, this message translates to:
  /// **'Salaries Expense'**
  String get accountSalariesExpense;

  /// No description provided for @accountDepreciationExpense.
  ///
  /// In en, this message translates to:
  /// **'Depreciation Expense'**
  String get accountDepreciationExpense;

  /// No description provided for @accountInsuranceExpense.
  ///
  /// In en, this message translates to:
  /// **'Insurance Expense'**
  String get accountInsuranceExpense;

  /// No description provided for @accountSuppliesExpense.
  ///
  /// In en, this message translates to:
  /// **'Supplies Expense'**
  String get accountSuppliesExpense;

  /// No description provided for @accountMiscellaneousExpense.
  ///
  /// In en, this message translates to:
  /// **'Miscellaneous Expense'**
  String get accountMiscellaneousExpense;

  /// No description provided for @joinOrganization.
  ///
  /// In en, this message translates to:
  /// **'Join Organization'**
  String get joinOrganization;

  /// No description provided for @enterInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the invite code from your administrator'**
  String get enterInviteCode;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get inviteCode;

  /// No description provided for @validInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Valid Invite Code!'**
  String get validInviteCode;

  /// No description provided for @invalidInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired invite code'**
  String get invalidInviteCode;

  /// No description provided for @codeMustBe6Digits.
  ///
  /// In en, this message translates to:
  /// **'Code must be 6 digits'**
  String get codeMustBe6Digits;

  /// No description provided for @pleaseEnterInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the invite code'**
  String get pleaseEnterInviteCode;

  /// No description provided for @enterDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Enter your display name'**
  String get enterDisplayName;

  /// No description provided for @successfullyJoined.
  ///
  /// In en, this message translates to:
  /// **'Successfully joined organization!'**
  String get successfullyJoined;

  /// No description provided for @inviteCodeUsed.
  ///
  /// In en, this message translates to:
  /// **'This invite code has already been used'**
  String get inviteCodeUsed;

  /// No description provided for @inviteCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'This invite code has expired'**
  String get inviteCodeExpired;

  /// No description provided for @pleaseSignInFirst.
  ///
  /// In en, this message translates to:
  /// **'Please sign in first'**
  String get pleaseSignInFirst;

  /// No description provided for @createNewOrganization.
  ///
  /// In en, this message translates to:
  /// **'Create New Organization'**
  String get createNewOrganization;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// No description provided for @newCustomer.
  ///
  /// In en, this message translates to:
  /// **'New Customer'**
  String get newCustomer;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomer;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @taxId.
  ///
  /// In en, this message translates to:
  /// **'Tax ID'**
  String get taxId;

  /// No description provided for @creditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit'**
  String get creditLimit;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @noCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomersYet;

  /// No description provided for @tapToAddFirstCustomer.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to add your first customer'**
  String get tapToAddFirstCustomer;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @owed.
  ///
  /// In en, this message translates to:
  /// **'Owed'**
  String get owed;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @newInvoice.
  ///
  /// In en, this message translates to:
  /// **'New Invoice'**
  String get newInvoice;

  /// No description provided for @invoiceDate.
  ///
  /// In en, this message translates to:
  /// **'Invoice Date'**
  String get invoiceDate;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @lineItems.
  ///
  /// In en, this message translates to:
  /// **'Line Items'**
  String get lineItems;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @createInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get createInvoice;

  /// No description provided for @invoiceCreated.
  ///
  /// In en, this message translates to:
  /// **'Invoice created successfully'**
  String get invoiceCreated;

  /// No description provided for @noInvoicesYet.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet'**
  String get noInvoicesYet;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @partial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @arAgingReport.
  ///
  /// In en, this message translates to:
  /// **'AR Aging Report'**
  String get arAgingReport;

  /// No description provided for @totalReceivables.
  ///
  /// In en, this message translates to:
  /// **'Total Receivables'**
  String get totalReceivables;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @days31to60.
  ///
  /// In en, this message translates to:
  /// **'31-60 Days'**
  String get days31to60;

  /// No description provided for @days61to90.
  ///
  /// In en, this message translates to:
  /// **'61-90 Days'**
  String get days61to90;

  /// No description provided for @over90Days.
  ///
  /// In en, this message translates to:
  /// **'90+ Days'**
  String get over90Days;

  /// No description provided for @byCustomer.
  ///
  /// In en, this message translates to:
  /// **'By Customer'**
  String get byCustomer;

  /// No description provided for @noOutstandingReceivables.
  ///
  /// In en, this message translates to:
  /// **'No Outstanding Receivables'**
  String get noOutstandingReceivables;

  /// No description provided for @allInvoicesPaid.
  ///
  /// In en, this message translates to:
  /// **'All invoices are paid!'**
  String get allInvoicesPaid;

  /// No description provided for @customersWithBalances.
  ///
  /// In en, this message translates to:
  /// **'{count} customers with balances'**
  String customersWithBalances(int count);

  /// No description provided for @vendors.
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get vendors;

  /// No description provided for @addVendor.
  ///
  /// In en, this message translates to:
  /// **'Add Vendor'**
  String get addVendor;

  /// No description provided for @newVendor.
  ///
  /// In en, this message translates to:
  /// **'New Vendor'**
  String get newVendor;

  /// No description provided for @editVendor.
  ///
  /// In en, this message translates to:
  /// **'Edit Vendor'**
  String get editVendor;

  /// No description provided for @vendorName.
  ///
  /// In en, this message translates to:
  /// **'Vendor Name'**
  String get vendorName;

  /// No description provided for @paymentTerms.
  ///
  /// In en, this message translates to:
  /// **'Payment Terms (e.g., Net 30)'**
  String get paymentTerms;

  /// No description provided for @noVendorsYet.
  ///
  /// In en, this message translates to:
  /// **'No vendors yet'**
  String get noVendorsYet;

  /// No description provided for @tapToAddFirstVendor.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to add your first vendor'**
  String get tapToAddFirstVendor;

  /// No description provided for @weOwe.
  ///
  /// In en, this message translates to:
  /// **'We Owe'**
  String get weOwe;

  /// No description provided for @bills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get bills;

  /// No description provided for @newBill.
  ///
  /// In en, this message translates to:
  /// **'New Bill'**
  String get newBill;

  /// No description provided for @billDate.
  ///
  /// In en, this message translates to:
  /// **'Bill Date'**
  String get billDate;

  /// No description provided for @vendorInvoice.
  ///
  /// In en, this message translates to:
  /// **'Vendor Invoice #'**
  String get vendorInvoice;

  /// No description provided for @createBill.
  ///
  /// In en, this message translates to:
  /// **'Create Bill'**
  String get createBill;

  /// No description provided for @billCreated.
  ///
  /// In en, this message translates to:
  /// **'Bill created successfully'**
  String get billCreated;

  /// No description provided for @noBillsYet.
  ///
  /// In en, this message translates to:
  /// **'No bills yet'**
  String get noBillsYet;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @apAgingReport.
  ///
  /// In en, this message translates to:
  /// **'AP Aging Report'**
  String get apAgingReport;

  /// No description provided for @totalPayables.
  ///
  /// In en, this message translates to:
  /// **'Total Payables'**
  String get totalPayables;

  /// No description provided for @byVendor.
  ///
  /// In en, this message translates to:
  /// **'By Vendor'**
  String get byVendor;

  /// No description provided for @noOutstandingPayables.
  ///
  /// In en, this message translates to:
  /// **'No Outstanding Payables'**
  String get noOutstandingPayables;

  /// No description provided for @allBillsPaid.
  ///
  /// In en, this message translates to:
  /// **'All bills are paid!'**
  String get allBillsPaid;

  /// No description provided for @vendorsWithBalances.
  ///
  /// In en, this message translates to:
  /// **'{count} vendors with balances'**
  String vendorsWithBalances(int count);

  /// No description provided for @statementOfCashFlows.
  ///
  /// In en, this message translates to:
  /// **'Statement of Cash Flows'**
  String get statementOfCashFlows;

  /// No description provided for @cashFlowsFromOperating.
  ///
  /// In en, this message translates to:
  /// **'Cash Flows from Operating Activities'**
  String get cashFlowsFromOperating;

  /// No description provided for @cashFlowsFromInvesting.
  ///
  /// In en, this message translates to:
  /// **'Cash Flows from Investing Activities'**
  String get cashFlowsFromInvesting;

  /// No description provided for @cashFlowsFromFinancing.
  ///
  /// In en, this message translates to:
  /// **'Cash Flows from Financing Activities'**
  String get cashFlowsFromFinancing;

  /// No description provided for @addDepreciation.
  ///
  /// In en, this message translates to:
  /// **'Add: Depreciation Expense'**
  String get addDepreciation;

  /// No description provided for @decreaseInReceivables.
  ///
  /// In en, this message translates to:
  /// **'Decrease in Accounts Receivable'**
  String get decreaseInReceivables;

  /// No description provided for @increaseInReceivables.
  ///
  /// In en, this message translates to:
  /// **'Increase in Accounts Receivable'**
  String get increaseInReceivables;

  /// No description provided for @increaseInPayables.
  ///
  /// In en, this message translates to:
  /// **'Increase in Accounts Payable'**
  String get increaseInPayables;

  /// No description provided for @decreaseInPayables.
  ///
  /// In en, this message translates to:
  /// **'Decrease in Accounts Payable'**
  String get decreaseInPayables;

  /// No description provided for @netCashFromOperating.
  ///
  /// In en, this message translates to:
  /// **'Net Cash from Operating'**
  String get netCashFromOperating;

  /// No description provided for @netCashFromInvesting.
  ///
  /// In en, this message translates to:
  /// **'Net Cash from Investing'**
  String get netCashFromInvesting;

  /// No description provided for @netCashFromFinancing.
  ///
  /// In en, this message translates to:
  /// **'Net Cash from Financing'**
  String get netCashFromFinancing;

  /// No description provided for @purchaseOfFixedAssets.
  ///
  /// In en, this message translates to:
  /// **'Purchase of Fixed Assets'**
  String get purchaseOfFixedAssets;

  /// No description provided for @netChangeInCash.
  ///
  /// In en, this message translates to:
  /// **'Net Change in Cash'**
  String get netChangeInCash;

  /// No description provided for @beginningCashBalance.
  ///
  /// In en, this message translates to:
  /// **'Beginning Cash Balance'**
  String get beginningCashBalance;

  /// No description provided for @endingCashBalance.
  ///
  /// In en, this message translates to:
  /// **'Ending Cash Balance'**
  String get endingCashBalance;

  /// No description provided for @noInvestingActivities.
  ///
  /// In en, this message translates to:
  /// **'No investing activities'**
  String get noInvestingActivities;

  /// No description provided for @noFinancingActivities.
  ///
  /// In en, this message translates to:
  /// **'No financing activities'**
  String get noFinancingActivities;

  /// No description provided for @financialRatios.
  ///
  /// In en, this message translates to:
  /// **'Financial Ratios'**
  String get financialRatios;

  /// No description provided for @currentRatio.
  ///
  /// In en, this message translates to:
  /// **'Current Ratio'**
  String get currentRatio;

  /// No description provided for @quickRatio.
  ///
  /// In en, this message translates to:
  /// **'Quick Ratio'**
  String get quickRatio;

  /// No description provided for @debtToEquity.
  ///
  /// In en, this message translates to:
  /// **'Debt/Equity'**
  String get debtToEquity;

  /// No description provided for @grossProfitMargin.
  ///
  /// In en, this message translates to:
  /// **'Gross Profit Margin'**
  String get grossProfitMargin;

  /// No description provided for @netProfitMargin.
  ///
  /// In en, this message translates to:
  /// **'Net Profit Margin'**
  String get netProfitMargin;

  /// No description provided for @returnOnAssets.
  ///
  /// In en, this message translates to:
  /// **'Return on Assets (ROA)'**
  String get returnOnAssets;

  /// No description provided for @workingCapital.
  ///
  /// In en, this message translates to:
  /// **'Working Capital'**
  String get workingCapital;

  /// No description provided for @receivablesTurnover.
  ///
  /// In en, this message translates to:
  /// **'Receivables Turnover'**
  String get receivablesTurnover;

  /// No description provided for @receivables.
  ///
  /// In en, this message translates to:
  /// **'Receivables'**
  String get receivables;

  /// No description provided for @payables.
  ///
  /// In en, this message translates to:
  /// **'Payables'**
  String get payables;

  /// No description provided for @currentAmount.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentAmount;

  /// No description provided for @overdueAmount.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueAmount;

  /// No description provided for @bankReconciliations.
  ///
  /// In en, this message translates to:
  /// **'Bank Reconciliations'**
  String get bankReconciliations;

  /// No description provided for @newReconciliation.
  ///
  /// In en, this message translates to:
  /// **'New Reconciliation'**
  String get newReconciliation;

  /// No description provided for @noReconciliationsYet.
  ///
  /// In en, this message translates to:
  /// **'No reconciliations yet'**
  String get noReconciliationsYet;

  /// No description provided for @startReconciling.
  ///
  /// In en, this message translates to:
  /// **'Start reconciling your bank statements'**
  String get startReconciling;

  /// No description provided for @bankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get bankAccount;

  /// No description provided for @statementDate.
  ///
  /// In en, this message translates to:
  /// **'Statement Date'**
  String get statementDate;

  /// No description provided for @statementEndingBalance.
  ///
  /// In en, this message translates to:
  /// **'Statement Ending Balance'**
  String get statementEndingBalance;

  /// No description provided for @statementBalance.
  ///
  /// In en, this message translates to:
  /// **'Statement Balance'**
  String get statementBalance;

  /// No description provided for @bookBalance.
  ///
  /// In en, this message translates to:
  /// **'Book Balance'**
  String get bookBalance;

  /// No description provided for @selectedCleared.
  ///
  /// In en, this message translates to:
  /// **'Selected Cleared:'**
  String get selectedCleared;

  /// No description provided for @differenceAmount.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get differenceAmount;

  /// No description provided for @balanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced!'**
  String get balanced;

  /// No description provided for @unclearedTransactions.
  ///
  /// In en, this message translates to:
  /// **'Uncleared Transactions'**
  String get unclearedTransactions;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @allTransactionsReconciled.
  ///
  /// In en, this message translates to:
  /// **'All transactions reconciled!'**
  String get allTransactionsReconciled;

  /// No description provided for @completeReconciliation.
  ///
  /// In en, this message translates to:
  /// **'Complete Reconciliation'**
  String get completeReconciliation;

  /// No description provided for @reconciliationCompleted.
  ///
  /// In en, this message translates to:
  /// **'Reconciliation completed!'**
  String get reconciliationCompleted;

  /// No description provided for @pleaseSelectTransactions.
  ///
  /// In en, this message translates to:
  /// **'Please select transactions to reconcile'**
  String get pleaseSelectTransactions;

  /// No description provided for @noBankAccountsFound.
  ///
  /// In en, this message translates to:
  /// **'No bank accounts found'**
  String get noBankAccountsFound;

  /// No description provided for @closeBooks.
  ///
  /// In en, this message translates to:
  /// **'Close Books'**
  String get closeBooks;

  /// No description provided for @currentLockDate.
  ///
  /// In en, this message translates to:
  /// **'Current Lock Date'**
  String get currentLockDate;

  /// No description provided for @booksAreOpen.
  ///
  /// In en, this message translates to:
  /// **'Books are OPEN'**
  String get booksAreOpen;

  /// No description provided for @closingInstructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Closing Instructions'**
  String get closingInstructionsTitle;

  /// No description provided for @closingInstructionsBody.
  ///
  /// In en, this message translates to:
  /// **'This action will:\n1. Zero out all Revenue & Expenses for the period.\n2. Transfer Net Income to Retained Earnings.\n3. LOCK the period from future edits.'**
  String get closingInstructionsBody;

  /// No description provided for @stepSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Select Closing Date'**
  String get stepSelectDate;

  /// No description provided for @stepSelectEquityAccount.
  ///
  /// In en, this message translates to:
  /// **'Step 2: Select Retained Earnings Account'**
  String get stepSelectEquityAccount;

  /// No description provided for @errorNoEquityAccount.
  ///
  /// In en, this message translates to:
  /// **'Error: No Equity accounts found. Please create one in Accounts.'**
  String get errorNoEquityAccount;

  /// No description provided for @closePeriodAndLock.
  ///
  /// In en, this message translates to:
  /// **'CLOSE PERIOD & LOCK'**
  String get closePeriodAndLock;

  /// No description provided for @confirmPeriodCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Period Close'**
  String get confirmPeriodCloseTitle;

  /// No description provided for @confirmPeriodCloseMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This will lock all transactions on or before this date. This action cannot be easily undone.'**
  String get confirmPeriodCloseMessage;

  /// No description provided for @periodClosedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Period Closed Successfully.'**
  String get periodClosedSuccessfully;

  /// No description provided for @periodLockedError.
  ///
  /// In en, this message translates to:
  /// **'Period is closed for edits.'**
  String get periodLockedError;

  /// No description provided for @cvpAnalysis.
  ///
  /// In en, this message translates to:
  /// **'CVP Analysis'**
  String get cvpAnalysis;

  /// No description provided for @calculator.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get calculator;

  /// No description provided for @breakEven.
  ///
  /// In en, this message translates to:
  /// **'Break-Even'**
  String get breakEven;

  /// No description provided for @marginOfSafety.
  ///
  /// In en, this message translates to:
  /// **'Margin of Safety'**
  String get marginOfSafety;

  /// No description provided for @whatIf.
  ///
  /// In en, this message translates to:
  /// **'What-If'**
  String get whatIf;

  /// No description provided for @costStructure.
  ///
  /// In en, this message translates to:
  /// **'Cost Structure'**
  String get costStructure;

  /// No description provided for @fixedCostsTotal.
  ///
  /// In en, this message translates to:
  /// **'Fixed Costs (Total)'**
  String get fixedCostsTotal;

  /// No description provided for @fixedCostsHelper.
  ///
  /// In en, this message translates to:
  /// **'Rent, salaries, depreciation, etc.'**
  String get fixedCostsHelper;

  /// No description provided for @perUnitData.
  ///
  /// In en, this message translates to:
  /// **'Per-Unit Data'**
  String get perUnitData;

  /// No description provided for @sellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get sellingPrice;

  /// No description provided for @variableCost.
  ///
  /// In en, this message translates to:
  /// **'Variable Cost'**
  String get variableCost;

  /// No description provided for @contributionMargin.
  ///
  /// In en, this message translates to:
  /// **'Contribution Margin'**
  String get contributionMargin;

  /// No description provided for @contributionMarginPerUnit.
  ///
  /// In en, this message translates to:
  /// **'CM per Unit'**
  String get contributionMarginPerUnit;

  /// No description provided for @actualExpectedSales.
  ///
  /// In en, this message translates to:
  /// **'Actual/Expected Sales'**
  String get actualExpectedSales;

  /// No description provided for @unitsSold.
  ///
  /// In en, this message translates to:
  /// **'Units Sold'**
  String get unitsSold;

  /// No description provided for @targetProfit.
  ///
  /// In en, this message translates to:
  /// **'Target Profit'**
  String get targetProfit;

  /// No description provided for @desiredProfit.
  ///
  /// In en, this message translates to:
  /// **'Desired Profit'**
  String get desiredProfit;

  /// No description provided for @desiredProfitHelper.
  ///
  /// In en, this message translates to:
  /// **'How much profit do you want to earn?'**
  String get desiredProfitHelper;

  /// No description provided for @analyzeAndViewResults.
  ///
  /// In en, this message translates to:
  /// **'Analyze & View Results'**
  String get analyzeAndViewResults;

  /// No description provided for @enterDataFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter data in the Calculator tab first'**
  String get enterDataFirst;

  /// No description provided for @breakEvenPoint.
  ///
  /// In en, this message translates to:
  /// **'Break-Even Point'**
  String get breakEvenPoint;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @targetProfitAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Target Profit Analysis'**
  String get targetProfitAnalysis;

  /// No description provided for @requiredUnits.
  ///
  /// In en, this message translates to:
  /// **'Required Units'**
  String get requiredUnits;

  /// No description provided for @requiredSales.
  ///
  /// In en, this message translates to:
  /// **'Required Sales'**
  String get requiredSales;

  /// No description provided for @risk.
  ///
  /// In en, this message translates to:
  /// **'RISK'**
  String get risk;

  /// No description provided for @mosRatio.
  ///
  /// In en, this message translates to:
  /// **'MOS Ratio'**
  String get mosRatio;

  /// No description provided for @financialSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Financial Snapshot'**
  String get financialSnapshot;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// No description provided for @cashFlow.
  ///
  /// In en, this message translates to:
  /// **'Cash Flow'**
  String get cashFlow;

  /// No description provided for @operatingLeverage.
  ///
  /// In en, this message translates to:
  /// **'Operating Leverage'**
  String get operatingLeverage;

  /// No description provided for @degreeOfOperatingLeverage.
  ///
  /// In en, this message translates to:
  /// **'Degree of Operating Leverage'**
  String get degreeOfOperatingLeverage;

  /// No description provided for @leverageLevel.
  ///
  /// In en, this message translates to:
  /// **'Leverage Level'**
  String get leverageLevel;

  /// No description provided for @leverageImpact.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get leverageImpact;

  /// No description provided for @priceSensitivityAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Price Sensitivity Analysis'**
  String get priceSensitivityAnalysis;

  /// No description provided for @priceSensitivityDescription.
  ///
  /// In en, this message translates to:
  /// **'Shows how break-even changes when you adjust selling price'**
  String get priceSensitivityDescription;

  /// No description provided for @currentBreakEven.
  ///
  /// In en, this message translates to:
  /// **'Current Break-Even: {units} units'**
  String currentBreakEven(String units);

  /// No description provided for @depreciationProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Depreciation Processing'**
  String get depreciationProcessingTitle;

  /// No description provided for @selectPeriodEndDate.
  ///
  /// In en, this message translates to:
  /// **'Select Period End Date'**
  String get selectPeriodEndDate;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @noActiveAssets.
  ///
  /// In en, this message translates to:
  /// **'No Active Assets'**
  String get noActiveAssets;

  /// No description provided for @addFixedAssetsHint.
  ///
  /// In en, this message translates to:
  /// **'Add fixed assets to run depreciation'**
  String get addFixedAssetsHint;

  /// No description provided for @bookValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Book Value'**
  String get bookValueLabel;

  /// No description provided for @monthlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyLabel;

  /// No description provided for @remainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingLabel;

  /// No description provided for @depreciationRecordedFor.
  ///
  /// In en, this message translates to:
  /// **'Depreciation recorded: {amount} for {assetName}'**
  String depreciationRecordedFor(String amount, String assetName);

  /// No description provided for @processedAssetsTotal.
  ///
  /// In en, this message translates to:
  /// **'Processed {count} assets. Total: {amount}'**
  String processedAssetsTotal(int count, String amount);

  /// No description provided for @assetsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} assets'**
  String assetsCount(int count);

  /// No description provided for @ghostMoneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ghost Money'**
  String get ghostMoneyTitle;

  /// No description provided for @whatIsGhostMoneyTooltip.
  ///
  /// In en, this message translates to:
  /// **'What is Ghost Money?'**
  String get whatIsGhostMoneyTooltip;

  /// No description provided for @allBalanced.
  ///
  /// In en, this message translates to:
  /// **'All Balanced!'**
  String get allBalanced;

  /// No description provided for @noGhostMoneyToReconcile.
  ///
  /// In en, this message translates to:
  /// **'No ghost money to reconcile'**
  String get noGhostMoneyToReconcile;

  /// No description provided for @entryLabel.
  ///
  /// In en, this message translates to:
  /// **'entry'**
  String get entryLabel;

  /// No description provided for @entriesLabel.
  ///
  /// In en, this message translates to:
  /// **'entries'**
  String get entriesLabel;

  /// No description provided for @noEntriesToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No entries to display'**
  String get noEntriesToDisplay;

  /// No description provided for @reconcileCurrency.
  ///
  /// In en, this message translates to:
  /// **'Reconcile {currency}'**
  String reconcileCurrency(String currency);

  /// No description provided for @writeOffConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Write off {amount} in ghost money?\n\nThis will create a journal entry to clear {count} {entryText}.'**
  String writeOffConfirmation(String amount, int count, String entryText);

  /// No description provided for @reconcileButton.
  ///
  /// In en, this message translates to:
  /// **'Reconcile'**
  String get reconcileButton;

  /// No description provided for @reconciledEntries.
  ///
  /// In en, this message translates to:
  /// **'Reconciled {count} entries for {currency}'**
  String reconciledEntries(int count, String currency);

  /// No description provided for @entryReconciledMessage.
  ///
  /// In en, this message translates to:
  /// **'Entry reconciled'**
  String get entryReconciledMessage;

  /// No description provided for @ghostMoneyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'What is Ghost Money?'**
  String get ghostMoneyDialogTitle;

  /// No description provided for @ghostMoneyDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Ghost money represents tiny rounding differences that occur during financial calculations.\n\nExamples:\n• Splitting a bill 3 ways (100 ÷ 3)\n• Currency exchange rate conversions\n• Percentage-based tax calculations\n\nThese small differences typically accumulate to just a few cents and can be periodically written off or allocated.'**
  String get ghostMoneyDialogContent;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @fixedAssetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Fixed Assets'**
  String get fixedAssetsTitle;

  /// No description provided for @netBookValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Book Value'**
  String get netBookValueLabel;

  /// No description provided for @totalCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCostLabel;

  /// No description provided for @depreciatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Depreciated'**
  String get depreciatedLabel;

  /// No description provided for @progressLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressLabel;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @fullDeprLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Depr.'**
  String get fullDeprLabel;

  /// No description provided for @disposedLabel.
  ///
  /// In en, this message translates to:
  /// **'Disposed'**
  String get disposedLabel;

  /// No description provided for @allAssetsTab.
  ///
  /// In en, this message translates to:
  /// **'All Assets'**
  String get allAssetsTab;

  /// No description provided for @byCategoryTab.
  ///
  /// In en, this message translates to:
  /// **'By Category'**
  String get byCategoryTab;

  /// No description provided for @scheduleTab.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTab;

  /// No description provided for @noFixedAssets.
  ///
  /// In en, this message translates to:
  /// **'No Fixed Assets'**
  String get noFixedAssets;

  /// No description provided for @addFixedAssetsDescription.
  ///
  /// In en, this message translates to:
  /// **'Add equipment, vehicles, or property to track depreciation'**
  String get addFixedAssetsDescription;

  /// No description provided for @noScheduledDepreciation.
  ///
  /// In en, this message translates to:
  /// **'No Scheduled Depreciation'**
  String get noScheduledDepreciation;

  /// No description provided for @percentDepreciated.
  ///
  /// In en, this message translates to:
  /// **'{percent}% depreciated'**
  String percentDepreciated(String percent);

  /// No description provided for @monthlyDepreciationInfo.
  ///
  /// In en, this message translates to:
  /// **'Monthly: {amount} • {months} months left'**
  String monthlyDepreciationInfo(String amount, int months);

  /// No description provided for @valueInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Value Information'**
  String get valueInformationTitle;

  /// No description provided for @depreciationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Depreciation Settings'**
  String get depreciationSettingsTitle;

  /// No description provided for @acquisitionCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Acquisition Cost'**
  String get acquisitionCostLabel;

  /// No description provided for @salvageValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Salvage Value'**
  String get salvageValueLabel;

  /// No description provided for @accumulatedDepreciationLabel.
  ///
  /// In en, this message translates to:
  /// **'Accumulated Depreciation'**
  String get accumulatedDepreciationLabel;

  /// No description provided for @methodLabel.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get methodLabel;

  /// No description provided for @usefulLifeLabel.
  ///
  /// In en, this message translates to:
  /// **'Useful Life'**
  String get usefulLifeLabel;

  /// No description provided for @usefulLifeMonths.
  ///
  /// In en, this message translates to:
  /// **'{months} months'**
  String usefulLifeMonths(int months);

  /// No description provided for @runDepreciationButton.
  ///
  /// In en, this message translates to:
  /// **'Run Depreciation'**
  String get runDepreciationButton;

  /// No description provided for @disposeButton.
  ///
  /// In en, this message translates to:
  /// **'Dispose'**
  String get disposeButton;

  /// No description provided for @addAssetName.
  ///
  /// In en, this message translates to:
  /// **'Asset Name'**
  String get addAssetName;

  /// No description provided for @addAssetDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get addAssetDescription;

  /// No description provided for @addAssetAcquisitionCost.
  ///
  /// In en, this message translates to:
  /// **'Acquisition Cost'**
  String get addAssetAcquisitionCost;

  /// No description provided for @addAssetSalvageValue.
  ///
  /// In en, this message translates to:
  /// **'Salvage Value'**
  String get addAssetSalvageValue;

  /// No description provided for @addAssetUsefulLife.
  ///
  /// In en, this message translates to:
  /// **'Useful Life (Months)'**
  String get addAssetUsefulLife;

  /// No description provided for @addAssetAcquisitionDate.
  ///
  /// In en, this message translates to:
  /// **'Acquisition Date'**
  String get addAssetAcquisitionDate;

  /// No description provided for @addAssetDepreciationMethod.
  ///
  /// In en, this message translates to:
  /// **'Depreciation Method'**
  String get addAssetDepreciationMethod;

  /// No description provided for @addAssetDecliningRate.
  ///
  /// In en, this message translates to:
  /// **'Declining Balance Rate'**
  String get addAssetDecliningRate;

  /// No description provided for @reportsAndAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Reports & Analytics'**
  String get reportsAndAnalytics;

  /// No description provided for @reportMarketplaceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Report Marketplace'**
  String get reportMarketplaceTooltip;

  /// No description provided for @financialStatementsSection.
  ///
  /// In en, this message translates to:
  /// **'Financial Statements'**
  String get financialStatementsSection;

  /// No description provided for @performanceSection.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performanceSection;

  /// No description provided for @analysisToolsSection.
  ///
  /// In en, this message translates to:
  /// **'Analysis Tools'**
  String get analysisToolsSection;

  /// No description provided for @inventoryOperationsSection.
  ///
  /// In en, this message translates to:
  /// **'Inventory & Operations (Coming Soon)'**
  String get inventoryOperationsSection;

  /// No description provided for @cvpAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'CVP Analysis'**
  String get cvpAnalysisTitle;

  /// No description provided for @capitalBudgetingTitle.
  ///
  /// In en, this message translates to:
  /// **'Capital Budgeting'**
  String get capitalBudgetingTitle;

  /// No description provided for @budgetAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Analysis'**
  String get budgetAnalysisTitle;

  /// No description provided for @fraudDetectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Fraud Detection'**
  String get fraudDetectionTitle;

  /// No description provided for @standardCostingTitle.
  ///
  /// In en, this message translates to:
  /// **'Standard Costing'**
  String get standardCostingTitle;

  /// No description provided for @financialRatiosTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Ratios'**
  String get financialRatiosTitle;

  /// No description provided for @stockVelocityTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock Velocity'**
  String get stockVelocityTitle;

  /// No description provided for @lowStockAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alert'**
  String get lowStockAlertTitle;

  /// No description provided for @salesByCashierTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales by Cashier'**
  String get salesByCashierTitle;

  /// No description provided for @taxLiabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Tax Liability'**
  String get taxLiabilityTitle;

  /// No description provided for @reportHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Hub'**
  String get reportHubTitle;

  /// No description provided for @myReportsTab.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get myReportsTab;

  /// No description provided for @marketplaceTab.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplaceTab;

  /// No description provided for @noInstalledReports.
  ///
  /// In en, this message translates to:
  /// **'No Installed Reports'**
  String get noInstalledReports;

  /// No description provided for @goToMarketplaceHint.
  ///
  /// In en, this message translates to:
  /// **'Go to the Marketplace to download standard reports.'**
  String get goToMarketplaceHint;

  /// No description provided for @marketplaceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Marketplace Unavailable'**
  String get marketplaceUnavailable;

  /// No description provided for @noStandardReportsOnline.
  ///
  /// In en, this message translates to:
  /// **'No standard reports found online.'**
  String get noStandardReportsOnline;

  /// No description provided for @installButton.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get installButton;

  /// No description provided for @includedLabel.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get includedLabel;

  /// No description provided for @buyLabel.
  ///
  /// In en, this message translates to:
  /// **'Buy {price}'**
  String buyLabel(String price);

  /// No description provided for @lockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockedLabel;

  /// No description provided for @purchaseReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase Report'**
  String get purchaseReportTitle;

  /// No description provided for @buyReportConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Buy \'{title}\' for {price}?'**
  String buyReportConfirmation(String title, String price);

  /// No description provided for @buyNowButton.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNowButton;

  /// No description provided for @processingPayment.
  ///
  /// In en, this message translates to:
  /// **'Processing Payment...'**
  String get processingPayment;

  /// No description provided for @installedReport.
  ///
  /// In en, this message translates to:
  /// **'✅ Installed {title}'**
  String installedReport(String title);

  /// No description provided for @premiumReportLocked.
  ///
  /// In en, this message translates to:
  /// **'🔒 Premium Report. Upgrade to Pro or Enterprise.'**
  String get premiumReportLocked;

  /// No description provided for @posTerminalTitle.
  ///
  /// In en, this message translates to:
  /// **'POS Terminal'**
  String get posTerminalTitle;

  /// No description provided for @searchProductTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search Product'**
  String get searchProductTooltip;

  /// No description provided for @recallOrderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Recall Order'**
  String get recallOrderTooltip;

  /// No description provided for @holdButton.
  ///
  /// In en, this message translates to:
  /// **'HOLD'**
  String get holdButton;

  /// No description provided for @orderParkedMessage.
  ///
  /// In en, this message translates to:
  /// **'Order Parked'**
  String get orderParkedMessage;

  /// No description provided for @recallOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Recall Order'**
  String get recallOrderTitle;

  /// No description provided for @noParkedOrders.
  ///
  /// In en, this message translates to:
  /// **'No parked orders'**
  String get noParkedOrders;

  /// No description provided for @orderNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Order #{orderId}'**
  String orderNumberLabel(String orderId);

  /// No description provided for @orderInfo.
  ///
  /// In en, this message translates to:
  /// **'{itemCount} items • {minutes} mins ago'**
  String orderInfo(int itemCount, int minutes);

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @cartIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get cartIsEmpty;

  /// No description provided for @payWithButton.
  ///
  /// In en, this message translates to:
  /// **'Pay with {method}'**
  String payWithButton(String method);

  /// No description provided for @editQtyMode.
  ///
  /// In en, this message translates to:
  /// **'EDIT QTY MODE'**
  String get editQtyMode;

  /// No description provided for @scanMode.
  ///
  /// In en, this message translates to:
  /// **'SCAN MODE'**
  String get scanMode;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get totalLabel;

  /// No description provided for @payPrintButton.
  ///
  /// In en, this message translates to:
  /// **'PAY / PRINT'**
  String get payPrintButton;

  /// No description provided for @importProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Products'**
  String get importProductsTitle;

  /// No description provided for @selectDefaultCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'1. Select a default category for these products:'**
  String get selectDefaultCategoryHint;

  /// No description provided for @pleaseCreateCategoryFirst.
  ///
  /// In en, this message translates to:
  /// **'Please create a category first.'**
  String get pleaseCreateCategoryFirst;

  /// No description provided for @uploadFileHint.
  ///
  /// In en, this message translates to:
  /// **'2. Upload CSV or Excel file (Cols: Name, Barcode, Cat, Price, Cost, Qty)'**
  String get uploadFileHint;

  /// No description provided for @selectFileButton.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get selectFileButton;

  /// No description provided for @noProductsFoundInFile.
  ///
  /// In en, this message translates to:
  /// **'No products found in file.'**
  String get noProductsFoundInFile;

  /// No description provided for @noDataLoaded.
  ///
  /// In en, this message translates to:
  /// **'No data loaded. Upload a file to preview.'**
  String get noDataLoaded;

  /// No description provided for @importProductsButton.
  ///
  /// In en, this message translates to:
  /// **'Import {count} Products'**
  String importProductsButton(int count);

  /// No description provided for @importSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported {count} products!'**
  String importSuccessMessage(int count);

  /// No description provided for @importFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Import Failed: {error}'**
  String importFailedMessage(String error);

  /// No description provided for @pleaseSelectDefaultCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a Default Category'**
  String get pleaseSelectDefaultCategory;

  /// No description provided for @budgetAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Budget Analysis'**
  String get budgetAnalysis;

  /// No description provided for @summaryTab.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryTab;

  /// No description provided for @variancesTab.
  ///
  /// In en, this message translates to:
  /// **'Variances'**
  String get variancesTab;

  /// No description provided for @flexibleBudgetTab.
  ///
  /// In en, this message translates to:
  /// **'Flexible Budget'**
  String get flexibleBudgetTab;

  /// No description provided for @budgetedNetIncome.
  ///
  /// In en, this message translates to:
  /// **'Budgeted Net Income'**
  String get budgetedNetIncome;

  /// No description provided for @actualNetIncome.
  ///
  /// In en, this message translates to:
  /// **'Actual Net Income'**
  String get actualNetIncome;

  /// No description provided for @netIncomeVariance.
  ///
  /// In en, this message translates to:
  /// **'Net Income Variance'**
  String get netIncomeVariance;

  /// No description provided for @revenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenueLabel;

  /// No description provided for @expensesLabel.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesLabel;

  /// No description provided for @flexibleBudgetAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Flexible Budget Analysis'**
  String get flexibleBudgetAnalysis;

  /// No description provided for @fixedCosts.
  ///
  /// In en, this message translates to:
  /// **'Fixed Costs'**
  String get fixedCosts;

  /// No description provided for @variableRateUnit.
  ///
  /// In en, this message translates to:
  /// **'Variable Rate/Unit'**
  String get variableRateUnit;

  /// No description provided for @plannedActivity.
  ///
  /// In en, this message translates to:
  /// **'Planned Activity'**
  String get plannedActivity;

  /// No description provided for @actualActivity.
  ///
  /// In en, this message translates to:
  /// **'Actual Activity'**
  String get actualActivity;

  /// No description provided for @actualTotalCost.
  ///
  /// In en, this message translates to:
  /// **'Actual Total Cost'**
  String get actualTotalCost;

  /// No description provided for @budgetedLabel.
  ///
  /// In en, this message translates to:
  /// **'Budgeted'**
  String get budgetedLabel;

  /// No description provided for @actualLabel.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get actualLabel;

  /// No description provided for @varianceLabel.
  ///
  /// In en, this message translates to:
  /// **'Variance'**
  String get varianceLabel;

  /// No description provided for @favorableLabel.
  ///
  /// In en, this message translates to:
  /// **'Favorable'**
  String get favorableLabel;

  /// No description provided for @unfavorableLabel.
  ///
  /// In en, this message translates to:
  /// **'Unfavorable'**
  String get unfavorableLabel;

  /// No description provided for @onTarget.
  ///
  /// In en, this message translates to:
  /// **'On Target'**
  String get onTarget;

  /// No description provided for @capitalBudgeting.
  ///
  /// In en, this message translates to:
  /// **'Capital Budgeting'**
  String get capitalBudgeting;

  /// No description provided for @calculatorTab.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get calculatorTab;

  /// No description provided for @resultsTab.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultsTab;

  /// No description provided for @sensitivityTab.
  ///
  /// In en, this message translates to:
  /// **'Sensitivity'**
  String get sensitivityTab;

  /// No description provided for @initialInvestment.
  ///
  /// In en, this message translates to:
  /// **'Initial Investment'**
  String get initialInvestment;

  /// No description provided for @investmentAmount.
  ///
  /// In en, this message translates to:
  /// **'Investment Amount'**
  String get investmentAmount;

  /// No description provided for @discountRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount Rate'**
  String get discountRateLabel;

  /// No description provided for @rateLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rateLabel;

  /// No description provided for @requiredReturn.
  ///
  /// In en, this message translates to:
  /// **'Required Return'**
  String get requiredReturn;

  /// No description provided for @expectedCashFlows.
  ///
  /// In en, this message translates to:
  /// **'Expected Cash Flows'**
  String get expectedCashFlows;

  /// No description provided for @forArrCalculation.
  ///
  /// In en, this message translates to:
  /// **'For ARR Calculation'**
  String get forArrCalculation;

  /// No description provided for @annualNetIncome.
  ///
  /// In en, this message translates to:
  /// **'Annual Net Income'**
  String get annualNetIncome;

  /// No description provided for @residualValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Residual Value'**
  String get residualValueLabel;

  /// No description provided for @calculateViewResults.
  ///
  /// In en, this message translates to:
  /// **'Calculate & View Results'**
  String get calculateViewResults;

  /// No description provided for @netPresentValue.
  ///
  /// In en, this message translates to:
  /// **'Net Present Value (NPV)'**
  String get netPresentValue;

  /// No description provided for @internalRateOfReturn.
  ///
  /// In en, this message translates to:
  /// **'Internal Rate of Return (IRR)'**
  String get internalRateOfReturn;

  /// No description provided for @paybackPeriod.
  ///
  /// In en, this message translates to:
  /// **'Payback Period'**
  String get paybackPeriod;

  /// No description provided for @investmentRecovered.
  ///
  /// In en, this message translates to:
  /// **'Investment will be recovered'**
  String get investmentRecovered;

  /// No description provided for @investmentMayNotRecover.
  ///
  /// In en, this message translates to:
  /// **'Investment may not be recovered'**
  String get investmentMayNotRecover;

  /// No description provided for @discountedPaybackPeriod.
  ///
  /// In en, this message translates to:
  /// **'Discounted Payback Period'**
  String get discountedPaybackPeriod;

  /// No description provided for @accountsForTimeValue.
  ///
  /// In en, this message translates to:
  /// **'Accounts for time value of money'**
  String get accountsForTimeValue;

  /// No description provided for @profitabilityIndex.
  ///
  /// In en, this message translates to:
  /// **'Profitability Index (PI)'**
  String get profitabilityIndex;

  /// No description provided for @accountingRateOfReturn.
  ///
  /// In en, this message translates to:
  /// **'Accounting Rate of Return (ARR)'**
  String get accountingRateOfReturn;

  /// No description provided for @acceptDecision.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptDecision;

  /// No description provided for @rejectDecision.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectDecision;

  /// No description provided for @npvSensitivity.
  ///
  /// In en, this message translates to:
  /// **'NPV Sensitivity to Discount Rate'**
  String get npvSensitivity;

  /// No description provided for @discountRateColumn.
  ///
  /// In en, this message translates to:
  /// **'Discount Rate'**
  String get discountRateColumn;

  /// No description provided for @npvColumn.
  ///
  /// In en, this message translates to:
  /// **'NPV'**
  String get npvColumn;

  /// No description provided for @decisionColumn.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get decisionColumn;

  /// No description provided for @selectPeriodTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select Period'**
  String get selectPeriodTooltip;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @errorLoadingRatios.
  ///
  /// In en, this message translates to:
  /// **'Error loading ratios'**
  String get errorLoadingRatios;

  /// No description provided for @analysisPeriod.
  ///
  /// In en, this message translates to:
  /// **'Analysis Period'**
  String get analysisPeriod;

  /// No description provided for @liquidityRatios.
  ///
  /// In en, this message translates to:
  /// **'Liquidity Ratios'**
  String get liquidityRatios;

  /// No description provided for @activityRatios.
  ///
  /// In en, this message translates to:
  /// **'Activity Ratios'**
  String get activityRatios;

  /// No description provided for @profitabilityRatios.
  ///
  /// In en, this message translates to:
  /// **'Profitability Ratios'**
  String get profitabilityRatios;

  /// No description provided for @leverageRatios.
  ///
  /// In en, this message translates to:
  /// **'Leverage Ratios'**
  String get leverageRatios;

  /// No description provided for @cashRatio.
  ///
  /// In en, this message translates to:
  /// **'Cash Ratio'**
  String get cashRatio;

  /// No description provided for @workingCapitalLabel.
  ///
  /// In en, this message translates to:
  /// **'Working Capital'**
  String get workingCapitalLabel;

  /// No description provided for @inventoryTurnover.
  ///
  /// In en, this message translates to:
  /// **'Inventory Turnover'**
  String get inventoryTurnover;

  /// No description provided for @daysSalesInInventory.
  ///
  /// In en, this message translates to:
  /// **'Days Sales in Inventory'**
  String get daysSalesInInventory;

  /// No description provided for @daysSalesOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Days Sales Outstanding'**
  String get daysSalesOutstanding;

  /// No description provided for @cashConversionCycle.
  ///
  /// In en, this message translates to:
  /// **'Cash Conversion Cycle'**
  String get cashConversionCycle;

  /// No description provided for @assetTurnover.
  ///
  /// In en, this message translates to:
  /// **'Asset Turnover'**
  String get assetTurnover;

  /// No description provided for @operatingProfitMargin.
  ///
  /// In en, this message translates to:
  /// **'Operating Profit Margin'**
  String get operatingProfitMargin;

  /// No description provided for @returnOnEquity.
  ///
  /// In en, this message translates to:
  /// **'Return on Equity (ROE)'**
  String get returnOnEquity;

  /// No description provided for @ebitdaMargin.
  ///
  /// In en, this message translates to:
  /// **'EBITDA Margin'**
  String get ebitdaMargin;

  /// No description provided for @debtToEquityRatio.
  ///
  /// In en, this message translates to:
  /// **'Debt-to-Equity Ratio'**
  String get debtToEquityRatio;

  /// No description provided for @debtToAssetsRatio.
  ///
  /// In en, this message translates to:
  /// **'Debt-to-Assets Ratio'**
  String get debtToAssetsRatio;

  /// No description provided for @equityMultiplier.
  ///
  /// In en, this message translates to:
  /// **'Equity Multiplier'**
  String get equityMultiplier;

  /// No description provided for @interestCoverage.
  ///
  /// In en, this message translates to:
  /// **'Interest Coverage'**
  String get interestCoverage;

  /// No description provided for @timesInterestEarned.
  ///
  /// In en, this message translates to:
  /// **'Times Interest Earned'**
  String get timesInterestEarned;

  /// No description provided for @cashFlowsOperating.
  ///
  /// In en, this message translates to:
  /// **'Cash Flows from Operating Activities'**
  String get cashFlowsOperating;

  /// No description provided for @cashFlowsInvesting.
  ///
  /// In en, this message translates to:
  /// **'Cash Flows from Investing Activities'**
  String get cashFlowsInvesting;

  /// No description provided for @cashFlowsFinancing.
  ///
  /// In en, this message translates to:
  /// **'Cash Flows from Financing Activities'**
  String get cashFlowsFinancing;

  /// No description provided for @netCashOperating.
  ///
  /// In en, this message translates to:
  /// **'Net Cash from Operating'**
  String get netCashOperating;

  /// No description provided for @netCashInvesting.
  ///
  /// In en, this message translates to:
  /// **'Net Cash from Investing'**
  String get netCashInvesting;

  /// No description provided for @netCashFinancing.
  ///
  /// In en, this message translates to:
  /// **'Net Cash from Financing'**
  String get netCashFinancing;

  /// No description provided for @fraudDetection.
  ///
  /// In en, this message translates to:
  /// **'Fraud Detection (M-Score)'**
  String get fraudDetection;

  /// No description provided for @inputTab.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get inputTab;

  /// No description provided for @learnTab.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learnTab;

  /// No description provided for @currentPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Period'**
  String get currentPeriodLabel;

  /// No description provided for @priorPeriod.
  ///
  /// In en, this message translates to:
  /// **'Prior Period'**
  String get priorPeriod;

  /// No description provided for @componentIndices.
  ///
  /// In en, this message translates to:
  /// **'Component Indices'**
  String get componentIndices;

  /// No description provided for @redFlagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Red Flags'**
  String get redFlagsLabel;

  /// No description provided for @whatIsBeneish.
  ///
  /// In en, this message translates to:
  /// **'What is the Beneish M-Score?'**
  String get whatIsBeneish;

  /// No description provided for @theFormula.
  ///
  /// In en, this message translates to:
  /// **'The Formula'**
  String get theFormula;

  /// No description provided for @indexExplanations.
  ///
  /// In en, this message translates to:
  /// **'Index Explanations'**
  String get indexExplanations;

  /// No description provided for @famousCases.
  ///
  /// In en, this message translates to:
  /// **'Famous Cases'**
  String get famousCases;

  /// No description provided for @probableManipulator.
  ///
  /// In en, this message translates to:
  /// **'Probable Manipulator'**
  String get probableManipulator;

  /// No description provided for @standardCosting.
  ///
  /// In en, this message translates to:
  /// **'Standard Costing'**
  String get standardCosting;

  /// No description provided for @standardsTab.
  ///
  /// In en, this message translates to:
  /// **'Standards'**
  String get standardsTab;

  /// No description provided for @materialsTab.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materialsTab;

  /// No description provided for @laborTab.
  ///
  /// In en, this message translates to:
  /// **'Labor'**
  String get laborTab;

  /// No description provided for @overheadTab.
  ///
  /// In en, this message translates to:
  /// **'Overhead'**
  String get overheadTab;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get selectFile;

  /// No description provided for @chooseDataType.
  ///
  /// In en, this message translates to:
  /// **'Choose Data Type'**
  String get chooseDataType;

  /// No description provided for @mapColumns.
  ///
  /// In en, this message translates to:
  /// **'Map Columns'**
  String get mapColumns;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @importBtn.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importBtn;

  /// No description provided for @backBtn.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backBtn;

  /// No description provided for @doneBtn.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneBtn;

  /// No description provided for @selectCsvFile.
  ///
  /// In en, this message translates to:
  /// **'Select a CSV or Excel file to import.'**
  String get selectCsvFile;

  /// No description provided for @whatDataImporting.
  ///
  /// In en, this message translates to:
  /// **'What type of data are you importing?'**
  String get whatDataImporting;

  /// No description provided for @mapEachColumn.
  ///
  /// In en, this message translates to:
  /// **'Map each column to a field:'**
  String get mapEachColumn;

  /// No description provided for @errorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Errors:'**
  String get errorsLabel;

  /// No description provided for @productsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTitle;

  /// No description provided for @newProduct.
  ///
  /// In en, this message translates to:
  /// **'New Product'**
  String get newProduct;

  /// No description provided for @addProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProductTitle;

  /// No description provided for @editProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProductTitle;

  /// No description provided for @saveProduct.
  ///
  /// In en, this message translates to:
  /// **'Save Product'**
  String get saveProduct;

  /// No description provided for @vendorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get vendorsTitle;

  /// No description provided for @addVendorBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Vendor'**
  String get addVendorBtn;

  /// No description provided for @newVendorForm.
  ///
  /// In en, this message translates to:
  /// **'New Vendor'**
  String get newVendorForm;

  /// No description provided for @editVendorForm.
  ///
  /// In en, this message translates to:
  /// **'Edit Vendor'**
  String get editVendorForm;

  /// No description provided for @vendorCreated.
  ///
  /// In en, this message translates to:
  /// **'Vendor created successfully'**
  String get vendorCreated;

  /// No description provided for @vendorUpdated.
  ///
  /// In en, this message translates to:
  /// **'Vendor updated successfully'**
  String get vendorUpdated;

  /// No description provided for @vendorDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendorDetailTitle;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @addCustomerBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomerBtn;

  /// No description provided for @newCustomerForm.
  ///
  /// In en, this message translates to:
  /// **'New Customer'**
  String get newCustomerForm;

  /// No description provided for @editCustomerForm.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomerForm;

  /// No description provided for @customerCreated.
  ///
  /// In en, this message translates to:
  /// **'Customer created successfully'**
  String get customerCreated;

  /// No description provided for @customerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Customer updated successfully'**
  String get customerUpdated;

  /// No description provided for @customerDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerDetailTitle;

  /// No description provided for @putCustomerOnHold.
  ///
  /// In en, this message translates to:
  /// **'Put Customer On Hold'**
  String get putCustomerOnHold;

  /// No description provided for @preventsNewInvoices.
  ///
  /// In en, this message translates to:
  /// **'Prevents new invoices/orders'**
  String get preventsNewInvoices;

  /// No description provided for @pleaseAddLineItem.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one line item with an amount.'**
  String get pleaseAddLineItem;

  /// No description provided for @saveBtn.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveBtn;

  /// No description provided for @cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelBtn;

  /// No description provided for @createBtn.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createBtn;

  /// No description provided for @changeBtn.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeBtn;

  /// No description provided for @reconcileBtn.
  ///
  /// In en, this message translates to:
  /// **'Reconcile'**
  String get reconcileBtn;

  /// No description provided for @statementBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Statement Balance:'**
  String get statementBalanceLabel;

  /// No description provided for @bookBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Book Balance:'**
  String get bookBalanceLabel;

  /// No description provided for @entryReconciled.
  ///
  /// In en, this message translates to:
  /// **'Entry reconciled'**
  String get entryReconciled;

  /// No description provided for @staffManagement.
  ///
  /// In en, this message translates to:
  /// **'Staff Management'**
  String get staffManagement;

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get changeRole;

  /// No description provided for @removeAccess.
  ///
  /// In en, this message translates to:
  /// **'Remove Access'**
  String get removeAccess;

  /// No description provided for @roleSaved.
  ///
  /// In en, this message translates to:
  /// **'Role saved successfully!'**
  String get roleSaved;

  /// No description provided for @roleNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Role Name'**
  String get roleNameLabel;

  /// No description provided for @selectPermission.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one permission.'**
  String get selectPermission;

  /// No description provided for @systemAdminReadonly.
  ///
  /// In en, this message translates to:
  /// **'System Admin role cannot be edited.'**
  String get systemAdminReadonly;

  /// No description provided for @customFieldsProducts.
  ///
  /// In en, this message translates to:
  /// **'Custom Fields (Products)'**
  String get customFieldsProducts;

  /// No description provided for @enterDataCalculator.
  ///
  /// In en, this message translates to:
  /// **'Enter investment data in the Calculator tab'**
  String get enterDataCalculator;

  /// No description provided for @enterDataAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Enter data to see analysis'**
  String get enterDataAnalysis;

  /// No description provided for @enterFinancialData.
  ///
  /// In en, this message translates to:
  /// **'Enter financial data to see results'**
  String get enterFinancialData;

  /// No description provided for @iUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I Understand'**
  String get iUnderstand;

  /// No description provided for @gotItBtn.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotItBtn;

  /// No description provided for @budgetVsActual.
  ///
  /// In en, this message translates to:
  /// **'Budget vs Actual by Account'**
  String get budgetVsActual;

  /// No description provided for @greenFavorable.
  ///
  /// In en, this message translates to:
  /// **'Green = Favorable | Red = Unfavorable'**
  String get greenFavorable;

  /// No description provided for @budgetComparison.
  ///
  /// In en, this message translates to:
  /// **'Budget Comparison'**
  String get budgetComparison;

  /// No description provided for @staticBudget.
  ///
  /// In en, this message translates to:
  /// **'Static Budget'**
  String get staticBudget;

  /// No description provided for @actualCost.
  ///
  /// In en, this message translates to:
  /// **'Actual Cost'**
  String get actualCost;

  /// No description provided for @varianceAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Variance Analysis'**
  String get varianceAnalysis;

  /// No description provided for @volumeVariance.
  ///
  /// In en, this message translates to:
  /// **'Volume Variance'**
  String get volumeVariance;

  /// No description provided for @dueToActivityLevel.
  ///
  /// In en, this message translates to:
  /// **'Due to activity level difference'**
  String get dueToActivityLevel;

  /// No description provided for @spendingVariance.
  ///
  /// In en, this message translates to:
  /// **'Spending Variance'**
  String get spendingVariance;

  /// No description provided for @dueToEfficiency.
  ///
  /// In en, this message translates to:
  /// **'Due to efficiency/price'**
  String get dueToEfficiency;

  /// No description provided for @totalVariance.
  ///
  /// In en, this message translates to:
  /// **'Total Variance'**
  String get totalVariance;

  /// No description provided for @actualMinusStatic.
  ///
  /// In en, this message translates to:
  /// **'Actual - Static Budget'**
  String get actualMinusStatic;

  /// No description provided for @separateVariances.
  ///
  /// In en, this message translates to:
  /// **'Separate volume variances from spending variances'**
  String get separateVariances;

  /// No description provided for @formulasUsed.
  ///
  /// In en, this message translates to:
  /// **'Formulas Used'**
  String get formulasUsed;

  /// No description provided for @revenueInput.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenueInput;

  /// No description provided for @receivablesInput.
  ///
  /// In en, this message translates to:
  /// **'Receivables'**
  String get receivablesInput;

  /// No description provided for @grossProfitInput.
  ///
  /// In en, this message translates to:
  /// **'Gross Profit'**
  String get grossProfitInput;

  /// No description provided for @totalAssetsInput.
  ///
  /// In en, this message translates to:
  /// **'Total Assets'**
  String get totalAssetsInput;

  /// No description provided for @currentAssetsInput.
  ///
  /// In en, this message translates to:
  /// **'Current Assets'**
  String get currentAssetsInput;

  /// No description provided for @ppeInput.
  ///
  /// In en, this message translates to:
  /// **'PP&E'**
  String get ppeInput;

  /// No description provided for @depreciationInput.
  ///
  /// In en, this message translates to:
  /// **'Depreciation'**
  String get depreciationInput;

  /// No description provided for @sgaExpenseInput.
  ///
  /// In en, this message translates to:
  /// **'SG&A Expense'**
  String get sgaExpenseInput;

  /// No description provided for @netIncomeInput.
  ///
  /// In en, this message translates to:
  /// **'Net Income'**
  String get netIncomeInput;

  /// No description provided for @cashFromOps.
  ///
  /// In en, this message translates to:
  /// **'Cash from Ops'**
  String get cashFromOps;

  /// No description provided for @longTermDebt.
  ///
  /// In en, this message translates to:
  /// **'Long-Term Debt'**
  String get longTermDebt;

  /// No description provided for @currentLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Current Liabilities'**
  String get currentLiabilities;

  /// No description provided for @probableManipulatorLabel.
  ///
  /// In en, this message translates to:
  /// **'PROBABLE MANIPULATOR'**
  String get probableManipulatorLabel;

  /// No description provided for @vendorInvoiceOptional.
  ///
  /// In en, this message translates to:
  /// **'Vendor Invoice # (Optional)'**
  String get vendorInvoiceOptional;

  /// No description provided for @customerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer Name *'**
  String get customerNameRequired;

  /// No description provided for @vendorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Vendor Name *'**
  String get vendorNameRequired;

  /// No description provided for @paymentTermsHint.
  ///
  /// In en, this message translates to:
  /// **'Payment Terms (e.g., Net 30)'**
  String get paymentTermsHint;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @qtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qtyLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @joinedOrganization.
  ///
  /// In en, this message translates to:
  /// **'Successfully joined organization!'**
  String get joinedOrganization;

  /// No description provided for @roleNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Senior Cashier'**
  String get roleNameHint;

  /// No description provided for @mapTo.
  ///
  /// In en, this message translates to:
  /// **'Map to'**
  String get mapTo;

  /// No description provided for @addAssetComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Add Asset feature coming soon'**
  String get addAssetComingSoon;

  /// No description provided for @assetDisposalComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Asset disposal feature coming soon'**
  String get assetDisposalComingSoon;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @errorLoadingBills.
  ///
  /// In en, this message translates to:
  /// **'Error loading bills'**
  String get errorLoadingBills;

  /// No description provided for @errorLoadingInvoices.
  ///
  /// In en, this message translates to:
  /// **'Error loading invoices'**
  String get errorLoadingInvoices;

  /// No description provided for @errorSavingRole.
  ///
  /// In en, this message translates to:
  /// **'Error saving role'**
  String get errorSavingRole;

  /// No description provided for @selectTransactionsToReconcile.
  ///
  /// In en, this message translates to:
  /// **'Please select transactions to reconcile'**
  String get selectTransactionsToReconcile;

  /// No description provided for @reconcileAmount.
  ///
  /// In en, this message translates to:
  /// **'Reconcile {currency}'**
  String reconcileAmount(String currency);

  /// No description provided for @enterDataInCalculator.
  ///
  /// In en, this message translates to:
  /// **'Enter data in the Calculator tab first'**
  String get enterDataInCalculator;

  /// No description provided for @scenarioColumn.
  ///
  /// In en, this message translates to:
  /// **'Scenario'**
  String get scenarioColumn;

  /// No description provided for @breakEvenColumn.
  ///
  /// In en, this message translates to:
  /// **'Break-Even'**
  String get breakEvenColumn;

  /// No description provided for @changeColumn.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeColumn;

  /// No description provided for @impactColumn.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get impactColumn;

  /// No description provided for @variableOverhead.
  ///
  /// In en, this message translates to:
  /// **'Variable Overhead'**
  String get variableOverhead;

  /// No description provided for @fixedOverhead.
  ///
  /// In en, this message translates to:
  /// **'Fixed Overhead'**
  String get fixedOverhead;

  /// No description provided for @examplesLabel.
  ///
  /// In en, this message translates to:
  /// **'Examples:'**
  String get examplesLabel;

  /// No description provided for @reconciliation.
  ///
  /// In en, this message translates to:
  /// **'Reconciliation'**
  String get reconciliation;

  /// No description provided for @letsSetUpCorrectly.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set things up correctly.'**
  String get letsSetUpCorrectly;

  /// No description provided for @addField.
  ///
  /// In en, this message translates to:
  /// **'Add Field'**
  String get addField;

  /// No description provided for @editField.
  ///
  /// In en, this message translates to:
  /// **'Edit Field'**
  String get editField;

  /// No description provided for @editRole.
  ///
  /// In en, this message translates to:
  /// **'Edit Role'**
  String get editRole;

  /// No description provided for @createNewRole.
  ///
  /// In en, this message translates to:
  /// **'Create New Role'**
  String get createNewRole;

  /// No description provided for @creatingBtn.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creatingBtn;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'{count} in stock'**
  String inStock(int count);

  /// No description provided for @cartSummary.
  ///
  /// In en, this message translates to:
  /// **'Cart: {count} items — {total}'**
  String cartSummary(int count, String total);

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @taxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax ({rate}%)'**
  String taxLabel(String rate);

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountLabel;

  /// No description provided for @totalUppercase.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get totalUppercase;

  /// No description provided for @holdOrder.
  ///
  /// In en, this message translates to:
  /// **'Hold Order'**
  String get holdOrder;

  /// No description provided for @noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProducts;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// No description provided for @cartEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap products to add them to your order'**
  String get cartEmptyHint;

  /// No description provided for @payWith.
  ///
  /// In en, this message translates to:
  /// **'Pay with {method}'**
  String payWith(String method);

  /// No description provided for @orderParked.
  ///
  /// In en, this message translates to:
  /// **'Order Parked'**
  String get orderParked;

  /// No description provided for @recallOrder.
  ///
  /// In en, this message translates to:
  /// **'Recall Order'**
  String get recallOrder;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String orderNumber(String id);

  /// No description provided for @itemsAndTime.
  ///
  /// In en, this message translates to:
  /// **'{count} items • {time} mins ago'**
  String itemsAndTime(int count, int time);

  /// No description provided for @closeBtn.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeBtn;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @selectPrimaryCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select Primary Currency'**
  String get selectPrimaryCurrency;

  /// No description provided for @currencyCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code (e.g. YER)'**
  String get currencyCodeLabel;

  /// No description provided for @currencySymbolLabel.
  ///
  /// In en, this message translates to:
  /// **'Symbol (﷼)'**
  String get currencySymbolLabel;

  /// No description provided for @benchmarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Benchmark: {value}'**
  String benchmarkLabel(String value);

  /// No description provided for @breakEvenTab.
  ///
  /// In en, this message translates to:
  /// **'Break-Even'**
  String get breakEvenTab;

  /// No description provided for @marginOfSafetyTab.
  ///
  /// In en, this message translates to:
  /// **'Margin of Safety'**
  String get marginOfSafetyTab;

  /// No description provided for @whatIfTab.
  ///
  /// In en, this message translates to:
  /// **'What-If'**
  String get whatIfTab;

  /// No description provided for @contributionMarginLabel.
  ///
  /// In en, this message translates to:
  /// **'Contribution Margin:'**
  String get contributionMarginLabel;

  /// No description provided for @perUnitSuffix.
  ///
  /// In en, this message translates to:
  /// **'per unit'**
  String get perUnitSuffix;

  /// No description provided for @unitsSuffix.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get unitsSuffix;

  /// No description provided for @salesRevenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Sales Revenue'**
  String get salesRevenueLabel;

  /// No description provided for @analyzeViewResults.
  ///
  /// In en, this message translates to:
  /// **'Analyze & View Results'**
  String get analyzeViewResults;

  /// No description provided for @enterDataCalculatorFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter data in the Calculator tab first'**
  String get enterDataCalculatorFirst;

  /// No description provided for @unitsLabel.
  ///
  /// In en, this message translates to:
  /// **'UNITS'**
  String get unitsLabel;

  /// No description provided for @salesLabel.
  ///
  /// In en, this message translates to:
  /// **'SALES'**
  String get salesLabel;

  /// No description provided for @contributionMarginTitle.
  ///
  /// In en, this message translates to:
  /// **'Contribution Margin'**
  String get contributionMarginTitle;

  /// No description provided for @cmPerUnit.
  ///
  /// In en, this message translates to:
  /// **'CM per Unit'**
  String get cmPerUnit;

  /// No description provided for @cmRatio.
  ///
  /// In en, this message translates to:
  /// **'CM Ratio'**
  String get cmRatio;

  /// No description provided for @marginOfSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Margin of Safety'**
  String get marginOfSafetyTitle;

  /// No description provided for @riskSuffix.
  ///
  /// In en, this message translates to:
  /// **'RISK'**
  String get riskSuffix;

  /// No description provided for @mosDollar.
  ///
  /// In en, this message translates to:
  /// **'MOS (\$)'**
  String get mosDollar;

  /// No description provided for @mosUnits.
  ///
  /// In en, this message translates to:
  /// **'MOS (Units)'**
  String get mosUnits;

  /// No description provided for @impactLabel.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get impactLabel;

  /// No description provided for @leverageImpactDesc.
  ///
  /// In en, this message translates to:
  /// **'1% sales change → {percent}% profit change'**
  String leverageImpactDesc(String percent);

  /// No description provided for @priceSensitivityDesc.
  ///
  /// In en, this message translates to:
  /// **'Shows how break-even changes when you adjust selling price'**
  String get priceSensitivityDesc;

  /// No description provided for @baseImpact.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get baseImpact;

  /// No description provided for @betterImpact.
  ///
  /// In en, this message translates to:
  /// **'Better'**
  String get betterImpact;

  /// No description provided for @worseImpact.
  ///
  /// In en, this message translates to:
  /// **'Worse'**
  String get worseImpact;

  /// No description provided for @keyInsights.
  ///
  /// In en, this message translates to:
  /// **'Key Insights'**
  String get keyInsights;

  /// No description provided for @projectedProfit.
  ///
  /// In en, this message translates to:
  /// **'PROJECTED PROFIT'**
  String get projectedProfit;

  /// No description provided for @projectedLoss.
  ///
  /// In en, this message translates to:
  /// **'PROJECTED LOSS'**
  String get projectedLoss;

  /// No description provided for @strongSafetyMargin.
  ///
  /// In en, this message translates to:
  /// **'Strong safety margin. Sales can drop {percent}% before reaching break-even.'**
  String strongSafetyMargin(String percent);

  /// No description provided for @moderateSafetyMargin.
  ///
  /// In en, this message translates to:
  /// **'Moderate safety margin. Consider strategies to increase sales or reduce costs.'**
  String get moderateSafetyMargin;

  /// No description provided for @thinSafetyMargin.
  ///
  /// In en, this message translates to:
  /// **'Thin safety margin. The business is close to break-even and vulnerable to sales declines.'**
  String get thinSafetyMargin;

  /// No description provided for @belowBreakEven.
  ///
  /// In en, this message translates to:
  /// **'Operating below break-even. Immediate action needed to increase revenue or reduce costs.'**
  String get belowBreakEven;

  /// No description provided for @higherPricesInsight.
  ///
  /// In en, this message translates to:
  /// **'Higher prices = Lower break-even (fewer units needed)'**
  String get higherPricesInsight;

  /// No description provided for @lowerPricesInsight.
  ///
  /// In en, this message translates to:
  /// **'Lower prices = Higher break-even (more units needed)'**
  String get lowerPricesInsight;

  /// No description provided for @priceIncreaseEffect.
  ///
  /// In en, this message translates to:
  /// **'A 10% price increase reduces break-even by {units} units'**
  String priceIncreaseEffect(String units);

  /// No description provided for @priceDecreaseEffect.
  ///
  /// In en, this message translates to:
  /// **'A 10% price decrease increases break-even by {units} units'**
  String priceDecreaseEffect(String units);

  /// No description provided for @formulaCurrentRatio.
  ///
  /// In en, this message translates to:
  /// **'Current Assets ÷ Current Liabilities'**
  String get formulaCurrentRatio;

  /// No description provided for @formulaQuickRatio.
  ///
  /// In en, this message translates to:
  /// **'(Cash + Receivables) ÷ Current Liabilities'**
  String get formulaQuickRatio;

  /// No description provided for @formulaCashRatio.
  ///
  /// In en, this message translates to:
  /// **'Cash ÷ Current Liabilities'**
  String get formulaCashRatio;

  /// No description provided for @formulaWorkingCapital.
  ///
  /// In en, this message translates to:
  /// **'Current Assets - Current Liabilities'**
  String get formulaWorkingCapital;

  /// No description provided for @formulaInventoryTurnover.
  ///
  /// In en, this message translates to:
  /// **'COGS ÷ Average Inventory'**
  String get formulaInventoryTurnover;

  /// No description provided for @formulaDaysSalesInInventory.
  ///
  /// In en, this message translates to:
  /// **'365 ÷ Inventory Turnover'**
  String get formulaDaysSalesInInventory;

  /// No description provided for @formulaReceivablesTurnover.
  ///
  /// In en, this message translates to:
  /// **'Net Sales ÷ Average Receivables'**
  String get formulaReceivablesTurnover;

  /// No description provided for @formulaDaysSalesOutstanding.
  ///
  /// In en, this message translates to:
  /// **'365 ÷ Receivables Turnover'**
  String get formulaDaysSalesOutstanding;

  /// No description provided for @formulaCashConversionCycle.
  ///
  /// In en, this message translates to:
  /// **'DSI + DSO - DPO'**
  String get formulaCashConversionCycle;

  /// No description provided for @formulaAssetTurnover.
  ///
  /// In en, this message translates to:
  /// **'Net Sales ÷ Average Total Assets'**
  String get formulaAssetTurnover;

  /// No description provided for @formulaGrossProfitMargin.
  ///
  /// In en, this message translates to:
  /// **'(Revenue - COGS) ÷ Revenue'**
  String get formulaGrossProfitMargin;

  /// No description provided for @formulaOperatingProfitMargin.
  ///
  /// In en, this message translates to:
  /// **'Operating Income ÷ Revenue'**
  String get formulaOperatingProfitMargin;

  /// No description provided for @formulaNetProfitMargin.
  ///
  /// In en, this message translates to:
  /// **'Net Income ÷ Revenue'**
  String get formulaNetProfitMargin;

  /// No description provided for @formulaReturnOnAssets.
  ///
  /// In en, this message translates to:
  /// **'Net Income ÷ Average Total Assets'**
  String get formulaReturnOnAssets;

  /// No description provided for @formulaReturnOnEquity.
  ///
  /// In en, this message translates to:
  /// **'Net Income ÷ Average Equity'**
  String get formulaReturnOnEquity;

  /// No description provided for @formulaEbitdaMargin.
  ///
  /// In en, this message translates to:
  /// **'EBITDA ÷ Revenue'**
  String get formulaEbitdaMargin;

  /// No description provided for @formulaDebtToEquity.
  ///
  /// In en, this message translates to:
  /// **'Total Liabilities ÷ Shareholders\' Equity'**
  String get formulaDebtToEquity;

  /// No description provided for @formulaDebtToAssets.
  ///
  /// In en, this message translates to:
  /// **'Total Liabilities ÷ Total Assets'**
  String get formulaDebtToAssets;

  /// No description provided for @formulaEquityMultiplier.
  ///
  /// In en, this message translates to:
  /// **'Total Assets ÷ Shareholders\' Equity'**
  String get formulaEquityMultiplier;

  /// No description provided for @formulaInterestCoverage.
  ///
  /// In en, this message translates to:
  /// **'EBIT ÷ Interest Expense'**
  String get formulaInterestCoverage;

  /// No description provided for @formulaTimesInterestEarned.
  ///
  /// In en, this message translates to:
  /// **'(Net Income + Interest + Tax) ÷ Interest'**
  String get formulaTimesInterestEarned;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @daysSuffix.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysSuffix;

  /// No description provided for @standardCostCard.
  ///
  /// In en, this message translates to:
  /// **'Standard Cost Card'**
  String get standardCostCard;

  /// No description provided for @materialQtyUnit.
  ///
  /// In en, this message translates to:
  /// **'Material Qty/Unit'**
  String get materialQtyUnit;

  /// No description provided for @materialPrice.
  ///
  /// In en, this message translates to:
  /// **'Material Price'**
  String get materialPrice;

  /// No description provided for @laborHoursUnit.
  ///
  /// In en, this message translates to:
  /// **'Labor Hours/Unit'**
  String get laborHoursUnit;

  /// No description provided for @laborRate.
  ///
  /// In en, this message translates to:
  /// **'Labor Rate'**
  String get laborRate;

  /// No description provided for @vohRate.
  ///
  /// In en, this message translates to:
  /// **'VOH Rate'**
  String get vohRate;

  /// No description provided for @budgetedFoh.
  ///
  /// In en, this message translates to:
  /// **'Budgeted FOH'**
  String get budgetedFoh;

  /// No description provided for @normalCapacity.
  ///
  /// In en, this message translates to:
  /// **'Normal Capacity'**
  String get normalCapacity;

  /// No description provided for @actualProduction.
  ///
  /// In en, this message translates to:
  /// **'Actual Production'**
  String get actualProduction;

  /// No description provided for @unitsProduced.
  ///
  /// In en, this message translates to:
  /// **'Units Produced'**
  String get unitsProduced;

  /// No description provided for @materialUsed.
  ///
  /// In en, this message translates to:
  /// **'Material Used'**
  String get materialUsed;

  /// No description provided for @laborHours.
  ///
  /// In en, this message translates to:
  /// **'Labor Hours'**
  String get laborHours;

  /// No description provided for @actualVoh.
  ///
  /// In en, this message translates to:
  /// **'Actual VOH'**
  String get actualVoh;

  /// No description provided for @actualFoh.
  ///
  /// In en, this message translates to:
  /// **'Actual FOH'**
  String get actualFoh;

  /// No description provided for @totalVarianceAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Variance: {amount}'**
  String totalVarianceAmount(String amount);

  /// No description provided for @netFavorable.
  ///
  /// In en, this message translates to:
  /// **'Net Favorable'**
  String get netFavorable;

  /// No description provided for @netUnfavorable.
  ///
  /// In en, this message translates to:
  /// **'Net Unfavorable'**
  String get netUnfavorable;

  /// No description provided for @directMaterialsVariance.
  ///
  /// In en, this message translates to:
  /// **'Direct Materials Variance'**
  String get directMaterialsVariance;

  /// No description provided for @standardCost.
  ///
  /// In en, this message translates to:
  /// **'Standard Cost'**
  String get standardCost;

  /// No description provided for @actualCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Actual Cost'**
  String get actualCostLabel;

  /// No description provided for @varianceBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Variance Breakdown'**
  String get varianceBreakdown;

  /// No description provided for @priceVariance.
  ///
  /// In en, this message translates to:
  /// **'Price Variance'**
  String get priceVariance;

  /// No description provided for @priceVarianceFormula.
  ///
  /// In en, this message translates to:
  /// **'(AP - SP) × AQ'**
  String get priceVarianceFormula;

  /// No description provided for @quantityVariance.
  ///
  /// In en, this message translates to:
  /// **'Quantity Variance'**
  String get quantityVariance;

  /// No description provided for @quantityVarianceFormula.
  ///
  /// In en, this message translates to:
  /// **'(AQ - SQ) × SP'**
  String get quantityVarianceFormula;

  /// No description provided for @materialsFormulas.
  ///
  /// In en, this message translates to:
  /// **'Materials Formulas'**
  String get materialsFormulas;

  /// No description provided for @priceVarianceFormulaFull.
  ///
  /// In en, this message translates to:
  /// **'Price Variance = (Actual Price - Standard Price) × Actual Qty'**
  String get priceVarianceFormulaFull;

  /// No description provided for @quantityVarianceFormulaFull.
  ///
  /// In en, this message translates to:
  /// **'Quantity Variance = (Actual Qty - Standard Qty) × Standard Price'**
  String get quantityVarianceFormulaFull;

  /// No description provided for @directLaborVariance.
  ///
  /// In en, this message translates to:
  /// **'Direct Labor Variance'**
  String get directLaborVariance;

  /// No description provided for @rateVariance.
  ///
  /// In en, this message translates to:
  /// **'Rate Variance'**
  String get rateVariance;

  /// No description provided for @rateVarianceFormula.
  ///
  /// In en, this message translates to:
  /// **'(AR - SR) × AH'**
  String get rateVarianceFormula;

  /// No description provided for @efficiencyVariance.
  ///
  /// In en, this message translates to:
  /// **'Efficiency Variance'**
  String get efficiencyVariance;

  /// No description provided for @efficiencyVarianceFormula.
  ///
  /// In en, this message translates to:
  /// **'(AH - SH) × SR'**
  String get efficiencyVarianceFormula;

  /// No description provided for @laborFormulas.
  ///
  /// In en, this message translates to:
  /// **'Labor Formulas'**
  String get laborFormulas;

  /// No description provided for @rateVarianceFormulaFull.
  ///
  /// In en, this message translates to:
  /// **'Rate Variance = (Actual Rate - Standard Rate) × Actual Hours'**
  String get rateVarianceFormulaFull;

  /// No description provided for @efficiencyVarianceFormulaFull.
  ///
  /// In en, this message translates to:
  /// **'Efficiency Variance = (Actual Hours - Std Hours) × Std Rate'**
  String get efficiencyVarianceFormulaFull;

  /// No description provided for @manufacturingOverheadVariance.
  ///
  /// In en, this message translates to:
  /// **'Manufacturing Overhead Variance'**
  String get manufacturingOverheadVariance;

  /// No description provided for @appliedOverhead.
  ///
  /// In en, this message translates to:
  /// **'Applied Overhead'**
  String get appliedOverhead;

  /// No description provided for @actualOverhead.
  ///
  /// In en, this message translates to:
  /// **'Actual Overhead'**
  String get actualOverhead;

  /// No description provided for @overapplied.
  ///
  /// In en, this message translates to:
  /// **'Overapplied'**
  String get overapplied;

  /// No description provided for @underapplied.
  ///
  /// In en, this message translates to:
  /// **'Underapplied'**
  String get underapplied;

  /// No description provided for @budgetVariance.
  ///
  /// In en, this message translates to:
  /// **'Budget Variance'**
  String get budgetVariance;

  /// No description provided for @actualFohMinusBudgeted.
  ///
  /// In en, this message translates to:
  /// **'Actual FOH - Budgeted FOH'**
  String get actualFohMinusBudgeted;

  /// No description provided for @budgetedFohMinusApplied.
  ///
  /// In en, this message translates to:
  /// **'Budgeted FOH - Applied FOH'**
  String get budgetedFohMinusApplied;

  /// No description provided for @actualVohFormula.
  ///
  /// In en, this message translates to:
  /// **'Actual VOH - (AH × SR)'**
  String get actualVohFormula;

  /// No description provided for @unitSuffix.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get unitSuffix;

  /// No description provided for @dollarPerUnit.
  ///
  /// In en, this message translates to:
  /// **'\$/unit'**
  String get dollarPerUnit;

  /// No description provided for @hrsSuffix.
  ///
  /// In en, this message translates to:
  /// **'hrs'**
  String get hrsSuffix;

  /// No description provided for @dollarPerHr.
  ///
  /// In en, this message translates to:
  /// **'\$/hr'**
  String get dollarPerHr;

  /// No description provided for @favorableBadge.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get favorableBadge;

  /// No description provided for @unfavorableBadge.
  ///
  /// In en, this message translates to:
  /// **'U'**
  String get unfavorableBadge;

  /// No description provided for @mScoreValue.
  ///
  /// In en, this message translates to:
  /// **'M-Score: {value}'**
  String mScoreValue(String value);

  /// No description provided for @riskLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'{level} Risk'**
  String riskLevelLabel(String level);

  /// No description provided for @riskOfEarningsManipulation.
  ///
  /// In en, this message translates to:
  /// **'{level} Risk of Earnings Manipulation'**
  String riskOfEarningsManipulation(String level);

  /// No description provided for @thresholdNote.
  ///
  /// In en, this message translates to:
  /// **'Threshold: > -1.78 indicates manipulation'**
  String get thresholdNote;

  /// No description provided for @dsriAbbr.
  ///
  /// In en, this message translates to:
  /// **'DSRI'**
  String get dsriAbbr;

  /// No description provided for @dsriDesc.
  ///
  /// In en, this message translates to:
  /// **'Receivables/Sales'**
  String get dsriDesc;

  /// No description provided for @gmiAbbr.
  ///
  /// In en, this message translates to:
  /// **'GMI'**
  String get gmiAbbr;

  /// No description provided for @gmiDesc.
  ///
  /// In en, this message translates to:
  /// **'Gross Margin'**
  String get gmiDesc;

  /// No description provided for @aqiAbbr.
  ///
  /// In en, this message translates to:
  /// **'AQI'**
  String get aqiAbbr;

  /// No description provided for @aqiDesc.
  ///
  /// In en, this message translates to:
  /// **'Asset Quality'**
  String get aqiDesc;

  /// No description provided for @sgiAbbr.
  ///
  /// In en, this message translates to:
  /// **'SGI'**
  String get sgiAbbr;

  /// No description provided for @sgiDesc.
  ///
  /// In en, this message translates to:
  /// **'Sales Growth'**
  String get sgiDesc;

  /// No description provided for @depiAbbr.
  ///
  /// In en, this message translates to:
  /// **'DEPI'**
  String get depiAbbr;

  /// No description provided for @depiDesc.
  ///
  /// In en, this message translates to:
  /// **'Depreciation'**
  String get depiDesc;

  /// No description provided for @sgaiAbbr.
  ///
  /// In en, this message translates to:
  /// **'SGAI'**
  String get sgaiAbbr;

  /// No description provided for @sgaiDesc.
  ///
  /// In en, this message translates to:
  /// **'SG&A Expenses'**
  String get sgaiDesc;

  /// No description provided for @tataAbbr.
  ///
  /// In en, this message translates to:
  /// **'TATA'**
  String get tataAbbr;

  /// No description provided for @tataDesc.
  ///
  /// In en, this message translates to:
  /// **'Accruals'**
  String get tataDesc;

  /// No description provided for @lvgiAbbr.
  ///
  /// In en, this message translates to:
  /// **'LVGI'**
  String get lvgiAbbr;

  /// No description provided for @lvgiDesc.
  ///
  /// In en, this message translates to:
  /// **'Leverage'**
  String get lvgiDesc;

  /// No description provided for @redFlagsCount.
  ///
  /// In en, this message translates to:
  /// **'Red Flags ({count})'**
  String redFlagsCount(int count);

  /// No description provided for @whatIsBeneishMScore.
  ///
  /// In en, this message translates to:
  /// **'What is the Beneish M-Score?'**
  String get whatIsBeneishMScore;

  /// No description provided for @beneishDescription.
  ///
  /// In en, this message translates to:
  /// **'The M-Score is a mathematical model that uses 8 financial ratios to identify whether a company has manipulated its earnings. Developed by Professor Messod Beneish, it is widely used by auditors, investors, and analysts.'**
  String get beneishDescription;

  /// No description provided for @beneishFormula.
  ///
  /// In en, this message translates to:
  /// **'M = -4.84 + 0.92×DSRI + 0.528×GMI\n+ 0.404×AQI + 0.892×SGI\n+ 0.115×DEPI - 0.172×SGAI\n+ 4.679×TATA - 0.327×LVGI'**
  String get beneishFormula;

  /// No description provided for @indexExplanationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Index Explanations'**
  String get indexExplanationsTitle;

  /// No description provided for @dsriFullName.
  ///
  /// In en, this message translates to:
  /// **'Days Sales in Receivables Index'**
  String get dsriFullName;

  /// No description provided for @dsriExplanation.
  ///
  /// In en, this message translates to:
  /// **'Measures if receivables grew faster than sales'**
  String get dsriExplanation;

  /// No description provided for @gmiFullName.
  ///
  /// In en, this message translates to:
  /// **'Gross Margin Index'**
  String get gmiFullName;

  /// No description provided for @gmiExplanation.
  ///
  /// In en, this message translates to:
  /// **'Detects deteriorating gross margins'**
  String get gmiExplanation;

  /// No description provided for @aqiFullName.
  ///
  /// In en, this message translates to:
  /// **'Asset Quality Index'**
  String get aqiFullName;

  /// No description provided for @aqiExplanation.
  ///
  /// In en, this message translates to:
  /// **'Identifies expense capitalization'**
  String get aqiExplanation;

  /// No description provided for @sgiFullName.
  ///
  /// In en, this message translates to:
  /// **'Sales Growth Index'**
  String get sgiFullName;

  /// No description provided for @sgiExplanation.
  ///
  /// In en, this message translates to:
  /// **'High growth creates manipulation pressure'**
  String get sgiExplanation;

  /// No description provided for @depiFullName.
  ///
  /// In en, this message translates to:
  /// **'Depreciation Index'**
  String get depiFullName;

  /// No description provided for @depiExplanation.
  ///
  /// In en, this message translates to:
  /// **'Detects slowing depreciation rates'**
  String get depiExplanation;

  /// No description provided for @sgaiFullName.
  ///
  /// In en, this message translates to:
  /// **'SG&A Index'**
  String get sgaiFullName;

  /// No description provided for @sgaiExplanation.
  ///
  /// In en, this message translates to:
  /// **'Measures administrative efficiency'**
  String get sgaiExplanation;

  /// No description provided for @tataFullName.
  ///
  /// In en, this message translates to:
  /// **'Total Accruals to Total Assets'**
  String get tataFullName;

  /// No description provided for @tataExplanation.
  ///
  /// In en, this message translates to:
  /// **'High accruals vs cash = low quality'**
  String get tataExplanation;

  /// No description provided for @lvgiFullName.
  ///
  /// In en, this message translates to:
  /// **'Leverage Index'**
  String get lvgiFullName;

  /// No description provided for @lvgiExplanation.
  ///
  /// In en, this message translates to:
  /// **'Increasing debt creates pressure'**
  String get lvgiExplanation;

  /// No description provided for @famousCasesTitle.
  ///
  /// In en, this message translates to:
  /// **'Famous Cases'**
  String get famousCasesTitle;

  /// No description provided for @famousCasesContent.
  ///
  /// In en, this message translates to:
  /// **'• Enron (2001): Would have had M-Score > -1.78\n• WorldCom (2002): Showed multiple red flags\n• Satyam (2009): DSRI and AQI were extreme\n• The model correctly identifies ~76% of manipulators'**
  String get famousCasesContent;

  /// No description provided for @yearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year {number}'**
  String yearLabel(int number);

  /// No description provided for @pvOfCashFlows.
  ///
  /// In en, this message translates to:
  /// **'PV of Cash Flows: {value}'**
  String pvOfCashFlows(String value);

  /// No description provided for @initialInvestmentDetail.
  ///
  /// In en, this message translates to:
  /// **'Initial Investment: {value}'**
  String initialInvestmentDetail(String value);

  /// No description provided for @discountRateDetail.
  ///
  /// In en, this message translates to:
  /// **'Discount Rate: {value}'**
  String discountRateDetail(String value);

  /// No description provided for @convergedLabel.
  ///
  /// In en, this message translates to:
  /// **'Converged: {value}'**
  String convergedLabel(String value);

  /// No description provided for @iterationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Iterations: {value}'**
  String iterationsLabel(int value);

  /// No description provided for @averageInvestment.
  ///
  /// In en, this message translates to:
  /// **'Average Investment: {value}'**
  String averageInvestment(String value);

  /// No description provided for @acceptLabel.
  ///
  /// In en, this message translates to:
  /// **'ACCEPT'**
  String get acceptLabel;

  /// No description provided for @rejectLabel.
  ///
  /// In en, this message translates to:
  /// **'REJECT'**
  String get rejectLabel;

  /// No description provided for @recommendationLabel.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDATION: {value}'**
  String recommendationLabel(String value);

  /// No description provided for @criteriaMetLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} of 4 criteria met'**
  String criteriaMetLabel(int count);

  /// No description provided for @npvSensitivityDesc.
  ///
  /// In en, this message translates to:
  /// **'Shows how NPV changes as the discount rate varies'**
  String get npvSensitivityDesc;

  /// No description provided for @irrApproxLabel.
  ///
  /// In en, this message translates to:
  /// **'The IRR (where NPV = 0) is approximately {min}% - {max}%'**
  String irrApproxLabel(String min, String max);

  /// No description provided for @revenueSection.
  ///
  /// In en, this message translates to:
  /// **'REVENUE'**
  String get revenueSection;

  /// No description provided for @expensesSection.
  ///
  /// In en, this message translates to:
  /// **'EXPENSES'**
  String get expensesSection;

  /// No description provided for @formulasDescription.
  ///
  /// In en, this message translates to:
  /// **'• Static Budget = Fixed + (Variable × Planned Activity)\n• Flexible Budget = Fixed + (Variable × Actual Activity)\n• Volume Variance = Flexible Budget - Static Budget\n• Spending Variance = Actual Cost - Flexible Budget'**
  String get formulasDescription;

  /// No description provided for @addExchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Add Exchange Rate'**
  String get addExchangeRate;

  /// No description provided for @fromCurrency.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromCurrency;

  /// No description provided for @toCurrency.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toCurrency;

  /// No description provided for @pleaseEnterCurrency.
  ///
  /// In en, this message translates to:
  /// **'Please select currency'**
  String get pleaseEnterCurrency;

  /// No description provided for @exchangeRateHelper.
  ///
  /// In en, this message translates to:
  /// **'1 From = X To'**
  String get exchangeRateHelper;

  /// No description provided for @pleaseEnterValidRate.
  ///
  /// In en, this message translates to:
  /// **'Valid rate required'**
  String get pleaseEnterValidRate;

  /// No description provided for @accountCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get accountCurrency;

  /// No description provided for @initialBalances.
  ///
  /// In en, this message translates to:
  /// **'Initial Balances'**
  String get initialBalances;

  /// No description provided for @debitBalance.
  ///
  /// In en, this message translates to:
  /// **'Debit Balance'**
  String get debitBalance;

  /// No description provided for @creditBalance.
  ///
  /// In en, this message translates to:
  /// **'Credit Balance'**
  String get creditBalance;

  /// No description provided for @netBalance.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get netBalance;

  /// No description provided for @exchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates'**
  String get exchangeRates;

  /// No description provided for @noExchangeRates.
  ///
  /// In en, this message translates to:
  /// **'No rates added'**
  String get noExchangeRates;

  /// No description provided for @saveAccount.
  ///
  /// In en, this message translates to:
  /// **'Save Account'**
  String get saveAccount;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get alreadyHaveAccount;

  /// No description provided for @needAccount.
  ///
  /// In en, this message translates to:
  /// **'Need an account? Sign Up'**
  String get needAccount;

  /// No description provided for @enterEmailAndPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter both email and password.'**
  String get enterEmailAndPassword;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up to create your business'**
  String get signUpSubtitle;

  /// No description provided for @orSeparator.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orSeparator;

  /// No description provided for @paidFeatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Paid Feature'**
  String get paidFeatureTitle;

  /// No description provided for @paidFeatureMessage.
  ///
  /// In en, this message translates to:
  /// **'This feature requires an active subscription and account login. Please sign in and subscribe to access staff and roles management.'**
  String get paidFeatureMessage;

  /// No description provided for @signInToAccess.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInToAccess;

  /// No description provided for @nameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameIsRequired;

  /// No description provided for @permissionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionsLabel;

  /// No description provided for @permViewDashboard.
  ///
  /// In en, this message translates to:
  /// **'View Dashboard'**
  String get permViewDashboard;

  /// No description provided for @permViewFinancialReports.
  ///
  /// In en, this message translates to:
  /// **'View Financial Reports'**
  String get permViewFinancialReports;

  /// No description provided for @permPerformSale.
  ///
  /// In en, this message translates to:
  /// **'Perform Sales (POS)'**
  String get permPerformSale;

  /// No description provided for @permVoidTransaction.
  ///
  /// In en, this message translates to:
  /// **'Void/Delete Transactions'**
  String get permVoidTransaction;

  /// No description provided for @permProcessRefund.
  ///
  /// In en, this message translates to:
  /// **'Process Refunds'**
  String get permProcessRefund;

  /// No description provided for @permViewSalesHistory.
  ///
  /// In en, this message translates to:
  /// **'View Sales History'**
  String get permViewSalesHistory;

  /// No description provided for @permViewInventory.
  ///
  /// In en, this message translates to:
  /// **'View Inventory'**
  String get permViewInventory;

  /// No description provided for @permManageProducts.
  ///
  /// In en, this message translates to:
  /// **'Add/Edit Products'**
  String get permManageProducts;

  /// No description provided for @permAdjustInventory.
  ///
  /// In en, this message translates to:
  /// **'Stock Adjustments'**
  String get permAdjustInventory;

  /// No description provided for @permManageStaff.
  ///
  /// In en, this message translates to:
  /// **'Manage Staff & Roles'**
  String get permManageStaff;

  /// No description provided for @permManageSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get permManageSettings;

  /// No description provided for @permSwitchTenant.
  ///
  /// In en, this message translates to:
  /// **'Switch Business Branch'**
  String get permSwitchTenant;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @availablePlans.
  ///
  /// In en, this message translates to:
  /// **'Available Plans'**
  String get availablePlans;

  /// No description provided for @enterpriseMonthlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Enterprise (Monthly)'**
  String get enterpriseMonthlyPlan;

  /// No description provided for @enterpriseMonthlyPrice.
  ///
  /// In en, this message translates to:
  /// **'\$30 / month'**
  String get enterpriseMonthlyPrice;

  /// No description provided for @freeTierPlan.
  ///
  /// In en, this message translates to:
  /// **'Free Tier'**
  String get freeTierPlan;

  /// No description provided for @freeTierPrice.
  ///
  /// In en, this message translates to:
  /// **'\$0 / forever'**
  String get freeTierPrice;

  /// No description provided for @featureCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get featureCloudSync;

  /// No description provided for @featureMultiUser.
  ///
  /// In en, this message translates to:
  /// **'Multi-User'**
  String get featureMultiUser;

  /// No description provided for @featureWebAccess.
  ///
  /// In en, this message translates to:
  /// **'Web Access'**
  String get featureWebAccess;

  /// No description provided for @featureLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Local Only'**
  String get featureLocalOnly;

  /// No description provided for @featureManualBackup.
  ///
  /// In en, this message translates to:
  /// **'Manual Backup'**
  String get featureManualBackup;

  /// No description provided for @currentPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'CURRENT PLAN'**
  String get currentPlanLabel;

  /// No description provided for @planStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String planStatusLabel(String status);

  /// No description provided for @planRenewsLabel.
  ///
  /// In en, this message translates to:
  /// **'Renews: {date}'**
  String planRenewsLabel(String date);

  /// No description provided for @planNeverExpires.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get planNeverExpires;

  /// No description provided for @buyButton.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buyButton;

  /// No description provided for @subscriptionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions are not available while offline. Please sign in to manage your subscription.'**
  String get subscriptionUnavailable;

  /// No description provided for @confirmMockPurchase.
  ///
  /// In en, this message translates to:
  /// **'Confirm Purchase'**
  String get confirmMockPurchase;

  /// No description provided for @simulatePaymentFor.
  ///
  /// In en, this message translates to:
  /// **'Simulate payment for {planName}?'**
  String simulatePaymentFor(String planName);

  /// No description provided for @payNowMock.
  ///
  /// In en, this message translates to:
  /// **'Pay Now (Demo)'**
  String get payNowMock;

  /// No description provided for @mockPaymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Demo Payment Successful!'**
  String get mockPaymentSuccess;

  /// No description provided for @noStaffFound.
  ///
  /// In en, this message translates to:
  /// **'No staff found. Invite someone!'**
  String get noStaffFound;

  /// No description provided for @ownerRole.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerRole;

  /// No description provided for @staffRoleAndEmail.
  ///
  /// In en, this message translates to:
  /// **'Role: {roleId} • {email}'**
  String staffRoleAndEmail(String roleId, String email);

  /// No description provided for @removeStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeStaffTitle(String name);

  /// No description provided for @removeStaffWarning.
  ///
  /// In en, this message translates to:
  /// **'They will lose access to this business immediately.'**
  String get removeStaffWarning;

  /// No description provided for @inviteStaff.
  ///
  /// In en, this message translates to:
  /// **'Invite Staff'**
  String get inviteStaff;

  /// No description provided for @stepSelectRole.
  ///
  /// In en, this message translates to:
  /// **'1. Select a Role'**
  String get stepSelectRole;

  /// No description provided for @chooseRoleHint.
  ///
  /// In en, this message translates to:
  /// **'Choose Role (e.g. Cashier)'**
  String get chooseRoleHint;

  /// No description provided for @errorLoadingRoles.
  ///
  /// In en, this message translates to:
  /// **'Error loading roles: {error}'**
  String errorLoadingRoles(String error);

  /// No description provided for @generateInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Generate Invite Code'**
  String get generateInviteCode;

  /// No description provided for @stepShareCode.
  ///
  /// In en, this message translates to:
  /// **'2. Share Code'**
  String get stepShareCode;

  /// No description provided for @validFor24Hours.
  ///
  /// In en, this message translates to:
  /// **'Valid for 24 hours'**
  String get validFor24Hours;

  /// No description provided for @shareViaApp.
  ///
  /// In en, this message translates to:
  /// **'Share via WhatsApp / Telegram'**
  String get shareViaApp;

  /// No description provided for @inviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Join my business on Mizan!\n\n1. Download the App\n2. Sign In\n3. Select \'Join Business\' and enter code: {code}\n\n(Valid for 24 hours)'**
  String inviteShareText(String code);

  /// No description provided for @validInviteCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Valid Invite Code!'**
  String get validInviteCodeTitle;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role: {roleId}'**
  String roleLabel(String roleId);

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @orText.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orText;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Mizan App v{version}'**
  String appVersion(String version);

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @redFlags.
  ///
  /// In en, this message translates to:
  /// **'Red Flags'**
  String get redFlags;

  /// No description provided for @dsriDescription.
  ///
  /// In en, this message translates to:
  /// **'Receivables/Sales'**
  String get dsriDescription;

  /// No description provided for @gmiDescription.
  ///
  /// In en, this message translates to:
  /// **'Gross Margin'**
  String get gmiDescription;

  /// No description provided for @aqiDescription.
  ///
  /// In en, this message translates to:
  /// **'Asset Quality'**
  String get aqiDescription;

  /// No description provided for @sgiDescription.
  ///
  /// In en, this message translates to:
  /// **'Sales Growth'**
  String get sgiDescription;

  /// No description provided for @depiDescription.
  ///
  /// In en, this message translates to:
  /// **'Depreciation'**
  String get depiDescription;

  /// No description provided for @sgaiDescription.
  ///
  /// In en, this message translates to:
  /// **'SG&A Expenses'**
  String get sgaiDescription;

  /// No description provided for @tataDescription.
  ///
  /// In en, this message translates to:
  /// **'Accruals'**
  String get tataDescription;

  /// No description provided for @lvgiDescription.
  ///
  /// In en, this message translates to:
  /// **'Leverage'**
  String get lvgiDescription;

  /// No description provided for @whatIsMScore.
  ///
  /// In en, this message translates to:
  /// **'What is the Beneish M-Score?'**
  String get whatIsMScore;

  /// No description provided for @mScoreDescription.
  ///
  /// In en, this message translates to:
  /// **'The M-Score is a mathematical model created by Professor Messod Beneish that uses financial ratios to detect whether a company has manipulated its earnings.\n\nAn M-Score greater than -1.78 suggests a HIGH probability (76%) that the company is an earnings manipulator.'**
  String get mScoreDescription;

  /// No description provided for @dsriName.
  ///
  /// In en, this message translates to:
  /// **'Days Sales in Receivables Index'**
  String get dsriName;

  /// No description provided for @dsriExpl.
  ///
  /// In en, this message translates to:
  /// **'Measures if receivables grew faster than sales'**
  String get dsriExpl;

  /// No description provided for @gmiName.
  ///
  /// In en, this message translates to:
  /// **'Gross Margin Index'**
  String get gmiName;

  /// No description provided for @gmiExpl.
  ///
  /// In en, this message translates to:
  /// **'Detects deteriorating gross margins'**
  String get gmiExpl;

  /// No description provided for @aqiName.
  ///
  /// In en, this message translates to:
  /// **'Asset Quality Index'**
  String get aqiName;

  /// No description provided for @aqiExpl.
  ///
  /// In en, this message translates to:
  /// **'Identifies expense capitalization'**
  String get aqiExpl;

  /// No description provided for @sgiName.
  ///
  /// In en, this message translates to:
  /// **'Sales Growth Index'**
  String get sgiName;

  /// No description provided for @sgiExpl.
  ///
  /// In en, this message translates to:
  /// **'High growth creates manipulation pressure'**
  String get sgiExpl;

  /// No description provided for @depiName.
  ///
  /// In en, this message translates to:
  /// **'Depreciation Index'**
  String get depiName;

  /// No description provided for @depiExpl.
  ///
  /// In en, this message translates to:
  /// **'Detects slowing depreciation rates'**
  String get depiExpl;

  /// No description provided for @sgaiName.
  ///
  /// In en, this message translates to:
  /// **'SG&A Index'**
  String get sgaiName;

  /// No description provided for @sgaiExpl.
  ///
  /// In en, this message translates to:
  /// **'Measures administrative efficiency'**
  String get sgaiExpl;

  /// No description provided for @tataName.
  ///
  /// In en, this message translates to:
  /// **'Total Accruals to Total Assets'**
  String get tataName;

  /// No description provided for @tataExpl.
  ///
  /// In en, this message translates to:
  /// **'High accruals vs cash = low quality'**
  String get tataExpl;

  /// No description provided for @lvgiName.
  ///
  /// In en, this message translates to:
  /// **'Leverage Index'**
  String get lvgiName;

  /// No description provided for @lvgiExpl.
  ///
  /// In en, this message translates to:
  /// **'Increasing debt creates pressure'**
  String get lvgiExpl;

  /// No description provided for @famousCasesDesc.
  ///
  /// In en, this message translates to:
  /// **'• Enron (2001): Would have had M-Score > -1.78\n• WorldCom (2002): High TATA due to expense capitalization\n• Satyam (2009): High DSRI from fictitious receivables\n\nThe M-Score correctly identified 76% of manipulators in backtesting studies.'**
  String get famousCasesDesc;

  /// No description provided for @mScoreThresholdLabel.
  ///
  /// In en, this message translates to:
  /// **'Threshold: > -1.78 indicates manipulation'**
  String get mScoreThresholdLabel;

  /// No description provided for @riskLevelHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get riskLevelHigh;

  /// No description provided for @riskLevelModerate.
  ///
  /// In en, this message translates to:
  /// **'MODERATE'**
  String get riskLevelModerate;

  /// No description provided for @riskLevelLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get riskLevelLow;

  /// No description provided for @unitsLowercase.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get unitsLowercase;

  /// No description provided for @flexibleBudgetResult.
  ///
  /// In en, this message translates to:
  /// **'Flexible Budget'**
  String get flexibleBudgetResult;

  /// No description provided for @varianceFormulas.
  ///
  /// In en, this message translates to:
  /// **'• Static Budget = Fixed + (Variable × Planned Activity)\n• Flexible Budget = Fixed + (Variable × Actual Activity)\n• Volume Variance = Flexible - Static\n• Spending Variance = Actual - Flexible'**
  String get varianceFormulas;

  /// No description provided for @materialQtyPerUnit.
  ///
  /// In en, this message translates to:
  /// **'Material Qty/Unit'**
  String get materialQtyPerUnit;

  /// No description provided for @laborHoursPerUnit.
  ///
  /// In en, this message translates to:
  /// **'Labor Hours/Unit'**
  String get laborHoursPerUnit;

  /// No description provided for @perHrSuffix.
  ///
  /// In en, this message translates to:
  /// **'\$/hr'**
  String get perHrSuffix;

  /// No description provided for @totalVarianceValue.
  ///
  /// In en, this message translates to:
  /// **'Total Variance: {amount}'**
  String totalVarianceValue(String amount);

  /// No description provided for @actualCostResult.
  ///
  /// In en, this message translates to:
  /// **'Actual Cost'**
  String get actualCostResult;

  /// No description provided for @priceVarianceResult.
  ///
  /// In en, this message translates to:
  /// **'Price Variance'**
  String get priceVarianceResult;

  /// No description provided for @quantityVarianceResult.
  ///
  /// In en, this message translates to:
  /// **'Quantity Variance'**
  String get quantityVarianceResult;

  /// No description provided for @materialsFormulasTitle.
  ///
  /// In en, this message translates to:
  /// **'Materials Formulas'**
  String get materialsFormulasTitle;

  /// No description provided for @materialsFormulasDesc.
  ///
  /// In en, this message translates to:
  /// **'• Price Variance = (Actual Price - Standard Price) × Actual Qty\n• Quantity Variance = (Actual Qty - Standard Qty) × Standard Price'**
  String get materialsFormulasDesc;

  /// No description provided for @rateVarianceResult.
  ///
  /// In en, this message translates to:
  /// **'Rate Variance'**
  String get rateVarianceResult;

  /// No description provided for @efficiencyVarianceResult.
  ///
  /// In en, this message translates to:
  /// **'Efficiency Variance'**
  String get efficiencyVarianceResult;

  /// No description provided for @laborFormulasTitle.
  ///
  /// In en, this message translates to:
  /// **'Labor Formulas'**
  String get laborFormulasTitle;

  /// No description provided for @laborFormulasDesc.
  ///
  /// In en, this message translates to:
  /// **'• Rate Variance = (Actual Rate - Standard Rate) × Actual Hours\n• Efficiency Variance = (Actual Hours - Std Hours) × Std Rate'**
  String get laborFormulasDesc;

  /// No description provided for @currentRatioTitle.
  ///
  /// In en, this message translates to:
  /// **'Current Ratio'**
  String get currentRatioTitle;

  /// No description provided for @debtEquityTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt/Equity'**
  String get debtEquityTitle;

  /// No description provided for @netMarginTitle.
  ///
  /// In en, this message translates to:
  /// **'Net Margin'**
  String get netMarginTitle;

  /// No description provided for @roaTitle.
  ///
  /// In en, this message translates to:
  /// **'ROA'**
  String get roaTitle;

  /// No description provided for @ratioCol.
  ///
  /// In en, this message translates to:
  /// **'Ratio'**
  String get ratioCol;

  /// No description provided for @valueCol.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get valueCol;

  /// No description provided for @benchmarkCol.
  ///
  /// In en, this message translates to:
  /// **'Benchmark'**
  String get benchmarkCol;

  /// No description provided for @statusCol.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusCol;

  /// No description provided for @descriptionCol.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionCol;

  /// No description provided for @totalVarianceLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Variance'**
  String get totalVarianceLabel;

  /// No description provided for @enterpriseLicenseActive.
  ///
  /// In en, this message translates to:
  /// **'Enterprise License Active'**
  String get enterpriseLicenseActive;

  /// No description provided for @systemAdministrator.
  ///
  /// In en, this message translates to:
  /// **'You are the System Administrator'**
  String get systemAdministrator;

  /// No description provided for @defineStaffPermissions.
  ///
  /// In en, this message translates to:
  /// **'Define staff permissions'**
  String get defineStaffPermissions;

  /// No description provided for @viewPlansBilling.
  ///
  /// In en, this message translates to:
  /// **'View plans & billing'**
  String get viewPlansBilling;

  /// No description provided for @manageStaff.
  ///
  /// In en, this message translates to:
  /// **'Manage Staff'**
  String get manageStaff;

  /// No description provided for @viewListInviteMembers.
  ///
  /// In en, this message translates to:
  /// **'View list & invite members'**
  String get viewListInviteMembers;

  /// No description provided for @activateBusinessLicense.
  ///
  /// In en, this message translates to:
  /// **'Activate Business License'**
  String get activateBusinessLicense;

  /// No description provided for @initializeSystemClaimOwnership.
  ///
  /// In en, this message translates to:
  /// **'Initialize system & claim ownership'**
  String get initializeSystemClaimOwnership;

  /// No description provided for @notLoggedInWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ You are not logged in! Please Sign In first.'**
  String get notLoggedInWarning;

  /// No description provided for @systemActivatedWelcome.
  ///
  /// In en, this message translates to:
  /// **'✅ System Activated! Welcome, Admin.'**
  String get systemActivatedWelcome;

  /// No description provided for @activationFailed.
  ///
  /// In en, this message translates to:
  /// **'❌ Activation Failed: {error}'**
  String activationFailed(String error);

  /// No description provided for @premiumReportWarning.
  ///
  /// In en, this message translates to:
  /// **'🔒 Premium Report. Upgrade to Pro or Enterprise.'**
  String get premiumReportWarning;

  /// No description provided for @buyReportPrompt.
  ///
  /// In en, this message translates to:
  /// **'Buy \'\'{reportTitle}\'\' for \$4.99?'**
  String buyReportPrompt(String reportTitle);

  /// No description provided for @buyNowAction.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNowAction;

  /// No description provided for @installedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'✅ Installed {reportTitle}'**
  String installedSuccessfully(String reportTitle);

  /// No description provided for @noStandardReportsFound.
  ///
  /// In en, this message translates to:
  /// **'No standard reports found online.'**
  String get noStandardReportsFound;

  /// No description provided for @installAction.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get installAction;

  /// No description provided for @includedAction.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get includedAction;

  /// No description provided for @buyPriceAction.
  ///
  /// In en, this message translates to:
  /// **'Buy \$4.99'**
  String get buyPriceAction;

  /// No description provided for @lockedAction.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockedAction;

  /// No description provided for @retailBusinessTemplate.
  ///
  /// In en, this message translates to:
  /// **'Retail Business'**
  String get retailBusinessTemplate;

  /// No description provided for @serviceBusinessTemplate.
  ///
  /// In en, this message translates to:
  /// **'Service Business'**
  String get serviceBusinessTemplate;

  /// No description provided for @customersAr.
  ///
  /// In en, this message translates to:
  /// **'Customers (AR)'**
  String get customersAr;

  /// No description provided for @vendorsAp.
  ///
  /// In en, this message translates to:
  /// **'Vendors (AP)'**
  String get vendorsAp;

  /// No description provided for @openingBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance (Owes You). Input 0 if no balance.'**
  String get openingBalanceHint;

  /// No description provided for @openingBalanceHintVendor.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance (You Owe). Input 0 if no balance.'**
  String get openingBalanceHintVendor;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (Optional)'**
  String get emailOptional;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (Optional)'**
  String get phoneOptional;

  /// No description provided for @addressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (Optional)'**
  String get addressOptional;

  /// No description provided for @taxIdOptional.
  ///
  /// In en, this message translates to:
  /// **'Tax ID / VAT Number (Optional)'**
  String get taxIdOptional;

  /// No description provided for @paymentTermsOptional.
  ///
  /// In en, this message translates to:
  /// **'Payment Terms (Optional)'**
  String get paymentTermsOptional;

  /// No description provided for @creditLimitOptional.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit (Optional)'**
  String get creditLimitOptional;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// No description provided for @searchCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search Customers...'**
  String get searchCustomers;

  /// No description provided for @searchVendors.
  ///
  /// In en, this message translates to:
  /// **'Search Vendors...'**
  String get searchVendors;

  /// No description provided for @customerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customerDetails;

  /// No description provided for @vendorDetails.
  ///
  /// In en, this message translates to:
  /// **'Vendor Details'**
  String get vendorDetails;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInfo;

  /// No description provided for @noAddressProvided.
  ///
  /// In en, this message translates to:
  /// **'No address provided'**
  String get noAddressProvided;

  /// No description provided for @noEmailProvided.
  ///
  /// In en, this message translates to:
  /// **'No email provided'**
  String get noEmailProvided;

  /// No description provided for @noPhoneProvided.
  ///
  /// In en, this message translates to:
  /// **'No phone provided'**
  String get noPhoneProvided;

  /// No description provided for @noTaxIdProvided.
  ///
  /// In en, this message translates to:
  /// **'No Tax ID provided'**
  String get noTaxIdProvided;

  /// No description provided for @noNotesProvided.
  ///
  /// In en, this message translates to:
  /// **'No notes provided'**
  String get noNotesProvided;

  /// No description provided for @noPaymentTermsProvided.
  ///
  /// In en, this message translates to:
  /// **'No payment terms provided'**
  String get noPaymentTermsProvided;

  /// No description provided for @financialOverview.
  ///
  /// In en, this message translates to:
  /// **'Financial Overview'**
  String get financialOverview;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @totalInvoiced.
  ///
  /// In en, this message translates to:
  /// **'Total Invoiced'**
  String get totalInvoiced;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get totalPaid;

  /// No description provided for @recentInvoices.
  ///
  /// In en, this message translates to:
  /// **'Recent Invoices'**
  String get recentInvoices;

  /// No description provided for @recentBills.
  ///
  /// In en, this message translates to:
  /// **'Recent Bills'**
  String get recentBills;

  /// No description provided for @noRecentInvoices.
  ///
  /// In en, this message translates to:
  /// **'No recent invoices.'**
  String get noRecentInvoices;

  /// No description provided for @noRecentBills.
  ///
  /// In en, this message translates to:
  /// **'No recent bills.'**
  String get noRecentBills;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @receivePayment.
  ///
  /// In en, this message translates to:
  /// **'Receive Payment'**
  String get receivePayment;

  /// No description provided for @statement.
  ///
  /// In en, this message translates to:
  /// **'Statement'**
  String get statement;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @partiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially Paid'**
  String get partiallyPaid;

  /// No description provided for @vendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendor;

  /// No description provided for @addFirstCustomer.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to add your first customer'**
  String get addFirstCustomer;

  /// No description provided for @noCustomersMatch.
  ///
  /// In en, this message translates to:
  /// **'No customers match your search.'**
  String get noCustomersMatch;

  /// No description provided for @customerBalances.
  ///
  /// In en, this message translates to:
  /// **'Customer Balances'**
  String get customerBalances;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @addFirstVendor.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to add your first vendor'**
  String get addFirstVendor;

  /// No description provided for @noVendorsMatch.
  ///
  /// In en, this message translates to:
  /// **'No vendors match your search.'**
  String get noVendorsMatch;

  /// No description provided for @vendorBalances.
  ///
  /// In en, this message translates to:
  /// **'Vendor Balances'**
  String get vendorBalances;

  /// No description provided for @outstandingBalance.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Balance'**
  String get outstandingBalance;

  /// No description provided for @quickLedgerAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Quick Ledger Adjustment'**
  String get quickLedgerAdjustment;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creating;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @pleaseAddLineItemBill.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one line item with an amount.'**
  String get pleaseAddLineItemBill;

  /// No description provided for @vendorInvoiceNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Vendor Invoice # (Optional)'**
  String get vendorInvoiceNumberOptional;

  /// No description provided for @current0To30.
  ///
  /// In en, this message translates to:
  /// **'Current\n(0-30)'**
  String get current0To30;

  /// No description provided for @days31To60.
  ///
  /// In en, this message translates to:
  /// **'31-60\nDays'**
  String get days31To60;

  /// No description provided for @days61To90.
  ///
  /// In en, this message translates to:
  /// **'61-90\nDays'**
  String get days61To90;

  /// No description provided for @days90Plus.
  ///
  /// In en, this message translates to:
  /// **'90+\nDays'**
  String get days90Plus;

  /// No description provided for @days31To60Short.
  ///
  /// In en, this message translates to:
  /// **'31-60'**
  String get days31To60Short;

  /// No description provided for @days61To90Short.
  ///
  /// In en, this message translates to:
  /// **'61-90'**
  String get days61To90Short;

  /// No description provided for @days90PlusShort.
  ///
  /// In en, this message translates to:
  /// **'90+'**
  String get days90PlusShort;

  /// No description provided for @adjustBalance.
  ///
  /// In en, this message translates to:
  /// **'Adjust Balance: {name}'**
  String adjustBalance(String name);

  /// No description provided for @charge.
  ///
  /// In en, this message translates to:
  /// **'Charge (+)'**
  String get charge;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive (-)'**
  String get receive;

  /// No description provided for @increasesDebt.
  ///
  /// In en, this message translates to:
  /// **'Increases their debt to you'**
  String get increasesDebt;

  /// No description provided for @decreasesDebt.
  ///
  /// In en, this message translates to:
  /// **'Decreases their debt (routes to Cash)'**
  String get decreasesDebt;

  /// No description provided for @saveAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Save Adjustment'**
  String get saveAdjustment;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
