import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feature_settings/src/presentation/roles/roles_list_screen.dart';

void main() {
  testWidgets(
    'roles errors are localized and do not expose transport details',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rolesStreamProvider.overrideWith(
              (ref) => Stream<List<AppRole>>.error(
                StateError('RealtimeSubscribeException(channelError)'),
              ),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [AppLocalizations.delegate],
            supportedLocales: AppLocalizations.supportedLocales,
            home: RolesListScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Error loading data'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.textContaining('RealtimeSubscribeException'), findsNothing);
    },
  );
}
