import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:shared_ui/shared_ui.dart';

import 'vendor_form_screen.dart';
import 'bill_form_screen.dart';

/// 📋 Vendor Detail Screen
class VendorDetailScreen extends ConsumerWidget {
  final String vendorId;
  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(vendorBillsProvider(vendorId));
    final vendorsAsync = ref.watch(vendorsStreamProvider);
    final l10n = AppLocalizations.of(context)!;

    return vendorsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.vendorDetailTitle)),
        body: Center(child: Text('Error: $e')),
      ),
      data: (vendors) {
        final vendor = vendors.firstWhere(
          (v) => v.id == vendorId,
          orElse: () => throw Exception('Vendor not found'),
        );
        final currencyCode = ref.watch(currentCurrencyCodeProvider);

        return ContactDetailBody(
          type: ContactType.payable,
          contactName: vendor.name,
          email: vendor.email,
          phone: vendor.phone ?? '-',
          address: vendor.address ?? '-',
          taxId: vendor.taxId ?? '-',
          extraInfoLabel: l10n.paymentTerms,
          extraInfoValue: vendor.paymentTerms ?? '-',
          balance: vendor.balance,
          currencyCode: currencyCode,
          outstandingBalanceLabel: l10n.outstandingBalance,
          onEdit: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => VendorFormScreen(vendorId: vendor.id),
              ),
            );
          },
          onNewDocument: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BillFormScreen(vendorId: vendor.id),
              ),
            );
          },
          newDocumentLabel: l10n.newBill,
          newDocumentIcon: Icons.receipt,
          documentsSectionTitle: l10n.bills,
          documentsCount: billsAsync.valueOrNull?.length ?? 0,
          isLoadingDocuments: billsAsync.isLoading,
          documentsError: billsAsync.hasError ? billsAsync.error : null,
          hasDocuments: (billsAsync.valueOrNull?.length ?? 0) > 0,
          noDocumentsMessage: l10n.noBillsYet,
          noDocumentsIcon: Icons.receipt_outlined,
          documentBuilder: (context, index) {
            final bill = billsAsync.value![index];
            return _BillCard(bill: bill, currencyCode: currencyCode);
          },
        );
      },
    );
  }
}

class _BillCard extends StatelessWidget {
  final Bill bill;
  final String currencyCode;
  const _BillCard({required this.bill, required this.currencyCode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outstanding = bill.totalAmount - bill.amountPaid;
    final isPaid = outstanding <= 0;

    Color statusColor = switch (bill.status) {
      'paid' => context.appColors.success,
      'overdue' => colorScheme.error,
      'partial' => context.appColors.warning,
      _ => colorScheme.tertiary,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 48,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              bill.billNumber,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              CurrencyFormatter.formatAmount(bill.totalAmount, currencyCode),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${bill.billDate.day}/${bill.billDate.month}/${bill.billDate.year}',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                bill.status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: isPaid
            ? Icon(Icons.check_circle, color: context.appColors.success)
            : Text(
                CurrencyFormatter.formatAmount(outstanding, currencyCode),
                style: TextStyle(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
