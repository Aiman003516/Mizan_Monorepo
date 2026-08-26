import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_accounts/feature_accounts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

import '../data/budget_repository.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _fixedCostController = TextEditingController();
  final _variableRateController = TextEditingController();
  final _plannedActivityController = TextEditingController();
  final _actualActivityController = TextEditingController();
  final _actualCostController = TextEditingController();
  FlexibleBudgetResult? _flexibleBudgetResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    final fixedCost = CurrencyFormatter.doubleToCents(
      double.tryParse(_fixedCostController.text) ?? 0,
    );
    final variableRate = CurrencyFormatter.doubleToCents(
      double.tryParse(_variableRateController.text) ?? 0,
    );
    final plannedActivity = int.tryParse(_plannedActivityController.text) ?? 0;
    final actualActivity = int.tryParse(_actualActivityController.text) ?? 0;
    final actualCost = CurrencyFormatter.doubleToCents(
      double.tryParse(_actualCostController.text) ?? 0,
    );
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

  String _formatCurrency(int cents, String currencyCode) {
    return CurrencyFormatter.formatAmount(cents, currencyCode);
  }

  Future<void> _addBudget() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const _BudgetEditorDialog(),
    );
    if (saved != true || !mounted) return;
    ref.invalidate(budgetSummariesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.budgetSaved)),
    );
  }

  Future<void> _deleteBudget(BudgetReportSummary summary) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteLabel),
        content: Text(summary.budget.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.deleteLabel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(budgetRepositoryProvider).deleteBudget(summary.budget.id);
    ref.invalidate(budgetSummariesProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.budgetDeleted)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.budgetAnalysis),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.summaryTab),
            Tab(text: l10n.variancesTab),
            Tab(text: l10n.flexibleBudgetTab),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBudget,
        icon: const Icon(Icons.add),
        label: Text(l10n.addBudget),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildVariancesTab(),
          _buildFlexibleBudgetTab(),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    final l10n = AppLocalizations.of(context)!;
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final budgetsAsync = ref.watch(budgetSummariesProvider);
    return budgetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l10n.errorLoadingData)),
      data: (summaries) {
        if (summaries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.noBudgets, textAlign: TextAlign.center),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: summaries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final summary = summaries[index];
            return _buildBudgetCard(summary, currencyCode);
          },
        );
      },
    );
  }

  Widget _buildBudgetCard(BudgetReportSummary summary, String currencyCode) {
    final l10n = AppLocalizations.of(context)!;
    final budget = summary.budget;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    budget.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') _deleteBudget(summary);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.deleteLabel),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '${MaterialLocalizations.of(context).formatMediumDate(budget.startDate)} – '
              '${MaterialLocalizations.of(context).formatMediumDate(budget.endDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Metric(
                  label: l10n.budgetedNetIncome,
                  value: _formatCurrency(
                    summary.budgetedNetIncome,
                    currencyCode,
                  ),
                  color: colorScheme.primary,
                ),
                _Metric(
                  label: l10n.actualNetIncome,
                  value: _formatCurrency(summary.actualNetIncome, currencyCode),
                  color: colorScheme.tertiary,
                ),
                _Metric(
                  label: l10n.netIncomeVariance,
                  value: _formatCurrency(
                    summary.netIncomeVariance,
                    currencyCode,
                  ),
                  color: summary.netIncomeVariance >= 0
                      ? colorScheme.tertiary
                      : colorScheme.error,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              label: l10n.revenueLabel,
              budgeted: _formatCurrency(summary.budgetedRevenue, currencyCode),
              actual: _formatCurrency(summary.actualRevenue, currencyCode),
            ),
            _SummaryRow(
              label: l10n.expensesLabel,
              budgeted: _formatCurrency(summary.budgetedExpenses, currencyCode),
              actual: _formatCurrency(summary.actualExpenses, currencyCode),
            ),
            if (summary.lines.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(l10n.noTransactionEntries),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariancesTab() {
    final l10n = AppLocalizations.of(context)!;
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final budgetsAsync = ref.watch(budgetSummariesProvider);
    return budgetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l10n.errorLoadingData)),
      data: (summaries) {
        if (summaries.isEmpty) return Center(child: Text(l10n.noBudgets));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(
              l10n.budgetVsActual,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(l10n.greenFavorable),
            const SizedBox(height: 16),
            for (final summary in summaries) ...[
              Text(
                summary.budget.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (summary.lines.isEmpty) Text(l10n.noTransactionEntries),
              for (final line in summary.lines)
                Card(
                  child: ListTile(
                    title: Text(line.account.name),
                    subtitle: Text(
                      '${l10n.budgetedLabel}: ${_formatCurrency(line.line.budgetedAmount, currencyCode)}\n'
                      '${l10n.actualLabel}: ${_formatCurrency(line.actualAmount, currencyCode)}',
                    ),
                    trailing: Text(
                      '${line.variance >= 0 ? '+' : ''}${_formatCurrency(line.variance, currencyCode)}',
                      style: TextStyle(
                        color: line.isFavorable
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFlexibleBudgetTab() {
    final l10n = AppLocalizations.of(context)!;
    final currencyCode = ref.watch(defaultCurrencyProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text(
          l10n.flexibleBudgetAnalysis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(l10n.flexibleBudgetResult),
        const SizedBox(height: 16),
        _amountField(_fixedCostController, l10n.fixedCosts),
        _amountField(_variableRateController, l10n.variableRateUnit),
        _numberField(_plannedActivityController, l10n.plannedActivity),
        _numberField(_actualActivityController, l10n.actualActivity),
        _amountField(_actualCostController, l10n.actualCost),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _calculateFlexibleBudget,
          icon: const Icon(Icons.calculate_outlined),
          label: Text(l10n.calculate),
        ),
        if (_flexibleBudgetResult != null) ...[
          const SizedBox(height: 16),
          _ResultRow(
            l10n.staticBudget,
            _formatCurrency(_flexibleBudgetResult!.staticBudget, currencyCode),
          ),
          _ResultRow(
            l10n.flexibleBudgetResult,
            _formatCurrency(
              _flexibleBudgetResult!.flexibleBudget,
              currencyCode,
            ),
          ),
          _ResultRow(
            l10n.actualTotalCost,
            _formatCurrency(_flexibleBudgetResult!.actualAmount, currencyCode),
          ),
          _ResultRow(
            l10n.volumeVariance,
            _formatCurrency(
              _flexibleBudgetResult!.volumeVariance,
              currencyCode,
            ),
          ),
          _ResultRow(
            l10n.spendingVariance,
            _formatCurrency(
              _flexibleBudgetResult!.spendingVariance,
              currencyCode,
            ),
          ),
          _ResultRow(
            l10n.totalVariance,
            _formatCurrency(_flexibleBudgetResult!.totalVariance, currencyCode),
          ),
        ],
      ],
    );
  }

  Widget _amountField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 260),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.budgeted,
    required this.actual,
  });
  final String label;
  final String budgeted;
  final String actual;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(budgeted, textDirection: TextDirection.ltr),
          const SizedBox(width: 12),
          Text(actual, textDirection: TextDirection.ltr),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(value, textDirection: TextDirection.ltr),
    );
  }
}

class _BudgetEditorDialog extends ConsumerStatefulWidget {
  const _BudgetEditorDialog();

  @override
  ConsumerState<_BudgetEditorDialog> createState() =>
      _BudgetEditorDialogState();
}

class _DraftLine {
  _DraftLine();
  Account? account;
  final amountController = TextEditingController();

  void dispose() => amountController.dispose();
}

class _BudgetEditorDialogState extends ConsumerState<_BudgetEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  final _lines = <_DraftLine>[];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _lines.add(_DraftLine());
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: start ? _startDate : _endDate,
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        _startDate = selected;
      } else {
        _endDate = selected;
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final drafts = <BudgetLineDraft>[];
    for (final line in _lines) {
      final amount = double.tryParse(line.amountController.text.trim());
      if (line.account == null || amount == null || amount < 0) {
        setState(() => _error = AppLocalizations.of(context)!.invalidAmount);
        return;
      }
      drafts.add(
        BudgetLineDraft(
          accountId: line.account!.id,
          budgetedAmount: CurrencyFormatter.doubleToCents(amount),
        ),
      );
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(budgetRepositoryProvider)
          .createBudget(
            name: _nameController.text,
            periodType: 'custom',
            startDate: _startDate,
            endDate: _endDate,
            status: 'draft',
            budgetType: 'static',
            lines: drafts,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!.errorLoadingData);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(accountsStreamProvider);
    return AlertDialog(
      title: Text(l10n.addBudget),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.budgetName),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.nameIsRequired
                      : null,
                ),
                const SizedBox(height: 12),
                _DateButton(
                  label: l10n.periodStartDate,
                  date: _startDate,
                  onPressed: () => _pickDate(start: true),
                ),
                _DateButton(
                  label: l10n.periodEndDate,
                  date: _endDate,
                  onPressed: () => _pickDate(start: false),
                ),
                const SizedBox(height: 8),
                accountsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => Text(l10n.errorLoadingAccounts),
                  data: (accounts) {
                    final usable = accounts
                        .where(
                          (account) =>
                              (account.type.toLowerCase() == 'revenue' ||
                                  account.type.toLowerCase() == 'expense') &&
                              !account.isHeader,
                        )
                        .toList();
                    return Column(
                      children: [
                        for (final line in _lines)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<Account>(
                                    initialValue: usable.contains(line.account)
                                        ? line.account
                                        : null,
                                    decoration: InputDecoration(
                                      labelText: l10n.budgetLineAccount,
                                      border: const OutlineInputBorder(),
                                    ),
                                    items: usable
                                        .map(
                                          (account) => DropdownMenuItem(
                                            value: account,
                                            child: Text(
                                              account.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => line.account = value),
                                    validator: (value) => value == null
                                        ? l10n.requiredField
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 125,
                                  child: TextFormField(
                                    controller: line.amountController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: InputDecoration(
                                      labelText: l10n.plannedAmount,
                                      border: const OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      final amount = double.tryParse(
                                        value ?? '',
                                      );
                                      return amount == null || amount < 0
                                          ? l10n.invalidAmount
                                          : null;
                                    },
                                  ),
                                ),
                                if (_lines.length > 1)
                                  IconButton(
                                    onPressed: () => setState(() {
                                      line.dispose();
                                      _lines.remove(line);
                                    }),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: usable.isEmpty
                                ? null
                                : () =>
                                      setState(() => _lines.add(_DraftLine())),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.addLineItem),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onPressed,
  });
  final String label;
  final DateTime date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(MaterialLocalizations.of(context).formatMediumDate(date)),
      trailing: const Icon(Icons.calendar_today_outlined),
      onTap: onPressed,
    );
  }
}
