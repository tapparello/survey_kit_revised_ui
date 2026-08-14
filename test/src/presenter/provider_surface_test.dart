// SurveyStateProvider is exported from the barrel, so every public member on it
// is published API. ADO #1041 moved the state machine into SurveyEngine and very
// nearly took `countSteps` and `currentStepIndex` with it — they are the only
// two members that delegate to the navigator rather than the engine, so they sat
// outside the block of delegations the extraction was careful to preserve.
//
// Nothing caught that: api_surface_test.dart does not name them, the engine's
// normalised-diff gate only read the engine, and a consumer's progress readout
// is the kind of code no test in this package renders. This file is that gate.
// No barrel import: every symbol here comes from rebuild_harness.dart, and an
// unused import is a warning that `flutter analyze --fatal-infos` fails on.
import 'package:flutter_test/flutter_test.dart';

import 'rebuild_harness.dart';

void main() {
  testWidgets('the provider still exposes the navigator progress readout', (
    tester,
  ) async {
    await tester.pumpWidget(RebuildHost(task: twoStepTask(), onResult: (_) {}));
    await tester.pumpAndSettle();

    final provider = providerFrom(tester, find.text('One'));

    // The shape a consumer writes for "step 1 of 2" in a custom app bar.
    expect(provider.countSteps, 2);

    final step = provider.taskNavigator.firstStep()!;
    expect(provider.currentStepIndex(step), 0);
  });
}
