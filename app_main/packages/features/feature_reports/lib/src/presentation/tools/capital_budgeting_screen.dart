// FILE: packages/features/feature_reports/lib/src/presentation/tools/capital_budgeting_screen.dart
// Purpose: Capital Budgeting Calculator for investment analysis

import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
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
    // ignore: unused_local_variable
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.capitalBudgeting),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.calculatorTab, icon: Icon(Icons.calculate)),
            Tab(text: l10n.resultsTab, icon: Icon(Icons.analytics)),
            Tab(text: l10n.sensitivityTab, icon: Icon(Icons.show_chart)),
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
    final l10n = AppLocalizations.of(context)!;
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
                    l10n.initialInvestment,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _investmentController,
                    decoration: InputDecoration(
                      labelText: l10n.investmentAmount,
                      prefixText: '\$ ',
                      border: const OutlineInputBorder(),
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
                  Text(l10n.discountRateLabel, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _discountRateController,
                          decoration: InputDecoration(
                            labelText: l10n.rateLabel,
                            suffixText: '%',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateAll(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _requiredReturnController,
                          decoration: InputDecoration(
                            labelText: l10n.requiredReturn,
                            suffixText: '%',
                            border: const OutlineInputBorder(),
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
                        l10n.expectedCashFlows,
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
                    l10n.forArrCalculation,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _annualIncomeController,
                          decoration: InputDecoration(
                            labelText: l10n.annualNetIncome,
                            prefixText: '\$ ',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateAll(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _residualValueController,
                          decoration: InputDecoration(
                            labelText: l10n.residualValueLabel,
                            prefixText: '\$ ',
                            border: const OutlineInputBorder(),
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
              label: Text(l10n.calculateViewResults),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTab(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    if (_npvResult == null) {
      return Center(
        child: Text(l10n.enterDataCalculator),
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
            title: l10n.netPresentValue,
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
            title: l10n.internalRateOfReturn,
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
            title: l10n.paybackPeriod,
            value: _paybackResult!.formattedPayback,
            isGood: _paybackResult!.recoversInvestment,
            description: _paybackResult!.recoversInvestment
                ? l10n.investmentRecovered
                : l10n.investmentMayNotRecover,
            details: [],
          ),
          const SizedBox(height: 16),

          // Discounted Payback
          _buildResultCard(
            theme,
            title: l10n.discountedPaybackPeriod,
            value: _discountedPaybackResult!.formattedPayback,
            isGood: _discountedPaybackResult!.recoversInvestment,
            description: l10n.accountsForTimeValue,
            details: [],
          ),
          const SizedBox(height: 16),

          // Profitability Index
          _buildResultCard(
            theme,
            title: l10n.profitabilityIndex,
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
              title: l10n.accountingRateOfReturn,
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
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isGood ? Icons.check_circle : Icons.cancel,
                  color: isGood ? context.appColors.success : context.appColors.error,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isGood ? context.appColors.success : context.appColors.error,
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
      color: isAccept ? context.appColors.success.withValues(alpha: 0.1) : context.appColors.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              isAccept ? Icons.thumb_up : Icons.thumb_down,
              size: 48,
              color: isAccept ? context.appColors.success : context.appColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'RECOMMENDATION: $recommendation',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isAccept ? context.appColors.success : context.appColors.error,
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
    final l10n = AppLocalizations.of(context)!;
    if (_sensitivityPoints == null || _sensitivityPoints!.isEmpty) {
      return Center(
        child: Text(l10n.enterDataCalculator),
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
            l10n.npvSensitivity,
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(l10n.discountRateColumn)),
                  DataColumn(label: Text(l10n.npvColumn), numeric: true),
                  DataColumn(label: Text(l10n.decisionColumn)),
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
                            color: isPositive ? context.appColors.success : context.appColors.error,
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
                                ? context.appColors.success.withValues(alpha: 0.15)
                                : context.appColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isPositive ? l10n.acceptDecision : l10n.rejectDecision,
                            style: TextStyle(
                              color: isPositive
                                  ? context.appColors.success
                                  : context.appColors.error,
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