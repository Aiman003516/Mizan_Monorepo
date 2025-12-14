// FILE: packages/features/feature_reports/lib/src/presentation/tools/fraud_detection_screen.dart
// Purpose: Beneish M-Score fraud detection calculator
// Reference: Messod D. Beneish, "The Detection of Earnings Manipulation" (1999)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core_data/src/services/financial_analysis_service.dart';

/// Fraud Detection Screen using Beneish M-Score
class FraudDetectionScreen extends StatefulWidget {
  const FraudDetectionScreen({super.key});

  @override
  State<FraudDetectionScreen> createState() => _FraudDetectionScreenState();
}

class _FraudDetectionScreenState extends State<FraudDetectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Current Period Controllers
  final _currentRevenueController = TextEditingController(text: '1000000');
  final _currentReceivablesController = TextEditingController(text: '100000');
  final _currentGrossProfitController = TextEditingController(text: '400000');
  final _currentTotalAssetsController = TextEditingController(text: '1000000');
  final _currentCurrentAssetsController = TextEditingController(text: '400000');
  final _currentPPEController = TextEditingController(text: '500000');
  final _currentDepreciationController = TextEditingController(text: '50000');
  final _currentSGAController = TextEditingController(text: '200000');
  final _currentNetIncomeController = TextEditingController(text: '100000');
  final _currentCFOController = TextEditingController(text: '120000');
  final _currentLTDebtController = TextEditingController(text: '200000');
  final _currentCLController = TextEditingController(text: '100000');

  // Prior Period Controllers
  final _priorRevenueController = TextEditingController(text: '950000');
  final _priorReceivablesController = TextEditingController(text: '95000');
  final _priorGrossProfitController = TextEditingController(text: '380000');
  final _priorTotalAssetsController = TextEditingController(text: '950000');
  final _priorCurrentAssetsController = TextEditingController(text: '380000');
  final _priorPPEController = TextEditingController(text: '475000');
  final _priorDepreciationController = TextEditingController(text: '47500');
  final _priorSGAController = TextEditingController(text: '190000');
  final _priorLTDebtController = TextEditingController(text: '190000');
  final _priorCLController = TextEditingController(text: '95000');

  BeneishMScoreResult? _result;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calculate();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Dispose all controllers
    _currentRevenueController.dispose();
    _currentReceivablesController.dispose();
    _currentGrossProfitController.dispose();
    _currentTotalAssetsController.dispose();
    _currentCurrentAssetsController.dispose();
    _currentPPEController.dispose();
    _currentDepreciationController.dispose();
    _currentSGAController.dispose();
    _currentNetIncomeController.dispose();
    _currentCFOController.dispose();
    _currentLTDebtController.dispose();
    _currentCLController.dispose();
    _priorRevenueController.dispose();
    _priorReceivablesController.dispose();
    _priorGrossProfitController.dispose();
    _priorTotalAssetsController.dispose();
    _priorCurrentAssetsController.dispose();
    _priorPPEController.dispose();
    _priorDepreciationController.dispose();
    _priorSGAController.dispose();
    _priorLTDebtController.dispose();
    _priorCLController.dispose();
    super.dispose();
  }

  int _parse(TextEditingController c) => int.tryParse(c.text) ?? 0;

  void _calculate() {
    final input = MScoreInput(
      currentRevenue: _parse(_currentRevenueController),
      currentReceivables: _parse(_currentReceivablesController),
      currentGrossProfit: _parse(_currentGrossProfitController),
      currentTotalAssets: _parse(_currentTotalAssetsController),
      currentCurrentAssets: _parse(_currentCurrentAssetsController),
      currentPPE: _parse(_currentPPEController),
      currentDepreciation: _parse(_currentDepreciationController),
      currentSGA: _parse(_currentSGAController),
      currentNetIncome: _parse(_currentNetIncomeController),
      currentCFO: _parse(_currentCFOController),
      currentLongTermDebt: _parse(_currentLTDebtController),
      currentCurrentLiabilities: _parse(_currentCLController),
      priorRevenue: _parse(_priorRevenueController),
      priorReceivables: _parse(_priorReceivablesController),
      priorGrossProfit: _parse(_priorGrossProfitController),
      priorTotalAssets: _parse(_priorTotalAssetsController),
      priorCurrentAssets: _parse(_priorCurrentAssetsController),
      priorPPE: _parse(_priorPPEController),
      priorDepreciation: _parse(_priorDepreciationController),
      priorSGA: _parse(_priorSGAController),
      priorLongTermDebt: _parse(_priorLTDebtController),
      priorCurrentLiabilities: _parse(_priorCLController),
    );

    setState(() {
      _result = BeneishMScore.calculate(input);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fraud Detection (M-Score)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Input', icon: Icon(Icons.edit)),
            Tab(text: 'Results', icon: Icon(Icons.warning_amber)),
            Tab(text: 'Learn', icon: Icon(Icons.school)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInputTab(theme),
          _buildResultsTab(theme),
          _buildLearnTab(theme),
        ],
      ),
    );
  }

  Widget _buildInputTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Result Banner
          if (_result != null) _buildQuickResultBanner(theme),
          const SizedBox(height: 16),

          // Current Period
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current Period',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInputRow('Revenue', _currentRevenueController),
                  _buildInputRow('Receivables', _currentReceivablesController),
                  _buildInputRow('Gross Profit', _currentGrossProfitController),
                  _buildInputRow('Total Assets', _currentTotalAssetsController),
                  _buildInputRow(
                    'Current Assets',
                    _currentCurrentAssetsController,
                  ),
                  _buildInputRow('PP&E', _currentPPEController),
                  _buildInputRow(
                    'Depreciation',
                    _currentDepreciationController,
                  ),
                  _buildInputRow('SG&A Expense', _currentSGAController),
                  _buildInputRow('Net Income', _currentNetIncomeController),
                  _buildInputRow('Cash from Ops', _currentCFOController),
                  _buildInputRow('Long-Term Debt', _currentLTDebtController),
                  _buildInputRow('Current Liabilities', _currentCLController),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Prior Period
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Prior Period', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInputRow('Revenue', _priorRevenueController),
                  _buildInputRow('Receivables', _priorReceivablesController),
                  _buildInputRow('Gross Profit', _priorGrossProfitController),
                  _buildInputRow('Total Assets', _priorTotalAssetsController),
                  _buildInputRow(
                    'Current Assets',
                    _priorCurrentAssetsController,
                  ),
                  _buildInputRow('PP&E', _priorPPEController),
                  _buildInputRow('Depreciation', _priorDepreciationController),
                  _buildInputRow('SG&A Expense', _priorSGAController),
                  _buildInputRow('Long-Term Debt', _priorLTDebtController),
                  _buildInputRow('Current Liabilities', _priorCLController),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixText: '\$ ',
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => _calculate(),
      ),
    );
  }

  Widget _buildQuickResultBanner(ThemeData theme) {
    final result = _result!;
    final Color color;
    final IconData icon;

    switch (result.riskLevel) {
      case 'HIGH':
        color = Colors.red;
        icon = Icons.warning;
        break;
      case 'MODERATE':
        color = Colors.orange;
        icon = Icons.error_outline;
        break;
      default:
        color = Colors.green;
        icon = Icons.check_circle;
    }

    return Card(
      color: color.withOpacity(0.1),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          'M-Score: ${result.mScore.toStringAsFixed(2)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        subtitle: Text(
          '${result.riskLevel} Risk${result.isProbableManipulator ? ' - Probable Manipulator' : ''}',
          style: TextStyle(color: color),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => _tabController.animateTo(1),
        ),
      ),
    );
  }

  Widget _buildResultsTab(ThemeData theme) {
    if (_result == null) {
      return const Center(child: Text('Enter financial data to see results'));
    }

    final result = _result!;
    final Color riskColor;

    switch (result.riskLevel) {
      case 'HIGH':
        riskColor = Colors.red;
        break;
      case 'MODERATE':
        riskColor = Colors.orange;
        break;
      default:
        riskColor = Colors.green;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main Score Card
          Card(
            color: riskColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    result.riskLevel == 'HIGH'
                        ? Icons.warning
                        : result.riskLevel == 'MODERATE'
                        ? Icons.error_outline
                        : Icons.verified_user,
                    size: 64,
                    color: riskColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'M-Score: ${result.mScore.toStringAsFixed(3)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.riskLevel} Risk of Earnings Manipulation',
                    style: theme.textTheme.titleMedium,
                  ),
                  if (result.isProbableManipulator) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'PROBABLE MANIPULATOR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Threshold: > -1.78 indicates manipulation',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Component Indices
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Component Indices', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  _buildIndexRow(
                    'DSRI',
                    result.dsri,
                    1.031,
                    'Receivables/Sales',
                  ),
                  _buildIndexRow('GMI', result.gmi, 1.041, 'Gross Margin'),
                  _buildIndexRow('AQI', result.aqi, 1.254, 'Asset Quality'),
                  _buildIndexRow('SGI', result.sgi, 1.134, 'Sales Growth'),
                  _buildIndexRow('DEPI', result.depi, 1.077, 'Depreciation'),
                  _buildIndexRow('SGAI', result.sgai, 1.0, 'SG&A Expenses'),
                  _buildIndexRow('TATA', result.tata, 0.018, 'Accruals'),
                  _buildIndexRow('LVGI', result.lvgi, 1.111, 'Leverage'),
                ],
              ),
            ),
          ),

          // Red Flags
          if (result.redFlags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flag, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Red Flags (${result.redFlags.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...result.redFlags.map(
                      (flag) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                flag,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildIndexRow(
    String name,
    double value,
    double threshold,
    String description,
  ) {
    final isAboveThreshold = value > threshold;
    final color = isAboveThreshold ? Colors.red : Colors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(description, style: const TextStyle(fontSize: 12)),
          ),
          Text(
            value.toStringAsFixed(3),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 8),
          Icon(
            isAboveThreshold ? Icons.arrow_upward : Icons.check,
            color: color,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildLearnTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What is the Beneish M-Score?',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The M-Score is a mathematical model created by Professor '
                    'Messod Beneish that uses financial ratios to detect '
                    'whether a company has manipulated its earnings.\n\n'
                    'An M-Score greater than -1.78 suggests a HIGH probability '
                    '(76%) that the company is an earnings manipulator.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('The Formula', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'M = -4.84 + 0.92×DSRI + 0.528×GMI\n'
                      '    + 0.404×AQI + 0.892×SGI + 0.115×DEPI\n'
                      '    - 0.172×SGAI + 4.679×TATA - 0.327×LVGI',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Index Explanations',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildExplanationRow(
                    'DSRI',
                    'Days Sales in Receivables Index',
                    'Measures if receivables grew faster than sales',
                  ),
                  _buildExplanationRow(
                    'GMI',
                    'Gross Margin Index',
                    'Detects deteriorating gross margins',
                  ),
                  _buildExplanationRow(
                    'AQI',
                    'Asset Quality Index',
                    'Identifies expense capitalization',
                  ),
                  _buildExplanationRow(
                    'SGI',
                    'Sales Growth Index',
                    'High growth creates manipulation pressure',
                  ),
                  _buildExplanationRow(
                    'DEPI',
                    'Depreciation Index',
                    'Detects slowing depreciation rates',
                  ),
                  _buildExplanationRow(
                    'SGAI',
                    'SG&A Index',
                    'Measures administrative efficiency',
                  ),
                  _buildExplanationRow(
                    'TATA',
                    'Total Accruals to Total Assets',
                    'High accruals vs cash = low quality',
                  ),
                  _buildExplanationRow(
                    'LVGI',
                    'Leverage Index',
                    'Increasing debt creates pressure',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

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
                        'Famous Cases',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Enron (2001): Would have had M-Score > -1.78\n'
                    '• WorldCom (2002): High TATA due to expense capitalization\n'
                    '• Satyam (2009): High DSRI from fictitious receivables\n\n'
                    'The M-Score correctly identified 76% of manipulators in '
                    'backtesting studies.',
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

  Widget _buildExplanationRow(String abbr, String name, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              abbr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
