// FILE: packages/core/core_data/lib/src/account_templates.dart
// Purpose: Industry-standard Chart of Accounts templates

/// Standard account structure with hierarchy
class AccountTemplate {
  final int number;
  final String name;
  final String type;
  final int? parentNumber;
  final bool isHeader;
  final int level;

  const AccountTemplate({
    required this.number,
    required this.name,
    required this.type,
    this.parentNumber,
    this.isHeader = false,
    this.level = 0,
  });
}

/// Industry templates for Chart of Accounts
class ChartOfAccountsTemplates {
  /// Standard Retail Business template
  static const List<AccountTemplate> retailBusiness = [
    // === ASSETS (1000-1999) ===
    AccountTemplate(
      number: 1000,
      name: 'Assets',
      type: 'asset',
      isHeader: true,
      level: 0,
    ),
    AccountTemplate(
      number: 1100,
      name: 'Current Assets',
      type: 'asset',
      parentNumber: 1000,
      isHeader: true,
      level: 1,
    ),
    AccountTemplate(
      number: 1110,
      name: 'Cash',
      type: 'asset',
      parentNumber: 1100,
      level: 2,
    ),
    AccountTemplate(
      number: 1120,
      name: 'Petty Cash',
      type: 'asset',
      parentNumber: 1100,
      level: 2,
    ),
    AccountTemplate(
      number: 1130,
      name: 'Bank Account',
      type: 'asset',
      parentNumber: 1100,
      level: 2,
    ),
    AccountTemplate(
      number: 1140,
      name: 'Accounts Receivable',
      type: 'asset',
      parentNumber: 1100,
      level: 2,
    ),
    AccountTemplate(
      number: 1150,
      name: 'Inventory',
      type: 'asset',
      parentNumber: 1100,
      level: 2,
    ),
    AccountTemplate(
      number: 1160,
      name: 'Prepaid Expenses',
      type: 'asset',
      parentNumber: 1100,
      level: 2,
    ),
    AccountTemplate(
      number: 1200,
      name: 'Fixed Assets',
      type: 'asset',
      parentNumber: 1000,
      isHeader: true,
      level: 1,
    ),
    AccountTemplate(
      number: 1210,
      name: 'Furniture & Fixtures',
      type: 'asset',
      parentNumber: 1200,
      level: 2,
    ),
    AccountTemplate(
      number: 1220,
      name: 'Equipment',
      type: 'asset',
      parentNumber: 1200,
      level: 2,
    ),
    AccountTemplate(
      number: 1230,
      name: 'Vehicles',
      type: 'asset',
      parentNumber: 1200,
      level: 2,
    ),
    AccountTemplate(
      number: 1240,
      name: 'Buildings',
      type: 'asset',
      parentNumber: 1200,
      level: 2,
    ),
    AccountTemplate(
      number: 1250,
      name: 'Accumulated Depreciation',
      type: 'asset',
      parentNumber: 1200,
      level: 2,
    ),

    // === LIABILITIES (2000-2999) ===
    AccountTemplate(
      number: 2000,
      name: 'Liabilities',
      type: 'liability',
      isHeader: true,
      level: 0,
    ),
    AccountTemplate(
      number: 2100,
      name: 'Current Liabilities',
      type: 'liability',
      parentNumber: 2000,
      isHeader: true,
      level: 1,
    ),
    AccountTemplate(
      number: 2110,
      name: 'Accounts Payable',
      type: 'liability',
      parentNumber: 2100,
      level: 2,
    ),
    AccountTemplate(
      number: 2120,
      name: 'Accrued Expenses',
      type: 'liability',
      parentNumber: 2100,
      level: 2,
    ),
    AccountTemplate(
      number: 2130,
      name: 'Wages Payable',
      type: 'liability',
      parentNumber: 2100,
      level: 2,
    ),
    AccountTemplate(
      number: 2140,
      name: 'VAT/Sales Tax Payable',
      type: 'liability',
      parentNumber: 2100,
      level: 2,
    ),
    AccountTemplate(
      number: 2150,
      name: 'Unearned Revenue',
      type: 'liability',
      parentNumber: 2100,
      level: 2,
    ),
    AccountTemplate(
      number: 2200,
      name: 'Long-Term Liabilities',
      type: 'liability',
      parentNumber: 2000,
      isHeader: true,
      level: 1,
    ),
    AccountTemplate(
      number: 2210,
      name: 'Bank Loans',
      type: 'liability',
      parentNumber: 2200,
      level: 2,
    ),
    AccountTemplate(
      number: 2220,
      name: 'Notes Payable',
      type: 'liability',
      parentNumber: 2200,
      level: 2,
    ),

    // === EQUITY (3000-3999) ===
    AccountTemplate(
      number: 3000,
      name: 'Equity',
      type: 'equity',
      isHeader: true,
      level: 0,
    ),
    AccountTemplate(
      number: 3100,
      name: 'Owner\'s Capital',
      type: 'equity',
      parentNumber: 3000,
      level: 1,
    ),
    AccountTemplate(
      number: 3200,
      name: 'Retained Earnings',
      type: 'equity',
      parentNumber: 3000,
      level: 1,
    ),
    AccountTemplate(
      number: 3300,
      name: 'Owner\'s Drawings',
      type: 'equity',
      parentNumber: 3000,
      level: 1,
    ),

    // === REVENUE (4000-4999) ===
    AccountTemplate(
      number: 4000,
      name: 'Revenue',
      type: 'revenue',
      isHeader: true,
      level: 0,
    ),
    AccountTemplate(
      number: 4100,
      name: 'Sales Revenue',
      type: 'revenue',
      parentNumber: 4000,
      level: 1,
    ),
    AccountTemplate(
      number: 4200,
      name: 'Service Revenue',
      type: 'revenue',
      parentNumber: 4000,
      level: 1,
    ),
    AccountTemplate(
      number: 4300,
      name: 'Sales Discounts',
      type: 'revenue',
      parentNumber: 4000,
      level: 1,
    ),
    AccountTemplate(
      number: 4400,
      name: 'Sales Returns',
      type: 'revenue',
      parentNumber: 4000,
      level: 1,
    ),
    AccountTemplate(
      number: 4900,
      name: 'Other Income',
      type: 'revenue',
      parentNumber: 4000,
      level: 1,
    ),

    // === EXPENSES (5000-5999) ===
    AccountTemplate(
      number: 5000,
      name: 'Cost of Goods Sold',
      type: 'expense',
      isHeader: true,
      level: 0,
    ),
    AccountTemplate(
      number: 5100,
      name: 'Purchases',
      type: 'expense',
      parentNumber: 5000,
      level: 1,
    ),
    AccountTemplate(
      number: 5200,
      name: 'Freight In',
      type: 'expense',
      parentNumber: 5000,
      level: 1,
    ),
    AccountTemplate(
      number: 5300,
      name: 'Purchase Discounts',
      type: 'expense',
      parentNumber: 5000,
      level: 1,
    ),

    AccountTemplate(
      number: 6000,
      name: 'Operating Expenses',
      type: 'expense',
      isHeader: true,
      level: 0,
    ),
    AccountTemplate(
      number: 6100,
      name: 'Salaries & Wages',
      type: 'expense',
      parentNumber: 6000,
      level: 1,
    ),
    AccountTemplate(
      number: 6200,
      name: 'Rent Expense',
      type: 'expense',
      parentNumber: 6000,
      level: 1,
    ),
    AccountTemplate(
      number: 6300,
      name: 'Utilities',
      type: 'expense',
      parentNumber: 6000,
      level: 1,
    ),
    AccountTemplate(
      number: 6400,
      name: 'Insurance',
      type: 'expense',
      parentNumber: 6000,
      level: 1,
    ),
    AccountTemplate(
      number: 6500,
      name: 'Depreciation Expense',
      type: 'expense',
      parentNumber: 6000,
      level: 1,
    ),
    AccountTemplate(
      number: 6600,
      name: 'Office Supplies',
      type: 'expense',
      parentNumber: 6000,
      level: 1,
    ),
    AccountTemplate(
      number: 6700,
      name: 'Marketing & Advertising',
      type: 'expense',
      parentNumber: 6000,
      level: 1,
    ),
    AccountTemplate(
      number: 6800,
      name: 'Bank Charges',
      type: 'expense',
      parentNumber: 6000,
      level: 1,
    ),
    AccountTemplate(
      number: 6900,
      name: 'Miscellaneous Expense',
      type: 'expense',
      parentNumber: 6000,
      level: 1,
    ),
  ];

