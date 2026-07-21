import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:shared_ui/shared_ui.dart';

import 'vendor_form_screen.dart';
import 'vendor_detail_screen.dart';

class VendorDataSource extends DataTableSource {
  final List<Vendor> vendors;
  final BuildContext context;
  final String currencyCode;

  VendorDataSource(this.vendors, this.context, this.currencyCode);

  @override
  DataRow? getRow(int index) {
    if (index >= vendors.length) return null;
    final vendor = vendors[index];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasBalance = vendor.balance > 0;

    return DataRow(
      cells: [
        DataCell(Text(vendor.name, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(vendor.phone ?? vendor.email ?? '-')),
        DataCell(
          Text(
            CurrencyFormatter.formatAmount(vendor.balance, currencyCode),
            style: TextStyle(
              color: hasBalance ? colorScheme.tertiary : null,
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
                  builder: (context) => VendorDetailScreen(vendorId: vendor.id),
                ),
              );
            },
          ),
        ),
      ],
      onSelectChanged: (_) {
         Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VendorDetailScreen(vendorId: vendor.id),
            ),
          );
      }
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => vendors.length;
  @override
  int get selectedRowCount => 0;
}

class VendorsTableScreen extends ConsumerStatefulWidget {
  const VendorsTableScreen({super.key});

  @override
  ConsumerState<VendorsTableScreen> createState() => _VendorsTableScreenState();
}

class _VendorsTableScreenState extends ConsumerState<VendorsTableScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(vendorsStreamProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    final currencyCode = ref.watch(currentCurrencyCodeProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const VendorFormScreen()),
          );
        },
        icon: const Icon(Icons.add_business),
        label: Text(l10n.addVendorBtn),
      ),
      body: vendorsAsync.when(
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
                    l10n.noVendorsYet,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.addFirstVendor,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          // Filter
          final filteredVendors = vendors.where((v) {
             if (_searchQuery.isEmpty) return true;
             return v.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                    (v.phone != null && v.phone!.contains(_searchQuery)) ||
                    (v.email != null && v.email!.toLowerCase().contains(_searchQuery.toLowerCase()));
          }).toList();

          final source = VendorDataSource(filteredVendors, context, currencyCode);
          final rowsPerPage = filteredVendors.isEmpty ? 1 : filteredVendors.length.clamp(1, 10);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.searchVendors,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 16),
               if (filteredVendors.isEmpty)
                 Center(child: Padding(
                   padding: const EdgeInsets.all(32.0),
                   child: Text(l10n.noVendorsMatch),
                 ))
              else
                 SingleChildScrollView(
                   scrollDirection: Axis.horizontal,
                   child: SizedBox(
                     width: math.max(MediaQuery.of(context).size.width - 32, 600.0),
                     child: PaginatedDataTable(
                       header: Text(l10n.vendorBalances),
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
