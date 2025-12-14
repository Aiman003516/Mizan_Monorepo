import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return vendorsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Vendor')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (vendors) {
        final vendor = vendors.firstWhere(
          (v) => v.id == vendorId,
          orElse: () => throw Exception('Vendor not found'),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(vendor.name),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => VendorFormScreen(vendorId: vendor.id),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BillFormScreen(vendorId: vendor.id),
              ),
            ),
            icon: const Icon(Icons.receipt),
            label: const Text('New Bill'),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vendor Info Card
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
                            backgroundColor: colorScheme.tertiary,
                            child: Text(
                              vendor.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: colorScheme.onTertiary,
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
                                  vendor.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (vendor.email != null &&
                                    vendor.email!.isNotEmpty)
                                  Text(
                                    vendor.email!,
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
                        value: vendor.phone ?? '-',
                      ),
                      _InfoRow(
                        icon: Icons.location_on,
                        label: 'Address',
                        value: vendor.address ?? '-',
                      ),
                      _InfoRow(
                        icon: Icons.receipt_long,
                        label: 'Tax ID',
                        value: vendor.taxId ?? '-',
                      ),
                      _InfoRow(
                        icon: Icons.schedule,
                        label: 'Payment Terms',
                        value: vendor.paymentTerms ?? '-',
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
                      colors: vendor.balance > 0
                          ? [
                              colorScheme.tertiary,
                              colorScheme.tertiaryContainer,
                            ]
                          : [Colors.green, Colors.green.shade300],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'We Owe',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${(vendor.balance / 100).toStringAsFixed(2)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bills Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Bills',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                billsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading bills: $e'),
                  ),
                  data: (bills) {
                    if (bills.isEmpty) {
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
                              Icons.receipt_outlined,
                              size: 48,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No bills yet',
                              style: TextStyle(color: colorScheme.outline),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bills.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) =>
                          _BillCard(bill: bills[index]),
                    );
                  },
                ),
                const SizedBox(height: 80),
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

class _BillCard extends StatelessWidget {
  final Bill bill;
  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outstanding = bill.totalAmount - bill.amountPaid;
    final isPaid = outstanding <= 0;

    Color statusColor = switch (bill.status) {
      'paid' => Colors.green,
      'overdue' => colorScheme.error,
      'partial' => Colors.orange,
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
              '\$${(bill.totalAmount / 100).toStringAsFixed(2)}',
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
            ? const Icon(Icons.check_circle, color: Colors.green)
            : Text(
                '\$${(outstanding / 100).toStringAsFixed(2)}',
                style: TextStyle(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
