import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProcurementOperationsScreen extends ConsumerStatefulWidget {
  const ProcurementOperationsScreen({super.key});

  @override
  ConsumerState<ProcurementOperationsScreen> createState() =>
      _ProcurementOperationsScreenState();
}

class _ProcurementOperationsScreenState
    extends ConsumerState<ProcurementOperationsScreen> {
  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  final _purchaseOrderFormKey = GlobalKey<FormState>();
  final _receiptFormKey = GlobalKey<FormState>();
  final _returnFormKey = GlobalKey<FormState>();

  final _orderNumberController = TextEditingController();
  final _vendorIdController = TextEditingController();
  final _requisitionIdController = TextEditingController();
  final _orderDescriptionController = TextEditingController();
  final _orderQuantityController = TextEditingController(text: '1');
  final _orderUnitPriceController = TextEditingController(text: '0');
  final _orderCurrencyController = TextEditingController(text: 'YER');

  final _receiptNumberController = TextEditingController();
  final _receiptPurchaseOrderIdController = TextEditingController();
  final _receiptLineIdController = TextEditingController();
  final _warehouseIdController = TextEditingController(text: 'default');
  final _receiptQuantityController = TextEditingController(text: '1');
  final _receiptUnitCostController = TextEditingController(text: '0');

  final _returnNumberController = TextEditingController();
  final _returnPurchaseOrderIdController = TextEditingController();
  final _returnReceiptIdController = TextEditingController();
  final _returnLineIdController = TextEditingController();
  final _returnReasonController = TextEditingController();
  final _returnQuantityController = TextEditingController(text: '1');
  final _returnUnitCostController = TextEditingController(text: '0');

  String? _purchaseOrderId;
  String? _receiptId;
  String? _returnId;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [
      _orderNumberController,
      _vendorIdController,
      _requisitionIdController,
      _orderDescriptionController,
      _orderQuantityController,
      _orderUnitPriceController,
      _orderCurrencyController,
      _receiptNumberController,
      _receiptPurchaseOrderIdController,
      _receiptLineIdController,
      _warehouseIdController,
      _receiptQuantityController,
      _receiptUnitCostController,
      _returnNumberController,
      _returnPurchaseOrderIdController,
      _returnReceiptIdController,
      _returnLineIdController,
      _returnReasonController,
      _returnQuantityController,
      _returnUnitCostController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) {
    final l10n = AppLocalizations.of(context)!;
    return value == null || value.trim().isEmpty ? l10n.fieldRequired : null;
  }

  String? _identifier(String? value, {bool optional = false}) {
    final l10n = AppLocalizations.of(context)!;
    final normalized = value?.trim() ?? '';
    if (optional && normalized.isEmpty) return null;
    return _uuidPattern.hasMatch(normalized) ? null : l10n.invalidIdentifier;
  }

  String? _currency(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final normalized = value?.trim().toUpperCase() ?? '';
    return RegExp(r'^[A-Z]{3,5}$').hasMatch(normalized)
        ? null
        : l10n.invalidCurrencyCode;
  }

  String? _quantity(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final parsed = double.tryParse(value?.trim() ?? '');
    return parsed != null && parsed.isFinite && parsed > 0
        ? null
        : l10n.positiveQuantityRequired;
  }

  String? _amount(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final parsed = int.tryParse(value?.trim() ?? '');
    return parsed != null && parsed >= 0
        ? null
        : l10n.nonNegativeAmountRequired;
  }

  Future<void> _createPurchaseOrder() async {
    if (!_purchaseOrderFormKey.currentState!.validate()) return;
    final quantity = double.tryParse(_orderQuantityController.text.trim());
    final unitPrice = int.tryParse(_orderUnitPriceController.text.trim());
    if (quantity == null || unitPrice == null) return;
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(procurementRepositoryProvider)
          .createPurchaseOrder(
            orderNumber: _orderNumberController.text,
            vendorId: _vendorIdController.text,
            requisitionId: _optionalValue(_requisitionIdController.text),
            orderDate: DateTime.now(),
            currencyCode: _orderCurrencyController.text,
            lines: [
              ProcurementLineInput(
                description: _orderDescriptionController.text,
                quantity: quantity,
                unitPriceMinor: unitPrice,
              ),
            ],
          );
      if (!mounted) return;
      final id = result['purchase_order_id']?.toString();
      setState(() {
        _purchaseOrderId = id;
        if (id != null) {
          _receiptPurchaseOrderIdController.text = id;
          _returnPurchaseOrderIdController.text = id;
        }
      });
      _message(AppLocalizations.of(context)!.purchaseOrderCreated);
    } catch (_) {
      if (mounted) {
        _message(AppLocalizations.of(context)!.purchaseOrderCreateFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitPurchaseOrder() async {
    final id = _purchaseOrderId;
    if (id == null) return;
    await _runAction(
      () => ref
          .read(procurementRepositoryProvider)
          .submitPurchaseOrderForApproval(id),
      AppLocalizations.of(context)!.purchaseOrderSubmitFailed,
    );
  }

  Future<void> _createReceipt() async {
    if (!_receiptFormKey.currentState!.validate()) return;
    final quantity = double.tryParse(_receiptQuantityController.text.trim());
    final unitCost = int.tryParse(_receiptUnitCostController.text.trim());
    if (quantity == null || unitCost == null) return;
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(procurementRepositoryProvider)
          .createReceipt(
            purchaseOrderId: _receiptPurchaseOrderIdController.text,
            receiptNumber: _receiptNumberController.text,
            warehouseId: _warehouseIdController.text,
            receiptDate: DateTime.now(),
            lines: [
              ProcurementReceiptLineInput(
                purchaseOrderLineId: _receiptLineIdController.text,
                quantity: quantity,
                unitCostMinor: unitCost,
              ),
            ],
          );
      if (!mounted) return;
      final id = result['receipt_id']?.toString();
      setState(() {
        _receiptId = id;
        if (id != null) _returnReceiptIdController.text = id;
      });
      _message(AppLocalizations.of(context)!.receiptCreated);
    } catch (_) {
      if (mounted) _message(AppLocalizations.of(context)!.receiptCreateFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _postReceipt() async {
    final id = _receiptId;
    if (id == null) return;
    await _runAction(
      () => ref.read(procurementRepositoryProvider).postReceipt(id),
      AppLocalizations.of(context)!.receiptPostFailed,
    );
  }

  Future<void> _createReturn() async {
    if (!_returnFormKey.currentState!.validate()) return;
    final quantity = double.tryParse(_returnQuantityController.text.trim());
    final unitCost = int.tryParse(_returnUnitCostController.text.trim());
    if (quantity == null || unitCost == null) return;
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(procurementRepositoryProvider)
          .createReturn(
            purchaseOrderId: _returnPurchaseOrderIdController.text,
            receiptId: _optionalValue(_returnReceiptIdController.text),
            returnNumber: _returnNumberController.text,
            returnDate: DateTime.now(),
            reason: _returnReasonController.text,
            lines: [
              ProcurementReceiptLineInput(
                purchaseOrderLineId: _returnLineIdController.text,
                quantity: quantity,
                unitCostMinor: unitCost,
              ),
            ],
          );
      if (!mounted) return;
      setState(() => _returnId = result['return_id']?.toString());
      _message(AppLocalizations.of(context)!.returnCreated);
    } catch (_) {
      if (mounted) _message(AppLocalizations.of(context)!.returnCreateFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _postReturn() async {
    final id = _returnId;
    if (id == null) return;
    await _runAction(
      () => ref.read(procurementRepositoryProvider).postReturn(id),
      AppLocalizations.of(context)!.returnPostFailed,
    );
  }

  Future<void> _runAction(
    Future<Map<String, dynamic>> Function() action,
    String failureMessage,
  ) async {
    setState(() => _saving = true);
    try {
      await action();
      if (mounted)
        _message(AppLocalizations.of(context)!.procurementActionCompleted);
    } catch (_) {
      if (mounted) _message(failureMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _optionalValue(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  InputDecoration _decoration(String label) =>
      InputDecoration(labelText: label);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.procurementOperations)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth > 880 ? 840.0 : double.infinity;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.procurementOperationsHint,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      _purchaseOrderCard(l10n),
                      const SizedBox(height: 16),
                      _receiptCard(l10n),
                      const SizedBox(height: 16),
                      _returnCard(l10n),
                      const SizedBox(height: 16),
                      Text(
                        l10n.workflowComingSoon,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _purchaseOrderCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _purchaseOrderFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.purchaseOrder,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _orderNumberController,
                decoration: _decoration(l10n.purchaseOrderNumber),
                validator: _required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _vendorIdController,
                decoration: _decoration(l10n.vendorId),
                validator: _identifier,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _requisitionIdController,
                decoration: _decoration(l10n.requisitionIdOptional),
                validator: (value) => _identifier(value, optional: true),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _orderDescriptionController,
                decoration: _decoration(l10n.description),
                validator: _required,
              ),
              const SizedBox(height: 10),
              _numericRow(
                TextFormField(
                  controller: _orderQuantityController,
                  decoration: _decoration(l10n.quantity),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _quantity,
                ),
                TextFormField(
                  controller: _orderUnitPriceController,
                  decoration: _decoration(l10n.estimatedUnitPrice),
                  keyboardType: TextInputType.number,
                  validator: _amount,
                ),
                TextFormField(
                  controller: _orderCurrencyController,
                  decoration: _decoration(l10n.currency),
                  textCapitalization: TextCapitalization.characters,
                  validator: _currency,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _saving ? null : _createPurchaseOrder,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(l10n.createPurchaseOrder),
              ),
              if (_purchaseOrderId != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _submitPurchaseOrder,
                  icon: const Icon(Icons.approval_outlined),
                  label: Text(l10n.submitForApproval),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _receiptFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.receipt, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _receiptNumberController,
                decoration: _decoration(l10n.receiptNumber),
                validator: _required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _receiptPurchaseOrderIdController,
                decoration: _decoration(l10n.purchaseOrderId),
                validator: _identifier,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _receiptLineIdController,
                decoration: _decoration(l10n.purchaseOrderLineId),
                validator: _identifier,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _warehouseIdController,
                decoration: _decoration(l10n.warehouseId),
                validator: _required,
              ),
              const SizedBox(height: 10),
              _numericRow(
                TextFormField(
                  controller: _receiptQuantityController,
                  decoration: _decoration(l10n.quantity),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _quantity,
                ),
                TextFormField(
                  controller: _receiptUnitCostController,
                  decoration: _decoration(l10n.cost),
                  keyboardType: TextInputType.number,
                  validator: _amount,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _saving ? null : _createReceipt,
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(l10n.createReceipt),
              ),
              if (_receiptId != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _postReceipt,
                  icon: const Icon(Icons.post_add),
                  label: Text(l10n.postReceipt),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _returnCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _returnFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.returnTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _returnNumberController,
                decoration: _decoration(l10n.returnNumber),
                validator: _required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _returnPurchaseOrderIdController,
                decoration: _decoration(l10n.purchaseOrderId),
                validator: _identifier,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _returnReceiptIdController,
                decoration: _decoration(l10n.receiptIdOptional),
                validator: (value) => _identifier(value, optional: true),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _returnLineIdController,
                decoration: _decoration(l10n.purchaseOrderLineId),
                validator: _identifier,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _returnReasonController,
                decoration: _decoration(l10n.returnReason),
                validator: _required,
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              _numericRow(
                TextFormField(
                  controller: _returnQuantityController,
                  decoration: _decoration(l10n.quantity),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _quantity,
                ),
                TextFormField(
                  controller: _returnUnitCostController,
                  decoration: _decoration(l10n.cost),
                  keyboardType: TextInputType.number,
                  validator: _amount,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _saving ? null : _createReturn,
                icon: const Icon(Icons.assignment_return_outlined),
                label: Text(l10n.createReturn),
              ),
              if (_returnId != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _postReturn,
                  icon: const Icon(Icons.post_add),
                  label: Text(l10n.postReturn),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _numericRow(Widget first, Widget second, [Widget? third]) {
    final children = <Widget>[
      Expanded(child: first),
      const SizedBox(width: 10),
      Expanded(child: second),
    ];
    if (third != null)
      children.addAll([
        const SizedBox(width: 10),
        SizedBox(width: 96, child: third),
      ]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
