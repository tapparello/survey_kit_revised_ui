// Guards ADO #973: the answer-feedback dialog's "Next" button routes through the
// app localizations map (reusing the existing `next` key), falling back to English.
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

// Return type is `Step` (see Task 1 note). Format is NOT `const`: its `textChoices`
// hold non-const `TextChoice`s (TextChoice has a constructor body).
Step _feedbackStep() => QuestionStep(
  id: 'q_fb',
  title: 'Choose',
  answerFormat: SingleChoiceAnswerWithFeedbackFormat(
    textChoices: [TextChoice(id: '1', text: 'Option one', value: 'wrong')],
    feedbackWrong: 'Not quite.',
  ),
  buttonText: 'Advance',
);

Widget _app({Map<String, String>? localizations}) => MaterialApp(
  home: Scaffold(
    body: SurveyKit(
      task: OrderedTask(
        id: 't',
        steps: [
          _feedbackStep(),
          CompletionStep(title: 'Done', text: 'Thanks', buttonText: 'Submit'),
        ],
      ),
      localizations: localizations,
      onResult: (_) {},
    ),
  ),
);

// Selecting a value != 'correct' makes the feedback non-auto-dismiss, so the
// tappable "Next" button is shown.
Future<void> _answerAndAdvance(WidgetTester tester) async {
  await tester.tap(find.text('Option one'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Advance'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('feedback dialog Next uses the localized `next` value', (
    tester,
  ) async {
    await tester.pumpWidget(_app(localizations: {'next': 'ZZ_NEXT'}));
    await tester.pumpAndSettle();
    await _answerAndAdvance(tester);

    expect(find.text('ZZ_NEXT'), findsOneWidget); // the feedback dialog button
    expect(find.text('Next'), findsNothing);
  });

  testWidgets('feedback dialog Next falls back to English when no map', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _answerAndAdvance(tester);

    // Step forward button is 'Advance', so this 'Next' is the feedback button.
    expect(find.text('Next'), findsOneWidget);
  });
}
