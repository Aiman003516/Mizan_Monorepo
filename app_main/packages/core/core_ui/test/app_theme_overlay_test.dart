import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core_ui/core_ui.dart';

void main() {
  test('light theme places snackbars above the primary action area', () {
    final theme = AppTheme.lightTheme;
    final snackBarTheme = theme.snackBarTheme;

    expect(snackBarTheme.behavior, SnackBarBehavior.floating);
    expect(snackBarTheme.insetPadding?.bottom, greaterThanOrEqualTo(88));
  });

  test('dark theme uses the same snackbar clearance contract', () {
    final theme = AppTheme.darkTheme;
    final snackBarTheme = theme.snackBarTheme;

    expect(snackBarTheme.behavior, SnackBarBehavior.floating);
    expect(snackBarTheme.insetPadding?.bottom, greaterThanOrEqualTo(88));
  });
}
