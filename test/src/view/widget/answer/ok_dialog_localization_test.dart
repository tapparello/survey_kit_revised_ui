// Guards ADO #973: the max-allowed-choices dialog "OK" button must render the
// localized label from the app's `localizations` map, falling back to English.
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

// Return type is `Step` (not `QuestionStep`): `QuestionStep` is a @Deprecated
// factory function returning `Step`, not a type. `Step` is exported by the barrel
// (Material's Step is hidden via `hide Step`).
Step _maxOneStep() => QuestionStep(
      id: 'q_multi',
      title: 'Pick one',
      answerFormat: MultipleChoiceAnswerFormat(
        textChoices: [
          TextChoice(id: 'a', text: 'Alpha', value: 'Alpha'),
          TextChoice(id: 'b', text: 'Bravo', value: 'Bravo'),
        ],
        noneOption: false,
        maxAllowedChoices: 1,
      ),
      buttonText: 'Advance',
    );

Widget _app({Map<String, String>? localizations}) => MaterialApp(
      home: Scaffold(
        body: SurveyKit(
          task: OrderedTask(id: 't', steps: [
            _maxOneStep(),
            CompletionStep(title: 'Done', text: 'Thanks', buttonText: 'Submit'),
          ]),
          localizations: localizations,
          onResult: (_) {},
        ),
      ),
    );

Future<void> _triggerMaxDialog(WidgetTester tester) async {
  await tester.tap(find.text('Alpha'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Bravo')); // exceeds maxAllowedChoices:1 -> dialog
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('OK dialog uses the localized label when provided', (tester) async {
    await tester.pumpWidget(_app(localizations: {'ok': 'ZZ_OK'}));
    await tester.pumpAndSettle();
    await _triggerMaxDialog(tester);

    expect(find.text('ZZ_OK'), findsOneWidget);
    expect(find.text('OK'), findsNothing);
  });

  testWidgets('OK dialog falls back to English when no map', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _triggerMaxDialog(tester);

    expect(find.text('OK'), findsOneWidget);
  });
}
