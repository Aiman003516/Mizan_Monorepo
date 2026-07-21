// FILE: packages/features/feature_transactions/lib/src/presentation/pos_screen.dart

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as d;
import 'package:audioplayers/audioplayers.dart';
import 'package:printing/printing.dart';

// Core Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:core_data/core_data.dart';
import 'package:core_database/core_database.dart';

// Shared Imports
import 'package:shared_ui/shared_ui.dart';

// Feature Imports
import 'package:feature_products/feature_products.dart'
    hide accountsRepositoryProvider, databaseProvider;
import 'package:feature_accounts/feature_accounts.dart';

// Local Feature Imports
import 'package:feature_transactions/src/data/transactions_repository.dart';
import 'package:feature_transactions/src/data/database_provider.dart';
import 'package:feature_transactions/src/data/receipt_service.dart';
import 'package:feature_transactions/src/presentation/barcode_scanner_screen.dart';

// Legacy receipt provider (for printer compat)
import 'package:feature_transactions/src/presentation/pos_receipt_provider.dart'
    as legacy;

// NEW: State & Widgets
import 'package:feature_transactions/src/presentation/pos_state_provider.dart';
import 'package:feature_transactions/src/presentation/widgets/pos_product_grid.dart';
import 'package:feature_transactions/src/presentation/widgets/pos_cart_sheet.dart';

// ──────────────────────────────────────────────────
// PROVIDERS
// ──────────────────────────────────────────────────

final paymentMethodsProvider = StreamProvider<List<PaymentMethod>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.paymentMethods)).watch();
});

class PosScreen extends ConsumerStatefulWidget {
  final bool isStandalone;

  const PosScreen({
    super.key,
    this.isStandalone = false,
  });

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  // ─── STATE ───────────────────────────────────────
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isProcessing = false;

  // ─── KEYBOARD / BARCODE ─────────────────────────
  final FocusNode _focusNode = FocusNode();
  String _barcodeBuffer = '';
  DateTime? _lastKeyTime;

  // ─── AUDIO ──────────────────────────────────────
  late final AudioPlayer _audioPlayer;
  final _beepSound = AssetSource('audio/beep.mp3');

