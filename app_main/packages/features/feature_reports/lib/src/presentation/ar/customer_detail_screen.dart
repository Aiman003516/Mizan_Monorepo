import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';

import 'customer_form_screen.dart';
import 'invoice_form_screen.dart';

/// 📋 Customer Detail Screen
/// Shows customer info, invoices, and balance history.
class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(customerInvoicesProvider(customerId));
    final customersAsync = ref.watch(customersStreamProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return customersAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Customer')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (customers) {
        final customer = customers.firstWhere(
          (c) => c.id == customerId,
          orElse: () => throw Exception('Customer not found'),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(customer.name),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          CustomerFormScreen(customerId: customer.id),
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      InvoiceFormScreen(customerId: customer.id),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long),
            label: const Text('New Invoice'),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Customer Info Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: colorScheme.primary,
                            child: Text(
                              customer.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (customer.email != null &&
                                    customer.email!.isNotEmpty)
                                  Text(
                                    customer.email!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _InfoRow(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: customer.phone ?? '-',
                      ),
                      _InfoRow(
                        icon: Icons.location_on,
                        label: 'Address',
                        value: customer.address ?? '-',
                      ),
                      _InfoRow(
                        icon: Icons.receipt_long,
                        label: 'Tax ID',
                        value: customer.taxId ?? '-',
                      ),
                      _InfoRow(
                        icon: Icons.credit_card,
                        label: 'Credit Limit',
                        value:
                            '\$${(customer.creditLimit / 100).toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),

                // Balance Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: customer.balance > 0
                          ? [colorScheme.error, colorScheme.errorContainer]
                          : [Colors.green, Colors.green.shade300],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Outstanding Balance',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${(customer.balance / 100).toStringAsFixed(2)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Invoices Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Invoices',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      invoicesAsync.when(
                        data: (invoices) => Text(
                          '${invoices.length} invoices',
                          style: theme.textTheme.bodySmall,
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),

                invoicesAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading invoices: $e'),
                  ),
                  data: (invoices) {
                    if (invoices.isEmpty) {
                      return Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No invoices yet',
                              style: TextStyle(color: colorScheme.outline),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: invoices.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        return _InvoiceCard(invoice: invoice);
                      },
                    );
                  },
                ),

                const SizedBox(height: 80), // FAB space
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;

  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outstanding = invoice.totalAmount - invoice.amountPaid;
    final isPaid = outstanding <= 0;

    Color statusColor;
    switch (invoice.status) {
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'overdue':
        statusColor = colorScheme.error;
        break;
      case 'partial':
        statusColor = Colors.orange;
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
              '\$${(invoice.totalAmount / 100).toStringAsFixed(2)}',
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
            ? const Icon(Icons.check_circle, color: Colors.green)
            : Text(
                '\$${(outstanding / 100).toStringAsFixed(2)}',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
        onTap: () {
          // TODO: Navigate to invoice detail
        },
      ),
    );
  }
}
