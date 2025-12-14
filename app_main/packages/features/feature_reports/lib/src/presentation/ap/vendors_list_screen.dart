import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';

import 'vendor_form_screen.dart';
import 'vendor_detail_screen.dart';

/// 🏢 Vendors List Screen
/// Displays all vendors with outstanding balances and quick actions.
class VendorsListScreen extends ConsumerWidget {
  const VendorsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(vendorsStreamProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Vendors'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const VendorFormScreen()),
          );
        },
        icon: const Icon(Icons.add_business),
        label: const Text('Add Vendor'),
      ),
      body: vendorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (vendors) {
          if (vendors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 64,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No vendors yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the button below to add your first vendor',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          int totalPayable = 0;
          for (final v in vendors) {
            totalPayable += v.balance;
          }

          return Column(
            children: [
              // Summary Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.tertiary,
                      colorScheme.tertiaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Payable',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onTertiary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${(totalPayable / 100).toStringAsFixed(2)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onTertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${vendors.length} vendors',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onTertiary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Vendor List
              Expanded(
                child: ListView.builder(
                  itemCount: vendors.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final vendor = vendors[index];
                    final hasBalance = vendor.balance > 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: hasBalance
                              ? colorScheme.tertiaryContainer
                              : colorScheme.surfaceContainerHighest,
                          child: Text(
                            vendor.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: hasBalance
                                  ? colorScheme.tertiary
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          vendor.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle:
                            vendor.email != null && vendor.email!.isNotEmpty
                            ? Text(vendor.email!)
                            : vendor.phone != null && vendor.phone!.isNotEmpty
                            ? Text(vendor.phone!)
                            : null,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${(vendor.balance / 100).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: hasBalance ? colorScheme.tertiary : null,
                              ),
                            ),
                            if (hasBalance)
                              Text(
                                'We Owe',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.tertiary,
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  VendorDetailScreen(vendorId: vendor.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
