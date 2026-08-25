// Fixed Assets Dashboard Screen - Comprehensive view with metrics and visualizations
import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feature_settings/src/data/fixed_assets_repository.dart';
import 'package:core_data/core_data.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:intl/intl.dart';

class FixedAssetsScreen extends ConsumerStatefulWidget {
  const FixedAssetsScreen({super.key});

  @override
  ConsumerState<FixedAssetsScreen> createState() => _FixedAssetsScreenState();
}

class _FixedAssetsScreenState extends ConsumerState<FixedAssetsScreen>
    with SingleTickerProviderStateMixin {
  final _dateFormat = DateFormat('MMM d, yyyy');
  late TabController _tabController;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  String _formatCurrency(int amountInCents) {
    final currencyCode = ref.read(defaultCurrencyProvider);
    final symbol = CurrencySymbols.forCode(currencyCode);
    return NumberFormat.currency(
      symbol: '$symbol ',
      decimalDigits: 2,
    ).format(amountInCents / 100);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'DISPOSED':
        return Colors.grey;
      case 'FULLY_DEPRECIATED':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return l10n.activeLabel;
      case 'DISPOSED':
        return l10n.disposedLabel;
      case 'FULLY_DEPRECIATED':
        return l10n.fullDeprLabel;
      default:
        return status;
    }
  }

  String _getMethodLabel(String method) {
    switch (method) {
      case 'STRAIGHT_LINE':
        return l10n.straightLine;
      case 'DECLINING_BALANCE':
        return l10n.decliningBalance;
      case 'UNITS_OF_ACTIVITY':
        return l10n.unitsOfActivity;
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(defaultCurrencyProvider);
    final assetsAsync = ref.watch(fixedAssetsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fixedAssetsTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.allAssetsTab),
            Tab(text: l10n.byCategoryTab),
            Tab(text: l10n.scheduleTab),
          ],
        ),
      ),
      body: assetsAsync.when(
        data: (assets) => _buildDashboard(assets),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.errorLoadingData)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAssetDialog,
        icon: const Icon(Icons.add),
        label: Text(l10n.addAsset),
      ),
    );
  }

  Widget _buildDashboard(List<FixedAsset> assets) {
    // Calculate summary metrics
    int totalCost = 0;
    int totalDepreciation = 0;
    int activeCount = 0;
    int disposedCount = 0;
    int fullyDepreciatedCount = 0;

    for (final asset in assets) {
      totalCost += asset.acquisitionCost;
      totalDepreciation += asset.totalDepreciation;
      switch (asset.status) {
        case 'ACTIVE':
          activeCount++;
          break;
        case 'DISPOSED':
          disposedCount++;
          break;
        case 'FULLY_DEPRECIATED':
          fullyDepreciatedCount++;
          break;
      }
    }

    final netBookValue = totalCost - totalDepreciation;
    final depreciationPercent = totalCost > 0
        ? (totalDepreciation / totalCost * 100)
        : 0.0;

    return Column(
      children: [
        // Summary Cards Section
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main Value Card
              _buildMainValueCard(
                totalCost,
                netBookValue,
                totalDepreciation,
                depreciationPercent,
              ),
              const SizedBox(height: 12),
              // Status Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      l10n.activeLabel,
                      activeCount,
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusCard(
                      l10n.fullDeprLabel,
                      fullyDepreciatedCount,
                      Colors.orange,
                      Icons.pending,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusCard(
                      l10n.disposedLabel,
                      disposedCount,
                      Colors.grey,
                      Icons.cancel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAssetsList(assets),
              _buildCategoryView(assets),
              _buildScheduleView(assets),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainValueCard(
    int totalCost,
    int netBookValue,
    int totalDepreciation,
    double depreciationPercent,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.netBookValueLabel,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(netBookValue),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: Colors.blue[700],
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: depreciationPercent / 100,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  depreciationPercent > 80 ? Colors.orange : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniStat(l10n.totalCostLabel, _formatCurrency(totalCost)),
                _buildMiniStat(
                  l10n.depreciatedLabel,
                  _formatCurrency(totalDepreciation),
                ),
                _buildMiniStat(
                  l10n.progressLabel,
                  '${depreciationPercent.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
      ],
    );
  }

  Widget _buildStatusCard(String label, int count, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsList(List<FixedAsset> assets) {
    if (assets.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        return _buildAssetCard(asset);
      },
    );
  }

  Widget _buildAssetCard(FixedAsset asset) {
    final bookValue = asset.acquisitionCost - asset.totalDepreciation;
    final depreciableBase = asset.acquisitionCost - asset.salvageValue;
    final depreciationPercent = depreciableBase > 0
        ? (asset.totalDepreciation / depreciableBase * 100).clamp(0, 100)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAssetDetails(asset),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        asset.status,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.business,
                      color: _getStatusColor(asset.status),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _getMethodLabel(asset.depreciationMethod),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(bookValue),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        l10n.bookValueLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: depreciationPercent / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    depreciationPercent >= 100
                        ? Colors.orange
                        : _getStatusColor(asset.status),
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.percentDepreciated(
                      depreciationPercent.toStringAsFixed(0),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Chip(
                    label: Text(
                      _getStatusLabel(asset.status),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getStatusColor(asset.status),
                      ),
                    ),
                    backgroundColor: _getStatusColor(
                      asset.status,
                    ).withValues(alpha: 0.1),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryView(List<FixedAsset> assets) {
    // Group by depreciation method
    final groupedByMethod = <String, List<FixedAsset>>{};
    for (final asset in assets) {
      groupedByMethod
          .putIfAbsent(asset.depreciationMethod, () => [])
          .add(asset);
    }

    if (groupedByMethod.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: groupedByMethod.entries.map((entry) {
        final method = entry.key;
        final methodAssets = entry.value;
        int methodTotal = 0;
        for (final asset in methodAssets) {
          methodTotal += asset.acquisitionCost - asset.totalDepreciation;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              child: Text(
                methodAssets.length.toString(),
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(_getMethodLabel(method)),
            subtitle: Text(
              '${l10n.bookValueLabel}: ${_formatCurrency(methodTotal)}',
            ),
            children: methodAssets.map((asset) {
              return ListTile(
                title: Text(asset.name),
                trailing: Text(
                  _formatCurrency(
                    asset.acquisitionCost - asset.totalDepreciation,
                  ),
                ),
                onTap: () => _showAssetDetails(asset),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScheduleView(List<FixedAsset> assets) {
    // Filter active assets only
    final activeAssets = assets.where((a) => a.status == 'ACTIVE').toList();

    if (activeAssets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.noScheduledDepreciation,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Sort by acquisition date
    activeAssets.sort((a, b) => a.acquisitionDate.compareTo(b.acquisitionDate));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeAssets.length,
      itemBuilder: (context, index) {
        final asset = activeAssets[index];
        final monthlyDepreciation = _calculateMonthlyDepreciation(asset);
        final monthsRemaining = _calculateMonthsRemaining(asset);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withValues(alpha: 0.1),
              child: const Icon(Icons.schedule, color: Colors.green),
            ),
            title: Text(asset.name),
            subtitle: Text(
              l10n.monthlyDepreciationInfo(
                _formatCurrency(monthlyDepreciation),
                monthsRemaining,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(
                    asset.acquisitionCost - asset.totalDepreciation,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  l10n.bookValueLabel,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            onTap: () => _showAssetDetails(asset),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.noFixedAssets,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addFixedAssetsDescription,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  int _calculateMonthlyDepreciation(FixedAsset asset) {
    final depreciableBase = asset.acquisitionCost - asset.salvageValue;
    if (asset.depreciationMethod == 'STRAIGHT_LINE') {
      return (depreciableBase / asset.usefulLifeMonths).round();
    } else if (asset.depreciationMethod == 'DECLINING_BALANCE') {
      final bookValue = asset.acquisitionCost - asset.totalDepreciation;
      final rate =
          (asset.decliningBalanceRate ?? 2.0) / (asset.usefulLifeMonths / 12);
      return ((bookValue * rate) / 12).round();
    }
    return 0;
  }

  int _calculateMonthsRemaining(FixedAsset asset) {
    final monthsElapsed =
        DateTime.now().difference(asset.acquisitionDate).inDays ~/ 30;
    return (asset.usefulLifeMonths - monthsElapsed).clamp(
      0,
      asset.usefulLifeMonths,
    );
  }

  void _showAssetDetails(FixedAsset asset) {
    final bookValue = asset.acquisitionCost - asset.totalDepreciation;
    final depreciableBase = asset.acquisitionCost - asset.salvageValue;
    final depreciationPercent = depreciableBase > 0
        ? (asset.totalDepreciation / depreciableBase * 100).clamp(0, 100)
        : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      asset.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Chip(
                    label: Text(_getStatusLabel(asset.status)),
                    backgroundColor: _getStatusColor(
                      asset.status,
                    ).withValues(alpha: 0.2),
                    labelStyle: TextStyle(color: _getStatusColor(asset.status)),
                  ),
                ],
              ),
              if (asset.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  asset.description!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
              const Divider(height: 32),

              // Depreciation Progress
              Text(
                l10n.progressLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: depreciationPercent / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  depreciationPercent >= 100 ? Colors.orange : Colors.blue,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.percentDepreciated(depreciationPercent.toStringAsFixed(1)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),

              // Value Details
              _buildDetailCard(context, l10n.valueInformationTitle, [
                _buildDetailRow(
                  l10n.acquisitionCostLabel,
                  _formatCurrency(asset.acquisitionCost),
                ),
                _buildDetailRow(
                  l10n.salvageValueLabel,
                  _formatCurrency(asset.salvageValue),
                ),
                _buildDetailRow(
                  l10n.accumulatedDepreciationLabel,
                  _formatCurrency(asset.totalDepreciation),
                ),
                _buildDetailRow(
                  l10n.netBookValueLabel,
                  _formatCurrency(bookValue),
                  highlight: true,
                ),
              ]),
              const SizedBox(height: 16),

              // Depreciation Details
              _buildDetailCard(context, l10n.depreciationSettingsTitle, [
                _buildDetailRow(
                  l10n.methodLabel,
                  _getMethodLabel(asset.depreciationMethod),
                ),
                _buildDetailRow(
                  l10n.usefulLifeLabel,
                  l10n.usefulLifeMonths(asset.usefulLifeMonths),
                ),
                _buildDetailRow(
                  l10n.addAssetAcquisitionDate,
                  _dateFormat.format(asset.acquisitionDate),
                ),
                if (asset.currentPeriodDepreciation > 0)
                  _buildDetailRow(
                    l10n.currentPeriodLabel,
                    _formatCurrency(asset.currentPeriodDepreciation),
                  ),
              ]),
              const SizedBox(height: 24),

              // Action Buttons
              if (asset.status == 'ACTIVE') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _runDepreciation(asset),
                        icon: const Icon(Icons.calculate),
                        label: Text(l10n.runDepreciationButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _disposeAsset(asset),
                        icon: const Icon(Icons.sell),
                        label: Text(l10n.disposeButton),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? Colors.blue : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runDepreciation(FixedAsset asset) async {
    Navigator.pop(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run Depreciation'),
        content: Text('Calculate and record depreciation for "${asset.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Run Depreciation'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final depreciationService = ref.read(depreciationServiceProvider);
        final result = await depreciationService.processDepreciation(
          assetId: asset.id,
          periodEndDate: DateTime.now(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.depreciationRecordedFor(
                  _formatCurrency(result.annualDepreciation),
                  asset.name,
                ),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.errorLoadingData)));
        }
      }
    }
  }

  Future<void> _disposeAsset(FixedAsset asset) async {
    Navigator.pop(context);

    final disposalDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: asset.acquisitionDate,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: l10n.assetDisposalDate,
    );
    if (disposalDate == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.disposeAssetTitle),
        content: Text(l10n.disposeAssetMessage(asset.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.disposeButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(fixedAssetsRepositoryProvider)
          .updateAsset(
            asset.copyWith(
              disposalDate: Value(disposalDate),
              status: 'DISPOSED',
              lastUpdated: DateTime.now(),
            ),
          );
      ref.invalidate(fixedAssetsStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.assetDisposedSuccess)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorLoadingData)));
      }
    }
  }

  Future<void> _showAddAssetDialog() async {
    final db = ref.read(appDatabaseProvider);
    final accounts =
        await (db.select(db.accounts)
              ..where((table) => table.isDeleted.equals(false))
              ..orderBy([(table) => OrderingTerm.asc(table.name)]))
            .get();
    if (!mounted) return;

    final draft = await showDialog<_AssetDraft>(
      context: context,
      builder: (context) => _AssetFormDialog(accounts: accounts),
    );
    if (draft == null || !mounted) return;

    try {
      await ref
          .read(fixedAssetsRepositoryProvider)
          .createAsset(
            name: draft.name,
            description: draft.description,
            assetAccountId: draft.assetAccountId,
            accumulatedDepreciationAccountId:
                draft.accumulatedDepreciationAccountId,
            depreciationExpenseAccountId: draft.depreciationExpenseAccountId,
            acquisitionCost: draft.acquisitionCost,
            salvageValue: draft.salvageValue,
            acquisitionDate: draft.acquisitionDate,
            usefulLifeMonths: draft.usefulLifeMonths,
            depreciationMethod: draft.depreciationMethod,
            decliningBalanceRate: draft.decliningBalanceRate,
            usefulLifeUnits: draft.usefulLifeUnits,
          );
      ref.invalidate(fixedAssetsStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.assetSavedSuccess)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorLoadingData)));
      }
    }
  }
}

class _AssetDraft {
  const _AssetDraft({
    required this.name,
    required this.description,
    required this.assetAccountId,
    required this.accumulatedDepreciationAccountId,
    required this.depreciationExpenseAccountId,
    required this.acquisitionCost,
    required this.salvageValue,
    required this.acquisitionDate,
    required this.usefulLifeMonths,
    required this.depreciationMethod,
    this.decliningBalanceRate,
    this.usefulLifeUnits,
  });

  final String name;
  final String? description;
  final String assetAccountId;
  final String accumulatedDepreciationAccountId;
  final String depreciationExpenseAccountId;
  final int acquisitionCost;
  final int salvageValue;
  final DateTime acquisitionDate;
  final int usefulLifeMonths;
  final String depreciationMethod;
  final double? decliningBalanceRate;
  final int? usefulLifeUnits;
}

class _AssetFormDialog extends StatefulWidget {
  const _AssetFormDialog({required this.accounts});

  final List<Account> accounts;

  @override
  State<_AssetFormDialog> createState() => _AssetFormDialogState();
}

class _AssetFormDialogState extends State<_AssetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _salvageController = TextEditingController(text: '0');
  final _usefulLifeController = TextEditingController(text: '60');
  final _decliningRateController = TextEditingController(text: '2');
  final _usefulLifeUnitsController = TextEditingController();

  late String? _assetAccountId;
  late String? _accumulatedDepreciationAccountId;
  late String? _depreciationExpenseAccountId;
  DateTime _acquisitionDate = DateTime.now();
  String _depreciationMethod = 'STRAIGHT_LINE';

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _assetAccountId = _findAccountId(
      (account) => account.type.toUpperCase().contains('ASSET'),
    );
    _accumulatedDepreciationAccountId = _findAccountId(
      (account) => account.name.toUpperCase().contains('ACCUMULATED'),
    );
    _depreciationExpenseAccountId = _findAccountId(
      (account) => account.type.toUpperCase().contains('EXPENSE'),
    );
  }

  String? _findAccountId(bool Function(Account account) predicate) {
    for (final account in widget.accounts) {
      if (predicate(account)) return account.id;
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _salvageController.dispose();
    _usefulLifeController.dispose();
    _decliningRateController.dispose();
    _usefulLifeUnitsController.dispose();
    super.dispose();
  }

  int? _parseCents(String value) {
    final amount = double.tryParse(value.trim());
    if (amount == null || !amount.isFinite || amount < 0) return null;
    return (amount * 100).round();
  }

  int? _parsePositiveInt(String value) {
    final parsed = int.tryParse(value.trim());
    return parsed != null && parsed > 0 ? parsed : null;
  }

  Future<void> _pickAcquisitionDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _acquisitionDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: l10n.addAssetAcquisitionDate,
    );
    if (selected != null && mounted) {
      setState(() => _acquisitionDate = selected);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final acquisitionCost = _parseCents(_costController.text);
    final salvageValue = _parseCents(_salvageController.text);
    final usefulLifeMonths = _parsePositiveInt(_usefulLifeController.text);
    if (acquisitionCost == null ||
        salvageValue == null ||
        usefulLifeMonths == null) {
      return;
    }
    if (salvageValue > acquisitionCost) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.salvageExceedsCost)));
      return;
    }

    final decliningRate = _depreciationMethod == 'DECLINING_BALANCE'
        ? double.tryParse(_decliningRateController.text.trim())
        : null;
    if (_depreciationMethod == 'DECLINING_BALANCE' &&
        (decliningRate == null ||
            !decliningRate.isFinite ||
            decliningRate <= 0)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidDecliningRate)));
      return;
    }

    final usefulLifeUnits = _depreciationMethod == 'UNITS_OF_ACTIVITY'
        ? _parsePositiveInt(_usefulLifeUnitsController.text)
        : null;
    if (_depreciationMethod == 'UNITS_OF_ACTIVITY' && usefulLifeUnits == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidUsefulLife)));
      return;
    }

    Navigator.of(context).pop(
      _AssetDraft(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        assetAccountId: _assetAccountId!,
        accumulatedDepreciationAccountId: _accumulatedDepreciationAccountId!,
        depreciationExpenseAccountId: _depreciationExpenseAccountId!,
        acquisitionCost: acquisitionCost,
        salvageValue: salvageValue,
        acquisitionDate: _acquisitionDate,
        usefulLifeMonths: usefulLifeMonths,
        depreciationMethod: _depreciationMethod,
        decliningBalanceRate: decliningRate,
        usefulLifeUnits: usefulLifeUnits,
      ),
    );
  }

  Widget _accountField({
    required String label,
    required String hint,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      hint: Text(hint),
      items: widget.accounts
          .map(
            (account) => DropdownMenuItem<String>(
              value: account.id,
              child: Text(account.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
      validator: (selected) => selected == null ? l10n.requiredField : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.addAsset),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.accounts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      l10n.criticalAccountError,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.addAssetName),
                  textInputAction: TextInputAction.next,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.requiredField
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.addAssetDescription,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _accountField(
                  label: l10n.assetAccountLabel,
                  hint: l10n.selectAssetAccount,
                  value: _assetAccountId,
                  onChanged: (value) => setState(() => _assetAccountId = value),
                ),
                const SizedBox(height: 12),
                _accountField(
                  label: l10n.accumulatedDepreciationAccountLabel,
                  hint: l10n.selectAccumulatedDepreciationAccount,
                  value: _accumulatedDepreciationAccountId,
                  onChanged: (value) =>
                      setState(() => _accumulatedDepreciationAccountId = value),
                ),
                const SizedBox(height: 12),
                _accountField(
                  label: l10n.depreciationExpenseAccountLabel,
                  hint: l10n.selectDepreciationExpenseAccount,
                  value: _depreciationExpenseAccountId,
                  onChanged: (value) =>
                      setState(() => _depreciationExpenseAccountId = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _costController,
                        decoration: InputDecoration(
                          labelText: l10n.addAssetAcquisitionCost,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) => _parseCents(value ?? '') == null
                            ? l10n.invalidAmount
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _salvageController,
                        decoration: InputDecoration(
                          labelText: l10n.addAssetSalvageValue,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) => _parseCents(value ?? '') == null
                            ? l10n.invalidAmount
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.addAssetAcquisitionDate),
                  subtitle: Text(DateFormat.yMMMd().format(_acquisitionDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickAcquisitionDate,
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _usefulLifeController,
                  decoration: InputDecoration(
                    labelText: l10n.addAssetUsefulLife,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => _parsePositiveInt(value ?? '') == null
                      ? l10n.invalidUsefulLife
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _depreciationMethod,
                  decoration: InputDecoration(
                    labelText: l10n.addAssetDepreciationMethod,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'STRAIGHT_LINE',
                      child: Text(l10n.straightLine),
                    ),
                    DropdownMenuItem(
                      value: 'DECLINING_BALANCE',
                      child: Text(l10n.decliningBalance),
                    ),
                    DropdownMenuItem(
                      value: 'UNITS_OF_ACTIVITY',
                      child: Text(l10n.unitsOfActivity),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null)
                      setState(() => _depreciationMethod = value);
                  },
                ),
                if (_depreciationMethod == 'DECLINING_BALANCE') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _decliningRateController,
                    decoration: InputDecoration(
                      labelText: l10n.addAssetDecliningRate,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ],
                if (_depreciationMethod == 'UNITS_OF_ACTIVITY') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _usefulLifeUnitsController,
                    decoration: InputDecoration(
                      labelText: l10n.usefulLifeUnitsLabel,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => _parsePositiveInt(value ?? '') == null
                        ? l10n.invalidUsefulLife
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
