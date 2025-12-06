// FILE: packages/features/feature_transactions/lib/src/presentation/pos_screen.dart

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as d;
import 'package:audioplayers/audioplayers.dart'; // 🔊 Core Audio Package
import 'package:printing/printing.dart';

// Core Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:core_data/core_data.dart';

// Shared Imports
import 'package:shared_ui/shared_ui.dart';

// Feature Imports
// ✅ FIX 1: Hide databaseProvider to prevent "Ambiguous Import" error
import 'package:feature_products/feature_products.dart' hide accountsRepositoryProvider, databaseProvider;
import 'package:feature_accounts/feature_accounts.dart';

// Local Feature Imports
import 'package:feature_transactions/src/data/transactions_repository.dart';
import 'package:feature_transactions/src/data/database_provider.dart';
import 'package:feature_transactions/src/data/receipt_service.dart';
import 'package:feature_transactions/src/presentation/barcode_scanner_screen.dart';

// ✅ FIX 2: Import the OLD provider as 'legacy' to satisfy the Printer Service types
import 'package:feature_transactions/src/presentation/pos_receipt_provider.dart' as legacy;

// NEW IMPORTS (Phase 2 System)
import 'package:feature_transactions/src/presentation/pos_state_provider.dart';
import 'package:feature_transactions/src/presentation/widgets/virtual_numpad.dart';
import 'package:feature_transactions/src/presentation/widgets/pos_order_table.dart';

