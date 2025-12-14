import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import '../data/reports_service.dart';

/// 📊 Statement of Cash Flows Screen (Indirect Method)
/// Shows cash flows from Operating, Investing, and Financing activities.
class CashFlowScreen extends ConsumerStatefulWidget {
  const CashFlowScreen({super.key});

  @override
  ConsumerState<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends ConsumerState<CashFlowScreen> {
  late DateTimeRange _dateRange;
  bool _isLoading = true;
  CashFlowData _data = CashFlowData.empty();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, 1, 1),
      end: DateTime(now.year, 12, 31),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final reportsService = ref.read(reportsServiceProvider);
      final db = ref.read(appDatabaseProvider);

      // Get P&L data for net income
      final pnl = await reportsService.watchProfitAndLoss(_dateRange).first;
      final netIncome = pnl.netIncome;

      // Get cash account balances - fetch all asset accounts and filter in memory
      final allAssets = await (db.select(
        db.accounts,
      )..where((a) => a.type.equals('Asset'))).get();

      final cashAccounts = allAssets
          .where(
            (a) =>
                a.name.toLowerCase().contains('cash') ||
                a.name.toLowerCase().contains('bank'),
          )
          .toList();

      double beginningCash = 0;
      double endingCash = 0;

      for (final acc in cashAccounts) {
        beginningCash += acc.initialBalance / 100;
        // Calculate ending balance from transactions
        final entries = await (db.select(
          db.transactionEntries,
        )..where((e) => e.accountId.equals(acc.id))).get();
        double balance = acc.initialBalance / 100;
        for (final entry in entries) {
          balance += entry.amount / 100;
        }
        endingCash += balance;
      }

      final netChange = endingCash - beginningCash;

      // Build operating adjustments (simplified - depreciation, etc.)
      final operatingAdjustments = <CashFlowLine>[];

      // Add depreciation add-back
      final depreciationExpense = await _getDepreciationExpense(db);
      if (depreciationExpense > 0) {
        operatingAdjustments.add(
          CashFlowLine(
            description: 'Add: Depreciation Expense',
            amount: depreciationExpense,
            category: 'operating',
          ),
        );
      }

      // Get changes in AR/AP (simplified)
      final arApChanges = await _getWorkingCapitalChanges(db);
      operatingAdjustments.addAll(arApChanges);

      final netOperating =
          netIncome +
          depreciationExpense +
          arApChanges.fold<double>(0, (sum, line) => sum + line.amount);

      // Investing activities (asset purchases, etc.)
      final investingActivities = await _getInvestingActivities(db);
      final netInvesting = investingActivities.fold<double>(
        0,
        (sum, line) => sum + line.amount,
      );

      // Financing activities (loans, equity, etc.)
      final financingActivities = await _getFinancingActivities(db);
      final netFinancing = financingActivities.fold<double>(
        0,
        (sum, line) => sum + line.amount,
      );

