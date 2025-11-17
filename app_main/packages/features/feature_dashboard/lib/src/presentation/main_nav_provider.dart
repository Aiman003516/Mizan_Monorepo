import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MainPage {
  dashboard,
  pos,
  reportTotalAmounts,
  reportMonthlyAmounts,
  reportAccountActivity,
  orderHistory,
  reportProfitAndLoss,
  reportBalanceSheet,
  reportTrialBalance,
  manageAccounts,
  manageProducts,
  manageCategories,
  settings,
}

final mainNavProvider = StateProvider<MainPage>((ref) {
  return MainPage.dashboard;
});