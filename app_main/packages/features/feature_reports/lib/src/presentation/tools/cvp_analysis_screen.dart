// FILE: packages/features/feature_reports/lib/src/presentation/tools/cvp_analysis_screen.dart
// Purpose: Cost-Volume-Profit Analysis interactive calculator
// Reference: Accounting Principles 13e (Weygandt), Chapter 22

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core_data/src/services/cvp_analysis_service.dart';

/// CVP Analysis Calculator Screen
class CVPAnalysisScreen extends StatefulWidget {
  const CVPAnalysisScreen({super.key});

  @override
  State<CVPAnalysisScreen> createState() => _CVPAnalysisScreenState();
}

class _CVPAnalysisScreenState extends State<CVPAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CVPAnalysisService _cvpService = CVPAnalysisService();

  // Input controllers (amounts in cents, display as dollars)
  final _fixedCostsController = TextEditingController(text: '100000');
  final _sellingPriceController = TextEditingController(text: '50');
  final _variableCostController = TextEditingController(text: '30');
  final _actualSalesController = TextEditingController(text: '300000');
  final _actualUnitsController = TextEditingController(text: '6000');
  final _targetProfitController = TextEditingController(text: '50000');

  // Results
  BreakEvenResult? _breakEvenResult;
  TargetProfitResult? _targetProfitResult;
  MarginOfSafetyResult? _mosResult;
  OperatingLeverageResult? _leverageResult;
  SensitivityAnalysisResult? _sensitivityResult;
  int? _projectedProfit;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _calculateAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fixedCostsController.dispose();
    _sellingPriceController.dispose();
    _variableCostController.dispose();
    _actualSalesController.dispose();
    _actualUnitsController.dispose();
    _targetProfitController.dispose();
    super.dispose();
  }

  // Convert dollars to cents for calculations
  int _dollarsToCents(String text) =>
      ((double.tryParse(text) ?? 0) * 100).round();

  // Format cents as dollars
  String _formatCurrency(int cents) {
    final dollars = cents / 100;
    if (dollars >= 1000000) {
      return '\$${(dollars / 1000000).toStringAsFixed(2)}M';
    } else if (dollars >= 1000) {
      return '\$${(dollars / 1000).toStringAsFixed(1)}K';
    }
    return '\$${dollars.toStringAsFixed(2)}';
  }

  void _calculateAll() {
    final fixedCosts = _dollarsToCents(_fixedCostsController.text);
    final sellingPrice = _dollarsToCents(_sellingPriceController.text);
    final variableCost = _dollarsToCents(_variableCostController.text);
    final actualSales = _dollarsToCents(_actualSalesController.text);
    final actualUnits = int.tryParse(_actualUnitsController.text) ?? 0;
    final targetProfit = _dollarsToCents(_targetProfitController.text);

    if (sellingPrice <= 0 || variableCost >= sellingPrice) {
      setState(() {
        _breakEvenResult = null;
        _targetProfitResult = null;
        _mosResult = null;
        _leverageResult = null;
        _sensitivityResult = null;
        _projectedProfit = null;
      });
      return;
    }

    setState(() {
      // Break-even analysis
      _breakEvenResult = _cvpService.analyzeBreakEven(
        fixedCosts: fixedCosts,
        unitSellingPrice: sellingPrice,
        variableCostPerUnit: variableCost,
      );

      // Target profit analysis
      _targetProfitResult = _cvpService.analyzeTargetProfit(
        fixedCosts: fixedCosts,
        targetProfit: targetProfit,
        unitSellingPrice: sellingPrice,
        variableCostPerUnit: variableCost,
      );

      // Margin of safety
      _mosResult = _cvpService.analyzeMarginOfSafety(
        actualSales: actualSales,
        actualUnits: actualUnits,
        fixedCosts: fixedCosts,
        unitSellingPrice: sellingPrice,
        variableCostPerUnit: variableCost,
      );

      // Operating leverage
      final variableCosts = variableCost * actualUnits;
      _leverageResult = _cvpService.analyzeOperatingLeverage(
        actualSales: actualSales,
        variableCosts: variableCosts,
        fixedCosts: fixedCosts,
      );

      // Projected profit
      _projectedProfit = _cvpService.calculateProjectedProfit(
        projectedUnits: actualUnits,
        unitSellingPrice: sellingPrice,
        variableCostPerUnit: variableCost,
        fixedCosts: fixedCosts,
      );

      // Sensitivity analysis
      _sensitivityResult = _cvpService.performSensitivityAnalysis(
        fixedCosts: fixedCosts,
        unitSellingPrice: sellingPrice,
        variableCostPerUnit: variableCost,
        priceChangePercents: const [-20, -15, -10, -5, 0, 5, 10, 15, 20],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CVP Analysis'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Calculator', icon: Icon(Icons.calculate)),
            Tab(text: 'Break-Even', icon: Icon(Icons.trending_up)),
            Tab(text: 'Margin of Safety', icon: Icon(Icons.security)),
            Tab(text: 'What-If', icon: Icon(Icons.compare_arrows)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalculatorTab(theme),
          _buildBreakEvenTab(theme),
          _buildMarginOfSafetyTab(theme),
          _buildWhatIfTab(theme),
        ],
      ),
    );
  }

  Widget _buildCalculatorTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cost Structure Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cost Structure',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _fixedCostsController,
                    decoration: const InputDecoration(
                      labelText: 'Fixed Costs (Total)',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                      helperText: 'Rent, salaries, depreciation, etc.',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _calculateAll(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Per-Unit Costs Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text('Per-Unit Data', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _sellingPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Selling Price',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateAll(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _variableCostController,
                          decoration: const InputDecoration(
                            labelText: 'Variable Cost',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateAll(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Show calculated contribution margin
                  if (_breakEvenResult != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Contribution Margin:',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            '${_formatCurrency(_breakEvenResult!.contributionMarginPerUnit)} per unit (${(_breakEvenResult!.contributionMarginRatio * 100).toStringAsFixed(1)}%)',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Actual/Expected Sales Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Actual/Expected Sales',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _actualUnitsController,
                          decoration: const InputDecoration(
                            labelText: 'Units Sold',
                            suffixText: 'units',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) {
                            // Auto-calculate sales from units
                            final units =
                                int.tryParse(_actualUnitsController.text) ?? 0;
                            final price =
                                double.tryParse(_sellingPriceController.text) ??
                                0;
                            final sales = (units * price).round();
                            _actualSalesController.text = sales.toString();
                            _calculateAll();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _actualSalesController,
                          decoration: const InputDecoration(
                            labelText: 'Sales Revenue',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => _calculateAll(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Target Profit Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Target Profit', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _targetProfitController,
                    decoration: const InputDecoration(
                      labelText: 'Desired Profit',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                      helperText: 'How much profit do you want to earn?',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _calculateAll(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Calculate Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                _calculateAll();
                _tabController.animateTo(1);
              },
              icon: const Icon(Icons.analytics),
              label: const Text('Analyze & View Results'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakEvenTab(ThemeData theme) {
    if (_breakEvenResult == null) {
      return const Center(
        child: Text('Enter data in the Calculator tab first'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Break-Even Summary Card
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.trending_up, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Break-Even Point',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMetricColumn(
                        theme,
                        '${_breakEvenResult!.breakEvenUnits}',
                        'UNITS',
                        theme.colorScheme.onPrimaryContainer,
                      ),
                      Container(
                        height: 60,
                        width: 1,
                        color: theme.colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      _buildMetricColumn(
                        theme,
                        _formatCurrency(_breakEvenResult!.breakEvenSales),
                        'SALES',
                        theme.colorScheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contribution Margin Details
          _buildInfoCard(
            theme,
            title: 'Contribution Margin',
            icon: Icons.pie_chart,
            rows: [
              _buildInfoRow(
                'CM per Unit',
                _formatCurrency(_breakEvenResult!.contributionMarginPerUnit),
              ),
              _buildInfoRow(
                'CM Ratio',
                '${(_breakEvenResult!.contributionMarginRatio * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Target Profit Analysis
          if (_targetProfitResult != null)
            _buildInfoCard(
              theme,
              title: 'Target Profit Analysis',
              icon: Icons.flag,
              rows: [
                _buildInfoRow(
                  'Target Profit',
                  _formatCurrency(_targetProfitResult!.targetProfit),
                ),
                _buildInfoRow(
                  'Required Units',
                  '${_targetProfitResult!.requiredUnits} units',
                ),
                _buildInfoRow(
                  'Required Sales',
                  _formatCurrency(_targetProfitResult!.requiredSales),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Current Performance
          if (_projectedProfit != null)
            _buildProfitCard(theme, _projectedProfit!),
        ],
      ),
    );
  }

  Widget _buildMarginOfSafetyTab(ThemeData theme) {
    if (_mosResult == null || _leverageResult == null) {
      return const Center(
        child: Text('Enter data in the Calculator tab first'),
      );
    }

    final mosColor = _mosResult!.riskLevel == 'LOW'
        ? Colors.green
        : _mosResult!.riskLevel == 'MODERATE'
        ? Colors.orange
        : Colors.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Margin of Safety Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Margin of Safety',
                        style: theme.textTheme.titleLarge,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: mosColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_mosResult!.riskLevel} RISK',
                          style: TextStyle(
                            color: mosColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // MOS Ratio Gauge
                  SizedBox(
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: _mosResult!.marginOfSafetyRatio.clamp(0, 1),
                            strokeWidth: 12,
                            backgroundColor: Colors.grey.shade200,
                            color: mosColor,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(_mosResult!.marginOfSafetyRatio * 100).toStringAsFixed(1)}%',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: mosColor,
                              ),
                            ),
                            Text('MOS Ratio', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMetricColumn(
                        theme,
                        _formatCurrency(_mosResult!.marginOfSafetyDollars),
                        'MOS (\$)',
                        mosColor,
                      ),
                      _buildMetricColumn(
                        theme,
                        '${_mosResult!.marginOfSafetyUnits}',
                        'MOS (Units)',
                        mosColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Interpretation Card
          Card(
            color: mosColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: mosColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getMOSInterpretation(),
                      style: TextStyle(color: mosColor.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Operating Leverage Card
          _buildInfoCard(
            theme,
            title: 'Operating Leverage',
            icon: Icons.speed,
            rows: [
              _buildInfoRow(
                'Degree of Operating Leverage',
                _leverageResult!.degreeOfOperatingLeverage.toStringAsFixed(2),
              ),
              _buildInfoRow('Leverage Level', _leverageResult!.leverageLevel),
              _buildInfoRow(
                'Impact',
                '1% sales change → ${_leverageResult!.impactMultiplier.toStringAsFixed(1)}% profit change',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatIfTab(ThemeData theme) {
    if (_sensitivityResult == null) {
      return const Center(
        child: Text('Enter data in the Calculator tab first'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Sensitivity Analysis', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Shows how break-even changes when you adjust selling price',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Base Case Card
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.anchor,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Current Break-Even: ${_sensitivityResult!.baseBreakEvenUnits} units',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sensitivity Table
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Scenario')),
                  DataColumn(label: Text('Break-Even'), numeric: true),
                  DataColumn(label: Text('Change'), numeric: true),
                  DataColumn(label: Text('Impact')),
                ],
                rows: _sensitivityResult!.scenarios.map((scenario) {
                  final isBase = scenario.changePercent == 0;
                  final isBetter = scenario.changeFromBase < 0;
                  final isWorse = scenario.changeFromBase > 0;

                  return DataRow(
                    color: isBase
                        ? WidgetStateProperty.all(
                            theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.3,
                            ),
                          )
                        : null,
                    cells: [
                      DataCell(
                        Text(
                          scenario.name,
                          style: TextStyle(
                            fontWeight: isBase ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${scenario.breakEvenUnits} units',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isBetter
                                ? Colors.green
                                : isWorse
                                ? Colors.red
                                : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          scenario.changeFromBase == 0
                              ? '-'
                              : '${scenario.changeFromBase > 0 ? '+' : ''}${scenario.changeFromBase}',
                          style: TextStyle(
                            color: isBetter
                                ? Colors.green
                                : isWorse
                                ? Colors.red
                                : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isBetter
                                ? Colors.green.shade100
                                : isWorse
                                ? Colors.red.shade100
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isBase
                                ? 'Base'
                                : isBetter
                                ? 'Better'
                                : 'Worse',
                            style: TextStyle(
                              fontSize: 12,
                              color: isBetter
                                  ? Colors.green.shade800
                                  : isWorse
                                  ? Colors.red.shade800
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Key Insights
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
                        Icons.lightbulb,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Key Insights',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getSensitivityInsights(),
                    style: TextStyle(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildMetricColumn(
    ThemeData theme,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Widget> rows,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProfitCard(ThemeData theme, int profit) {
    final isProfit = profit >= 0;
    final color = isProfit ? Colors.green : Colors.red;

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              isProfit ? Icons.trending_up : Icons.trending_down,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              isProfit ? 'PROJECTED PROFIT' : 'PROJECTED LOSS',
              style: theme.textTheme.titleMedium?.copyWith(color: color),
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(profit.abs()),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMOSInterpretation() {
    final ratio = _mosResult!.marginOfSafetyRatio;
    if (ratio >= 0.30) {
      return 'Strong safety margin. Sales can drop ${(ratio * 100).toStringAsFixed(0)}% before reaching break-even.';
    } else if (ratio >= 0.15) {
      return 'Moderate safety margin. Consider strategies to increase sales or reduce costs.';
    } else if (ratio > 0) {
      return 'Thin safety margin. The business is close to break-even and vulnerable to sales declines.';
    } else {
      return 'Operating below break-even. Immediate action needed to increase revenue or reduce costs.';
    }
  }

  String _getSensitivityInsights() {
    if (_sensitivityResult == null || _sensitivityResult!.scenarios.isEmpty) {
      return '';
    }

    final priceIncrease10 = _sensitivityResult!.scenarios
        .where((s) => s.changePercent == 10)
        .firstOrNull;
    final priceDecrease10 = _sensitivityResult!.scenarios
        .where((s) => s.changePercent == -10)
        .firstOrNull;

    final buffer = StringBuffer();
    buffer.writeln('• Higher prices = Lower break-even (fewer units needed)');
    buffer.writeln('• Lower prices = Higher break-even (more units needed)');

    if (priceIncrease10 != null) {
      buffer.writeln(
        '• A 10% price increase reduces break-even by ${priceIncrease10.changeFromBase.abs()} units',
      );
    }
    if (priceDecrease10 != null) {
      buffer.writeln(
        '• A 10% price decrease increases break-even by ${priceDecrease10.changeFromBase} units',
      );
    }

    return buffer.toString().trim();
  }
}

extension _ColorShade on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }
}
