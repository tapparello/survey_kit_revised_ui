// Coverage gap: no existing test drives StepBack across a conditional step.
// engine_conditional_test.dart covers forward resolution; engine_transitions_
// test.dart covers back-navigation with no conditionals; they never meet, even
// though `_handleStepBack` is one of the three `_resolveStep` call sites (ADO
// #1045 phase 3d).
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/engine/survey_engine.dart';
import 'package:survey_kit/survey_kit.dart';

import 'engine_harness.dart';

/// A directive branching on the answer to step [variable]. Copied from
/// engine_conditional_test.dart rather than shared, to keep this file
/// self-contained and its fixture obviously in sync with what it drives.
Map<String, dynamic> conditionalFormat(String variable) => <String, dynamic>{
  'type': 'conditional',
  'variable': variable,
  'default': 'Caroline',
  'variants': <String, dynamic>{
    'Caroline': <String, dynamic>{'type': 'text'},
    'Lilia': <String, dynamic>{'type': 'integer'},
  },
};

/// s1 is a plain question; s2's answer format branches on s1's answer, and is
/// NOT mandatory (needed for the "stale result survives" test below, where the
/// user must be able to advance past s2 with no new answer for it); s3 is a
/// plain trailing step, needed so there is somewhere to stand while stepping
/// BACK into s2 from beyond it.
Task threeStepBranchingTask() => Task.fromJson(<String, dynamic>{
  'type': 'navigable',
  'id': 't',
  'variables': const <String, dynamic>{},
  'steps': <dynamic>[
    const <String, dynamic>{
      'id': 's1',
      'content': <dynamic>[],
      'answerFormat': <String, dynamic>{'type': 'text'},
    },
    <String, dynamic>{
      'id': 's2',
      'content': const <dynamic>[],
      'answerFormat': conditionalFormat('s1'),
      'isMandatory': false,
    },
    const <String, dynamic>{
      'id': 's3',
      'content': <dynamic>[],
      'answerFormat': <String, dynamic>{'type': 'text'},
    },
  ],
});

/// An integer answer for [id], the shape s2 takes under the 'Lilia' variant.
StepResult<int> integerResult(String id, int value) => StepResult<int>(
  id: id,
  result: value,
  answerType: AnswerFormatType.integer,
  startTime: DateTime.now(),
  endTime: DateTime.now(),
);

PresentingSurveyState presenting(SurveyEngine engine) =>
    engine.state as PresentingSurveyState;