  // ─── SEARCH ─────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAudioEngine();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
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
      iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
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
    _audioPlayer.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── KEYBOARD HANDLER ───────────────────────────

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.f1) {
      _showPaymentDialog();
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.f2) {
      _handleHoldOrder();
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_isSearching) {
        setState(() {
          _isSearching = false;
          _searchQuery = '';
          _searchController.clear();
        });
      }
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_barcodeBuffer.isNotEmpty) {
        _handleBarcodeScan(_barcodeBuffer);
        _barcodeBuffer = '';
        _lastKeyTime = null;
      }
      return;
    }

    final String? char = event.character;
    if (char != null && char.isNotEmpty) {
      final now = DateTime.now();
      if (_lastKeyTime != null &&
          now.difference(_lastKeyTime!).inMilliseconds > 50) {
        _barcodeBuffer = '';
      }
      _barcodeBuffer += char;
      _lastKeyTime = now;
    }
  }

  // ─── BARCODE SCAN ───────────────────────────────

  Future<void> _handleBarcodeScan(String barcode) async {
    if (barcode.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    final product = await ref
        .read(productsRepositoryProvider)
        .findProductByBarcode(barcode);

    if (product != null) {
      ref.read(posStateProvider.notifier).addItem(product);
      _audioPlayer.resume();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productNotFound(barcode)),
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    }
  }

  void _onProductTapped(Product product) {
    ref.read(posStateProvider.notifier).addItem(product);
    _audioPlayer.resume();
  }

  void _openMobileScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          onScan: (code) async => await _handleBarcodeScan(code),
        ),
      ),
    );
  }

  // ─── HOLD & RECALL ──────────────────────────────

  void _handleHoldOrder() {
    final state = ref.read(posStateProvider);
    if (state.activeOrder.items.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    ref.read(posStateProvider.notifier).parkOrder();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.orderParked)));
  }

  void _showParkedOrdersDialog() {
    final state = ref.read(posStateProvider);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.recallOrder),
          content: SizedBox(
            width: 340,
            height: 400,
            child: state.parkedOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 48,
                            color: context.appColors.subtleText
                                .withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(l10n.noParkedOrders,
                            style: TextStyle(
                                color: context.appColors.subtleText)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: state.parkedOrders.length,
                    itemBuilder: (ctx, i) {
                      final order = state.parkedOrders[i];
                      final minutesAgo = DateTime.now()
                          .difference(order.createdAt)
                          .inMinutes;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: context.appColors.primary
                                .withValues(alpha: 0.1),
                            child: Icon(Icons.receipt_long,
                                color: context.appColors.primary),
                          ),
                          title: Text(l10n
                              .orderNumber(order.id.substring(0, 4))),
                          subtitle: Text(l10n.itemsAndTime(
                              order.items.length, minutesAgo)),
                          trailing: Text(
                            CurrencyFormatter.formatCentsToCurrency(
                              (order.total * 100).round(),
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.appColors.primary,
                            ),
                          ),
                          onTap: () {
                            ref
                                .read(posStateProvider.notifier)
                                .recallOrder(order.id);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.closeBtn),
            ),
          ],
        );
      },
    );
  }

  // ─── PAYMENT ────────────────────────────────────

  void _showPaymentDialog() {
    final state = ref.read(posStateProvider);
    if (state.activeOrder.items.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.cartEmpty)));
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final paymentMethodsAsync = ref.read(paymentMethodsProvider);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.orderDetails),
          content: SizedBox(
            width: 400,
            child: paymentMethodsAsync.when(
              data: (methods) {
                if (methods.isEmpty) return Text(l10n.criticalSetupError);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${l10n.total}: ${CurrencyFormatter.formatCentsToCurrency((state.activeOrder.total * 100).round())}",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 20),
                    ...methods.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _processTransaction(m);
                            },
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.payment),
                            label: Text(l10n.payWith(m.name)),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              error: (e, s) => Text("Error: $e"),
              loading: () => const CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _processTransaction(PaymentMethod method) async {
    setState(() => _isProcessing = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final profileData = ref.read(companyProfileProvider);

    // Check Period Lock
    final prefsRepo = ref.read(preferencesRepositoryProvider);
    final lockDate = await prefsRepo.getPeriodLockDate();
    if (lockDate != null) {
      final now = DateTime.now();
      final tDate = DateTime(now.year, now.month, now.day);
      final lDate = DateTime(lockDate.year, lockDate.month, lockDate.day);

      if (tDate.compareTo(lDate) <= 0) {
        setState(() => _isProcessing = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.periodLockedError),
            backgroundColor: context.appColors.error,
          ),
        );
        return;
      }
    }

    final order = ref.read(posStateProvider).activeOrder;
    final newItems = order.items;
    final totalAmount = order.total;

    // Convert to legacy items for receipt service
    final List<legacy.PosReceiptItem> legacyItems = newItems.map((item) {
      return legacy.PosReceiptItem(
        product: item.product,
        quantity: item.quantity,
      );
    }).toList();

    final accountsRepo = ref.read(accountsRepositoryProvider);
    final salesAccountId =
        await accountsRepo.getAccountIdByName(kSalesRevenueAccountName);

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
      final description = l10n.posSale(
        DateTime.now().microsecondsSinceEpoch.toString(),
      );

      await ref.read(transactionsRepositoryProvider).createPosSale(
            transactionCompanion: TransactionsCompanion.insert(
              description: description,
              transactionDate: DateTime.now(),
              attachmentPath: const d.Value(null),
              currencyCode: d.Value(ref.read(defaultCurrencyProvider)),
              relatedTransactionId: const d.Value(null),
            ),
            entries: entries,
            items: legacyItems,
            totalAmount: totalAmount,
          );

      // Print receipt
      try {
        final pdfData = await ref.read(receiptServiceProvider).generatePosReceipt(
              items: legacyItems,
              total: totalAmount,
              profile: profileData,
              l10n: l10n,
            );
        await Printing.layoutPdf(onLayout: (format) async => pdfData);
      } catch (e) {
        debugPrint("Print Error: $e");
      }

      // Cleanup
      ref.read(posStateProvider.notifier).clearActiveOrder();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.saleRecorded(totalAmount.toStringAsFixed(2))),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.transactionFailed} $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ─── FILTERING ──────────────────────────────────

  List<Product> _filterProducts(List<Product> allProducts) {
    var filtered = allProducts;

    // Category filter
    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((p) => p.categoryId == _selectedCategoryId)
          .toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((p) => p.name.toLowerCase().contains(query) ||
              (p.barcode?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    return filtered;
  }

  // ═══════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final parkCount = ref.watch(posStateProvider).parkedOrders.length;
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final productsAsync = ref.watch(allProductsStreamProvider);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        // ─── APP BAR ──────────────────────────────
        appBar: widget.isStandalone
            ? AppBar(
                title: _isSearching
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: l10n.searchProducts,
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: context.appColors.subtleText.withValues(alpha: 0.7),
                          ),
                        ),
                        style: TextStyle(color: context.appColors.onSurface),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      )
                    : Text(l10n.posTerminalTitle),
                actions: [
                  // Search
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search),
                    tooltip: l10n.searchProductTooltip,
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchQuery = '';
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                  // Barcode Scanner
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: l10n.scanMode,
                    onPressed: _openMobileScanner,
                  ),
                  // Parked Orders
                  Badge(
                    label: Text(parkCount.toString()),
                    isLabelVisible: parkCount > 0,
                    child: IconButton(
                      icon: const Icon(Icons.history),
                      onPressed: _showParkedOrdersDialog,
                      tooltip: l10n.recallOrderTooltip,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              )
            : null,

        // ─── BODY ─────────────────────────────────
        body: Stack(
          children: [
            Column(
              children: [
                if (!widget.isStandalone)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (_isSearching)
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: l10n.searchProducts,
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                setState(() => _searchQuery = value);
                              },
                            ),
                          )
                        else
                          Expanded(
                            child: Text(
                              l10n.posTerminalTitle,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: Icon(_isSearching ? Icons.close : Icons.search),
                          tooltip: l10n.searchProductTooltip,
                          onPressed: () {
                            setState(() {
                              _isSearching = !_isSearching;
                              if (!_isSearching) {
                                _searchQuery = '';
                                _searchController.clear();
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          tooltip: l10n.scanMode,
                          onPressed: _openMobileScanner,
                        ),
                        Badge(
                          label: Text(parkCount.toString()),
                          isLabelVisible: parkCount > 0,
                          child: IconButton(
                            icon: const Icon(Icons.history),
                            onPressed: _showParkedOrdersDialog,
                            tooltip: l10n.recallOrderTooltip,
                          ),
                        ),
                      ],
                    ),
                  ),
                // ── Category Filter Chips ──
                categoriesAsync.when(
                  data: (categories) => _buildCategoryChips(categories, l10n),
                  loading: () => const SizedBox(height: 50),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // ── Product Grid ──
                Expanded(
                  child: productsAsync.when(
                    data: (allProducts) {
                      final filtered = _filterProducts(allProducts);
                      return PosProductGrid(
                        products: filtered,
                        onAddToCart: _onProductTapped,
                      );
                    },
                    loading: () => const PosProductGrid(
                      products: [],
                      onAddToCart: _dummyAdd,
                      isLoading: true,
                    ),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),

            // ── Draggable Cart Bottom Sheet ──
            PosCartSheet(
              onPayPressed: _showPaymentDialog,
              onHoldPressed: _handleHoldOrder,
            ),
          ],
        ),

        // ─── FAB (mobile only) ────────────────────
        floatingActionButton: (!Platform.isWindows)
            ? Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: FloatingActionButton(
                  onPressed: _openMobileScanner,
                  child: const Icon(Icons.qr_code_scanner),
                ),
              )
            : null,
      ),
    );
  }

  // ─── CATEGORY CHIPS ─────────────────────────────

  Widget _buildCategoryChips(List<Category> categories, AppLocalizations l10n) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(l10n.allCategories),
              selected: _selectedCategoryId == null,
              selectedColor: context.appColors.primary,
              labelStyle: TextStyle(
                color: _selectedCategoryId == null
                    ? context.appColors.onPrimary
                    : null,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) {
                setState(() => _selectedCategoryId = null);
              },
            ),
          ),
          // Category chips
          ...categories.map((cat) {
            final isSelected = _selectedCategoryId == cat.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(cat.name),
                selected: isSelected,
                selectedColor: context.appColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? context.appColors.onPrimary : null,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedCategoryId = isSelected ? null : cat.id;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  static void _dummyAdd(Product p) {}
}