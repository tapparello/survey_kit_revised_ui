// ADO #1033 Defect 2: AnswerView depends on SurveyStateProvider and rebuilds a
// fresh QuestionAnswer, discarding the in-progress answer. The answer view's
// own State survives, so the UI kept showing the answer selected while the
// recorded value was gone.
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

import '../../../presenter/rebuild_harness.dart';

void main() {
  testWidgets('an answer entered before a parent rebuild is still recorded', (
    tester,
  ) async {
    SurveyResult? captured;
    final key = GlobalKey<RebuildHostState>();
    await tester.pumpWidget(
      RebuildHost(key: key, task: twoStepTask(), onResult: (r) => captured = r),
    );
    await tester.pumpAndSettle();

    // Answer q1, THEN force the rebuild, THEN advance.
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    key.currentState!.rebuild();
    await tester.pump();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Two'), findsOneWidget);

    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pump(const Duration(seconds: 1));

    expect(captured, isNotNull);
    final q1 = captured!.results.where((r) => r.id == 'q1');
    expect(
      q1,
      hasLength(1),
      reason: 'the q1 answer was dropped: StepView passed a null stepResult',
    );
    expect((q1.single.result! as TextChoice).value, 'alpha');
  });

  testWidgets('a mandatory step stays blocked across a parent rebuild', (
    tester,
  ) async {
    final key = GlobalKey<RebuildHostState>();
    await tester.pumpWidget(
      RebuildHost(key: key, task: twoStepTask(), onResult: (_) {}),
    );
    await tester.pumpAndSettle();

    ElevatedButton nextButton() => tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Next'),
    );

    expect(
      nextButton().onPressed,
      isNull,
      reason: 'an unanswered mandatory step must not be submittable',
    );

    key.currentState!.rebuild();
    await tester.pumpAndSettle();

    expect(
      nextButton().onPressed,
      isNull,
      reason: 'isValid reset to true, defeating mandatory gating',
    );
  });

  testWidgets(
    'going back preserves the earlier answer, across a parent rebuild',
    (tester) async {
      // Deliberately does not go forward again afterwards: SurveyAppBar's
      // BackButton calls stepBack without a stepResult, so re-advancing here
      // would exercise a separate, pre-existing defect this test is not about.
      final key = GlobalKey<RebuildHostState>();
      await tester.pumpWidget(
        RebuildHost(key: key, task: twoStepTask(), onResult: (_) {}),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Two'), findsOneWidget);

      key.currentState!.rebuild();
      await tester.pump();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(
        find.text('One'),
        findsOneWidget,
        reason: 'the back button must return to q1',
      );

      key.currentState!.rebuild();
      await tester.pump();

      // The checkmark next to a choice is how a user sees "this is what I
      // picked"; assert on that rather than reaching into the answer view's
      // private state.
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Alpha'),
            matching: find.byType(ListTile),
          ),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
        reason: "q1's answer was dropped on the way back",
      );

      final results = providerFrom(tester, find.text('One')).results;
      final byId = {for (final r in results) r.id: r};
      expect((byId['q1']!.result! as TextChoice).value, 'alpha');
      expect(
        byId.containsKey('q2'),
        isFalse,
        reason:
            'q2 was never answered, so no result should have bled onto '
            'it',
      );
    },
  );

  testWidgets('answers do not bleed between steps', (tester) async {
    SurveyResult? captured;
    await tester.pumpWidget(
      RebuildHost(task: twoStepTask(), onResult: (r) => captured = r),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pump(const Duration(seconds: 1));

    expect(captured, isNotNull);
    final byId = {for (final r in captured!.results) r.id: r};
    expect((byId['q1']!.result! as TextChoice).value, 'alpha');
    expect(
      (byId['q2']!.result! as TextChoice).value,
      'yes',
      reason: "q2 must carry its own answer, not q1's",
    );
  });
}
