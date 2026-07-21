import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:shared_ui/shared_ui.dart';

enum DocumentType { invoice, bill }

/// 📝 Document Form Body - Reusable form for Invoice and Bill creation
class DocumentFormBody extends ConsumerStatefulWidget {
  final DocumentType type;
  final String contactId;
  final String title;

  const DocumentFormBody({
    super.key,
    required this.type,
    required this.contactId,
    required this.title,
  });

  @override
  ConsumerState<DocumentFormBody> createState() => _DocumentFormBodyState();
}

class _LineItem {
  String description = '';
  double quantity = 1.0;
  int unitPrice = 0;

  int get amount => (quantity * unitPrice).round();
}

class _DocumentFormBodyState extends ConsumerState<DocumentFormBody> {
  final _formKey = GlobalKey<FormState>();
  DateTime _documentDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  final _vendorDocumentNumberController = TextEditingController();
  final _notesController = TextEditingController();

  List<_LineItem> _lineItems = [_LineItem()];
  bool _isLoading = false;
  String _selectedCurrencyCode = 'USD';

  @override
  void initState() {
    super.initState();
    _lineItems.add(_LineItem());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedCurrencyCode = ref.read(currentCurrencyCodeProvider);
        });
      }
    });
  }

  @override
  void dispose() {
    _vendorDocumentNumberController.dispose();
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

  Future<void> _selectDate(BuildContext context, bool isDocDate) async {
    final initialDate = isDocDate ? _documentDate : _dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isDocDate ? DateTime(2000) : _documentDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDocDate) {
          _documentDate = picked;
          if (_dueDate.isBefore(_documentDate)) {
            _dueDate = _documentDate.add(const Duration(days: 30));
          }
        } else {
          _dueDate = picked;
        }
      });
    }
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
      if (widget.type == DocumentType.invoice) {
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
          customerId: widget.contactId,
          invoiceDate: _documentDate,
          dueDate: _dueDate,
          items: items,
          currencyCode: _selectedCurrencyCode,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );
      } else {
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
          vendorId: widget.contactId,
          billDate: _documentDate,
          dueDate: _dueDate,
          items: items,
          currencyCode: _selectedCurrencyCode,
          vendorBillNumber: _vendorDocumentNumberController.text.trim().isNotEmpty
              ? _vendorDocumentNumberController.text.trim()
              : null,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.type == DocumentType.invoice ? 'Invoice' : 'Bill'} created'),
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
    final isInvoice = widget.type == DocumentType.invoice;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Currency Selector Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCurrencyCode,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: CurrencyFormatter.currencySymbols.keys.map((code) {
                      return DropdownMenuItem(
                        value: code,
                        child: Text('$code (${CurrencyFormatter.getCurrencySymbol(code)})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCurrencyCode = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  if (!isInvoice) ...[
                    TextFormField(
                      controller: _vendorDocumentNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Vendor Bill Number (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: isInvoice ? 'Invoice Date' : 'Bill Date',
                              border: const OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_documentDate.day}/${_documentDate.month}/${_documentDate.year}',
                                ),
                                const Icon(Icons.calendar_today, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Due Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                                ),
                                const Icon(Icons.calendar_today, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Line Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _lineItems.length,
                    itemBuilder: (context, index) {
                      return _LineItemCard(
                        item: _lineItems[index],
                        currencyCode: _selectedCurrencyCode,
                        onRemove: _lineItems.length > 1
                            ? () => _removeLineItem(index)
                            : null,
                        onChanged: () => setState(() {}),
                      );
                    },
                  ),
                  TextButton.icon(
                    onPressed: _addLineItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Line Item'),
                  ),
                  const Divider(height: 32),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatAmount(_subtotal, _selectedCurrencyCode),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _LineItemCard extends StatefulWidget {
  final _LineItem item;
  final String currencyCode;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _LineItemCard({
    required this.item,
    required this.currencyCode,
    this.onRemove,
    required this.onChanged,
  });

  @override
  State<_LineItemCard> createState() => _LineItemCardState();
}

class _LineItemCardState extends State<_LineItemCard> {
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;
  final FocusNode _qtyFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
        text: widget.item.quantity > 0 ? widget.item.quantity.toString() : '');
    _priceController = TextEditingController(
        text: widget.item.unitPrice > 0
            ? (widget.item.unitPrice / 100).toString()
            : '');

    _qtyFocus.addListener(() {
      if (_qtyFocus.hasFocus && _qtyController.text.isNotEmpty) {
        _qtyController.selection = TextSelection(
            baseOffset: 0, extentOffset: _qtyController.text.length);
      }
    });

    _priceFocus.addListener(() {
      if (_priceFocus.hasFocus && _priceController.text.isNotEmpty) {
        _priceController.selection = TextSelection(
            baseOffset: 0, extentOffset: _priceController.text.length);
      }
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _qtyFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: widget.item.description,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      widget.item.description = v;
                      widget.onChanged();
                    },
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                if (widget.onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: widget.onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _qtyController,
                    focusNode: _qtyFocus,
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) {
                      widget.item.quantity = double.tryParse(v) ?? 0.0;
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    focusNode: _priceFocus,
                    decoration: InputDecoration(
                      labelText: 'Unit Price',
                      hintText: '0.00',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      prefixText: '${CurrencyFormatter.getCurrencySymbol(widget.currencyCode)} ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (v) {
                      widget.item.unitPrice = ((double.tryParse(v) ?? 0) * 100).round();
                      widget.onChanged();
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
                    CurrencyFormatter.formatAmount(widget.item.amount, widget.currencyCode),
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
