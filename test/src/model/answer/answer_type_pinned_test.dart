import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

/// Phase 2b dispatches result conversion on [AnswerFormat.answerType], so a
/// format reporting a discriminator other than its own would convert with the
/// wrong branch in both directions. `answerType` is a getter rather than a
/// constructor parameter precisely so a caller cannot cause that; these tests
/// pin the values the getters return.
void main() {
  test('every answer format reports its own discriminator', () {
    final cases = <AnswerFormat, String>{
      const BooleanAnswerFormat(positiveAnswer: 'y', negativeAnswer: 'n'):
          BooleanAnswerFormat.type,
      // DateAnswerFormat's constructor is not const (date_answer_format.dart:25).
      DateAnswerFormat(): DateAnswerFormat.type,
      const DoubleAnswerFormat(): DoubleAnswerFormat.type,
      const ImageAnswerFormat(): ImageAnswerFormat.type,
      const IntegerAnswerFormat(): IntegerAnswerFormat.type,
      const MultipleChoiceAnswerFormat(textChoices: []):
          MultipleChoiceAnswerFormat.type,
      const MultipleChoiceAnswerWithFeedbackFormat(textChoices: []):
          MultipleChoiceAnswerWithFeedbackFormat.type,
      const MultipleChoiceAutoCompleteAnswerFormat(textChoices: []):
          MultipleChoiceAutoCompleteAnswerFormat.type,
      const MultipleDoubleAnswerFormat(hints: []):
          MultipleDoubleAnswerFormat.type,
      const ScaleAnswerFormat(
        minimumValue: 0,
        maximumValue: 10,
        defaultValue: 5,
        step: 1,
      ): ScaleAnswerFormat.type,
      const SingleChoiceAnswerFormat(textChoices: []):
          SingleChoiceAnswerFormat.type,
      const SingleChoiceAnswerWithFeedbackFormat(textChoices: []):
          SingleChoiceAnswerWithFeedbackFormat.type,
      const TextAnswerFormat(): TextAnswerFormat.type,
      const TimeAnswerFormat(): TimeAnswerFormat.type,
    };

    expect(cases.length, 14);
    cases.forEach((format, expected) {
      expect(format.answerType, expected, reason: expected);
    });
  });

  test('a format built from JSON also reports its discriminator', () {
    final format = AnswerFormat.fromJson(const <String, dynamic>{
      'type': 'time',
    });
    expect(format.answerType, TimeAnswerFormat.type);
  });

  test('toJson still emits the discriminator after the getter conversion', () {
    // Regression guard for the codegen hazard: json_serializable only emits a
    // superclass-declared annotated getter into a subclass's toJson if the
    // subclass repeats the @JsonKey annotation on its override. Dropping that
    // annotation silently removes 'type' and breaks AnswerFormat.fromJson
    // library-wide with a clean build and no errors. See ADO #1001 and #1012.
    expect(const TimeAnswerFormat().toJson()['type'], TimeAnswerFormat.type);
    expect(const TextAnswerFormat().toJson()['type'], TextAnswerFormat.type);
  });
}
