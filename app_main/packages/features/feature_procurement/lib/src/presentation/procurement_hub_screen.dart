import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'procurement_operations_screen.dart';
import 'three_way_match_screen.dart';

class ProcurementHubScreen extends ConsumerStatefulWidget {
  const ProcurementHubScreen({super.key});

  @override
  ConsumerState<ProcurementHubScreen> createState() =>
      _ProcurementHubScreenState();
}

class _ProcurementHubScreenState extends ConsumerState<ProcurementHubScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _purposeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController(text: '0');
  final _currencyController = TextEditingController(text: 'YER');
  String? _createdRequisitionId;
  bool _saving = false;

  @override
  void dispose() {
    _numberController.dispose();
    _purposeController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _createRequisition() async {
    if (!_formKey.currentState!.validate()) return;
    final quantity = double.tryParse(_quantityController.text.trim());
    final unitPriceMinor = int.tryParse(_unitPriceController.text.trim());
    final currencyCode = _currencyController.text.trim().toUpperCase();
    if (quantity == null || !quantity.isFinite || quantity <= 0) return;
    if (unitPriceMinor == null || unitPriceMinor < 0) return;
    if (!RegExp(r'^[A-Z]{3,5}$').hasMatch(currencyCode)) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(procurementRepositoryProvider)
          .createRequisition(
            requisitionNumber: _numberController.text.trim(),
            purpose: _purposeController.text.trim(),
            currencyCode: currencyCode,
            lines: [
              ProcurementLineInput(
                description: _descriptionController.text.trim(),
                quantity: quantity,
                unitPriceMinor: unitPriceMinor,
              ),
            ],
          );
      if (!mounted) return;
      setState(() {
        _createdRequisitionId = result['requisition_id']?.toString();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.requisitionCreated)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.requisitionCreateFailed)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitForApproval() async {
    final id = _createdRequisitionId;
    if (id == null) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await ref
          .read(procurementRepositoryProvider)
          .submitRequisitionForApproval(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.requisitionSubmitted)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.requisitionSubmitFailed)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) {
    final l10n = AppLocalizations.of(context)!;
    return value == null || value.trim().isEmpty ? l10n.fieldRequired : null;
  }

  String? _positiveQuantity(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final parsed = double.tryParse(value?.trim() ?? '');
    return parsed == null || !parsed.isFinite || parsed <= 0
        ? l10n.positiveQuantityRequired
        : null;
  }

  String? _nonNegativeAmount(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final parsed = int.tryParse(value?.trim() ?? '');
    return parsed == null || parsed < 0 ? l10n.nonNegativeAmountRequired : null;
  }

  String? _currencyCode(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final normalized = value?.trim().toUpperCase() ?? '';
    return RegExp(r'^[A-Z]{3,5}$').hasMatch(normalized)
        ? null
        : l10n.invalidCurrencyCode;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.procurementHub)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth > 760 ? 720.0 : double.infinity;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l10n.purchaseRequisition,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _numberController,
                                  decoration: InputDecoration(
                                    labelText: l10n.requisitionNumber,
                                  ),
                                  validator: _required,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _purposeController,
                                  decoration: InputDecoration(
                                    labelText: l10n.purpose,
                                  ),
                                  maxLines: 2,
                                  validator: _required,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _descriptionController,
                                  decoration: InputDecoration(
                                    labelText: l10n.description,
                                  ),
                                  validator: _required,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _quantityController,
                                        decoration: InputDecoration(
                                          labelText: l10n.quantity,
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        validator: _positiveQuantity,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _unitPriceController,
                                        decoration: InputDecoration(
                                          labelText: l10n.estimatedUnitPrice,
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: _nonNegativeAmount,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 88,
                                      child: TextFormField(
                                        controller: _currencyController,
                                        decoration: InputDecoration(
                                          labelText: l10n.currency,
                                        ),
                                        textCapitalization:
                                            TextCapitalization.characters,
                                        validator: _currencyCode,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  onPressed: _saving
                                      ? null
                                      : _createRequisition,
                                  icon: const Icon(Icons.add_task),
                                  label: Text(l10n.createRequisition),
                                ),
                                if (_createdRequisitionId != null) ...[
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: _saving
                                        ? null
                                        : _submitForApproval,
                                    icon: const Icon(Icons.approval_outlined),
                                    label: Text(l10n.submitForApproval),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.fact_check_outlined),
                          title: Text(l10n.threeWayMatching),
                          subtitle: Text(l10n.matchVendorBill),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ThreeWayMatchScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.shopping_cart_checkout),
                          title: Text(l10n.procurementOperations),
                          subtitle: Text(l10n.procurementOperationsHint),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ProcurementOperationsScreen(),
                            ),
                          ),
                        ),
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
}