void main() {
  test(
    'back-navigating TO a conditional step re-resolves it, not a stale copy',
    () async {
      // (a) `_handleStepBack` builds its own resolved copy of the step it is
      // returning to, via `_resolveStep(previousStep)`. `previousInList`
      // returns the AUTHORED step out of history (engine_conditional_test.dart
      // pins that history never holds a resolved copy), so if
      // `_handleStepBack` skipped resolution the presented step would still
      // carry the unresolved directive: `answerFormat: null`,
      // `conditionalAnswerFormat: <the directive>`. Asserting the CONCRETE
      // format here is what distinguishes "re-resolved" from "replayed
      // unresolved" — see the deliberate-break note below.
      final engine = makeEngine(
        task: threeStepBranchingTask(),
        host: FakeSurveyHost(),
      );

      await engine.handleEvent(StartSurvey());
      await engine.handleEvent(NextStep(textResult('s1', 'Lilia')));
      await drain();
      expect(presenting(engine).currentStep.id, 's2');
      expect(
        presenting(engine).currentStep.answerFormat,
        isA<IntegerAnswerFormat>(),
        reason: 'fixture guard: s1=Lilia must select the integer variant',
      );

      await engine.handleEvent(NextStep(integerResult('s2', 7)));
      await drain();
      expect(presenting(engine).currentStep.id, 's3');

      await engine.handleEvent(StepBack(null));
      await drain();

      final back = presenting(engine).currentStep;
      expect(back.id, 's2');
      expect(
        back.answerFormat,
        isA<IntegerAnswerFormat>(),
        reason:
            'the step returned to must be a freshly RESOLVED copy — s1 has '
            'not changed, so the same (integer) variant is expected — not '
            'the authored step with the directive still attached',
      );
      expect(
        back.conditionalAnswerFormat,
        isNull,
        reason:
            'copyResolved clears the directive on a resolved copy; a non-null '
            'value here would mean the unresolved authored step leaked '
            'through untouched',
      );

      engine.dispose();
    },
  );

  test(
    'changing the upstream answer via Back changes the resolved variant, and '
    'the STALE StepResult recorded under the old variant survives to the '
    'delivered SurveyResult',
    () async {
      // (b) + (c). This is the capability ADO #1045 phase 3d exists to
      // enable — a format that branches on an answer the user can still go
      // back and change — driven across an actual StepBack, plus a direct
      // measurement (not a prediction) of what happens to the StepResult
      // recorded for s2 under the FIRST resolution once the SECOND resolution
      // supersedes it.
      final engine = makeEngine(
        task: threeStepBranchingTask(),
        host: FakeSurveyHost(),
      );

      await engine.handleEvent(StartSurvey());
      await engine.handleEvent(NextStep(textResult('s1', 'Lilia')));
      await drain();
      expect(
        presenting(engine).currentStep.answerFormat,
        isA<IntegerAnswerFormat>(),
        reason: 'variant A: s1=Lilia selects the integer variant',
      );

      // Record an answer for s2 UNDER variant A, then move past it so there is
      // somewhere to come back FROM.
      await engine.handleEvent(NextStep(integerResult('s2', 7)));
      await drain();
      expect(presenting(engine).currentStep.id, 's3');

      // Back into s2 (still variant A — s1 unchanged), then back again into
      // s1, matching a user reconsidering their answer two steps upstream.
      await engine.handleEvent(StepBack(null));
      await drain();
      expect(presenting(engine).currentStep.id, 's2');
      await engine.handleEvent(StepBack(null));
      await drain();
      expect(presenting(engine).currentStep.id, 's1');

      // Change the upstream answer so the directive selects the OTHER
      // (default/text) variant, and go forward again.
      await engine.handleEvent(NextStep(textResult('s1', 'Caroline')));
      await drain();

      final resolvedAgain = presenting(engine).currentStep;
      expect(resolvedAgain.id, 's2');
      expect(
        resolvedAgain.answerFormat,
        isA<TextAnswerFormat>(),
        reason:
            'variant B: s1=Caroline selects the default (text) variant — '
            'the OTHER variant than the first pass took',
      );

      // MEASURED, not assumed: what does the state report as THIS step's
      // recorded result, now that the step has re-resolved out from under it?
      // `_presentStep` looks the result up by id alone (`resultById`), with no
      // regard for which AnswerFormat it was recorded under, so the CHANGELOG
      // predicts the untouched integer StepResult from the first pass should
      // still be here, attached to a state whose current format is now text.
      final resultAtSecondResolution = presenting(engine).result;
      expect(
        resultAtSecondResolution?.id,
        's2',
        reason: 'a StepResult IS present for s2 — not cleared by re-resolution',
      );
      expect(
        resultAtSecondResolution?.result,
        7,
        reason:
            'and it is the untouched value from variant A: nothing in '
            '_resolveStep or _presentStep invalidates a StepResult when the '
            'format that produced it stops matching the current resolution',
      );
      expect(resultAtSecondResolution?.answerType, AnswerFormatType.integer);
      // This is as far as the pure engine layer can honestly go: there is no
      // widget tree here, so nothing actually attempts to bind an int-typed
      // value into a text-typed view or observes `onChange` failing to fire.
      // What IS reachable and IS measured is the state the CHANGELOG's claim
      // depends on: a stale, format-mismatched StepResult sitting in the
      // engine's `results` set, undisturbed, while the currently-presented
      // step has moved on to a different concrete format.

      // The non-mandatory step lets the user press Next with no new answer,
      // exactly as the CHANGELOG describes ("questionAnswer.stepResult ==
      // null"). `addResult(null)` is a documented no-op, so the stale integer
      // result is never overwritten or removed.
      await engine.handleEvent(NextStep(null));
      await drain();
      expect(presenting(engine).currentStep.id, 's3');

      await engine.handleEvent(NextStep(textResult('s3', 'done')));
      await drain();

      final finalState = engine.state as SurveyResultState;
      final s2Result = finalState.result.results.firstWhere(
        (r) => r.id == 's2',
      );
      expect(
        s2Result.result,
        7,
        reason:
            'VERDICT: the CHANGELOG entry for 1.0.0-dev.20 is confirmed at '
            'the engine layer — the StepResult recorded under the OLD '
            '(integer) variant survives, untouched, into the delivered '
            'SurveyResult, even though s2 was last presented under the text '
            'variant',
      );
      expect(s2Result.answerType, AnswerFormatType.integer);

      engine.dispose();
    },
  );
}
