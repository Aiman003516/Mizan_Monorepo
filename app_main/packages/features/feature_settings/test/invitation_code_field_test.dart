import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/src/presentation/staff/invitation_code_field.dart';

void main() {
  testWidgets('starts empty and emits a six-digit code as boxes are filled', (
    tester,
  ) async {
    final values = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InvitationCodeField(
            pasteLabel: 'Paste',
            fieldLabel: 'Invitation code',
            onChanged: values.add,
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(6));
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.controller?.text ?? '', isEmpty);
    }

    final fields = find.byType(TextField);
    for (var index = 0; index < 6; index++) {
      await tester.enterText(fields.at(index), '${index + 1}');
    }
    await tester.pump();
    expect(values.last, '123456');
  });

  testWidgets('strips non-numeric characters from a pasted value', (
    tester,
  ) async {
    String? value;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InvitationCodeField(
            pasteLabel: 'Paste',
            fieldLabel: 'Invitation code',
            onChanged: (next) => value = next,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '12a3456');
    await tester.pump();
    expect(value, '123456');
    expect(find.byType(TextField).first, findsOneWidget);
  });
}
