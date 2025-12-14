// FILE: packages/features/feature_reports/lib/src/presentation/budget_screen.dart
// Purpose: Budget creation and variance analysis dashboard
// Reference: Accounting Principles 13e (Weygandt), Chapters 23-24

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core_data/src/services/budgeting_service.dart';

/// Budget Screen - Create budgets and analyze variances
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data for demonstration (in production, this comes from database)
  final List<_MockBudgetLine> _budgetLines = [
    _MockBudgetLine(
      accountName: 'Sales Revenue',
      accountType: 'revenue',
      budgetedAmount: 50000000, // $500,000
      actualAmount: 55000000, // $550,000
    ),
    _MockBudgetLine(
      accountName: 'Service Revenue',
      accountType: 'revenue',
      budgetedAmount: 15000000, // $150,000
      actualAmount: 14000000, // $140,000
    ),
    _MockBudgetLine(
      accountName: 'Cost of Goods Sold',
      accountType: 'expense',
      budgetedAmount: 30000000, // $300,000
      actualAmount: 28500000, // $285,000
    ),
    _MockBudgetLine(
      accountName: 'Salaries Expense',
      accountType: 'expense',
      budgetedAmount: 12000000, // $120,000
      actualAmount: 12500000, // $125,000
    ),
    _MockBudgetLine(
      accountName: 'Rent Expense',
      accountType: 'expense',
      budgetedAmount: 3600000, // $36,000
      actualAmount: 3600000, // $36,000
    ),
    _MockBudgetLine(
      accountName: 'Utilities Expense',
      accountType: 'expense',
      budgetedAmount: 1200000, // $12,000
      actualAmount: 1400000, // $14,000
    ),
    _MockBudgetLine(
      accountName: 'Marketing Expense',
      accountType: 'expense',
      budgetedAmount: 5000000, // $50,000
      actualAmount: 4200000, // $42,000
    ),
  ];

  // Flexible budget inputs
  final _fixedCostController = TextEditingController(text: '100000');
  final _variableRateController = TextEditingController(text: '50');
  final _plannedActivityController = TextEditingController(text: '2000');
  final _actualActivityController = TextEditingController(text: '2200');
  final _actualCostController = TextEditingController(text: '230000');
  FlexibleBudgetResult? _flexibleBudgetResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calculateFlexibleBudget();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fixedCostController.dispose();
    _variableRateController.dispose();
    _plannedActivityController.dispose();
    _actualActivityController.dispose();
    _actualCostController.dispose();
    super.dispose();
  }

  void _calculateFlexibleBudget() {
    final fixedCost = _dollarsToCents(_fixedCostController.text);
    final variableRate = _dollarsToCents(_variableRateController.text);
    final plannedActivity = int.tryParse(_plannedActivityController.text) ?? 0;
    final actualActivity = int.tryParse(_actualActivityController.text) ?? 0;
    final actualCost = _dollarsToCents(_actualCostController.text);

    setState(() {
      _flexibleBudgetResult = BudgetingService.calculateFlexibleBudget(
        fixedPortion: fixedCost,
        variableRate: variableRate,
        plannedActivity: plannedActivity,
        actualActivity: actualActivity,
        actualAmount: actualCost,
      );
    });
  }

  int _dollarsToCents(String text) =>
      ((double.tryParse(text) ?? 0) * 100).round();

  String _formatCurrency(int cents) {
    final dollars = cents / 100;
    if (dollars >= 1000000) {
      return '\$${(dollars / 1000000).toStringAsFixed(2)}M';
    } else if (dollars >= 1000) {
      return '\$${(dollars / 1000).toStringAsFixed(1)}K';
    }
    return '\$${dollars.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget & Variance Analysis'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Summary', icon: Icon(Icons.dashboard)),
            Tab(text: 'Variances', icon: Icon(Icons.compare_arrows)),
            Tab(text: 'Flexible Budget', icon: Icon(Icons.tune)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(theme),
          _buildVariancesTab(theme),
          _buildFlexibleBudgetTab(theme),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(ThemeData theme) {
    // Calculate totals
    int totalBudgetedRevenue = 0;
    int totalActualRevenue = 0;
    int totalBudgetedExpenses = 0;
    int totalActualExpenses = 0;

    for (final line in _budgetLines) {
      if (line.accountType == 'revenue') {
        totalBudgetedRevenue += line.budgetedAmount;
        totalActualRevenue += line.actualAmount;
      } else {
        totalBudgetedExpenses += line.budgetedAmount;
        totalActualExpenses += line.actualAmount;
      }
    }

    final budgetedNetIncome = totalBudgetedRevenue - totalBudgetedExpenses;
    final actualNetIncome = totalActualRevenue - totalActualExpenses;
    final netIncomeVariance = actualNetIncome - budgetedNetIncome;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  theme,
                  title: 'Budgeted Net Income',
                  value: _formatCurrency(budgetedNetIncome),
                  icon: Icons.flag,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  theme,
                  title: 'Actual Net Income',
                  value: _formatCurrency(actualNetIncome),
                  icon: Icons.check_circle,
                  color: netIncomeVariance >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            theme,
            title: 'Net Income Variance',
            value:
                '${netIncomeVariance >= 0 ? '+' : ''}${_formatCurrency(netIncomeVariance)}',
            subtitle: netIncomeVariance >= 0
                ? 'Favorable - Above Budget!'
                : 'Unfavorable - Below Budget',
            icon: netIncomeVariance >= 0
                ? Icons.trending_up
                : Icons.trending_down,
            color: netIncomeVariance >= 0 ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 24),

          // Revenue Summary
          _buildCategoryCard(
            theme,
            title: 'Revenue',
            budgeted: totalBudgetedRevenue,
            actual: totalActualRevenue,
            isRevenue: true,
          ),
          const SizedBox(height: 12),

          // Expenses Summary
          _buildCategoryCard(
            theme,
            title: 'Expenses',
            budgeted: totalBudgetedExpenses,
            actual: totalActualExpenses,
            isRevenue: false,
          ),
        ],
      ),
    );
  }

  Widget _buildVariancesTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget vs Actual by Account',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Green = Favorable | Red = Unfavorable',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Revenue Section
          Text(
            'REVENUE',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ..._budgetLines
              .where((l) => l.accountType == 'revenue')
              .map((line) => _buildVarianceRow(theme, line)),

          const SizedBox(height: 24),

          // Expenses Section
          Text(
            'EXPENSES',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          ..._budgetLines
              .where((l) => l.accountType == 'expense')
              .map((line) => _buildVarianceRow(theme, line)),
        ],
      ),
    );
  }

  Widget _buildFlexibleBudgetTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Flexible Budget Analysis', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Separate volume variances from spending variances',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Input Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cost Structure', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fixedCostController,
                          decoration: const InputDecoration(
                            labelText: 'Fixed Costs',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => _calculateFlexibleBudget(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _variableRateController,
                          decoration: const InputDecoration(
                            labelText: 'Variable Rate/Unit',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => _calculateFlexibleBudget(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _plannedActivityController,
                          decoration: const InputDecoration(
                            labelText: 'Planned Activity',
                            suffixText: 'units',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => _calculateFlexibleBudget(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _actualActivityController,
                          decoration: const InputDecoration(
                            labelText: 'Actual Activity',
                            suffixText: 'units',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => _calculateFlexibleBudget(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _actualCostController,
                    decoration: const InputDecoration(
                      labelText: 'Actual Total Cost',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _calculateFlexibleBudget(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Results
          if (_flexibleBudgetResult != null) ...[
            // Budget Comparison
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Budget Comparison',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildComparisonRow(
                      'Static Budget',
                      _formatCurrency(_flexibleBudgetResult!.staticBudget),
                      theme.colorScheme.primary,
                    ),
                    _buildComparisonRow(
                      'Flexible Budget',
                      _formatCurrency(_flexibleBudgetResult!.flexibleBudget),
                      Colors.purple,
                    ),
                    _buildComparisonRow(
                      'Actual Cost',
                      _formatCurrency(_flexibleBudgetResult!.actualAmount),
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Variance Analysis
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Variance Analysis',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildVarianceAnalysisRow(
                      'Volume Variance',
                      _flexibleBudgetResult!.volumeVariance,
                      'Due to activity level difference',
                    ),
                    const SizedBox(height: 12),
                    _buildVarianceAnalysisRow(
                      'Spending Variance',
                      _flexibleBudgetResult!.spendingVariance,
                      'Due to efficiency/price',
                    ),
                    const Divider(height: 24),
                    _buildVarianceAnalysisRow(
                      'Total Variance',
                      _flexibleBudgetResult!.totalVariance,
                      'Actual - Static Budget',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Formula Card
            Card(
              color: theme.colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.functions,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Formulas Used',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Static Budget = Fixed + (Variable × Planned Activity)\n'
                      '• Flexible Budget = Fixed + (Variable × Actual Activity)\n'
                      '• Volume Variance = Flexible - Static\n'
                      '• Spending Variance = Actual - Flexible',
                      style: TextStyle(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper Widgets

  Widget _buildSummaryCard(
    ThemeData theme, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    ThemeData theme, {
    required String title,
    required int budgeted,
    required int actual,
    required bool isRevenue,
  }) {
    final variance = actual - budgeted;
    final isFavorable = isRevenue ? variance > 0 : variance < 0;
    final color = isFavorable ? Colors.green : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Budgeted', style: theme.textTheme.bodySmall),
                      Text(
                        _formatCurrency(budgeted),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Actual', style: theme.textTheme.bodySmall),
                      Text(
                        _formatCurrency(actual),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Variance', style: theme.textTheme.bodySmall),
                      Text(
                        '${variance >= 0 ? '+' : ''}${_formatCurrency(variance)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVarianceRow(ThemeData theme, _MockBudgetLine line) {
    final variance = BudgetingService.calculateVariance(
      accountId: '',
      accountName: line.accountName,
      accountType: line.accountType,
      budgetedAmount: line.budgetedAmount,
      actualAmount: line.actualAmount,
    );

    final color = variance.isFavorable ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                line.accountName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                _formatCurrency(line.budgetedAmount),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              child: Text(
                _formatCurrency(line.actualAmount),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              child: Text(
                '${variance.variance >= 0 ? '+' : ''}${_formatCurrency(variance.variance)}',
                textAlign: TextAlign.right,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              width: 40,
              child: Icon(
                variance.isFavorable
                    ? Icons.check_circle_outline
                    : Icons.warning_outlined,
                color: color,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVarianceAnalysisRow(
    String label,
    int amount,
    String description, {
    bool isTotal = false,
  }) {
    final isFavorable = amount < 0; // For costs, negative = good
    final color = amount == 0
        ? Colors.grey
        : isFavorable
        ? Colors.green
        : Colors.red;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 16 : 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${amount >= 0 ? '+' : ''}${_formatCurrency(amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: isTotal ? 18 : 14,
              ),
            ),
            Text(
              amount == 0
                  ? 'On Target'
                  : isFavorable
                  ? 'Favorable'
                  : 'Unfavorable',
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ],
    );
  }
}

// Mock data class for demonstration
class _MockBudgetLine {
  final String accountName;
  final String accountType;
  final int budgetedAmount;
  final int actualAmount;

  const _MockBudgetLine({
    required this.accountName,
    required this.accountType,
    required this.budgetedAmount,
    required this.actualAmount,
  });
}
