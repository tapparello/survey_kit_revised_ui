import 'package:flutter/material.dart' hide Step;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

/// barrierDismissible: false blocks the barrier TAP only. The Android hardware
/// back button still pops the dialog route, running neither the "Next" button's
/// onPressed nor the auto-dismiss timer. Before 3b that stranded the user on
/// the step; with a Completer-based design it would hang the await forever and
/// freeze the survey permanently. `await showDialog<void>` completes on every
/// dismissal path, which is what these tests pin.
void main() {
  NavigableTask feedbackTask() => NavigableTask(
    id: 't',
    steps: [
      Step(
        id: 's1',
        content: const [TextContent(text: 'first')],
        buttonText: 'Next',
        // Not const: TextChoice has no const constructor
        // (text_choice.dart:15), so neither the list nor the format can be.
        answerFormat: SingleChoiceAnswerWithFeedbackFormat(
          textChoices: [
            TextChoice(text: 'Right', value: 'correct'),
            TextChoice(text: 'Wrong', value: 'wrong'),
          ],
          feedbackCorrect: 'Correct!',
          feedbackWrong: 'Nope.',
        ),
      ),
      Step(id: 's2', content: const [TextContent(text: 'second')]),
    ],
  );

  /// Sends a platform back press, the way the Android system button does.
  Future<void> pressSystemBack(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(
        const MethodCall('popRoute'),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a back-dismissed feedback dialog still advances the survey', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SurveyKit(task: feedbackTask(), onResult: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wrong'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nope.'), findsOneWidget, reason: 'dialog is up');

    await pressSystemBack(tester);

    expect(find.textContaining('Nope.'), findsNothing);
    expect(find.text('second'), findsOneWidget, reason: 'survey advanced');
  });

  testWidgets('the tap path still advances the survey', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SurveyKit(task: feedbackTask(), onResult: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wrong'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Next'));
    await tester.pumpAndSettle();

    expect(find.text('second'), findsOneWidget);
  });

  testWidgets('the auto-dismiss path still advances the survey', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SurveyKit(task: feedbackTask(), onResult: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 'correct' takes the autoDismiss branch.
    await tester.tap(find.text('Right'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('Correct!'), findsOneWidget);

    // pumpAndSettle does NOT advance the fake clock when no frame is scheduled,
    // so a naive test passes without the delayed callback ever running.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('second'), findsOneWidget);
  });

  testWidgets('back-dismissing an auto-dismiss dialog does not pop the host', (
    tester,
  ) async {
    // The dangerous combination: on the autoDismiss branch the dialog renders
    // SizedBox.shrink() instead of a button, so the only two ways out are the
    // timer and the back button. 3b promotes back-dismissal to a supported
    // path — so the timer must not fire afterwards onto a root navigator whose
    // top route is now the host page.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SurveyKit(task: feedbackTask(), onResult: (_) {})),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Right'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    await pressSystemBack(tester);
    expect(find.text('second'), findsOneWidget);

    // Let the (now stale) 1s timer elapse.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('second'),
      findsOneWidget,
      reason: 'the stale timer must not pop the survey out from under the user',
    );
  });

  group('acceptance criterion 14 — feedback AND an action rule on one step', () {
    // No step in FMF Connect carries both, so this fixture is the ONLY thing
    // that exercises the reorder in behaviour change 5: the action must fire
    // AFTER the dialog is acknowledged, not concurrently with it. An
    // implementer who awaits the action before _showFeedbackIfAny — the pre-3b
    // order, and the more natural reading of _handleNextStep — passes every
    // other test in this plan.
    late List<String> events;

    NavigableTask task() => NavigableTask(
      id: 't',
      steps: [
        Step(
          id: 's1',
          content: const [TextContent(text: 'first')],
          buttonText: 'Next',
          answerFormat: SingleChoiceAnswerWithFeedbackFormat(
            textChoices: [
              TextChoice(text: 'Right', value: 'correct'),
              TextChoice(text: 'Wrong', value: 'wrong'),
            ],
            feedbackCorrect: 'Correct!',
            feedbackWrong: 'Nope.',
          ),
        ),
        Step(id: 's2', content: const [TextContent(text: '{{x}}')]),
      ],
      navigationRules: const {
        's1': ActionNavigationRule(
          actionId: 'write_x',
          nextStepIdentifier: 's2',
        ),
      },
    );

    SurveyRegistries registries() => SurveyRegistries(
      actionHandlers: {
        'write_x': (ctx) async {
          events.add('handler');
          ctx.variables['x'] = 'AFTER_FEEDBACK';
        },
      },
    );

    setUp(() => events = <String>[]);

    testWidgets('tap path: the handler has not started while the dialog is up', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurveyKit(
              task: task(),
              registries: registries(),
              onResult: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wrong'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nope.'), findsOneWidget);
      expect(events, isEmpty, reason: 'the action must not have fired yet');

      await tester.tap(find.widgetWithText(TextButton, 'Next'));
      await tester.pumpAndSettle();

      expect(events, ['handler']);
      expect(find.text('AFTER_FEEDBACK'), findsOneWidget);
    });

    testWidgets('auto-dismiss path: same ordering', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurveyKit(
              task: task(),
              registries: registries(),
              onResult: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Right'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Correct!'), findsOneWidget);
      expect(events, isEmpty);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(events, ['handler']);
      expect(find.text('AFTER_FEEDBACK'), findsOneWidget);
    });
  });
}
