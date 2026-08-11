import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

/// Result conversion dispatches on [AnswerFormat.answerType], so a format
/// reporting a discriminator other than its own would convert with the wrong
/// branch in both directions. `answerType` is a getter rather than a
/// constructor parameter precisely so a caller cannot cause that.
void main() {
  final samples = <AnswerFormatType, AnswerFormat>{
    AnswerFormatType.boolean: const BooleanAnswerFormat(
      positiveAnswer: 'y',
      negativeAnswer: 'n',
    ),
    // DateAnswerFormat's constructor is not const (date_answer_format.dart:25).
    AnswerFormatType.date: DateAnswerFormat(),
    AnswerFormatType.doubleValue: const DoubleAnswerFormat(),
    AnswerFormatType.integer: const IntegerAnswerFormat(),
    AnswerFormatType.image: const ImageAnswerFormat(),
    AnswerFormatType.text: const TextAnswerFormat(),
    AnswerFormatType.time: const TimeAnswerFormat(),
    AnswerFormatType.scale: const ScaleAnswerFormat(
      minimumValue: 0,
      maximumValue: 10,
      defaultValue: 5,
      step: 1,
    ),
    AnswerFormatType.single: const SingleChoiceAnswerFormat(textChoices: []),
    AnswerFormatType.singleWithFeedback:
        const SingleChoiceAnswerWithFeedbackFormat(textChoices: []),
    AnswerFormatType.multi: const MultipleChoiceAnswerFormat(textChoices: []),
    AnswerFormatType.multiWithFeedback:
        const MultipleChoiceAnswerWithFeedbackFormat(textChoices: []),
    AnswerFormatType.multipleAutoComplete:
        const MultipleChoiceAutoCompleteAnswerFormat(textChoices: []),
    AnswerFormatType.multipleDouble: const MultipleDoubleAnswerFormat(
      hints: [],
    ),
  };

  test('every answer format reports its own discriminator', () {
    expect(samples.length, AnswerFormatType.values.length);
    for (final member in AnswerFormatType.values) {
      final format = samples[member];
      expect(format, isNotNull, reason: 'no sample for ${member.name}');
      expect(format!.answerType, member, reason: member.name);
    }
  });

  test('toJson emits the wire discriminator for all fourteen formats', () {
    // Regression guard for the codegen hazard: json_serializable only emits a
    // superclass-declared annotated getter into a subclass's toJson if the
    // subclass repeats the @JsonKey annotation on its override. Dropping that
    // annotation silently removes 'type'. The @JsonValue map on
    // AnswerFormatType is what keeps the emitted value correct. ADO #1001/#1012.
    for (final member in AnswerFormatType.values) {
      expect(
        samples[member]!.toJson()['type'],
        member.wireName,
        reason: member.name,
      );
    }
  });

  test('a format built from JSON also reports its discriminator', () {
    final format = AnswerFormat.fromJson(const <String, dynamic>{
      'type': 'time',
    });
    expect(format.answerType, AnswerFormatType.time);
  });
}
