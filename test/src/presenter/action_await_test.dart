import 'dart:async';

import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

import 'action_harness.dart';

/// THE headline test for ADO #1040.
///
/// Before 3b, ActionHandler was `void Function(...)` and every real handler
/// returned a Future that Dart discarded. A handler that wrote a variable AFTER
/// its first await therefore raced the step that renders it — which is why
/// FMF Connect's generateModule8Section5 carries a comment (ADO #975) requiring
/// the write to precede the first await. That constraint is what these tests
/// retire: the library now guarantees the ordering.
///
/// Written so a STATEMENT-BODIED handler fails it. `Future<void>` (not
/// `FutureOr<void>`) is chosen precisely to reject that shape at compile time;
/// if this test passes with the work un-awaited, it is not testing the contract.
void main() {
  NavigableTask taskWithActionThen(String templateStepId) {
    return NavigableTask(
      id: 't',
      steps: [
        Step(
          id: 's1',
          content: const [TextContent(text: 'first')],
          buttonText: 'Next',
        ),
        Step(
          id: templateStepId,
          content: const [TextContent(text: '{{x}}')],
          buttonText: 'Done',
        ),
      ],
      navigationRules: const {
        's1': ActionNavigationRule(actionId: 'write_x', nextStepIdentifier: 's2'),
      },
    );
  }

  testWidgets('the next step renders a variable written AFTER an await', (
    tester,
  ) async {
    // Gated on a test-controlled Completer rather than a delay: a delay leaves
    // this test unable to discriminate a fire-and-forget implementation from a
    // correctly-awaited one (a short delay passes either way once
    // pumpAndSettle drains it; a long delay fails either way, since
    // pumpAndSettle stops as soon as no frame is scheduled and never advances
    // the fake clock far enough). The Completer lets the test observe the
    // survey BEFORE the handler resolves, which is the actual discriminator.
    final handlerGate = Completer<void>();
    final registries = SurveyRegistries(
      actionHandlers: {
        'write_x': (ctx) async {
          // The whole point: the write is on the far side of a suspension.
          await handlerGate.future;
          ctx.variables['x'] = 'WRITTEN_LATE';
        },
      },
    );

    await tester.pumpWidget(
      ActionHost(
        task: taskWithActionThen('s2'),
        registries: registries,
        onResult: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // The discriminating assertion: under a fire-and-forget implementation the
    // survey would have already advanced to s2 here, before the handler (and
    // its variable write) ever completes.
    expect(find.text('first'), findsOneWidget, reason: 'must not advance yet');
    expect(find.text('WRITTEN_LATE'), findsNothing);

    handlerGate.complete();
    await tester.pumpAndSettle();

    expect(find.text('WRITTEN_LATE'), findsOneWidget);
  });

  testWidgets('the handler receives ActionTrigger.advance and the actionId', (
    tester,
  ) async {
    ActionContext? seen;
    final registries = SurveyRegistries(
      actionHandlers: {
        'write_x': (ctx) async {
          seen = ctx;
          ctx.variables['x'] = 'ok';
        },
      },
    );

    await tester.pumpWidget(
      ActionHost(
        task: taskWithActionThen('s2'),
        registries: registries,
        onResult: (_) {},
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(seen, isNotNull);
    expect(seen!.actionId, 'write_x');
    expect(seen!.trigger, ActionTrigger.advance);
  });

  testWidgets('resume replays the action with ActionTrigger.replay, once', (
    tester,
  ) async {
    final triggers = <ActionTrigger>[];
    final registries = SurveyRegistries(
      actionHandlers: {
        'write_x': (ctx) async {
          triggers.add(ctx.trigger);
          ctx.variables['x'] = 'replayed';
        },
      },
    );

    // initialStepId points PAST the action rule, so _handleInitialStep's replay
    // loop must walk s1 -> s2 and cross the rule.
    final task = NavigableTask(
      id: 't',
      steps: [
        Step(id: 's1', content: const [TextContent(text: 'first')]),
        Step(id: 's2', content: const [TextContent(text: '{{x}}')]),
      ],
      navigationRules: const {
        's1': ActionNavigationRule(actionId: 'write_x', nextStepIdentifier: 's2'),
      },
      initialStepId: 's2',
    );

    await tester.pumpWidget(
      ActionHost(task: task, registries: registries, onResult: (_) {}),
    );
    await tester.pumpAndSettle();

    expect(triggers, [ActionTrigger.replay]);
    expect(find.text('replayed'), findsOneWidget);
  });

  testWidgets('a handler that short-circuits on replay still writes its variable', (
    tester,
  ) async {
    // The 8_5_20 shape, reproduced in-library: the effect is skipped on resume
    // but the pre-return variable write is still visible to the resumed step.
    var effectRuns = 0;
    final registries = SurveyRegistries(
      actionHandlers: {
        'write_x': (ctx) async {
          ctx.variables['x'] = 'summary';
          if (ctx.trigger == ActionTrigger.replay) return;
          effectRuns++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
        },
      },
    );

    final task = NavigableTask(
      id: 't',
      steps: [
        Step(id: 's1', content: const [TextContent(text: 'first')]),
        Step(id: 's2', content: const [TextContent(text: '{{x}}')]),
      ],
      navigationRules: const {
        's1': ActionNavigationRule(actionId: 'write_x', nextStepIdentifier: 's2'),
      },
      initialStepId: 's2',
    );

    await tester.pumpWidget(
      ActionHost(task: task, registries: registries, onResult: (_) {}),
    );
    await tester.pumpAndSettle();

    expect(effectRuns, 0, reason: 'the PDF-equivalent must not run on resume');
    expect(find.text('summary'), findsOneWidget);
  });

  testWidgets('a rule that throws during replay still presents the resumed step', (
    tester,
  ) async {
    final failures = <SurveyHandlerFailure>[];
    final task = NavigableTask(
      id: 't',
      steps: [
        Step(id: 's1', content: const [TextContent(text: 'first')]),
        Step(id: 's2', content: const [TextContent(text: 'second')]),
      ],
      navigationRules: const {'s1': CustomNavigationRule(ruleId: 'route')},
      initialStepId: 's2',
    );

    await tester.pumpWidget(
      ActionHost(
        task: task,
        registries: SurveyRegistries(
          customNavigationRules: {
            'route': (results, currentResult, variables) =>
                throw StateError('rule boom'),
          },
        ),
        onHandlerError: failures.add,
        onResult: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(failures, hasLength(1));
    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'the survey must not sit on the startup spinner',
    );
  });

  testWidgets('a conditional mapper that throws during replay still presents', (
    tester,
  ) async {
    // This one exercises the PRESENTER's guard, not the navigator's. Decision 8
    // wraps action handlers and CustomNavigationRule handlers, but NOT
    // ConditionalNavigationRule mappers — so this throw reaches
    // _handleInitialStep's replay loop, which is the "second line of defence"
    // the spec names. Without that try/catch the survey sits on the startup
    // spinner forever with nothing logged, because onEvent's Future is
    // discarded by the post-frame callback. Remove the presenter guard and this
    // test is the only one that fails.
    final task = NavigableTask(
      id: 't',
      steps: [
        Step(id: 's1', content: const [TextContent(text: 'first')]),
        Step(id: 's2', content: const [TextContent(text: 'second')]),
      ],
      navigationRules: {
        's1': ConditionalNavigationRule(
          resultToStepIdentifierMapper: (results, input) =>
              throw StateError('mapper boom'),
        ),
      },
      initialStepId: 's2',
    );

    await tester.pumpWidget(
      ActionHost(
        task: task,
        registries: const SurveyRegistries(),
        onResult: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'the replay guard must present the furthest step reached',
    );
  });
}
