import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_control_center_contract.dart';
import '../data/owner_control_center_repository.dart';

class OwnerInventorySettingsScreen extends ConsumerStatefulWidget {
  const OwnerInventorySettingsScreen({super.key});

  @override
  ConsumerState<OwnerInventorySettingsScreen> createState() =>
      _OwnerInventorySettingsScreenState();
}

class _OwnerInventorySettingsScreenState
    extends ConsumerState<OwnerInventorySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reorderPointController = TextEditingController();
  final _defaultWarehouseController = TextEditingController();
  String _valuationMethod = 'fifo';
  String _negativeStockPolicy = 'strict';
  bool _lowStockNotifications = true;
  bool _barcodeRequired = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final values = ref
        .read(ownerControlSettingsProvider)
        .section(OwnerSettingSections.inventory);
    _reorderPointController.text =
        '${values['default_reorder_point'] as int? ?? 0}';
    _defaultWarehouseController.text =
        values['default_warehouse_id'] as String? ?? '';
    _valuationMethod = values['stock_valuation_method'] as String? ?? 'fifo';
    _negativeStockPolicy =
        values['negative_stock_policy'] as String? ?? 'strict';
    _lowStockNotifications =
        values['low_stock_notification_enabled'] as bool? ?? true;
    _barcodeRequired = values['barcode_required_for_pos'] as bool? ?? false;
  }

  @override
  void dispose() {
    _reorderPointController.dispose();
    _defaultWarehouseController.dispose();
    super.dispose();
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(ownerControlSettingsProvider.notifier)
          .saveSection(OwnerSettingSections.inventory, {
            'default_warehouse_id': _defaultWarehouseController.text.trim(),
            'stock_valuation_method': _valuationMethod,
            'negative_stock_policy': _negativeStockPolicy,
            'default_reorder_point': int.parse(_reorderPointController.text),
            'low_stock_notification_enabled': _lowStockNotifications,
            'barcode_required_for_pos': _barcodeRequired,
          });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settingsSaved),
          backgroundColor: context.appColors.success,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error} $error'),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addWarehouse() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.addWarehouse),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.warehouseName),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.requiredField
                    : null,
              ),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(labelText: l10n.warehouseAddress),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              await ref
                  .read(warehouseRepositoryProvider)
                  .create(
                    name: nameController.text.trim(),
                    address: addressController.text.trim().isEmpty
                        ? null
                        : addressController.text.trim(),
                  );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    nameController.dispose();
    addressController.dispose();
    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.warehouseCreated)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final warehouses = ref.watch(warehouseRepositoryProvider).watchAll();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productsInventoryWarehouses),
        actions: [
          IconButton(
            tooltip: l10n.saveSettings,
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.stockValuationMethod,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _valuationMethod,
                      items: const ['fifo', 'weighted_average', 'lifo']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _valuationMethod = value!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _negativeStockPolicy,
                      decoration: InputDecoration(
                        labelText: l10n.negativeStockPolicy,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'strict',
                          child: Text(l10n.policyStrict),
                        ),
                        DropdownMenuItem(
                          value: 'warn',
                          child: Text(l10n.policyWarn),
                        ),
                        DropdownMenuItem(
                          value: 'allow',
                          child: Text(l10n.policyAllow),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _negativeStockPolicy = value!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _defaultWarehouseController,
                      decoration: InputDecoration(
                        labelText: l10n.defaultWarehouse,
                      ),
                    ),
                    TextFormField(
                      controller: _reorderPointController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.lowStockThreshold,
                      ),
                      validator: (value) {
                        final number = int.tryParse(value?.trim() ?? '');
                        return number == null || number < 0
                            ? l10n.invalidNumber
                            : null;
                      },
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.notificationLowStock),
                      value: _lowStockNotifications,
                      onChanged: (value) =>
                          setState(() => _lowStockNotifications = value),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.barcodeScanner),
                      value: _barcodeRequired,
                      onChanged: (value) =>
                          setState(() => _barcodeRequired = value),
                    ),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: const Icon(Icons.save),
                      label: Text(l10n.saveSettings),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.warehouseManagement,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              FilledButton.icon(
                onPressed: _addWarehouse,
                icon: const Icon(Icons.add),
                label: Text(l10n.addWarehouse),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<dynamic>>(
            stream: warehouses,
            builder: (context, snapshot) {
              final records = snapshot.data ?? const <dynamic>[];
              if (records.isEmpty) return Text(l10n.noWarehousesYet);
              return Column(
                children: records
                    .map(
                      (warehouse) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.warehouse),
                          title: Text(warehouse.name as String),
                          subtitle: Text((warehouse.address as String?) ?? ''),
                          trailing: (warehouse.isDefault as bool)
                              ? Chip(label: Text(l10n.defaultWarehouse))
                              : null,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
