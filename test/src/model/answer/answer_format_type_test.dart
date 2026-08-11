import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

void main() {
  test('every member carries the discriminator its format declares', () {
    // Pinned against the `static const String type` constants while they are
    // still the source of truth. Task 2 deletes them and replaces the right
    // column with literals.
    final expected = <AnswerFormatType, String>{
      AnswerFormatType.boolean: BooleanAnswerFormat.type,
      AnswerFormatType.date: DateAnswerFormat.type,
      AnswerFormatType.doubleValue: DoubleAnswerFormat.type,
      AnswerFormatType.integer: IntegerAnswerFormat.type,
      AnswerFormatType.image: ImageAnswerFormat.type,
      AnswerFormatType.text: TextAnswerFormat.type,
      AnswerFormatType.time: TimeAnswerFormat.type,
      AnswerFormatType.scale: ScaleAnswerFormat.type,
      AnswerFormatType.single: SingleChoiceAnswerFormat.type,
      AnswerFormatType.singleWithFeedback:
          SingleChoiceAnswerWithFeedbackFormat.type,
      AnswerFormatType.multi: MultipleChoiceAnswerFormat.type,
      AnswerFormatType.multiWithFeedback:
          MultipleChoiceAnswerWithFeedbackFormat.type,
      AnswerFormatType.multipleAutoComplete:
          MultipleChoiceAutoCompleteAnswerFormat.type,
      AnswerFormatType.multipleDouble: MultipleDoubleAnswerFormat.type,
    };

    expect(AnswerFormatType.values.length, 14);
    expect(expected.length, 14);
    for (final member in AnswerFormatType.values) {
      expect(member.wireName, expected[member], reason: member.name);
    }
  });

  test('byWireName round-trips every member and rejects the rest', () {
    for (final member in AnswerFormatType.values) {
      expect(AnswerFormatType.byWireName(member.wireName), member);
    }
    expect(AnswerFormatType.byWireName('no-such-format'), isNull);
    expect(AnswerFormatType.byWireName(null), isNull);
  });

  test('each member builds its own format', () {
    // The factory tearoff is the dispatch itself; a copy-paste slip here would
    // silently build the wrong subtype for a correct discriminator.
    expect(
      AnswerFormatType.time.fromJson(const <String, dynamic>{'type': 'time'}),
      isA<TimeAnswerFormat>(),
    );
    expect(
      AnswerFormatType.text.fromJson(const <String, dynamic>{'type': 'text'}),
      isA<TextAnswerFormat>(),
    );
    expect(
      AnswerFormatType.single.fromJson(const <String, dynamic>{
        'type': 'single',
        'textChoices': <dynamic>[],
      }),
      isA<SingleChoiceAnswerFormat>(),
    );
  });

  test('wireNameOf maps back to the wire string', () {
    expect(AnswerFormatType.wireNameOf(AnswerFormatType.boolean), 'bool');
    expect(AnswerFormatType.wireNameOf(null), isNull);
  });
}
