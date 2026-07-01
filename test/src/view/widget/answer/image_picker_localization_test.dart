// Guards ADO #973: the image answer view's option dialog labels route through
// the app localizations map, falling back to English.
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

Widget _app({Map<String, String>? localizations}) => MaterialApp(
      home: Scaffold(
        body: SurveyKit(
          task: OrderedTask(id: 't', steps: [
            QuestionStep(
              id: 'q_img',
              title: 'Photo',
              answerFormat: const ImageAnswerFormat(buttonText: 'Choose'),
              buttonText: 'Advance',
            ),
            CompletionStep(title: 'Done', text: 'Thanks', buttonText: 'Submit'),
          ]),
          localizations: localizations,
          onResult: (_) {},
        ),
      ),
    );

Future<void> _openOptions(WidgetTester tester) async {
  await tester.tap(find.text('Choose')); // opens _optionsDialogBox
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('image option labels use localized values when provided',
      (tester) async {
    await tester.pumpWidget(_app(localizations: {
      'take_a_picture': 'ZZ_CAM',
      'select_from_gallery': 'ZZ_GAL',
    }));
    await tester.pumpAndSettle();
    await _openOptions(tester);

    expect(find.text('ZZ_CAM'), findsOneWidget);
    expect(find.text('ZZ_GAL'), findsOneWidget);
    expect(find.text('Take a picture'), findsNothing);
  });

  testWidgets('image option labels fall back to English when no map',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _openOptions(tester);

    expect(find.text('Take a picture'), findsOneWidget);
    expect(find.text('Select from Gallery'), findsOneWidget);
  });
}
