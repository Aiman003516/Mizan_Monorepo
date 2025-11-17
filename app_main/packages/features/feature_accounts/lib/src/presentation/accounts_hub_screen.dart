import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_accounts/src/presentation/add_account_screen.dart';
import 'package:feature_accounts/src/presentation/accounts_list_screen.dart';
import 'package:feature_accounts/src/presentation/filtered_accounts_list_page.dart';
import 'package:core_database/core_database.dart';

class AccountsHubScreen extends ConsumerWidget {
  const AccountsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3, // All, Clients, Suppliers
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.accounts),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.all),
              Tab(text: l10n.clients),
              Tab(text: l10n.suppliers),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AccountsListScreen(),
            FilteredAccountsListPage(
              classificationFilter: kClassificationClients,
            ),
            FilteredAccountsListPage(
              classificationFilter: kClassificationSuppliers,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddAccountScreen(),
              ),
            );
          },
          tooltip: l10n.addNewAccount,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}