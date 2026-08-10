// Guards ADO #978: a multi-choice question with an "Other / Add your own"
// write-in field must restore the previously entered text when the question is
// revisited (a new StepView instance on back-navigation, or a new run that
// reloads the saved result). The value is preserved in the step result, but the
// TextField was rendered without a controller, so it came up blank.
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

void main() {
  testWidgets(
    'restores the saved "Other" write-in text from an existing result',
    (WidgetTester tester) async {
      final otherStep = QuestionStep(
        id: 'q_other',
        title: 'Other',
        answerFormat: MultipleChoiceAnswerFormat(
          textChoices: [
            TextChoice(
              id: '1',
              text: 'Juvenile justice services',
              value: 'Juvenile justice services',
            ),
          ],
          otherField: true,
          otherHintText: 'Add your own...',
          noneOption: true,
          maxAllowedChoices: 5,
        ),
        buttonText: 'Next',
      );

      final t = DateTime(2024);
      // Simulates a prior run/back-nav: the "Other" free-text was saved as an
      // 'Other' choice on this step.
      final seeded = StepResult<List<TextChoice>>(
        id: 'q_other',
        answerType: MultipleChoiceAnswerFormat.type,
        startTime: t,
        endTime: t,
        result: [
          TextChoice(
            id: 'Other',
            text: 'My custom entry',
            value: 'My custom entry',
          ),
        ],
      );

      final widget = MaterialApp(
        home: Scaffold(
          body: SurveyKit(
            task: OrderedTask(
              id: 't',
              steps: [
                otherStep,
                CompletionStep(
                  title: 'Done',
                  text: 'Thanks',
                  buttonText: 'Submit',
                ),
              ],
            ),
            initialResults: {seeded},
            onResult: (_) {},
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // The write-in field must show the previously entered text, not just the hint.
      expect(find.text('My custom entry'), findsOneWidget);
    },
  );
}
