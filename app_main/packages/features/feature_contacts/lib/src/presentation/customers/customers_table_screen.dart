import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:shared_ui/shared_ui.dart';

import 'customer_form_screen.dart';
import 'customer_detail_screen.dart';

class CustomerDataSource extends DataTableSource {
  final List<Customer> customers;
  final BuildContext context;
  final String currencyCode;

  CustomerDataSource(this.customers, this.context, this.currencyCode);

  @override
  DataRow? getRow(int index) {
    if (index >= customers.length) return null;
    final customer = customers[index];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasBalance = customer.balance > 0;

    return DataRow(
      cells: [
        DataCell(Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(customer.phone ?? customer.email ?? '-')),
        DataCell(
          Text(
            CurrencyFormatter.formatAmount(customer.balance, currencyCode),
            style: TextStyle(
              color: hasBalance ? colorScheme.error : null,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DataCell(
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CustomerDetailScreen(customerId: customer.id),
                ),
              );
            },
          ),
        ),
      ],
      onSelectChanged: (_) {
         Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CustomerDetailScreen(customerId: customer.id),
            ),
          );
      }
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => customers.length;
  @override
  int get selectedRowCount => 0;
}

class CustomersTableScreen extends ConsumerStatefulWidget {
  const CustomersTableScreen({super.key});

  @override
  ConsumerState<CustomersTableScreen> createState() => _CustomersTableScreenState();
}

class _CustomersTableScreenState extends ConsumerState<CustomersTableScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    final currencyCode = ref.watch(currentCurrencyCodeProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CustomerFormScreen()),
          );
        },
        icon: const Icon(Icons.person_add),
        label: Text(l10n.addCustomerBtn),
      ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
        data: (customers) {
          if (customers.isEmpty) {
             return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noCustomersYet,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.addFirstCustomer,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          // Filter
          final filteredCustomers = customers.where((c) {
             if (_searchQuery.isEmpty) return true;
             return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                    (c.phone != null && c.phone!.contains(_searchQuery)) ||
                    (c.email != null && c.email!.toLowerCase().contains(_searchQuery.toLowerCase()));
          }).toList();

          final source = CustomerDataSource(filteredCustomers, context, currencyCode);
          final rowsPerPage = filteredCustomers.isEmpty ? 1 : filteredCustomers.length.clamp(1, 10);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.searchCustomers,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 16),
              if (filteredCustomers.isEmpty)
                 Center(child: Padding(
                   padding: const EdgeInsets.all(32.0),
                   child: Text(l10n.noCustomersMatch),
                 ))
              else
                 SingleChildScrollView(
                   scrollDirection: Axis.horizontal,
                   child: SizedBox(
                     width: math.max(MediaQuery.of(context).size.width - 32, 600.0),
                     child: PaginatedDataTable(
                       header: Text(l10n.customerBalances),
                       columns: [
                         DataColumn(label: Text(l10n.name)),
                         DataColumn(label: Text(l10n.contact)),
                         DataColumn(label: Text(l10n.balance)),
                         DataColumn(label: Text(l10n.actions)),
                       ],
                       source: source,
                       rowsPerPage: rowsPerPage,
                       availableRowsPerPage: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 50],
                       showCheckboxColumn: false,
                     ),
                   ),
                 ),
            ],
          );
        },
      ),
    );
  }
}
