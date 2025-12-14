// Fixed Assets Dashboard Screen - Comprehensive view with metrics and visualizations
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feature_settings/src/data/fixed_assets_repository.dart';
import 'package:core_data/core_data.dart';
import 'package:intl/intl.dart';

class FixedAssetsScreen extends ConsumerStatefulWidget {
  const FixedAssetsScreen({super.key});

  @override
  ConsumerState<FixedAssetsScreen> createState() => _FixedAssetsScreenState();
}

class _FixedAssetsScreenState extends ConsumerState<FixedAssetsScreen>
    with SingleTickerProviderStateMixin {
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _dateFormat = DateFormat('MMM d, yyyy');
  late TabController _tabController;

  String _formatCurrency(int amountInCents) {
    return _currencyFormat.format(amountInCents / 100);
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
        return 'Active';
      case 'DISPOSED':
        return 'Disposed';
      case 'FULLY_DEPRECIATED':
        return 'Fully Depreciated';
      default:
        return status;
    }
  }

  String _getMethodLabel(String method) {
    switch (method) {
      case 'STRAIGHT_LINE':
        return 'Straight-Line';
      case 'DECLINING_BALANCE':
        return 'Declining Balance';
      case 'UNITS_OF_ACTIVITY':
        return 'Units of Activity';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(fixedAssetsStreamProvider);

    return Scaffold(
      body: assetsAsync.when(
        data: (assets) => _buildDashboard(assets),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAssetDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Asset'),
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

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          title: const Text('Fixed Assets'),
          pinned: true,
          floating: true,
          expandedHeight: 340, // Increased from 320
          flexibleSpace: FlexibleSpaceBar(
            background: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 56), // AppBar height
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
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
                                'Active',
                                activeCount,
                                Colors.green,
                                Icons.check_circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatusCard(
                                'Full Depr.',
                                fullyDepreciatedCount,
                                Colors.orange,
                                Icons.pending,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatusCard(
                                'Disposed',
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
                ),
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All Assets'),
              Tab(text: 'By Category'),
              Tab(text: 'Schedule'),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssetsList(assets),
          _buildCategoryView(assets),
          _buildScheduleView(assets),
        ],
      ),
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
                      'Net Book Value',
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
                _buildMiniStat('Total Cost', _formatCurrency(totalCost)),
                _buildMiniStat(
                  'Depreciated',
                  _formatCurrency(totalDepreciation),
                ),
                _buildMiniStat(
                  'Progress',
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
                        'Book Value',
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
                    '${depreciationPercent.toStringAsFixed(0)}% depreciated',
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
            subtitle: Text('Book Value: ${_formatCurrency(methodTotal)}'),
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
              'No Scheduled Depreciation',
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
              'Monthly: ${_formatCurrency(monthlyDepreciation)} • $monthsRemaining months left',
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
                  'Book Value',
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
            'No Fixed Assets',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add equipment, vehicles, or property to track depreciation',
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
                'Depreciation Progress',
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
                '${depreciationPercent.toStringAsFixed(1)}% depreciated',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),

              // Value Details
              _buildDetailCard(context, 'Value Information', [
                _buildDetailRow(
                  'Acquisition Cost',
                  _formatCurrency(asset.acquisitionCost),
                ),
                _buildDetailRow(
                  'Salvage Value',
                  _formatCurrency(asset.salvageValue),
                ),
                _buildDetailRow(
                  'Accumulated Depreciation',
                  _formatCurrency(asset.totalDepreciation),
                ),
                _buildDetailRow(
                  'Net Book Value',
                  _formatCurrency(bookValue),
                  highlight: true,
                ),
              ]),
              const SizedBox(height: 16),

              // Depreciation Details
              _buildDetailCard(context, 'Depreciation Settings', [
                _buildDetailRow(
                  'Method',
                  _getMethodLabel(asset.depreciationMethod),
                ),
                _buildDetailRow(
                  'Useful Life',
                  '${asset.usefulLifeMonths} months',
                ),
                _buildDetailRow(
                  'Acquisition Date',
                  _dateFormat.format(asset.acquisitionDate),
                ),
                if (asset.currentPeriodDepreciation > 0)
                  _buildDetailRow(
                    'Current Period',
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
                        label: const Text('Run Depreciation'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _disposeAsset(asset),
                        icon: const Icon(Icons.sell),
                        label: const Text('Dispose'),
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
                'Depreciation recorded: ${_formatCurrency(result.annualDepreciation)}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _disposeAsset(FixedAsset asset) async {
    Navigator.pop(context);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asset disposal feature coming soon')),
      );
    }
  }

  void _showAddAssetDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Asset feature coming soon')),
    );
  }
}
