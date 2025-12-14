import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';

/// 📝 Invoice Form Screen
/// Create or edit an invoice with line items.
class InvoiceFormScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String? invoiceId; // null for new invoice

  const InvoiceFormScreen({
    super.key,
    required this.customerId,
    this.invoiceId,
  });

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  final _notesController = TextEditingController();

  List<_LineItem> _lineItems = [_LineItem()];
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int get _subtotal {
    int total = 0;
    for (final item in _lineItems) {
      total += item.amount;
    }
    return total;
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add(_LineItem());
    });
  }

  void _removeLineItem(int index) {
    if (_lineItems.length > 1) {
      setState(() {
        _lineItems.removeAt(index);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isInvoiceDate) async {
    final initialDate = isInvoiceDate ? _invoiceDate : _dueDate;
    final firstDate = isInvoiceDate ? DateTime(2000) : _invoiceDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isInvoiceDate) {
          _invoiceDate = picked;
          if (_dueDate.isBefore(_invoiceDate)) {
            _dueDate = _invoiceDate.add(const Duration(days: 30));
          }
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate line items
    bool hasValidItems = false;
    for (final item in _lineItems) {
      if (item.description.isNotEmpty && item.amount > 0) {
        hasValidItems = true;
        break;
      }
    }

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
      final arRepo = ref.read(arRepositoryProvider);

      final items = _lineItems
          .where((item) => item.description.isNotEmpty && item.amount > 0)
          .map(
            (item) => InvoiceItemData(
              description: item.description,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
            ),
          )
          .toList();

      await arRepo.createInvoice(
        customerId: widget.customerId,
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        items: items,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice created'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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
        title: const Text('New Invoice'),
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
            // Dates Row
            Row(
              children: [
                Expanded(
                  child: _DateCard(
                    label: 'Invoice Date',
                    date: _invoiceDate,
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

            // Line Items Section
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

            // Line Items List
            ...List.generate(_lineItems.length, (index) {
              return _LineItemCard(
                key: ValueKey(index),
                item: _lineItems[index],
                onRemove: _lineItems.length > 1
                    ? () => _removeLineItem(index)
                    : null,
                onChanged: () => setState(() {}),
              );
            }),
            const SizedBox(height: 16),

            // Subtotal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes
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

            // Create Button
            FilledButton(
              onPressed: _isLoading ? null : _save,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _isLoading ? 'Creating...' : 'Create Invoice',
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
                  color: colorScheme.primary,
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
                    onChanged: (value) {
                      item.description = value;
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
                    onChanged: (value) {
                      item.quantity = double.tryParse(value) ?? 1;
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
                    onChanged: (value) {
                      final parsed = double.tryParse(value) ?? 0;
                      item.unitPrice = (parsed * 100).round();
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
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
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
