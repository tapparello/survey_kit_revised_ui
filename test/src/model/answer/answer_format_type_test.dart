import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

void main() {
  test('every member carries the discriminator its format declares', () {
    final expected = <AnswerFormatType, String>{
      AnswerFormatType.boolean: 'bool',
      AnswerFormatType.date: 'date',
      AnswerFormatType.doubleValue: 'double',
      AnswerFormatType.integer: 'integer',
      AnswerFormatType.image: 'image',
      AnswerFormatType.text: 'text',
      AnswerFormatType.time: 'time',
      AnswerFormatType.scale: 'scale',
      AnswerFormatType.single: 'single',
      AnswerFormatType.singleWithFeedback: 'single_with_feedback',
      AnswerFormatType.multi: 'multi',
      AnswerFormatType.multiWithFeedback: 'multi_with_feedback',
      AnswerFormatType.multipleAutoComplete: 'multiple_auto_complete',
      AnswerFormatType.multipleDouble: 'multiple_double',
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
