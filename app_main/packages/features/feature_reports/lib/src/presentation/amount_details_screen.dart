// // lib/src/features/reports/presentation/amount_details_screen.dart

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// // ⭐️ 1. IMPORT THE GENERATED LOCALIZATIONS FILE
// import 'package:mizan/src/core/l10n/app_localizations.dart';
// import '../data/report_models.dart';
// import '../data/reports_service.dart';
// import 'package:mizan/src/core/database/initial_constants.dart' as c;
// import 'package:mizan/src/features/transactions/presentation/add_amount_screen.dart';

// class AmountDetailsScreen extends ConsumerStatefulWidget {
//   const AmountDetailsScreen({super.key});

//   @override
//   ConsumerState<AmountDetailsScreen> createState() =>
//       _AmountDetailsScreenState();
// }

// class _AmountDetailsScreenState extends ConsumerState<AmountDetailsScreen> {
//   ReportFilter _selectedReportFilter = ReportFilter.ALL;
//   String _selectedClassification = c.kClassificationGeneral;

//   @override
//   Widget build(BuildContext context) {
//     // ⭐️ 2. GET L10N OBJECT
//     final l10n = AppLocalizations.of(context)!;

//     return DefaultTabController(
//       length: 3, // General, Clients, Suppliers
//       child: Scaffold(
//         appBar: AppBar(
//           // ⭐️ 3. USE L10N KEYS
//           title: Text(l10n.accountActivity),
//           actions: [
//             IconButton(
//                 icon: const Icon(Icons.picture_as_pdf), onPressed: () {}),
//             IconButton(icon: const Icon(Icons.search), onPressed: () {}),
//           ],
//           bottom: PreferredSize(
//             preferredSize: const Size.fromHeight(kToolbarHeight * 2 + 10),
//             child: Column(
//               children: [
//                 TabBar(
//                   // ⭐️ 3. USE L10N KEYS
//                   tabs: [
//                     Tab(text: l10n.general),
//                     Tab(text: l10n.clients),
//                     Tab(text: l10n.suppliers),
//                   ],
//                   onTap: (index) {
//                     setState(() {
//                       _selectedClassification = [
//                         c.kClassificationGeneral,
//                         c.kClassificationClients,
//                         c.kClassificationSuppliers
//                       ][index];
//                     });
//                   },
//                 ),
//                 Padding(
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
//                   child: SegmentedButton<ReportFilter>(
//                     // ⭐️ 3. USE L10N KEYS
//                     segments: [
//                       ButtonSegment(
//                           value: ReportFilter.ALL,
//                           label: Text(l10n.all),
//                           icon: const Icon(Icons.all_inclusive)),
//                       ButtonSegment(
//                           value: ReportFilter.POS_ONLY,
//                           label: Text(l10n.posSales),
//                           icon: const Icon(Icons.point_of_sale)),
//                       ButtonSegment(
//                           value: ReportFilter.ACCOUNTS_ONLY,
//                           label: Text(l10n.accounts),
//                           icon: const Icon(Icons.account_balance_wallet)),
//                     ],
//                     selected: {_selectedReportFilter},
//                     onSelectionChanged: (Set<ReportFilter> newSelection) {
//                       setState(() {
//                         _selectedReportFilter = newSelection.first;
//                       });
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         body: _AmountDetailsListView(
//           filter: TotalAmountsFilter(
//             reportFilter: _selectedReportFilter,
//             classificationName: _selectedClassification,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _AmountDetailsListView extends ConsumerWidget {
//   final TotalAmountsFilter filter;

//   const _AmountDetailsListView({required this.filter});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // ⭐️ 2. GET L10N OBJECT
//     final l10n = AppLocalizations.of(context)!;
//     final detailsAsync = ref.watch(filteredTransactionDetailsProvider(filter));

//     return detailsAsync.when(
//       data: (details) {
//         if (details.isEmpty) {
//           // ⭐️ 3. USE L10N KEYS
//           return Center(child: Text(l10n.noTransactionEntries));
//         }

//         return SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: DataTable(
//             // ⭐️ 3. USE L10N KEYS
//             columns: [
//               DataColumn(label: Text(l10n.account)),
//               DataColumn(label: Text(l10n.date)),
//               DataColumn(label: Text(l10n.details)),
//               DataColumn(label: Text(l10n.amount), numeric: true),
//             ],
//             rows: details.map((detail) {
//               final isDebit = detail.entryAmount > 0;
//               final amountColor = isDebit ? Colors.green : Colors.red;

//               final amountText = isDebit
//                   ? '${detail.entryAmount.abs().toStringAsFixed(2)} ${detail.currencyCode}'
//                   : '(${detail.entryAmount.abs().toStringAsFixed(2)} ${detail.currencyCode})';

//               return DataRow(
//                 onSelectChanged: (isSelected) {
//                   if (isSelected == true) {
//                     Navigator.of(context).push(MaterialPageRoute(
//                       builder: (context) => AddAmountScreen(
//                         accountId: detail.accountId,
//                         classificationName:
//                         detail.classificationName ?? c.kClassificationGeneral,
//                       ),
//                     ));
//                   }
//                 },
//                 cells: [
//                   DataCell(Text(detail.accountName)),
//                   DataCell(
//                       Text(DateFormat.yMd().format(detail.transactionDate))),
//                   DataCell(Text(detail.transactionDescription)),
//                   DataCell(
//                     Text(
//                       amountText,
//                       style: TextStyle(
//                           color: amountColor, fontWeight: FontWeight.w500),
//                       textAlign: TextAlign.right,
//                     ),
//                   ),
//                 ],
//               );
//             }).toList(),
//           ),
//         );
//       },
//       // ⭐️ 3. USE L10N KEYS
//       error: (err, stack) => Center(child: Text('${l10n.error} ${err.toString()}')),
//       loading: () => const Center(child: CircularProgressIndicator()),
//     );
//   }
// }