// Hierarchical Accounts List Widget
// Displays accounts grouped by type with expandable parent/child hierarchy
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_accounts/src/presentation/accounts_list_provider.dart';
import 'package:feature_accounts/src/presentation/add_account_screen.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:intl/intl.dart';

/// A widget that displays accounts in a hierarchical tree structure
class HierarchicalAccountsList extends ConsumerStatefulWidget {
  const HierarchicalAccountsList({super.key});

  @override
  ConsumerState<HierarchicalAccountsList> createState() =>
      _HierarchicalAccountsListState();
}

class _HierarchicalAccountsListState
    extends ConsumerState<HierarchicalAccountsList> {
  final Set<String> _expandedAccounts = {};
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  String _formatBalance(double balance) {
    return _currencyFormat.format(balance);
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final summariesAsync = ref.watch(allAccountSummariesProvider);

    return summariesAsync.when(
      data: (summaries) {
        return accountsAsync.when(
          data: (accounts) => _buildHierarchicalList(accounts, summaries),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildHierarchicalList(
    List<Account> accounts,
    Map<String, AccountSummary> summaries,
  ) {
    // Group accounts by type
    final groupedByType = <String, List<Account>>{};
    for (final account in accounts) {
      groupedByType.putIfAbsent(account.type, () => []).add(account);
    }

    // Sort account types in standard order
    final typeOrder = ['ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'EXPENSE'];
    final sortedTypes = groupedByType.keys.toList()
      ..sort((a, b) {
        final indexA = typeOrder.indexOf(a);
        final indexB = typeOrder.indexOf(b);
        return indexA.compareTo(indexB);
      });

    return ListView(
      children: sortedTypes.map((type) {
        final typeAccounts = groupedByType[type]!;
        return _buildTypeSection(type, typeAccounts, summaries);
      }).toList(),
    );
  }

  Widget _buildTypeSection(
    String type,
    List<Account> accounts,
    Map<String, AccountSummary> summaries,
  ) {
    // Calculate total balance for this type
    double typeTotal = 0;
    for (final account in accounts) {
      final summary = summaries[account.id];
      typeTotal +=
          account.initialBalance.toDouble() + (summary?.netBalance ?? 0);
    }

    // Build tree structure
    final rootAccounts = accounts
        .where((a) => a.parentAccountId == null)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _getTypeIcon(type),
                    color: _getTypeColor(type),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getTypeLabel(type),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getTypeColor(type),
                    ),
                  ),
                ],
              ),
              Text(
                _formatBalance(typeTotal),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getTypeColor(type),
                ),
              ),
            ],
          ),
        ),
        // Accounts in this type
        ...rootAccounts.map(
          (account) => _buildAccountTile(account, accounts, summaries, 0),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildAccountTile(
    Account account,
    List<Account> allAccounts,
    Map<String, AccountSummary> summaries,
    int depth,
  ) {
    final children = allAccounts
        .where((a) => a.parentAccountId == account.id)
        .toList();
    final hasChildren = children.isNotEmpty;
    final isExpanded = _expandedAccounts.contains(account.id);

    final summary = summaries[account.id];
    final balance =
        account.initialBalance.toDouble() + (summary?.netBalance ?? 0);

    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddAccountScreen(accountToEdit: account),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.only(
              left: 16.0 + (depth * 20.0),
              right: 16,
              top: 12,
              bottom: 12,
            ),
            child: Row(
              children: [
                // Expand/collapse button for parents
                if (hasChildren)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedAccounts.remove(account.id);
                        } else {
                          _expandedAccounts.add(account.id);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 28),

                // Account icon/indicator
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: account.isHeader
                        ? Colors.grey[400]
                        : _getTypeColor(account.type),
                  ),
                ),

                // Account name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: TextStyle(
                          fontWeight: account.isHeader
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: account.isHeader ? 15 : 14,
                        ),
                      ),
                      if (account.accountNumber != null)
                        Text(
                          account.accountNumber.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),

                // Balance
                Text(
                  _formatBalance(balance),
                  style: TextStyle(
                    color: balance >= 0 ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Children (if expanded)
        if (hasChildren && isExpanded)
          ...children.map(
            (child) =>
                _buildAccountTile(child, allAccounts, summaries, depth + 1),
          ),
      ],
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'ASSET':
        return Icons.account_balance_wallet;
      case 'LIABILITY':
        return Icons.credit_card;
      case 'EQUITY':
        return Icons.pie_chart;
      case 'REVENUE':
        return Icons.trending_up;
      case 'EXPENSE':
        return Icons.trending_down;
      default:
        return Icons.account_balance;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'ASSET':
        return Colors.blue[700]!;
      case 'LIABILITY':
        return Colors.red[700]!;
      case 'EQUITY':
        return Colors.purple[700]!;
      case 'REVENUE':
        return Colors.green[700]!;
      case 'EXPENSE':
        return Colors.orange[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'ASSET':
        return 'Assets';
      case 'LIABILITY':
        return 'Liabilities';
      case 'EQUITY':
        return 'Equity';
      case 'REVENUE':
        return 'Revenue';
      case 'EXPENSE':
        return 'Expenses';
      default:
        return type;
    }
  }
}
