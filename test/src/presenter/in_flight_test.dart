import 'dart:async';

import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

import 'action_harness.dart';

/// Before ADO #1040 nothing was awaited, so a second Next tap could not
/// interleave with the first. The suspension opens that window; these tests
/// close it. Each one is only falsifiable if the test pumps STRICTLY INSIDE the
/// await window, which is what the Completer-gated handler is for.
void main() {
  ({
    NavigableTask task,
    SurveyRegistries registries,
    Completer<void> gate,
    List<int> fires,
  })
  gatedFixture() {
    final gate = Completer<void>();
    final fires = <int>[];
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
    );
    final registries = SurveyRegistries(
      actionHandlers: {
        'slow': (ctx) async {
          fires.add(fires.length);
          await gate.future;
        },
      },
    );
    return (task: task, registries: registries, gate: gate, fires: fires);
  }

  testWidgets('two NextStep events advance once and fire the handler once', (
    tester,
  ) async {
    final f = gatedFixture();
    await tester.pumpWidget(
      ActionHost(task: f.task, registries: f.registries, onResult: (_) {}),
    );
    await tester.pumpAndSettle();

    // Dispatched directly, NOT by tapping twice. Tapping would prove only that
    // StepView disables its button — which is the next test. This one must
    // exercise the guard in onEvent independently of the UI, because
    // SurveyController.nextStep is reachable from a consumer's own button.
    final provider = SurveyStateProvider.of(
      tester.element(find.byType(ElevatedButton)),
    );
    unawaited(provider.onEvent(NextStep(null)));
    await tester.pump();
    unawaited(provider.onEvent(NextStep(null)));
    await tester.pump();

    f.gate.complete();
    await tester.pumpAndSettle();

    expect(f.fires, hasLength(1), reason: 'handler fired once');
    expect(find.text('second'), findsOneWidget);
    expect(
      find.text('first'),
      findsNothing,
      reason: 'advanced exactly one step',
    );
  });

  testWidgets('Next is disabled inside the window and enabled after', (
    tester,
  ) async {
    final f = gatedFixture();
    await tester.pumpWidget(
      ActionHost(task: f.task, registries: f.registries, onResult: (_) {}),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Asserting on the SAME step: the advance has not happened yet, so this is
    // still s1's StepView. Once it completes, s2's button is enabled regardless
    // of isAdvancing, which is why the post-assertion reads the flag too.
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
      reason: 'Next must be disabled while the action is in flight',
    );

    f.gate.complete();
    await tester.pumpAndSettle();

    final provider = SurveyStateProvider.of(
      tester.element(find.byType(ElevatedButton)),
    );
    expect(provider.isAdvancing.value, isFalse);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'unmounting mid-flight, then completing the handler, does not throw',
    (tester) async {
      final f = gatedFixture();
      await tester.pumpWidget(
        ActionHost(task: f.task, registries: f.registries, onResult: (_) {}),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      // The handler completes AFTER disposal. A ValueNotifier whose value setter
      // runs post-dispose asserts; SurveySession must no-op instead.
      f.gate.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Cancel is still honoured while an action is in flight', (
    tester,
  ) async {
    final f = gatedFixture();
    SurveyResult? received;
    await tester.pumpWidget(
      ActionHost(
        task: f.task,
        registries: f.registries,
        onResult: (r) => received = r,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pump();

    expect(received, isNotNull, reason: 'the escape hatch stays live');

    // NOT pumpAndSettle: closing while s1 is still the only ever-pushed
    // PresentingSurveyState route pops back to the pre-StartSurvey initial
    // route, whose arguments are null, so SurveyKit's own onGenerateRoute
    // renders CircularProgressIndicator.adaptive() there (survey_kit.dart) —
    // pre-existing, out of scope for this task. Its indeterminate ticker never
    // settles, so pumpAndSettle would time out regardless of this guard;
    // survey_session_test.dart's own Cancel test hits the same hazard and
    // avoids it the same way.
    f.gate.complete();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text('second'),
      findsNothing,
      reason: 'the completing advance must not publish after a terminal state',
    );
  });
}
