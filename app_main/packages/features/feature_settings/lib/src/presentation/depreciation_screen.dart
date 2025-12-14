// Depreciation Processing Screen - Batch depreciation for all assets
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feature_settings/src/data/fixed_assets_repository.dart';
import 'package:core_data/core_data.dart';
import 'package:intl/intl.dart';

class DepreciationScreen extends ConsumerStatefulWidget {
  const DepreciationScreen({super.key});

  @override
  ConsumerState<DepreciationScreen> createState() => _DepreciationScreenState();
}

class _DepreciationScreenState extends ConsumerState<DepreciationScreen> {
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _dateFormat = DateFormat('MMM d, yyyy');
  bool _isProcessing = false;
  DateTime _periodEndDate = DateTime.now();

  String _formatCurrency(int amountInCents) {
    return _currencyFormat.format(amountInCents / 100);
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(activeAssetsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Depreciation Processing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Select Period End Date',
            onPressed: _selectPeriodEndDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Period Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Period End Date',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _dateFormat.format(_periodEndDate),
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _isProcessing ? null : _runBatchDepreciation,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isProcessing ? 'Processing...' : 'Run All'),
                ),
              ],
            ),
          ),

          // Assets List Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Assets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                assetsAsync.when(
                  data: (assets) => Text(
                    '${assets.length} assets',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),

          // Assets List
          Expanded(
            child: assetsAsync.when(
              data: (assets) {
                if (assets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Active Assets',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add fixed assets to run depreciation',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final asset = assets[index];
                    return _buildAssetCard(asset);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(FixedAsset asset) {
    final depreciableBase = asset.acquisitionCost - asset.salvageValue;
    final remainingDepreciation = depreciableBase - asset.totalDepreciation;
    final monthlyExpected = _calculateMonthlyDepreciation(asset);
    final isFullyDepreciated = asset.totalDepreciation >= depreciableBase;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isFullyDepreciated)
                  Chip(
                    label: const Text(
                      'Fully Depreciated',
                      style: TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    labelStyle: const TextStyle(color: Colors.orange),
                    visualDensity: VisualDensity.compact,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline),
                    tooltip: 'Run Depreciation',
                    onPressed: () => _runSingleDepreciation(asset),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildValueColumn(
                  'Book Value',
                  _formatCurrency(
                    asset.acquisitionCost - asset.totalDepreciation,
                  ),
                ),
                _buildValueColumn('Monthly', _formatCurrency(monthlyExpected)),
                _buildValueColumn(
                  'Remaining',
                  _formatCurrency(remainingDepreciation),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueColumn(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
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

  Future<void> _selectPeriodEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _periodEndDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _periodEndDate = picked;
      });
    }
  }

  Future<void> _runSingleDepreciation(FixedAsset asset) async {
    try {
      final depreciationService = ref.read(depreciationServiceProvider);
      final result = await depreciationService.processDepreciation(
        assetId: asset.id,
        periodEndDate: _periodEndDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Depreciation recorded: ${_formatCurrency(result.annualDepreciation)} for ${asset.name}',
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

  Future<void> _runBatchDepreciation() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final depreciationService = ref.read(depreciationServiceProvider);
      final assets = await ref.read(activeAssetsStreamProvider.future);

      int successCount = 0;
      int totalDepreciation = 0;

      for (final asset in assets) {
        // Skip fully depreciated assets
        final depreciableBase = asset.acquisitionCost - asset.salvageValue;
        if (asset.totalDepreciation >= depreciableBase) continue;

        try {
          final result = await depreciationService.processDepreciation(
            assetId: asset.id,
            periodEndDate: _periodEndDate,
          );
          successCount++;
          totalDepreciation += result.annualDepreciation;
        } catch (_) {
          // Continue with next asset
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Processed $successCount assets. Total: ${_formatCurrency(totalDepreciation)}',
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
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
