// Criteria 13-15: re-entrancy, currency and replay, driven with no widget tree.
// The `endAdvance after dispose` case was relocated here from
// survey_session_test.dart when SurveySession was absorbed into SurveyEngine.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

import 'engine_harness.dart';

void main() {
  test('endAdvance after dispose does not throw', () {
    final engine = makeEngine(task: twoStepTask(), host: FakeSurveyHost())
      ..beginAdvance()
      ..dispose();
    expect(engine.endAdvance, returnsNormally);
  });

  /// A task whose s1 -> s2 action handler suspends until the gate completes.
  ({
    NavigableTask task,
    SurveyRegistries registries,
    Completer<void> gate,
    List<ActionTrigger> triggers,
  })
  gatedFixture({String? initialStepId}) {
    final gate = Completer<void>();
    final triggers = <ActionTrigger>[];
    final task = NavigableTask(
      id: 't',
      steps: [
        Step(
          id: 's1',
          content: const [TextContent(text: 'first')],
        ),
        Step(
          id: 's2',
          content: const [TextContent(text: 'second')],
        ),
      ],
      navigationRules: const {
        's1': ActionNavigationRule(actionId: 'slow', nextStepIdentifier: 's2'),
      },
      initialStepId: initialStepId,
    );
    final registries = SurveyRegistries(
      actionHandlers: {
        'slow': (ctx) async {
          triggers.add(ctx.trigger);
          await gate.future;
        },
      },
    );
    return (task: task, registries: registries, gate: gate, triggers: triggers);
  }

  test('two NextStep events advance once and fire the handler once', () async {
    final f = gatedFixture();
    final host = FakeSurveyHost();
    final engine = makeEngine(
      task: f.task,
      host: host,
      registries: f.registries,
    );

    await engine.handleEvent(StartSurvey());
    // Not awaited: beginAdvance runs synchronously before the first suspension,
    // so the second dispatch must see the flag already set.
    final first = engine.handleEvent(NextStep(textResult('s1', 'a')));
    final second = engine.handleEvent(NextStep(textResult('s1', 'b')));

    f.gate.complete();
    await Future.wait([first, second]);
    await drain();

    expect(f.triggers, hasLength(1), reason: 'the handler fired twice');
    expect(host.calls, <String>['pushState', 'pushState']);

    engine.dispose();
  });

  test('a CloseSurvey mid-advance stops the advance from publishing', () async {
    final f = gatedFixture();
    final host = FakeSurveyHost();
    final engine = makeEngine(
      task: f.task,
      host: host,
      registries: f.registries,
    );

    await engine.handleEvent(StartSurvey());
    final advance = engine.handleEvent(NextStep(textResult('s1', 'a')));
    await drain();

    // Dispatched INSIDE the await window. CloseSurvey is deliberately not
    // blocked by the re-entrancy guard — it is the escape hatch.
    await engine.handleEvent(CloseSurvey(null));
    expect(engine.state, isA<SurveyResultState>());

    f.gate.complete();
    await advance;
    await drain();

    expect(host.calls, <String>[
      'pushState',
      'deliverResult',
      'popSurvey',
    ], reason: 'the resumed advance must not push onto a popped route');
    expect(
      engine.state,
      isA<SurveyResultState>(),
      reason: 'no PresentingSurveyState may follow a terminal state',
    );

    engine.dispose();
  });

  test(
    'a resume past an action rule replays it once, with ActionTrigger.replay',
    () async {
      final f = gatedFixture(initialStepId: 's2');
      final host = FakeSurveyHost();
      final engine = makeEngine(
        task: f.task,
        host: host,
        registries: f.registries,
      );

      final start = engine.handleEvent(StartSurvey());
      await drain();
      f.gate.complete();
      await start;
      await drain();

      expect(f.triggers, <ActionTrigger>[ActionTrigger.replay]);
      expect(host.pushed, hasLength(1));
      expect(
        (host.pushed.single as PresentingSurveyState).currentStep.id,
        's2',
      );

      engine.dispose();
    },
  );

  test('a rule that throws during replay still presents a step', () async {
    // The ENGINE's own guard, not the navigator's: a ConditionalNavigationRule
    // mapper is not wrapped by the navigator, so this throw reaches
    // _handleInitialStep's replay try/catch. Without it the survey sits on the
    // startup spinner forever with nothing logged.
    final host = FakeSurveyHost();
    final engine = makeEngine(
      host: host,
      task: NavigableTask(
        id: 't',
        steps: [
          Step(
            id: 's1',
            content: const [TextContent(text: 'first')],
          ),
          Step(
            id: 's2',
            content: const [TextContent(text: 'second')],
          ),
        ],
        navigationRules: {
          's1': ConditionalNavigationRule(
            resultToStepIdentifierMapper: (results, input) =>
                throw StateError('mapper boom'),
          ),
        },
        initialStepId: 's2',
      ),
    );

    await engine.handleEvent(StartSurvey());
    await drain();

    expect(host.pushed, hasLength(1));
    expect(
      host.pushed.single,
      isA<PresentingSurveyState>(),
      reason: 'the replay guard must present the furthest step reached',
    );

    engine.dispose();
  });
}
