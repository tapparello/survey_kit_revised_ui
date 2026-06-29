// Guards ADO #961: survey answer-view ListTiles must not trigger Flutter's
// "ListTile background color or ink splashes may be invisible." debug warning.
// The warning is reported via FlutterError.reportError inside an assert, so a
// widget test captures it through tester.takeException().
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

void main() {
  testWidgets(
      'single- and multiple-choice steps do not emit the ListTile background/ink warning',
      (WidgetTester tester) async {
    final widget = MaterialApp(
      home: Scaffold(
        body: SurveyKit(
          task: OrderedTask(
            id: '1',
            steps: [
              InstructionStep(
                title: 'Welcome',
                text: 'Tap to start',
                buttonText: "Let's go!",
              ),
              QuestionStep(
                title: 'Pick one',
                // NOTE: not const — TextChoice's constructor is non-const
                // (it generates a uuid for `id`), so neither the list nor the
                // answer format can be const.
                answerFormat: SingleChoiceAnswerFormat(
                  textChoices: [
                    TextChoice(text: 'Boy?', value: 'boy'),
                    TextChoice(text: 'Girl?', value: 'girl'),
                    TextChoice(text: 'Other?', value: 'other'),
                  ],
                ),
                buttonText: 'Next',
              ),
              QuestionStep(
                title: 'Pick any',
                answerFormat: MultipleChoiceAnswerFormat(
                  textChoices: [
                    TextChoice(text: 'Has meltdowns', value: 'a'),
                    TextChoice(text: "Can't sit still", value: 'b'),
                    TextChoice(text: 'Is disorganized', value: 'c'),
                  ],
                  maxAllowedChoices: 3,
                ),
                buttonText: 'Next',
              ),
              CompletionStep(
                title: 'Done!',
                text: 'Thanks',
                buttonText: 'Submit survey',
              ),
            ],
          ),
          onResult: (_) {},
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Advance past the instruction step to the single-choice question.
    await tester.tap(find.text("Let's go!"));
    await tester.pumpAndSettle();
    expect(find.text('Boy?'), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: 'single-choice render must not emit the ListTile ink/background warning');

    // ADO #961 follow-up: the selectable rows must disable ink so the
    // previously-hidden ripple stays hidden (flat look: blue text + check only).
    // Robust to extra Theme layers / ancestor ordering: assert SOME Theme
    // ancestor of the answer ListTile disables ink (NoSplash + transparent
    // highlight) — only SelectionListTile's override sets both.
    final answerTileThemes = tester.widgetList<Theme>(
      find.ancestor(of: find.byType(ListTile).first, matching: find.byType(Theme)),
    );
    expect(
      answerTileThemes.any((t) =>
          t.data.splashFactory == NoSplash.splashFactory &&
          t.data.highlightColor == Colors.transparent),
      isTrue,
      reason: 'answer rows must be wrapped in a Theme that disables ink (no ripple)',
    );

    // Selecting an option rebuilds the answer view — the rebuild that fires the
    // warning in production.
    await tester.tap(find.text('Boy?'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull,
        reason: 'single-choice selection rebuild must not emit the warning');

    // Advance to the multiple-choice question and assert the same.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Is disorganized'), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: 'multiple-choice render must not emit the warning');

    await tester.tap(find.text('Is disorganized'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull,
        reason: 'multiple-choice selection rebuild must not emit the warning');
  });
}
