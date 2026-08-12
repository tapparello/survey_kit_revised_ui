// ADO #1033: SurveyStateProvider.updateShouldNotify compared onResult, whose
// identity changes on every build, so it notified constantly - and relied on a
// _state term that no longer exists to propagate localizations changes.
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';

import 'rebuild_harness.dart';

void main() {
  testWidgets('a localizations change still re-renders labels', (tester) async {
    final key = GlobalKey<RebuildHostState>();
    await tester.pumpWidget(
      RebuildHost(
        key: key,
        task: twoStepTask(),
        onResult: (_) {},
        localizations: const {'cancel': 'Cancel', 'next': 'Next'},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextButton, 'Cancel'), findsWidgets);

    key.currentState!.setLocalizations(
      const {'cancel': 'Abbrechen', 'next': 'Weiter'},
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextButton, 'Abbrechen'), findsWidgets,
        reason: 'a real localizations change must reach dependents');
    expect(find.widgetWithText(TextButton, 'Cancel'), findsNothing);
  });

  testWidgets('a no-op parent rebuild does not notify dependents',
      (tester) async {
    final key = GlobalKey<RebuildHostState>();
    await tester.pumpWidget(
      RebuildHost(
        key: key,
        task: twoStepTask(),
        onResult: (_) {},
        localizations: const {'cancel': 'Cancel', 'next': 'Next'},
      ),
    );
    await tester.pumpAndSettle();

    final before = providerFrom(tester, find.text('One'));

    key.currentState!.rebuild();
    await tester.pump();

    final after = providerFrom(tester, find.text('One'));
    expect(after.updateShouldNotify(before), isFalse,
        reason: 'nothing structural changed, so dependents must not rebuild');
  });
}
