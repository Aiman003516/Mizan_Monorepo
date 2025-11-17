import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// UPDATED Local Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:core_data/core_data.dart';
import 'package:core_database/core_database.dart' as c;

import 'package:feature_accounts/feature_accounts.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_products/feature_products.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:feature_transactions/feature_transactions.dart';
import 'package:feature_sync/feature_sync.dart';
import 'package:feature_dashboard/src/presentation/main_nav_provider.dart';
import 'package:feature_dashboard/src/presentation/dashboard_providers.dart';


class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSyncWarningMaybe();
    });
  }

  Future<void> _showSyncWarningMaybe() async {
    final authState = ref.read(authControllerProvider);
    if (authState.status == AuthStatus.unauthenticated) {
      final prefs = ref.read(preferencesRepositoryProvider);
      final hasSeenWarning = prefs.hasSeenSyncWarning();

      if (!hasSeenWarning && mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.dataSafetyWarning),
            content: Text(l10n.dataSafetyMessage),
            actions: [
              TextButton(
                child: Text(l10n.ok),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
        await prefs.setHasSeenSyncWarning(true);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _stopSearching() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      ref.read(mainDashboardSearchProvider.notifier).state = '';
    });
  }

  Widget _buildAppBarTitle(MainPage currentPage, BuildContext context) {
    if (_isSearching) {
      return TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.search,
          border: InputBorder.none,
          filled: false,
        ),
        onChanged: (query) {
          ref.read(mainDashboardSearchProvider.notifier).state = query;
        },
      );
    }

    switch (currentPage) {
      case MainPage.dashboard:
        return Text(l10n.mainDashboard);
      case MainPage.pos:
        return Text(l10n.newSalePOS);
      case MainPage.reportTotalAmounts:
        return Text(l10n.totalAmountsReport);
      case MainPage.reportMonthlyAmounts:
        return Text(l10n.monthlyAmountsReport);
      case MainPage.reportAccountActivity:
        return Text(l10n.accountActivity);
      case MainPage.manageAccounts:
        return Text(l10n.manageAccounts);
      case MainPage.manageProducts:
        return Text(l10n.manageProducts);
      case MainPage.manageCategories:
        return Text(l10n.manageCategories);
      case MainPage.settings:
        return Text(l10n.settings);
      case MainPage.orderHistory:
        return Text(l10n.orderHistory);
      case MainPage.reportProfitAndLoss:
        return Text(l10n.profitAndLossReport);
      case MainPage.reportBalanceSheet:
        return Text(l10n.balanceSheetReport);
      case MainPage.reportTrialBalance:
        return Text(l10n.trialBalanceReport);
    }
  }

  List<Widget> _buildAppBarActions(
    MainPage currentPage,
    AuthStatus authStatus,
    bool isSyncing,
  ) {
    List<Widget> actions = [];
    final bool isOffline = authStatus == AuthStatus.authenticated_offline;

    final canSearch = currentPage == MainPage.dashboard ||
        currentPage == MainPage.reportTotalAmounts ||
        currentPage == MainPage.reportMonthlyAmounts ||
        currentPage == MainPage.manageAccounts ||
        currentPage == MainPage.manageProducts ||
        currentPage == MainPage.manageCategories;

    if (canSearch) {
      if (_isSearching) {
        actions.add(IconButton(
          icon: const Icon(Icons.close),
          onPressed: _stopSearching,
        ));
      } else {
        actions.add(IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ));
      }
    }

    if (currentPage != MainPage.settings &&
        authStatus != AuthStatus.unauthenticated) {
      if (isSyncing) {
        actions.add(const Padding(
          padding: EdgeInsets.all(16.0),
          child: SizedBox(
            width: 24,
            height: 24,
            child:
                CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ),
        ));
      } else {
        actions.add(IconButton(
          icon: const Icon(Icons.sync),
          tooltip: l10n.syncData,
          onPressed: isOffline
              ? null
              : () {
                  ref.read(syncControllerProvider.notifier).runBackup();
                },
        ));
      }
    }
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final authStatus = authState.status;

    final syncState = ref.watch(syncControllerProvider);
    final isSyncing = syncState.isLoading;

    final currentPage = ref.watch(mainNavProvider);
    final isDashboard = currentPage == MainPage.dashboard;

    if (_isSearching &&
        !(currentPage == MainPage.dashboard ||
            currentPage == MainPage.reportTotalAmounts ||
            currentPage == MainPage.reportMonthlyAmounts ||
            currentPage == MainPage.manageAccounts ||
            currentPage == MainPage.manageProducts ||
            currentPage == MainPage.manageCategories)) {
      _stopSearching();
    }

    ref.listen(syncControllerProvider, (previous, next) {
      if (next.isLoading) return;
      if (next.hasError) {
        final e = next.error;
        final errorMessage = e is String ? e : e.toString();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.backupFailed(errorMessage)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      if (!next.hasError && (previous?.isLoading ?? false)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.restoreSuccessful),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            tooltip: l10n.openNavigationMenu,
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: _buildAppBarTitle(currentPage, context),
          actions: _buildAppBarActions(currentPage, authStatus, isSyncing),
          bottom: isDashboard
              ? TabBar(
                  tabs: [
                    Tab(text: l10n.general),
                    Tab(text: l10n.clients),
                    Tab(text: l10n.suppliers),
                  ],
                )
              : null,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  authStatus != AuthStatus.unauthenticated
                      ? l10n.mizanUser
                      : l10n.notSignedIn,
                ),
                accountEmail: Text(
                  authStatus == AuthStatus.authenticated_online
                      ? l10n.online
                      : authStatus == AuthStatus.authenticated_offline
                          ? l10n.offlineMode
                          : l10n.syncDisabled,
                ),
                currentAccountPicture: const CircleAvatar(
                  child: Icon(Icons.person, size: 40),
                ),
                otherAccountsPictures: [
                  if (authStatus == AuthStatus.authenticated_online)
                    const Icon(Icons.cloud_queue, color: Colors.white)
                  else if (authStatus == AuthStatus.authenticated_offline)
                    const Icon(Icons.cloud_off, color: Colors.white)
                  else
                    const Icon(Icons.cloud_off, color: Colors.grey)
                ],
              ),

              ListTile(
                leading: const Icon(Icons.dashboard),
                title: Text(l10n.mainDashboard),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(mainNavProvider.notifier).state = MainPage.dashboard;
                },
              ),
              ListTile(
                leading: const Icon(Icons.point_of_sale),
                title: Text(l10n.newSalePOS),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(mainNavProvider.notifier).state = MainPage.pos;
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: Text(l10n.orderHistory),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(mainNavProvider.notifier).state =
                      MainPage.orderHistory;
                },
              ),

              const Divider(),
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(l10n.reports,
                      style: const TextStyle(fontWeight: FontWeight.bold))),
              ListTile(
                leading: const Icon(Icons.poll),
                title: Text(l10n.totalAmountsSummary),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(mainNavProvider.notifier).state =
                      MainPage.reportTotalAmounts;
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: Text(l10n.monthlyAmountsSummary),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(mainNavProvider.notifier).state =
                      MainPage.reportMonthlyAmounts;
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text(l10n.accountActivityLedger),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(mainNavProvider.notifier).state =
                      MainPage.reportAccountActivity;
                },
              ),
              ListTile(
                leading: const Icon(Icons.assessment_outlined),
                title: Text(l10n.profitAndLossReport),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(mainNavProvider.notifier).state =
                      MainPage.reportProfitAndLoss;
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.account_balance_outlined),
                title: Text(l10n.balanceSheetReport),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(mainNavProvider.notifier).state =
                      MainPage.reportBalanceSheet;
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.table_chart_outlined),
                title: Text(l10n.trialBalanceReport),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(mainNavProvider.notifier).state =
                      MainPage.reportTrialBalance;
                },
              ),

              const Divider(),
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(l10n.management,
                      style: const TextStyle(fontWeight: FontWeight.bold))),
              ListTile(
                leading: const Icon(Icons.account_balance),
                title: Text(l10n.accounts),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(mainNavProvider.notifier).state =
                      MainPage.manageAccounts;
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2),
                title: Text(l10n.products),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(mainNavProvider.notifier).state =
                      MainPage.manageProducts;
                },
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: Text(l10n.manageCategories),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(mainNavProvider.notifier).state =
                      MainPage.manageCategories;
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(l10n.settings),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(mainNavProvider.notifier).state = MainPage.settings;
                },
              ),
              if (authStatus == AuthStatus.unauthenticated)
                ListTile(
                  leading: Icon(Icons.login,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(
                    l10n.signInWithGoogle,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ));
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(l10n.signOut),
                  onTap: () {
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                ),
            ],
          ),
        ),

        body: switch (currentPage) {
          MainPage.dashboard => TabBarView(
              children: [
                FilteredAccountsListPage(
                    classificationFilter: c.kClassificationGeneral),
                FilteredAccountsListPage(
                    classificationFilter: c.kClassificationClients),
                FilteredAccountsListPage(
                    classificationFilter: c.kClassificationSuppliers),
              ],
            ),
          MainPage.pos => const PosScreen(),
          MainPage.reportTotalAmounts => const TotalAmountsScreen(),
          MainPage.reportMonthlyAmounts => const MonthlyAmountsScreen(),
          MainPage.reportAccountActivity => const AccountActivityScreen(),
          MainPage.manageAccounts => const AccountsHubScreen(),
          MainPage.manageProducts => const ProductsHubScreen(),
          MainPage.manageCategories => const CategoriesHubScreen(),
          MainPage.settings => const SettingsScreen(),
          MainPage.orderHistory =>
            const OrderHistoryScreen(),
          MainPage.reportProfitAndLoss => const ProfitAndLossScreen(),
          MainPage.reportBalanceSheet => const BalanceSheetScreen(),
          MainPage.reportTrialBalance => const TrialBalanceScreen(),
        },
      ),
    );
  }
}