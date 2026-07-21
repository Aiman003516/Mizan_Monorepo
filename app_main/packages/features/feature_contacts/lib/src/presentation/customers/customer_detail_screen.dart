import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:shared_ui/shared_ui.dart';

import 'customer_form_screen.dart';
import 'invoice_form_screen.dart';
import 'widgets/quick_adjustment_dialog.dart';

/// 📋 Customer Detail Screen
/// Shows customer info, invoices, and balance history.
class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(customerInvoicesProvider(customerId));
    final customersAsync = ref.watch(customersStreamProvider);
    final l10n = AppLocalizations.of(context)!;

    return customersAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.customerDetailTitle)),
        body: Center(child: Text('Error: $e')),
      ),
      data: (customers) {
        final customer = customers.firstWhere(
          (c) => c.id == customerId,
          orElse: () => throw Exception('Customer not found'),
        );
        final currencyCode = ref.watch(currentCurrencyCodeProvider);

        return ContactDetailBody(
          type: ContactType.receivable,
          contactName: customer.name,
          email: customer.email,
          phone: customer.phone ?? '-',
          address: customer.address ?? '-',
          taxId: customer.taxId ?? '-',
          extraInfoLabel: l10n.creditLimit,
          extraInfoValue: CurrencyFormatter.formatAmount(customer.creditLimit, currencyCode),
          balance: customer.balance,
          currencyCode: currencyCode,
          outstandingBalanceLabel: l10n.outstandingBalance,
          quickAdjustmentLabel: l10n.quickLedgerAdjustment,
          onEdit: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CustomerFormScreen(customerId: customer.id),
              ),
            );
          },
          onNewDocument: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => InvoiceFormScreen(customerId: customer.id),
              ),
            );
          },
          onQuickAdjustment: () {
            showDialog(
              context: context,
              builder: (context) => QuickAdjustmentDialog(
                customerId: customer.id,
                customerName: customer.name,
              ),
            );
          },
          newDocumentLabel: l10n.newInvoice,
          newDocumentIcon: Icons.receipt_long,
          documentsSectionTitle: l10n.invoices,
          documentsCount: invoicesAsync.valueOrNull?.length ?? 0,
          isLoadingDocuments: invoicesAsync.isLoading,
          documentsError: invoicesAsync.hasError ? invoicesAsync.error : null,
          hasDocuments: (invoicesAsync.valueOrNull?.length ?? 0) > 0,
          noDocumentsMessage: l10n.noInvoicesYet,
          noDocumentsIcon: Icons.receipt_long_outlined,
          documentBuilder: (context, index) {
            final invoice = invoicesAsync.value![index];
            return _InvoiceCard(invoice: invoice, currencyCode: currencyCode);
          },
        );
      },
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final String currencyCode;

  const _InvoiceCard({required this.invoice, required this.currencyCode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outstanding = invoice.totalAmount - invoice.amountPaid;
    final isPaid = outstanding <= 0;

    Color statusColor;
    switch (invoice.status) {
      case 'paid':
        statusColor = context.appColors.success;
        break;
      case 'overdue':
        statusColor = colorScheme.error;
        break;
      case 'partial':
        statusColor = context.appColors.warning;
        break;
      default:
        statusColor = colorScheme.primary;
    }

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
              invoice.invoiceNumber,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              CurrencyFormatter.formatAmount(invoice.totalAmount, currencyCode),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                invoice.status.toUpperCase(),
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
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
        onTap: () {},
      ),
    );
  }
}