  /// Service Business template
  static const List<AccountTemplate> serviceBusiness = [
    // Assets
    AccountTemplate(
      number: 1000,
      name: 'Assets',
      type: 'asset',
      isHeader: true,
      level: 0,
    ),
    AccountTemplate(
      number: 1100,
      name: 'Cash',
      type: 'asset',
      parentNumber: 1000,
      level: 1,
    ),
    AccountTemplate(
      number: 1200,
      name: 'Bank Account',
      type: 'asset',
      parentNumber: 1000,
      level: 1,
    ),
    AccountTemplate(
      number: 1300,
      name: 'Accounts Receivable',
      type: 'asset',
      parentNumber: 1000,
      level: 1,
    ),
    AccountTemplate(
      number: 1400,
      name: 'Prepaid Expenses',
      type: 'asset',
      parentNumber: 1000,
      level: 1,
    ),
    AccountTemplate(
      number: 1500,
      name: 'Equipment',
      type: 'asset',
      parentNumber: 1000,
      level: 1,
    ),
    AccountTemplate(
      number: 1600,
      name: 'Accumulated Depreciation',
      type: 'asset',
      parentNumber: 1000,
      level: 1,
    ),

    // Liabilities
    AccountTemplate(
      number: 2000,
      name: 'Liabilities',
      type: 'liability',
      isHeader: true,
      level: 0,
    ),
    AccountTemplate(
      number: 2100,
      name: 'Accounts Payable',
      type: 'liability',
      parentNumber: 2000,
      level: 1,
    ),
    AccountTemplate(
      number: 2200,
      name: 'Accrued Expenses',
      type: 'liability',
      parentNumber: 2000,
      level: 1,
    ),
    AccountTemplate(
      number: 2300,
      name: 'Unearned Revenue',
      type: 'liability',
      parentNumber: 2000,
      level: 1,
    ),

    // Equity
    AccountTemplate(
      number: 3000,
      name: 'Equity',
      type: 'equity',
      isHeader: true,
      level: 0,
    ),
    AccountTemplate(
      number: 3100,
      name: 'Owner\'s Capital',
      type: 'equity',
      parentNumber: 3000,
      level: 1,
    ),
    AccountTemplate(
      number: 3200,
      name: 'Retained Earnings',
      type: 'equity',
      parentNumber: 3000,
      level: 1,
    ),

    // Revenue
    AccountTemplate(
      number: 4000,
      name: 'Revenue',
      type: 'revenue',
      isHeader: true,
      level: 0,
    ),
    AccountTemplate(
      number: 4100,
      name: 'Service Revenue',
      type: 'revenue',
      parentNumber: 4000,
      level: 1,
    ),
    AccountTemplate(
      number: 4200,
      name: 'Consulting Fees',
      type: 'revenue',
      parentNumber: 4000,
      level: 1,
    ),
    AccountTemplate(
      number: 4900,
      name: 'Other Income',
      type: 'revenue',
      parentNumber: 4000,
      level: 1,
    ),

    // Expenses
    AccountTemplate(
      number: 5000,
      name: 'Expenses',
      type: 'expense',
      isHeader: true,
      level: 0,
    ),
    AccountTemplate(
      number: 5100,
      name: 'Salaries & Wages',
      type: 'expense',
      parentNumber: 5000,
      level: 1,
    ),
    AccountTemplate(
      number: 5200,
      name: 'Rent Expense',
      type: 'expense',
      parentNumber: 5000,
      level: 1,
    ),
    AccountTemplate(
      number: 5300,
      name: 'Utilities',
      type: 'expense',
      parentNumber: 5000,
      level: 1,
    ),
    AccountTemplate(
      number: 5400,
      name: 'Office Supplies',
      type: 'expense',
      parentNumber: 5000,
      level: 1,
    ),
    AccountTemplate(
      number: 5500,
      name: 'Insurance',
      type: 'expense',
      parentNumber: 5000,
      level: 1,
    ),
    AccountTemplate(
      number: 5600,
      name: 'Professional Fees',
      type: 'expense',
      parentNumber: 5000,
      level: 1,
    ),
    AccountTemplate(
      number: 5700,
      name: 'Depreciation',
      type: 'expense',
      parentNumber: 5000,
      level: 1,
    ),
    AccountTemplate(
      number: 5800,
      name: 'Travel & Entertainment',
      type: 'expense',
      parentNumber: 5000,
      level: 1,
    ),
    AccountTemplate(
      number: 5900,
      name: 'Miscellaneous',
      type: 'expense',
      parentNumber: 5000,
      level: 1,
    ),
  ];

  /// Get all available template names
  static List<String> get templateNames => [
    'Retail Business',
    'Service Business',
  ];

  /// Get template by name
  static List<AccountTemplate> getTemplate(String name) {
    switch (name) {
      case 'Retail Business':
        return retailBusiness;
      case 'Service Business':
        return serviceBusiness;
      default:
        return retailBusiness;
    }
  }
}