      setState(() {
        _data = CashFlowData(
          netIncome: netIncome,
          operatingAdjustments: operatingAdjustments,
          netCashFromOperating: netOperating,
          investingActivities: investingActivities,
          netCashFromInvesting: netInvesting,
          financingActivities: financingActivities,
          netCashFromFinancing: netFinancing,
          netChangeInCash: netChange,
          beginningCash: beginningCash,
          endingCash: endingCash,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<double> _getDepreciationExpense(AppDatabase db) async {
    // Sum depreciation from fixed assets
    final assets = await db.select(db.fixedAssets).get();
    double total = 0;
    for (final asset in assets) {
      total += asset.currentPeriodDepreciation / 100;
    }
    return total;
  }

  Future<List<CashFlowLine>> _getWorkingCapitalChanges(AppDatabase db) async {
    final lines = <CashFlowLine>[];

    // Get AR changes from customers
    final customers = await db.select(db.customers).get();
    double arChange = 0;
    for (final c in customers) {
      arChange -= c.balance / 100; // Increase in AR reduces cash
    }
    if (arChange != 0) {
      lines.add(
        CashFlowLine(
          description: arChange > 0
              ? 'Decrease in Accounts Receivable'
              : 'Increase in Accounts Receivable',
          amount: arChange.abs() * (arChange > 0 ? 1 : -1),
          category: 'operating',
        ),
      );
    }

    // Get AP changes from vendors
    final vendors = await db.select(db.vendors).get();
    double apChange = 0;
    for (final v in vendors) {
      apChange += v.balance / 100; // Increase in AP adds cash
    }
    if (apChange != 0) {
      lines.add(
        CashFlowLine(
          description: apChange > 0
              ? 'Increase in Accounts Payable'
              : 'Decrease in Accounts Payable',
          amount: apChange.abs() * (apChange > 0 ? 1 : -1),
          category: 'operating',
        ),
      );
    }

    return lines;
  }

  Future<List<CashFlowLine>> _getInvestingActivities(AppDatabase db) async {
    final lines = <CashFlowLine>[];

    // Get fixed asset purchases
    final assets = await db.select(db.fixedAssets).get();
    double assetPurchases = 0;
    for (final asset in assets) {
      assetPurchases += asset.acquisitionCost / 100;
    }
    if (assetPurchases > 0) {
      lines.add(
        CashFlowLine(
          description: 'Purchase of Fixed Assets',
          amount: -assetPurchases,
          category: 'investing',
        ),
      );
    }

    return lines;
  }

  Future<List<CashFlowLine>> _getFinancingActivities(AppDatabase db) async {
    // Placeholder - would track loans, equity changes
    return [];
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statement of Cash Flows'),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text('${_dateRange.start.year}'),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'For the Year Ended ${_dateRange.end.day}/${_dateRange.end.month}/${_dateRange.end.year}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Operating Activities Section
                  _SectionHeader(
                    title: 'Cash Flows from Operating Activities',
                    color: Colors.blue,
                  ),
                  _CashFlowRow(
                    label: 'Net Income',
                    amount: _data.netIncome,
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adjustments to reconcile net income:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  ..._data.operatingAdjustments.map(
                    (line) => _CashFlowRow(
                      label: line.description,
                      amount: line.amount,
                    ),
                  ),
                  const Divider(),
                  _CashFlowRow(
                    label: 'Net Cash from Operating',
                    amount: _data.netCashFromOperating,
                    isBold: true,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),

                  // Investing Activities Section
                  _SectionHeader(
                    title: 'Cash Flows from Investing Activities',
                    color: Colors.orange,
                  ),
                  if (_data.investingActivities.isEmpty)
                    _CashFlowRow(label: 'No investing activities', amount: 0)
                  else
                    ..._data.investingActivities.map(
                      (line) => _CashFlowRow(
                        label: line.description,
                        amount: line.amount,
                      ),
                    ),
                  const Divider(),
                  _CashFlowRow(
                    label: 'Net Cash from Investing',
                    amount: _data.netCashFromInvesting,
                    isBold: true,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),

                  // Financing Activities Section
                  _SectionHeader(
                    title: 'Cash Flows from Financing Activities',
                    color: Colors.purple,
                  ),
                  if (_data.financingActivities.isEmpty)
                    _CashFlowRow(label: 'No financing activities', amount: 0)
                  else
                    ..._data.financingActivities.map(
                      (line) => _CashFlowRow(
                        label: line.description,
                        amount: line.amount,
                      ),
                    ),
                  const Divider(),
                  _CashFlowRow(
                    label: 'Net Cash from Financing',
                    amount: _data.netCashFromFinancing,
                    isBold: true,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 24),

                  // Summary Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _CashFlowRow(
                          label: 'Net Change in Cash',
                          amount: _data.netChangeInCash,
                          isBold: true,
                        ),
                        _CashFlowRow(
                          label: 'Beginning Cash Balance',
                          amount: _data.beginningCash,
                        ),
                        const Divider(),
                        _CashFlowRow(
                          label: 'Ending Cash Balance',
                          amount: _data.endingCash,
                          isBold: true,
                          isLarge: true,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _CashFlowRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;
  final bool isLarge;
  final Color? color;

  const _CashFlowRow({
    required this.label,
    required this.amount,
    this.isBold = false,
    this.isLarge = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNegative = amount < 0;
    final displayColor = color ?? (isNegative ? Colors.red : null);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isLarge ? 8 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  (isLarge
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(fontWeight: isBold ? FontWeight.bold : null),
            ),
          ),
          Text(
            '${isNegative ? "-" : ""}\$${amount.abs().toStringAsFixed(2)}',
            style:
                (isLarge
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(
                      fontWeight: isBold ? FontWeight.bold : null,
                      color: displayColor,
                    ),
          ),
        ],
      ),
    );
  }
}