// Local Provider for Payment Methods
final paymentMethodsProvider = StreamProvider<List<PaymentMethod>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.paymentMethods)).watch();
});

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  // --- UI CONTROLLERS ---
  final TextEditingController _displayController = TextEditingController();
  
  // --- STATE ---
  String _inputBuffer = "";
  int? _selectedRowIndex;
  bool _isProcessing = false;

  // --- AUDIO ENGINE ---
  late final AudioPlayer _audioPlayer;
  final _beepSound = AssetSource('audio/beep.mp3'); 

  @override
  void initState() {
    super.initState();
    _initAudioEngine();
  }

  Future<void> _initAudioEngine() async {
    _audioPlayer = AudioPlayer();
    final AudioContext audioContext = AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
      ),
    );
    await _audioPlayer.setAudioContext(audioContext);
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    try {
      await _audioPlayer.setSource(_beepSound);
    } catch (e) {
      debugPrint("⚠️ Audio Preload Failed: $e");
    }
  }

  @override
  void dispose() {
    _displayController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- LOGIC: NUMPAD & INPUT ---

  void _onNumpadPress(String value) {
    setState(() {
      _inputBuffer += value;
      _displayController.text = _inputBuffer;
    });
  }

  void _onBackspace() {
    if (_inputBuffer.isNotEmpty) {
      setState(() {
        _inputBuffer = _inputBuffer.substring(0, _inputBuffer.length - 1);
        _displayController.text = _inputBuffer;
      });
    }
  }

  void _onClear() {
    setState(() {
      _inputBuffer = "";
      _displayController.text = "";
      _selectedRowIndex = null;
    });
  }

  void _onEnter() async {
    if (_inputBuffer.isEmpty) return;

    // MODE A: QTY UPDATE (If row selected)
    if (_selectedRowIndex != null) {
       final qty = double.tryParse(_inputBuffer);
       if (qty != null) {
         ref.read(posStateProvider.notifier).updateLineItem(_selectedRowIndex!, quantity: qty);
       }
       _onClear();
       return;
    }

    // MODE B: BARCODE SCAN
    await _handleBarcodeScan(_inputBuffer);
    _onClear();
  }

  Future<void> _handleBarcodeScan(String barcode) async {
    if (barcode.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    // 1. Search Product
    final product = await ref
        .read(productsRepositoryProvider)
        .findProductByBarcode(barcode);

    if (product != null) {
      // 2. Add to Cart (Using NEW Provider)
      ref.read(posStateProvider.notifier).addItem(product);
      
      // 3. Play Sound
      _audioPlayer.resume(); 
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.productNotFound(barcode)), duration: const Duration(milliseconds: 500)),
        );
      }
    }
  }

  void _openMobileScanner() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => BarcodeScannerScreen(
        onScan: (code) async {
           await _handleBarcodeScan(code);
        },
      ),
    ));
  }

  // --- LOGIC: HOLD & RECALL ---

  void _handleHoldOrder() {
    final state = ref.read(posStateProvider);
    if (state.activeOrder.items.isEmpty) return;

    ref.read(posStateProvider.notifier).parkOrder();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Parked")));
  }

  void _showParkedOrdersDialog() {
    final state = ref.read(posStateProvider);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Recall Order"),
          content: SizedBox(
            width: 300,
            height: 400,
            child: state.parkedOrders.isEmpty 
              ? const Center(child: Text("No parked orders"))
              : ListView.builder(
                  itemCount: state.parkedOrders.length,
                  itemBuilder: (ctx, i) {
                    final order = state.parkedOrders[i];
                    return ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text("Order #${order.id.substring(0, 4)}"),
                      subtitle: Text("${order.items.length} items • ${order.createdAt.minute} mins ago"),
                      trailing: Text(CurrencyFormatter.formatCentsToCurrency((order.total * 100).round())),
                      onTap: () {
                        ref.read(posStateProvider.notifier).recallOrder(order.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ],
        );
      },
    );
  }

  // --- LOGIC: PAYMENT & PRINTING ---

  void _showPaymentDialog() {
    final state = ref.read(posStateProvider);
    if (state.activeOrder.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cart is empty")));
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final paymentMethodsAsync = ref.read(paymentMethodsProvider);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.orderDetails),
          content: SizedBox(
            width: 400,
            child: paymentMethodsAsync.when(
              data: (methods) {
                if (methods.isEmpty) return Text(l10n.criticalSetupError);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${l10n.total}: ${CurrencyFormatter.formatCentsToCurrency((state.activeOrder.total * 100).round())}", 
                      style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 20),
                    ...methods.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: () async {
                             Navigator.pop(context); // Close dialog
                             await _processTransaction(m);
                          },
                          icon: const Icon(Icons.payment),
                          label: Text("Pay with ${m.name}"),
                        ),
                      ),
                    )),
                  ],
                );
              },
              error: (e, s) => Text("Error: $e"),
              loading: () => const CircularProgressIndicator(),
            ),
          ),
        );
      }
    );
  }

  Future<void> _processTransaction(PaymentMethod method) async {
    setState(() => _isProcessing = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final profileData = ref.read(companyProfileProvider);
    
    // 1. Get Data from NEW Provider (PosStateProvider)
    final order = ref.read(posStateProvider).activeOrder;
    final newItems = order.items;
    final totalAmount = order.total;

    // ✅ FIX 3: Convert NEW Items to OLD Items (Type Adapter)
    // The ReceiptService expects 'legacy.PosReceiptItem', but we have 'PosReceiptItem' from state provider.
    final List<legacy.PosReceiptItem> legacyItems = newItems.map((item) {
      return legacy.PosReceiptItem(
        product: item.product,
        quantity: item.quantity,
      );
    }).toList();

    // 2. Database Logic
    final accountsRepo = ref.read(accountsRepositoryProvider);
    final salesAccountId = await accountsRepo.getAccountIdByName(kSalesRevenueAccountName);
    
    if (salesAccountId == null) {
      setState(() => _isProcessing = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.criticalSetupError)));
      return;
    }

    final int totalCents = (totalAmount * 100).round();
    final entries = [
      TransactionEntriesCompanion.insert(
        accountId: method.accountId,
        amount: totalCents,
        transactionId: 'TEMP',
        currencyRate: const d.Value(1.0),
      ),
      TransactionEntriesCompanion.insert(
        accountId: salesAccountId,
        amount: -totalCents,
        transactionId: 'TEMP',
        currencyRate: const d.Value(1.0),
      ),
    ];

    try {
      final description = l10n.posSale(DateTime.now().microsecondsSinceEpoch.toString());

      await ref.read(transactionsRepositoryProvider).createPosSale(
        transactionCompanion: TransactionsCompanion.insert(
          description: description,
          transactionDate: DateTime.now(),
          attachmentPath: const d.Value(null),
          currencyCode: const d.Value('Local'),
          relatedTransactionId: const d.Value(null),
        ),
        entries: entries,
        items: legacyItems, // ✅ Passing the converted legacy items here
        totalAmount: totalAmount,
      );

      // 3. Printing Logic
      try {
        final pdfData = await ref.read(receiptServiceProvider).generatePosReceipt(
          items: legacyItems, // ✅ Passing the converted legacy items here
          total: totalAmount,
          profile: profileData,
          l10n: l10n,
        );
        await Printing.layoutPdf(onLayout: (format) async => pdfData);
      } catch (e) {
        debugPrint("Print Error: $e");
      }

      // 4. Success & Cleanup
      ref.read(posStateProvider.notifier).clearActiveOrder();
      messenger.showSnackBar(SnackBar(content: Text(l10n.saleRecorded(totalAmount.toStringAsFixed(2)))));
      
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('${l10n.transactionFailed} $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    final activeTotal = ref.watch(posActiveTotalProvider);
    final parkCount = ref.watch(posStateProvider).parkedOrders.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("POS Terminal"),
        actions: [
           // 🔍 PRODUCT LOOKUP
           IconButton(
             icon: const Icon(Icons.search),
             tooltip: "Search Product",
             onPressed: _openMobileScanner, 
           ),
           const VerticalDivider(indent: 10, endIndent: 10),
           // ⏸️ PARK BUTTON
           Badge(
            label: Text(parkCount.toString()),
            isLabelVisible: parkCount > 0,
            child: IconButton(
              icon: const Icon(Icons.history),
              onPressed: _showParkedOrdersDialog,
              tooltip: "Recall Order",
            ),
          ),
          TextButton.icon(
            onPressed: _handleHoldOrder, 
            icon: const Icon(Icons.pause_circle_outline),
            label: const Text("HOLD"),
          ),
        ],
      ),
      body: Row(
        children: [
          // LEFT: Data Table & Input (60%)
          Expanded(
            flex: 6,
            child: Column(
              children: [
                // Display
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black87,
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _selectedRowIndex != null ? "EDIT QTY MODE" : "SCAN MODE",
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                      Text(
                        _displayController.text.isEmpty ? "0" : _displayController.text,
                        style: const TextStyle(
                          color: Colors.greenAccent, 
                          fontSize: 32, 
                          fontFamily: 'Courier', 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                ),
                // Table
                Expanded(
                  child: PosOrderTable(
                    selectedIndex: _selectedRowIndex,
                    onRowTap: (index) {
                      setState(() {
                        if (_selectedRowIndex == index) {
                          _selectedRowIndex = null;
                          _inputBuffer = "";
                        } else {
                          _selectedRowIndex = index;
                          _inputBuffer = "";
                        }
                        _displayController.text = "";
                      });
                    },
                  ),
                ),
                // Total
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("TOTAL", style: TextStyle(color: Colors.white, fontSize: 20)),
                      Text(
                        CurrencyFormatter.formatCentsToCurrency((activeTotal * 100).round()), 
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // RIGHT: Numpad (40%)
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: VirtualNumpad(
                    onKeyPressed: _onNumpadPress,
                    onEnter: _onEnter,
                    onClear: _onClear,
                    onBackspace: _onBackspace,
                  ),
                ),
                // PAY BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: _isProcessing ? null : _showPaymentDialog,
                    child: _isProcessing 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("PAY / PRINT", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: (!Platform.isWindows) 
        ? FloatingActionButton(
            onPressed: _openMobileScanner,
            child: const Icon(Icons.qr_code_scanner),
          )
        : null,
    );
  }
}