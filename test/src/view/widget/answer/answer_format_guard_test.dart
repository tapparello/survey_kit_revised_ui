import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/view/widget/answer/answer_format_guard.dart';
import 'package:survey_kit/survey_kit.dart';

void main() {
  group('requireAnswerFormat', () {
    test('returns the format when it is present and of the right type', () {
      final step = Step(
        id: 'step-ok',
        content: const [],
        answerFormat: const TextAnswerFormat(),
      );

      final format = requireAnswerFormat<TextAnswerFormat>(step);

      expect(format, isA<TextAnswerFormat>());
      expect(identical(format, step.answerFormat), isTrue);
    });

    test('throws MissingAnswerFormatException when the step has none', () {
      final step = Step(id: 'step-missing', content: const []);

      expect(
        () => requireAnswerFormat<TextAnswerFormat>(step),
        throwsA(
          isA<MissingAnswerFormatException>()
              .having((e) => e.stepId, 'stepId', 'step-missing')
              .having((e) => e.expected, 'expected', 'TextAnswerFormat'),
        ),
      );
    });

    test('throws AnswerFormatMismatchException on the wrong subtype', () {
      final step = Step(
        id: 'step-wrong',
        content: const [],
        answerFormat: const BooleanAnswerFormat(
          positiveAnswer: 'Yes',
          negativeAnswer: 'No',
        ),
      );

      expect(
        () => requireAnswerFormat<TextAnswerFormat>(step),
        throwsA(
          isA<AnswerFormatMismatchException>()
              .having((e) => e.stepId, 'stepId', 'step-wrong')
              .having((e) => e.expected, 'expected', 'TextAnswerFormat')
              .having((e) => e.actual, 'actual', 'BooleanAnswerFormat'),
        ),
      );
    });
  });

  group('the guard is wired at the public entry point', () {
    // ImageAnswerView is used deliberately. It is barrel-exported AND mixes in
    // only MeasureDateStateMixin. The 12 views that mix in AnswerMixin register
    // a post-frame QuestionAnswer.of(context) callback; when initState throws,
    // the element is left deactivated and that callback raises a SECOND
    // exception, so takeException() returns a String rather than our type.
    testWidgets('ImageAnswerView surfaces the typed exception', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ImageAnswerView(
            questionStep: Step(id: 'step-view', content: const []),
            result: null,
          ),
        ),
      );

      expect(
        tester.takeException(),
        isA<MissingAnswerFormatException>()
            .having((e) => e.stepId, 'stepId', 'step-view')
            .having((e) => e.expected, 'expected', 'ImageAnswerFormat'),
      );
    });
  });
}
