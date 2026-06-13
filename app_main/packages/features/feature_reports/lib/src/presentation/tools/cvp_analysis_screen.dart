// FILE: packages/features/feature_reports/lib/src/presentation/tools/cvp_analysis_screen.dart
// Purpose: Cost-Volume-Profit Analysis interactive calculator
// Reference: Accounting Principles 13e (Weygandt), Chapter 22

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';

/// CVP Analysis Calculator Screen
class CVPAnalysisScreen extends ConsumerStatefulWidget {
  const CVPAnalysisScreen({super.key});

  @override
  ConsumerState<CVPAnalysisScreen> createState() => _CVPAnalysisScreenState();
}

class _CVPAnalysisScreenState extends ConsumerState<CVPAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _debounceTimer;

  // Input controllers (amounts in cents, display as dollars)
  final _fixedCostsController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _variableCostController = TextEditingController();
  final _actualSalesController = TextEditingController();
  final _actualUnitsController = TextEditingController();
  final _targetProfitController = TextEditingController();

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
    _debounceTimer?.cancel();
    _tabController.dispose();
    _fixedCostsController.dispose();
    _sellingPriceController.dispose();
    _variableCostController.dispose();
    _actualSalesController.dispose();
    _actualUnitsController.dispose();
    _targetProfitController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _calculateAll();
    });
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
    final cvpService = ref.read(cvpAnalysisServiceProvider);

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
      _breakEvenResult = cvpService.analyzeBreakEven(
        fixedCosts: fixedCosts,
        unitSellingPrice: sellingPrice,
        variableCostPerUnit: variableCost,
      );

      // Target profit analysis
      _targetProfitResult = cvpService.analyzeTargetProfit(
        fixedCosts: fixedCosts,
        targetProfit: targetProfit,
        unitSellingPrice: sellingPrice,
        variableCostPerUnit: variableCost,
      );

      // Margin of safety
      _mosResult = cvpService.analyzeMarginOfSafety(
        actualSales: actualSales,
        actualUnits: actualUnits,
        fixedCosts: fixedCosts,
        unitSellingPrice: sellingPrice,
        variableCostPerUnit: variableCost,
      );

      // Operating leverage
      final variableCosts = variableCost * actualUnits;
      _leverageResult = cvpService.analyzeOperatingLeverage(
        actualSales: actualSales,
        variableCosts: variableCosts,
        fixedCosts: fixedCosts,
      );

      // Projected profit
      _projectedProfit = cvpService.calculateProjectedProfit(
        projectedUnits: actualUnits,
        unitSellingPrice: sellingPrice,
        variableCostPerUnit: variableCost,
        fixedCosts: fixedCosts,
      );

      // Sensitivity analysis
      _sensitivityResult = cvpService.performSensitivityAnalysis(
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cvpAnalysisTitle),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: l10n.calculatorTab, icon: const Icon(Icons.calculate)),
            Tab(text: l10n.breakEvenTab, icon: const Icon(Icons.trending_up)),
            Tab(text: l10n.marginOfSafetyTab, icon: const Icon(Icons.security)),
            Tab(text: l10n.whatIfTab, icon: const Icon(Icons.compare_arrows)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalculatorTab(theme, l10n),
          _buildBreakEvenTab(theme, l10n),
          _buildMarginOfSafetyTab(theme, l10n),
          _buildWhatIfTab(theme, l10n),
        ],
      ),
    );
  }

  Widget _buildCalculatorTab(ThemeData theme, AppLocalizations l10n) {
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
                        l10n.costStructure,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _fixedCostsController,
                    decoration: InputDecoration(
                      labelText: l10n.fixedCostsTotal,
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                      helperText: l10n.fixedCostsHelper,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _onInputChanged(),
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
                      Text(
                        l10n.perUnitData,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _sellingPriceController,
                          decoration: InputDecoration(
                            labelText: l10n.sellingPrice,
                            prefixText: '\$ ',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _onInputChanged(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _variableCostController,
                          decoration: InputDecoration(
                            labelText: l10n.variableCost,
                            prefixText: '\$ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _onInputChanged(),
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
                          Expanded(
                            child: Text(
                              l10n.contributionMarginLabel,
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${_formatCurrency(_breakEvenResult!.contributionMarginPerUnit)} per unit (${(_breakEvenResult!.contributionMarginRatio * 100).toStringAsFixed(1)}%)',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.end,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                        l10n.actualExpectedSales,
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
                          decoration: InputDecoration(
                            labelText: l10n.unitsSold,
                            suffixText: l10n.unitsSuffix,
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
                            if (sales > 0) {
                              _actualSalesController.text = sales.toString();
                            }
                            _onInputChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _actualSalesController,
                          decoration: InputDecoration(
                            labelText: l10n.salesRevenueLabel,
                            prefixText: '\$ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => _onInputChanged(),
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
                      Text(
                        l10n.targetProfit,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _targetProfitController,
                    decoration: InputDecoration(
                      labelText: l10n.desiredProfit,
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                      helperText: l10n.desiredProfitHelper,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _onInputChanged(),
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
              label: Text(l10n.analyzeViewResults),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakEvenTab(ThemeData theme, AppLocalizations l10n) {
    if (_breakEvenResult == null) {
      return Center(child: Text(l10n.enterDataCalculatorFirst));
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
                    l10n.breakEvenPoint,
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
                        l10n.unitsLabel,
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
                        l10n.salesLabel,
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
            title: l10n.contributionMarginTitle,
            icon: Icons.pie_chart,
            rows: [
              _buildInfoRow(
                l10n.cmPerUnit,
                _formatCurrency(_breakEvenResult!.contributionMarginPerUnit),
              ),
              _buildInfoRow(
                l10n.cmRatio,
                '${(_breakEvenResult!.contributionMarginRatio * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Target Profit Analysis
          if (_targetProfitResult != null)
            _buildInfoCard(
              theme,
              title: l10n.targetProfitAnalysis,
              icon: Icons.flag,
              rows: [
                _buildInfoRow(
                  l10n.targetProfit,
                  _formatCurrency(_targetProfitResult!.targetProfit),
                ),
                _buildInfoRow(
                  l10n.requiredUnits,
                  '${_targetProfitResult!.requiredUnits} units',
                ),
                _buildInfoRow(
                  l10n.requiredSales,
                  _formatCurrency(_targetProfitResult!.requiredSales),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Current Performance
          if (_projectedProfit != null)
            _buildProfitCard(theme, _projectedProfit!, l10n),
        ],
      ),
    );
  }

  Widget _buildMarginOfSafetyTab(ThemeData theme, AppLocalizations l10n) {
    if (_mosResult == null || _leverageResult == null) {
      return Center(child: Text(l10n.enterDataCalculatorFirst));
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
                      Expanded(
                        child: Text(
                          l10n.marginOfSafetyTitle,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                          '${_mosResult!.riskLevel == 'LOW'
                              ? 'LOW'
                              : _mosResult!.riskLevel == 'MODERATE'
                              ? 'MODERATE'
                              : 'HIGH'} ${l10n.riskSuffix}',
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
                            Text(
                              l10n.mosRatio,
                              style: theme.textTheme.bodySmall,
                            ),
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
                        l10n.mosDollar,
                        mosColor,
                      ),
                      _buildMetricColumn(
                        theme,
                        '${_mosResult!.marginOfSafetyUnits}',
                        l10n.mosUnits,
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
                      _getMOSInterpretation(l10n),
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
            title: l10n.operatingLeverage,
            icon: Icons.speed,
            rows: [
              _buildInfoRow(
                l10n.degreeOfOperatingLeverage,
                _leverageResult!.degreeOfOperatingLeverage.toStringAsFixed(2),
              ),
              _buildInfoRow(l10n.leverageLevel, _leverageResult!.leverageLevel),
              _buildInfoRow(
                l10n.leverageImpact,
                l10n.leverageImpactDesc(
                  _leverageResult!.impactMultiplier.toStringAsFixed(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatIfTab(ThemeData theme, AppLocalizations l10n) {
    if (_sensitivityResult == null) {
      return Center(child: Text(l10n.enterDataCalculatorFirst));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.priceSensitivityAnalysis,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.priceSensitivityDescription,
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
                      l10n.currentBreakEven(
                        '${_sensitivityResult!.baseBreakEvenUnits}',
                      ),
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
                columns: [
                  DataColumn(label: Text(l10n.scenarioColumn)),
                  DataColumn(label: Text(l10n.breakEvenColumn), numeric: true),
                  DataColumn(label: Text(l10n.changeColumn), numeric: true),
                  DataColumn(label: Text(l10n.impactLabel)),
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
                                ? l10n.baseImpact
                                : isBetter
                                ? l10n.betterImpact
                                : l10n.worseImpact,
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
                        l10n.keyInsights,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getSensitivityInsights(l10n),
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
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
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
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '\u200E$value',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCard(ThemeData theme, int profit, AppLocalizations l10n) {
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
              isProfit ? l10n.projectedProfit : l10n.projectedLoss,
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

  String _getMOSInterpretation(AppLocalizations l10n) {
    final ratio = _mosResult!.marginOfSafetyRatio;
    if (ratio >= 0.30) {
      return l10n.strongSafetyMargin((ratio * 100).toStringAsFixed(0));
    } else if (ratio >= 0.15) {
      return l10n.moderateSafetyMargin;
    } else if (ratio > 0) {
      return l10n.thinSafetyMargin;
    } else {
      return l10n.belowBreakEven;
    }
  }

  String _getSensitivityInsights(AppLocalizations l10n) {
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
    buffer.writeln(l10n.higherPricesInsight);
    buffer.writeln(l10n.lowerPricesInsight);

    if (priceIncrease10 != null) {
      buffer.writeln(
        l10n.priceIncreaseEffect(
          priceIncrease10.changeFromBase.abs().toString(),
        ),
      );
    }
    if (priceDecrease10 != null) {
      buffer.writeln(
        l10n.priceDecreaseEffect(priceDecrease10.changeFromBase.toString()),
      );
    }

    return buffer.toString().trim();
  }
}
