// Characterization, not a gate. ADO #1045 makes a conditional step resolve into
// a fresh Step copy per presentation, and PresentingSurveyState.== compares
// currentStep by reference because Step has no value equality. So two states for
// the same conditional step are no longer ==, while two for the same ordinary
// step still are (the engine short-circuits on identity).
//
// This documents the boundary. ADO #1046 owns the fix — including the three
// pre-existing defects underneath it: isInitialStep is missing from == and
// hashCode, `steps` and `questionResults` are always the same instance so they
// contribute nothing, and that mutable Set sits inside an @immutable class whose
// hashCode includes it. WHEN #1046 LANDS, THIS TEST IS THE ONE THAT FLIPS.
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

import '../engine/engine_harness.dart';

void main() {
  test('state equality compares currentStep by REFERENCE', () {
    // Constructed directly, not driven through the engine. Two states reached by
    // different transitions also differ in `isPreviousStep` and `result`, either
    // of which forces inequality on its own — a test built that way would report
    // "not equal" on the pre-3d baseline too, and would keep reporting it after
    // ADO #1046. This construction has no such confound: the ONLY difference
    // between the two comparisons is the identity of currentStep.
    const content = [TextContent(text: 'x')];
    final step = Step(id: 's1', content: content);
    final copy = Step(id: 's1', content: content);
    final results = <StepResult>{};
    final steps = [step];

    PresentingSurveyState stateWith(Step s) => PresentingSurveyState(
      stepCount: 2,
      currentStep: s,
      steps: steps,
      questionResults: results,
      currentStepIndex: 0,
    );

    expect(stateWith(step), equals(stateWith(step)));
    expect(
      stateWith(step),
      isNot(equals(stateWith(copy))),
      reason:
          'WHEN ADO #1046 GIVES Step VALUE EQUALITY, THIS IS THE '
          'ASSERTION THAT FLIPS',
    );
  });

  test('the engine copies a conditional step and only a conditional step', () {
    // The other half of the boundary, asserted with `identical` rather than
    // state equality so nothing else can influence the result. This is what
    // confines the gap above to conditional steps.
    Future<void> check({
      required bool conditional,
      required bool expectCopy,
    }) async {
      final authored = Step(
        id: 's1',
        content: conditional
            ? const [
                ConditionalContent(
                  variable: 'who',
                  options: {'x': TextContent(text: 'resolved')},
                  defaultOption: 'x',
                ),
              ]
            : const [TextContent(text: 'plain')],
      );
      final engine = makeEngine(
        task: NavigableTask(id: 't', steps: [authored]),
        host: FakeSurveyHost(),
      );

      await engine.handleEvent(StartSurvey());
      await drain();

      final presented = (engine.state as PresentingSurveyState).currentStep;
      expect(
        identical(presented, authored),
        !expectCopy,
        reason: conditional
            ? 'a conditional step must be resolved into a copy'
            : 'an ordinary step must pass through untouched',
      );
      engine.dispose();
    }

    return Future.wait([
      check(conditional: false, expectCopy: false),
      check(conditional: true, expectCopy: true),
    ]);
  });
}
