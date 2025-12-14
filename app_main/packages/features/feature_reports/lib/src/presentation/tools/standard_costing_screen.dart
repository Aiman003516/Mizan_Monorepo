// FILE: packages/features/feature_reports/lib/src/presentation/tools/standard_costing_screen.dart
// Purpose: Standard costing variance analysis calculator
// Reference: Accounting Principles 13e (Weygandt), Chapter 25

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core_data/src/services/standard_costing_service.dart';

/// Standard Costing Screen - Variance Analysis Calculator
class StandardCostingScreen extends StatefulWidget {
  const StandardCostingScreen({super.key});

  @override
  State<StandardCostingScreen> createState() => _StandardCostingScreenState();
}

class _StandardCostingScreenState extends State<StandardCostingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Standard Cost Card
  final _stdMaterialQtyController = TextEditingController(text: '2');
  final _stdMaterialPriceController = TextEditingController(text: '5.00');
  final _stdLaborHoursController = TextEditingController(text: '0.5');
  final _stdLaborRateController = TextEditingController(text: '20.00');
  final _stdVOHRateController = TextEditingController(text: '4.00');
  final _budgetedFOHController = TextEditingController(text: '10000');
  final _normalCapacityController = TextEditingController(text: '1000');

  // Actual Data
  final _unitsProducedController = TextEditingController(text: '500');
  final _actualMaterialQtyController = TextEditingController(text: '1050');
  final _actualMaterialPriceController = TextEditingController(text: '5.10');
  final _actualLaborHoursController = TextEditingController(text: '260');
  final _actualLaborRateController = TextEditingController(text: '20.50');
  final _actualVOHController = TextEditingController(text: '1100');
  final _actualFOHController = TextEditingController(text: '10200');

  ProductionVarianceReport? _report;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _calculate();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stdMaterialQtyController.dispose();
    _stdMaterialPriceController.dispose();
    _stdLaborHoursController.dispose();
    _stdLaborRateController.dispose();
    _stdVOHRateController.dispose();
    _budgetedFOHController.dispose();
    _normalCapacityController.dispose();
    _unitsProducedController.dispose();
    _actualMaterialQtyController.dispose();
    _actualMaterialPriceController.dispose();
    _actualLaborHoursController.dispose();
    _actualLaborRateController.dispose();
    _actualVOHController.dispose();
    _actualFOHController.dispose();
    super.dispose();
  }

  double _parseDouble(TextEditingController c) => double.tryParse(c.text) ?? 0;
  int _parseInt(TextEditingController c) => int.tryParse(c.text) ?? 0;
  int _dollarsToCents(TextEditingController c) =>
      ((double.tryParse(c.text) ?? 0) * 100).round();

  void _calculate() {
    final standardCost = StandardCostCard(
      productId: 'CALC',
      productName: 'Calculator Product',
      standardMaterialQuantity: _parseDouble(_stdMaterialQtyController),
      standardMaterialPrice: _dollarsToCents(_stdMaterialPriceController),
      standardLaborHours: _parseDouble(_stdLaborHoursController),
      standardLaborRate: _dollarsToCents(_stdLaborRateController),
      standardVOHHours: _parseDouble(_stdLaborHoursController), // Same as labor
      standardVOHRate: _dollarsToCents(_stdVOHRateController),
      budgetedFixedOverhead: _parseInt(_budgetedFOHController) * 100,
      normalCapacityHours: _parseDouble(_normalCapacityController),
    );

    final report = StandardCostingService.generateVarianceReport(
      standardCost: standardCost,
      unitsProduced: _parseInt(_unitsProducedController),
      actualMaterialQuantity: _parseDouble(_actualMaterialQtyController),
      actualMaterialPrice: _dollarsToCents(_actualMaterialPriceController),
      actualLaborHours: _parseDouble(_actualLaborHoursController),
      actualLaborRate: _dollarsToCents(_actualLaborRateController),
      actualVariableOverhead: _parseInt(_actualVOHController) * 100,
      actualFixedOverhead: _parseInt(_actualFOHController) * 100,
    );

    setState(() {
      _report = report;
    });
  }

  String _formatCurrency(int cents) {
    final dollars = cents / 100;
    if (dollars.abs() >= 1000) {
      return '\$${(dollars / 1000).toStringAsFixed(1)}K';
    }
    return '\$${dollars.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Standard Costing'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Standards', icon: Icon(Icons.settings)),
            Tab(text: 'Materials', icon: Icon(Icons.inventory_2)),
            Tab(text: 'Labor', icon: Icon(Icons.people)),
            Tab(text: 'Overhead', icon: Icon(Icons.factory)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStandardsTab(theme),
          _buildMaterialsTab(theme),
          _buildLaborTab(theme),
          _buildOverheadTab(theme),
        ],
      ),
    );
  }

  Widget _buildStandardsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Banner
          if (_report != null) _buildSummaryBanner(theme),
          const SizedBox(height: 16),

          // Standard Cost Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Standard Cost Card',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInputRow2(
                    'Material Qty/Unit',
                    _stdMaterialQtyController,
                    'units',
                  ),
                  _buildInputRow2(
                    'Material Price',
                    _stdMaterialPriceController,
                    '\$/unit',
                  ),
                  _buildInputRow2(
                    'Labor Hours/Unit',
                    _stdLaborHoursController,
                    'hrs',
                  ),
                  _buildInputRow2(
                    'Labor Rate',
                    _stdLaborRateController,
                    '\$/hr',
                  ),
                  _buildInputRow2('VOH Rate', _stdVOHRateController, '\$/hr'),
                  _buildInputRow2('Budgeted FOH', _budgetedFOHController, '\$'),
                  _buildInputRow2(
                    'Normal Capacity',
                    _normalCapacityController,
                    'hrs',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Actual Production
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.precision_manufacturing, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Actual Production',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInputRow2(
                    'Units Produced',
                    _unitsProducedController,
                    '',
                  ),
                  _buildInputRow2(
                    'Material Used',
                    _actualMaterialQtyController,
                    'units',
                  ),
                  _buildInputRow2(
                    'Material Price',
                    _actualMaterialPriceController,
                    '\$/unit',
                  ),
                  _buildInputRow2(
                    'Labor Hours',
                    _actualLaborHoursController,
                    'hrs',
                  ),
                  _buildInputRow2(
                    'Labor Rate',
                    _actualLaborRateController,
                    '\$/hr',
                  ),
                  _buildInputRow2('Actual VOH', _actualVOHController, '\$'),
                  _buildInputRow2('Actual FOH', _actualFOHController, '\$'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow2(
    String label,
    TextEditingController controller,
    String suffix,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                suffixText: suffix,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              onChanged: (_) => _calculate(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBanner(ThemeData theme) {
    final report = _report!;
    final isNetFavorable = report.isNetFavorable;
    final color = isNetFavorable ? Colors.green : Colors.red;

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isNetFavorable ? Icons.trending_down : Icons.trending_up,
              color: color,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Variance: ${_formatCurrency(report.totalVariance)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isNetFavorable ? 'Net Favorable' : 'Net Unfavorable',
                    style: TextStyle(color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsTab(ThemeData theme) {
    if (_report == null) {
      return const Center(child: Text('Enter data to see analysis'));
    }

    final mv = _report!.materialVariance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildVarianceHeader(
            theme,
            'Direct Materials Variance',
            Icons.inventory_2,
            mv.totalVariance,
            mv.totalVariance < 0,
          ),
          const SizedBox(height: 16),

          // Cost Comparison
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildComparisonRow('Standard Cost', mv.standardCost, theme),
                  _buildComparisonRow('Actual Cost', mv.actualCost, theme),
                  const Divider(),
                  _buildComparisonRow(
                    'Total Variance',
                    mv.totalVariance,
                    theme,
                    highlight: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Variance Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Variance Breakdown',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildVarianceRow(
                    'Price Variance',
                    '(AP - SP) × AQ',
                    mv.priceVariance,
                    mv.priceVarianceFavorable,
                  ),
                  const SizedBox(height: 12),
                  _buildVarianceRow(
                    'Quantity Variance',
                    '(AQ - SQ) × SP',
                    mv.quantityVariance,
                    mv.quantityVarianceFavorable,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Formula Card
          _buildFormulaCard(theme, 'Materials Formulas', [
            'Price Variance = (Actual Price - Standard Price) × Actual Qty',
            'Quantity Variance = (Actual Qty - Standard Qty) × Standard Price',
          ]),
        ],
      ),
    );
  }

  Widget _buildLaborTab(ThemeData theme) {
    if (_report == null) {
      return const Center(child: Text('Enter data to see analysis'));
    }

    final lv = _report!.laborVariance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildVarianceHeader(
            theme,
            'Direct Labor Variance',
            Icons.people,
            lv.totalVariance,
            lv.totalVariance < 0,
          ),
          const SizedBox(height: 16),

          // Cost Comparison
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildComparisonRow('Standard Cost', lv.standardCost, theme),
                  _buildComparisonRow('Actual Cost', lv.actualCost, theme),
                  const Divider(),
                  _buildComparisonRow(
                    'Total Variance',
                    lv.totalVariance,
                    theme,
                    highlight: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Variance Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Variance Breakdown',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildVarianceRow(
                    'Rate Variance',
                    '(AR - SR) × AH',
                    lv.rateVariance,
                    lv.rateVarianceFavorable,
                  ),
                  const SizedBox(height: 12),
                  _buildVarianceRow(
                    'Efficiency Variance',
                    '(AH - SH) × SR',
                    lv.efficiencyVariance,
                    lv.efficiencyVarianceFavorable,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildFormulaCard(theme, 'Labor Formulas', [
            'Rate Variance = (Actual Rate - Standard Rate) × Actual Hours',
            'Efficiency Variance = (Actual Hours - Std Hours) × Std Rate',
          ]),
        ],
      ),
    );
  }

  Widget _buildOverheadTab(ThemeData theme) {
    if (_report == null) {
      return const Center(child: Text('Enter data to see analysis'));
    }

    final ov = _report!.overheadVariance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildVarianceHeader(
            theme,
            'Manufacturing Overhead Variance',
            Icons.factory,
            ov.totalVariance,
            ov.isOverApplied,
          ),
          const SizedBox(height: 16),

          // Cost Comparison
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildComparisonRow(
                    'Applied Overhead',
                    ov.standardOverhead,
                    theme,
                  ),
                  _buildComparisonRow(
                    'Actual Overhead',
                    ov.actualOverhead,
                    theme,
                  ),
                  const Divider(),
                  _buildComparisonRow(
                    'Total Variance',
                    ov.totalVariance,
                    theme,
                    highlight: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ov.isOverApplied ? 'Overapplied' : 'Underapplied',
                    style: TextStyle(
                      color: ov.isOverApplied ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Variable Overhead
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Variable Overhead', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  _buildVarianceRow(
                    'Spending Variance',
                    'Actual VOH - (AH × SR)',
                    ov.variableSpendingVariance,
                    ov.variableSpendingVariance < 0,
                  ),
                  const SizedBox(height: 12),
                  _buildVarianceRow(
                    'Efficiency Variance',
                    '(AH - SH) × SR',
                    ov.variableEfficiencyVariance,
                    ov.variableEfficiencyVariance < 0,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Fixed Overhead
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fixed Overhead', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  _buildVarianceRow(
                    'Budget Variance',
                    'Actual FOH - Budgeted FOH',
                    ov.fixedBudgetVariance,
                    ov.fixedBudgetVariance < 0,
                  ),
                  const SizedBox(height: 12),
                  _buildVarianceRow(
                    'Volume Variance',
                    'Budgeted FOH - Applied FOH',
                    ov.fixedVolumeVariance,
                    ov.fixedVolumeVariance < 0,
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

  Widget _buildVarianceHeader(
    ThemeData theme,
    String title,
    IconData icon,
    int variance,
    bool isFavorable,
  ) {
    final color = isFavorable ? Colors.green : Colors.red;

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  Text(
                    _formatCurrency(variance),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isFavorable ? 'F' : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    int amount,
    ThemeData theme, {
    bool highlight = false,
  }) {
    final color = highlight
        ? (amount < 0
              ? Colors.green
              : amount > 0
              ? Colors.red
              : null)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: highlight
                ? const TextStyle(fontWeight: FontWeight.bold)
                : null,
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVarianceRow(
    String name,
    String formula,
    int amount,
    bool isFavorable,
  ) {
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
              Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                formula,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatCurrency(amount),
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              amount == 0
                  ? '-'
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

  Widget _buildFormulaCard(
    ThemeData theme,
    String title,
    List<String> formulas,
  ) {
    return Card(
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
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...formulas.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $f',
                  style: TextStyle(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
