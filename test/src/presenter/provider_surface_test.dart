// SurveyStateProvider is exported from the barrel, so every public member on it
// is published API. ADO #1041 moved the state machine into SurveyEngine and very
// nearly took `countSteps` and `currentStepIndex` with it — they are the only
// two members that delegate to the navigator rather than the engine, so they sat
// outside the block of delegations the extraction was careful to preserve.
//
// Nothing caught that: api_surface_test.dart does not name them, the engine's
// normalised-diff gate only read the engine, and a consumer's progress readout
// is the kind of code no test in this package renders. This file is that gate.
// Every symbol comes from rebuild_harness.dart except Step, which is imported
// directly to construct a copy for testing id-based comparison (ADO #1045).
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

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

  testWidgets('the readout finds a step by id, not by identity', (
    tester,
  ) async {
    // ADO #1045 makes SurveyEngine present a RESOLVED COPY of a conditional
    // step — same id, different instance, and Step has no value equality. This
    // method is public on an exported class, so a consumer's "step 1 of 2"
    // readout passes exactly such an instance back in.
    //
    // task.steps.indexOf(copy) returns -1. Nothing else in the navigator
    // compares by identity; this was the last one.
    await tester.pumpWidget(RebuildHost(task: twoStepTask(), onResult: (_) {}));
    await tester.pumpAndSettle();

    final provider = providerFrom(tester, find.text('One'));
    final authored = provider.taskNavigator.firstStep()!;
    final copy = Step(id: authored.id, content: authored.content);

    expect(copy, isNot(same(authored)), reason: 'the fixture must be a copy');
    expect(provider.currentStepIndex(copy), 0);
  });
}
