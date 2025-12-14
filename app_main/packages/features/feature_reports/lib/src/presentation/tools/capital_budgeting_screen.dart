// FILE: packages/features/feature_reports/lib/src/presentation/tools/capital_budgeting_screen.dart
// Purpose: Capital Budgeting Calculator for investment analysis

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core_data/src/services/capital_budgeting_service.dart';

/// Capital Budgeting Calculator Screen
class CapitalBudgetingScreen extends StatefulWidget {
  const CapitalBudgetingScreen({super.key});

  @override
  State<CapitalBudgetingScreen> createState() => _CapitalBudgetingScreenState();
}

class _CapitalBudgetingScreenState extends State<CapitalBudgetingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Input controllers
  final _investmentController = TextEditingController(text: '100000');
  final _discountRateController = TextEditingController(text: '10');
  final _requiredReturnController = TextEditingController(text: '10');
  final _residualValueController = TextEditingController(text: '0');
  final _annualIncomeController = TextEditingController(text: '20000');

  // Cash flows
  final List<TextEditingController> _cashFlowControllers = [
    TextEditingController(text: '30000'),
    TextEditingController(text: '40000'),
    TextEditingController(text: '50000'),
    TextEditingController(text: '40000'),
    TextEditingController(text: '30000'),
  ];

  // Results
  NPVResult? _npvResult;
  IRRResult? _irrResult;
  PaybackResult? _paybackResult;
  PaybackResult? _discountedPaybackResult;
  PIResult? _piResult;
  ARRResult? _arrResult;
  List<SensitivityPoint>? _sensitivityPoints;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calculateAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _investmentController.dispose();
    _discountRateController.dispose();
    _requiredReturnController.dispose();
    _residualValueController.dispose();
    _annualIncomeController.dispose();
    for (final c in _cashFlowControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _calculateAll() {
    final investment = double.tryParse(_investmentController.text) ?? 0;
    final discountRate =
        (double.tryParse(_discountRateController.text) ?? 10) / 100;
    final requiredReturn =
        (double.tryParse(_requiredReturnController.text) ?? 10) / 100;
    final cashFlows = _cashFlowControllers
        .map((c) => double.tryParse(c.text) ?? 0)
        .where((v) => v > 0)
        .toList();

    if (investment <= 0 || cashFlows.isEmpty) {
      setState(() {
        _npvResult = null;
        _irrResult = null;
        _paybackResult = null;
        _discountedPaybackResult = null;
        _piResult = null;
        _sensitivityPoints = null;
      });
      return;
    }

    setState(() {
      _npvResult = CapitalBudgetingService.calculateNPV(
        initialInvestment: investment,
        cashFlows: cashFlows,
        discountRate: discountRate,
      );

      _irrResult = CapitalBudgetingService.calculateIRR(
        initialInvestment: investment,
        cashFlows: cashFlows,
      );

      _paybackResult = CapitalBudgetingService.calculatePaybackPeriod(
        initialInvestment: investment,
        cashFlows: cashFlows,
      );

      _discountedPaybackResult =
          CapitalBudgetingService.calculateDiscountedPaybackPeriod(
            initialInvestment: investment,
            cashFlows: cashFlows,
            discountRate: discountRate,
          );

      _piResult = CapitalBudgetingService.calculateProfitabilityIndex(
        initialInvestment: investment,
        cashFlows: cashFlows,
        discountRate: discountRate,
      );

      final residualValue = double.tryParse(_residualValueController.text) ?? 0;
      final annualIncome = double.tryParse(_annualIncomeController.text) ?? 0;
      _arrResult = CapitalBudgetingService.calculateARR(
        expectedAnnualNetIncome: annualIncome,
        initialInvestment: investment,
        residualValue: residualValue,
      );

      _sensitivityPoints = CapitalBudgetingService.npvSensitivityAnalysis(
        initialInvestment: investment,
        cashFlows: cashFlows,
        minRate: 0.05,
        maxRate: 0.25,
        step: 0.02,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capital Budgeting'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Calculator', icon: Icon(Icons.calculate)),
            Tab(text: 'Results', icon: Icon(Icons.analytics)),
            Tab(text: 'Sensitivity', icon: Icon(Icons.show_chart)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalculatorTab(theme),
          _buildResultsTab(theme),
          _buildSensitivityTab(theme),
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
          // Investment Input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Initial Investment',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _investmentController,
                    decoration: const InputDecoration(
                      labelText: 'Investment Amount',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
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

          // Discount Rate
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Discount Rate', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _discountRateController,
                          decoration: const InputDecoration(
                            labelText: 'Rate',
                            suffixText: '%',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateAll(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _requiredReturnController,
                          decoration: const InputDecoration(
                            labelText: 'Required Return',
                            suffixText: '%',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
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

          // Cash Flows
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Expected Cash Flows',
                        style: theme.textTheme.titleMedium,
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _cashFlowControllers.length > 1
                                ? () => _removeCashFlow()
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _addCashFlow,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_cashFlowControllers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: _cashFlowControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Year ${index + 1}',
                          prefixText: '\$ ',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => _calculateAll(),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ARR Inputs
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For ARR Calculation',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _annualIncomeController,
                          decoration: const InputDecoration(
                            labelText: 'Annual Net Income',
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
                          controller: _residualValueController,
                          decoration: const InputDecoration(
                            labelText: 'Residual Value',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateAll(),
                        ),
                      ),
                    ],
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
              icon: const Icon(Icons.calculate),
              label: const Text('Calculate & View Results'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTab(ThemeData theme) {
    if (_npvResult == null) {
      return const Center(
        child: Text('Enter investment data in the Calculator tab'),
      );
    }

    final requiredReturn =
        (double.tryParse(_requiredReturnController.text) ?? 10) / 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // NPV Result
          _buildResultCard(
            theme,
            title: 'Net Present Value (NPV)',
            value: '\$${_npvResult!.npv.toStringAsFixed(2)}',
            isGood: _npvResult!.isAcceptable,
            description: _npvResult!.recommendation,
            details: [
              'PV of Cash Flows: \$${_npvResult!.pvOfCashFlows.toStringAsFixed(2)}',
              'Initial Investment: \$${_npvResult!.initialInvestment.toStringAsFixed(0)}',
              'Discount Rate: ${(_npvResult!.discountRate * 100).toStringAsFixed(1)}%',
            ],
          ),
          const SizedBox(height: 16),

          // IRR Result
          _buildResultCard(
            theme,
            title: 'Internal Rate of Return (IRR)',
            value: '${(_irrResult!.irr * 100).toStringAsFixed(2)}%',
            isGood: _irrResult!.isAcceptable(requiredReturn),
            description: _irrResult!.getRecommendation(requiredReturn),
            details: [
              'Converged: ${_irrResult!.converged ? 'Yes' : 'No'}',
              'Iterations: ${_irrResult!.iterations}',
            ],
          ),
          const SizedBox(height: 16),

          // Payback Period
          _buildResultCard(
            theme,
            title: 'Payback Period',
            value: _paybackResult!.formattedPayback,
            isGood: _paybackResult!.recoversInvestment,
            description: _paybackResult!.recoversInvestment
                ? 'Investment will be recovered'
                : 'Investment may not be recovered',
            details: [],
          ),
          const SizedBox(height: 16),

          // Discounted Payback
          _buildResultCard(
            theme,
            title: 'Discounted Payback Period',
            value: _discountedPaybackResult!.formattedPayback,
            isGood: _discountedPaybackResult!.recoversInvestment,
            description: 'Accounts for time value of money',
            details: [],
          ),
          const SizedBox(height: 16),

          // Profitability Index
          _buildResultCard(
            theme,
            title: 'Profitability Index (PI)',
            value: _piResult!.profitabilityIndex.toStringAsFixed(3),
            isGood: _piResult!.isAcceptable,
            description: _piResult!.recommendation,
            details: [
              'PV of Cash Flows: \$${_piResult!.pvOfCashFlows.toStringAsFixed(2)}',
            ],
          ),
          const SizedBox(height: 16),

          // ARR
          if (_arrResult != null)
            _buildResultCard(
              theme,
              title: 'Accounting Rate of Return (ARR)',
              value: _arrResult!.formattedARR,
              isGood: _arrResult!.arr > requiredReturn,
              description:
                  'Average Investment: \$${_arrResult!.averageInvestment.toStringAsFixed(0)}',
              details: [],
            ),
          const SizedBox(height: 24),

          // Decision Summary
          _buildDecisionSummary(theme, requiredReturn),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    ThemeData theme, {
    required String title,
    required String value,
    required bool isGood,
    required String description,
    required List<String> details,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Icon(
                  isGood ? Icons.check_circle : Icons.cancel,
                  color: isGood ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isGood ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyMedium),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...details.map(
                (d) => Text(
                  d,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionSummary(ThemeData theme, double requiredReturn) {
    int acceptCount = 0;
    int rejectCount = 0;

    if (_npvResult!.isAcceptable)
      acceptCount++;
    else
      rejectCount++;
    if (_irrResult!.isAcceptable(requiredReturn))
      acceptCount++;
    else
      rejectCount++;
    if (_piResult!.isAcceptable)
      acceptCount++;
    else
      rejectCount++;
    if (_paybackResult!.recoversInvestment)
      acceptCount++;
    else
      rejectCount++;

    final recommendation = acceptCount > rejectCount ? 'ACCEPT' : 'REJECT';
    final isAccept = acceptCount > rejectCount;

    return Card(
      color: isAccept ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              isAccept ? Icons.thumb_up : Icons.thumb_down,
              size: 48,
              color: isAccept ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'RECOMMENDATION: $recommendation',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isAccept ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$acceptCount of 4 criteria met',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensitivityTab(ThemeData theme) {
    if (_sensitivityPoints == null || _sensitivityPoints!.isEmpty) {
      return const Center(
        child: Text('Enter investment data in the Calculator tab'),
      );
    }

    // Find where NPV crosses zero (IRR)
    final crossingIndex = _sensitivityPoints!.indexWhere((p) => p.npv < 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NPV Sensitivity to Discount Rate',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Shows how NPV changes as the discount rate varies',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Sensitivity Table
          Card(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Discount Rate')),
                DataColumn(label: Text('NPV'), numeric: true),
                DataColumn(label: Text('Decision')),
              ],
              rows: _sensitivityPoints!.map((point) {
                final isPositive = point.npv > 0;
                return DataRow(
                  cells: [
                    DataCell(
                      Text('${(point.discountRate * 100).toStringAsFixed(0)}%'),
                    ),
                    DataCell(
                      Text(
                        '\$${point.npv.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
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
                          color: isPositive
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPositive ? 'Accept' : 'Reject',
                          style: TextStyle(
                            color: isPositive
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Key insight
          if (crossingIndex > 0) ...[
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'The IRR (where NPV = 0) is approximately ${(_sensitivityPoints![crossingIndex - 1].discountRate * 100).toStringAsFixed(0)}% - ${(_sensitivityPoints![crossingIndex].discountRate * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
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

  void _addCashFlow() {
    setState(() {
      _cashFlowControllers.add(TextEditingController(text: '0'));
    });
  }

  void _removeCashFlow() {
    if (_cashFlowControllers.length > 1) {
      setState(() {
        _cashFlowControllers.removeLast().dispose();
        _calculateAll();
      });
    }
  }
}
