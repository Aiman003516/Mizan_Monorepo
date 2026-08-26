import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feature_settings/src/presentation/staff/staff_list_screen.dart';

void main() {
  testWidgets('employee management hides Realtime errors and offers retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          staffStreamProvider.overrideWith(
            (ref) => Stream<List<StaffMember>>.error(
              StateError('RealtimeSubscribeException(channelError)'),
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: StaffListScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Error loading data'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('RealtimeSubscribeException'), findsNothing);
  });
}
