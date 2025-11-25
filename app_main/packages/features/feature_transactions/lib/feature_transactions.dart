// Data
export 'src/data/receipt_service.dart';
export 'src/data/transactions_repository.dart';
//
// 💡--- THIS IS THE FIX ---
// Export the placeholder provider so main.dart can override it.
export 'src/data/database_provider.dart';
//
//

// Presentation
export 'src/presentation/add_amount_screen.dart';
export 'src/presentation/barcode_scanner_screen.dart';
export 'src/presentation/general_journal_screen.dart';
export 'src/presentation/make_payment_screen.dart';
export 'src/presentation/order_details_screen.dart';
export 'src/presentation/order_history_screen.dart';
export 'src/presentation/order_history_provider.dart';
export 'src/presentation/pos_receipt_provider.dart';
export 'src/presentation/pos_screen.dart';
export 'src/presentation/purchase_screen.dart';
export 'src/presentation/return_items_screen.dart';
export 'src/presentation/transactions_list_provider.dart';
export 'src/presentation/transactions_list_screen.dart';
export 'src/presentation/adjusting_entries_screen.dart'; // ⭐️ NEW: Phase 2.1
export 'src/presentation/period_end_wizard_screen.dart';
export 'src/presentation/bank_reconciliation_screen.dart';