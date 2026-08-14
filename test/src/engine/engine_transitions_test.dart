// Criteria 7-10: the four transitions, driven with no widget tree.
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

import 'engine_harness.dart';

void main() {
  test(
    'StartSurvey emits one PresentingSurveyState and pushes that instance',
    () async {
      final host = FakeSurveyHost();
      final engine = makeEngine(task: twoStepTask(), host: host);
      final emitted = <SurveyState>[];
      final sub = engine.stateStream.stream.listen(emitted.add);

      await engine.handleEvent(StartSurvey());
      await drain();

      expect(emitted, hasLength(1));
      expect(emitted.single, isA<PresentingSurveyState>());
      expect((emitted.single as PresentingSurveyState).currentStep.id, 's1');
      expect(host.calls, <String>['pushState']);
      expect(
        identical(host.pushed.single, emitted.single),
        isTrue,
        reason: 'the pushed state must be the same object that was published',
      );

      await sub.cancel();
      engine.dispose();
    },
  );

  test('NextStep records the answer, advances and pushes', () async {
    final host = FakeSurveyHost();
    final engine = makeEngine(task: twoStepTask(), host: host);

    await engine.handleEvent(StartSurvey());
    await engine.handleEvent(NextStep(textResult('s1', 'alpha')));
    await drain();

    expect(engine.resultById('s1')?.result, 'alpha');
    expect(host.calls, <String>['pushState', 'pushState']);
    expect((host.pushed.last as PresentingSurveyState).currentStep.id, 's2');

    engine.dispose();
  });

  test(
    'the terminal NextStep delivers a completed, history-pruned result',
    () async {
      final host = FakeSurveyHost();
      final engine = makeEngine(
        task: twoStepTask(),
        host: host,
        // A seeded answer for a step this run never visits. ADO #969: completion
        // persists only the recorded path, so this must NOT survive.
        initialResults: {textResult('ghost', 'stale')},
      );

      await engine.handleEvent(StartSurvey());
      await engine.handleEvent(NextStep(textResult('s1', 'alpha')));
      await engine.handleEvent(NextStep(textResult('s2', 'beta')));
      await drain();

      expect(host.delivered, hasLength(1));
      final result = host.delivered.single;
      expect(result.finishReason, FinishReason.completed);
      expect(
        result.results.map((r) => r.id).toSet(),
        <String>{'s1', 's2'},
        reason: 'the unvisited seeded answer must be pruned',
      );
      expect(engine.state, isA<SurveyResultState>());

      engine.dispose();
    },
  );

  test('StepBack replaces rather than pushes, and marks the state', () async {
    final host = FakeSurveyHost();
    final engine = makeEngine(task: twoStepTask(), host: host);

    await engine.handleEvent(StartSurvey());
    await engine.handleEvent(NextStep(textResult('s1', 'alpha')));
    await engine.handleEvent(StepBack(textResult('s2', 'beta')));
    await drain();

    expect(host.calls, <String>['pushState', 'pushState', 'replaceState']);
    expect(host.replaced, hasLength(1));
    final back = host.replaced.single as PresentingSurveyState;
    expect(back.currentStep.id, 's1');
    expect(back.isPreviousStep, isTrue);

    engine.dispose();
  });

  test(
    'CloseSurvey delivers a discarded result, then pops — in that order',
    () async {
      final host = FakeSurveyHost();
      final engine = makeEngine(task: twoStepTask(), host: host);

      await engine.handleEvent(StartSurvey());
      await engine.handleEvent(CloseSurvey(textResult('s1', 'alpha')));
      await drain();

      expect(
        host.calls,
        <String>['pushState', 'deliverResult', 'popSurvey'],
        reason: 'the consumer must have the result before the route disappears',
      );
      final result = host.delivered.single;
      expect(result.finishReason, FinishReason.discarded);
      expect(result.lastShownStepId, 's1');
      expect(
        result.results.map((r) => r.id).toSet(),
        <String>{'s1'},
        reason: 'a discard keeps the full set — pruning is completion-only',
      );

      engine.dispose();
    },
  );
}
