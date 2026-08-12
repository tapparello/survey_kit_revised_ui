// ADO #1033 Defect 2: AnswerView depends on SurveyStateProvider and rebuilds a
// fresh QuestionAnswer, discarding the in-progress answer. The answer view's
// own State survives, so the UI kept showing the answer selected while the
// recorded value was gone.
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

import '../../../presenter/rebuild_harness.dart';

void main() {
  testWidgets('an answer entered before a parent rebuild is still recorded',
      (tester) async {
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
    expect(q1, hasLength(1),
        reason: 'the q1 answer was dropped: StepView passed a null stepResult');
    expect((q1.single.result! as TextChoice).value, 'alpha');
  });

  testWidgets('a mandatory step stays blocked across a parent rebuild',
      (tester) async {
    final key = GlobalKey<RebuildHostState>();
    await tester.pumpWidget(
      RebuildHost(key: key, task: twoStepTask(), onResult: (_) {}),
    );
    await tester.pumpAndSettle();

    ElevatedButton nextButton() => tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Next'),
        );

    expect(nextButton().onPressed, isNull,
        reason: 'an unanswered mandatory step must not be submittable');

    key.currentState!.rebuild();
    await tester.pumpAndSettle();

    expect(nextButton().onPressed, isNull,
        reason: 'isValid reset to true, defeating mandatory gating');
  });

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
    expect((byId['q2']!.result! as TextChoice).value, 'yes',
        reason: "q2 must carry its own answer, not q1's");
  });
}
