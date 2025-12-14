import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';

/// 📝 Bill Form Screen - Create a bill
class BillFormScreen extends ConsumerStatefulWidget {
  final String vendorId;
  const BillFormScreen({super.key, required this.vendorId});

  @override
  ConsumerState<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends ConsumerState<BillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _billDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  final _vendorBillNumberController = TextEditingController();
  final _notesController = TextEditingController();

  List<_LineItem> _lineItems = [_LineItem()];
  bool _isLoading = false;

  @override
  void dispose() {
    _vendorBillNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _subtotal {
    int total = 0;
    for (final item in _lineItems) total += item.amount;
    return total;
  }

  void _addLineItem() => setState(() => _lineItems.add(_LineItem()));
  void _removeLineItem(int index) {
    if (_lineItems.length > 1) setState(() => _lineItems.removeAt(index));
  }

  Future<void> _selectDate(BuildContext context, bool isBillDate) async {
    final initialDate = isBillDate ? _billDate : _dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isBillDate ? DateTime(2000) : _billDate,
      lastDate: DateTime(2100),
    );
    if (picked != null)
      setState(() {
        if (isBillDate) {
          _billDate = picked;
          if (_dueDate.isBefore(_billDate))
            _dueDate = _billDate.add(const Duration(days: 30));
        } else
          _dueDate = picked;
      });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    bool hasValidItems = _lineItems.any(
      (item) => item.description.isNotEmpty && item.amount > 0,
    );
    if (!hasValidItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one line item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final apRepo = ref.read(apRepositoryProvider);
      final items = _lineItems
          .where((item) => item.description.isNotEmpty && item.amount > 0)
          .map(
            (item) => BillItemData(
              description: item.description,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
            ),
          )
          .toList();
      await apRepo.createBill(
        vendorId: widget.vendorId,
        billDate: _billDate,
        dueDate: _dueDate,
        items: items,
        vendorBillNumber: _vendorBillNumberController.text.trim().isNotEmpty
            ? _vendorBillNumberController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill created'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Bill'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Vendor Bill Number
            TextFormField(
              controller: _vendorBillNumberController,
              decoration: const InputDecoration(
                labelText: 'Vendor Invoice # (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 16),

            // Dates Row
            Row(
              children: [
                Expanded(
                  child: _DateCard(
                    label: 'Bill Date',
                    date: _billDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DateCard(
                    label: 'Due Date',
                    date: _dueDate,
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Line Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Line Items',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addLineItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(
              _lineItems.length,
              (index) => _LineItemCard(
                key: ValueKey(index),
                item: _lineItems[index],
                onRemove: _lineItems.length > 1
                    ? () => _removeLineItem(index)
                    : null,
                onChanged: () => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),

            // Subtotal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${(_subtotal / 100).toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _save,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _isLoading ? 'Creating...' : 'Create Bill',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineItem {
  String description = '';
  double quantity = 1;
  int unitPrice = 0;
  int get amount => (quantity * unitPrice).round();
}

class _DateCard extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateCard({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LineItemCard extends StatelessWidget {
  final _LineItem item;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;
  const _LineItemCard({
    super.key,
    required this.item,
    this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.description,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      item.description = v;
                      onChanged();
                    },
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.error),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.quantity.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      item.quantity = double.tryParse(v) ?? 1;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: (item.unitPrice / 100).toString(),
                    decoration: const InputDecoration(
                      labelText: 'Unit Price',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      item.unitPrice = ((double.tryParse(v) ?? 0) * 100)
                          .round();
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$${(item.amount / 100).toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
