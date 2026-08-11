import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

Map<String, dynamic> conditional({
  String variable = 'child',
  String? defaultKey = 'Caroline',
  Map<String, dynamic>? variants,
}) => <String, dynamic>{
  'type': 'conditional',
  'variable': variable,
  if (defaultKey != null) 'default': defaultKey,
  'variants':
      variants ??
      <String, dynamic>{
        'Caroline': <String, dynamic>{'type': 'text'},
        'Lilia': <String, dynamic>{'type': 'integer'},
      },
};

void main() {
  group('resolution', () {
    test('a matching variable selects its variant', () {
      final format = AnswerFormat.fromJson(
        conditional(),
        variables: const <String, dynamic>{'child': 'Lilia'},
      );
      expect(format, isA<IntegerAnswerFormat>());
      expect(format.answerType, AnswerFormatType.integer);
    });

    test('an absent variable falls to the declared default', () {
      final format = AnswerFormat.fromJson(
        conditional(),
        variables: const <String, dynamic>{},
      );
      expect(format, isA<TextAnswerFormat>());
    });

    test('an unmatched variable falls to the declared default', () {
      final format = AnswerFormat.fromJson(
        conditional(),
        variables: const <String, dynamic>{'child': 'Thomas'},
      );
      expect(format, isA<TextAnswerFormat>());
    });

    test('a non-string variable value is matched by its toString', () {
      final format = AnswerFormat.fromJson(
        conditional(
          variants: <String, dynamic>{
            '1': <String, dynamic>{'type': 'text'},
            '2': <String, dynamic>{'type': 'integer'},
          },
          defaultKey: '1',
        ),
        variables: const <String, dynamic>{'child': 2},
      );
      expect(format, isA<IntegerAnswerFormat>());
    });

    test('no conditional value survives into the step', () {
      // The whole point: question_answer.dart stamps step.answerFormat's
      // discriminator onto every result, and _convert has no 'conditional'
      // branch. Resolution at parse makes that unreachable by construction.
      final step = Step.fromJson(
        <String, dynamic>{
          'id': 's1',
          'content': <dynamic>[],
          'answerFormat': conditional(),
        },
        variables: const <String, dynamic>{'child': 'Lilia'},
      );
      expect(step.answerFormat, isA<IntegerAnswerFormat>());
      expect(step.answerFormat!.answerType, AnswerFormatType.integer);
    });
  });

  group('malformed conditionals throw MalformedValueException', () {
    test('missing variable', () {
      final json = conditional()..remove('variable');
      expect(
        () => AnswerFormat.fromJson(json),
        throwsA(
          isA<MalformedValueException>().having(
            (e) => e.field,
            'field',
            'variable',
          ),
        ),
      );
    });

    test('missing variants', () {
      final json = conditional()..remove('variants');
      expect(
        () => AnswerFormat.fromJson(json),
        throwsA(
          isA<MalformedValueException>().having(
            (e) => e.field,
            'field',
            'variants',
          ),
        ),
      );
    });

    test('missing default', () {
      // Required deliberately. The consumer's preprocessing fell back to
      // `variants.values.first`, which makes behaviour depend on JSON key
      // order. Requiring `default` makes the fallback authored.
      final json = conditional(defaultKey: null);
      expect(
        () => AnswerFormat.fromJson(json),
        throwsA(
          isA<MalformedValueException>().having(
            (e) => e.field,
            'field',
            'default',
          ),
        ),
      );
    });

    test('default naming a key absent from variants', () {
      // Caught at parse, so an authoring typo fails when the survey loads
      // rather than when a user reaches the step.
      final json = conditional(defaultKey: 'Nobody');
      expect(
        () => AnswerFormat.fromJson(json),
        throwsA(
          isA<MalformedValueException>()
              .having((e) => e.field, 'field', 'default')
              .having((e) => e.value, 'value', 'Nobody'),
        ),
      );
    });

    test('a variant that is not an object', () {
      final json = conditional(
        variants: <String, dynamic>{'Caroline': 'not-an-object'},
      );
      expect(
        () => AnswerFormat.fromJson(json),
        throwsA(isA<MalformedValueException>()),
      );
    });
  });

  test('an unknown variant type still throws UnknownTypeException', () {
    // The variant is parsed through the normal dispatch, so it inherits the
    // same contract.
    final json = conditional(
      variants: <String, dynamic>{
        'Caroline': <String, dynamic>{'type': 'no-such-format'},
      },
    );
    expect(
      () => AnswerFormat.fromJson(json),
      throwsA(
        isA<UnknownTypeException>()
            .having((e) => e.kind, 'kind', 'AnswerFormat')
            .having((e) => e.discriminator, 'discriminator', 'no-such-format'),
      ),
    );
  });
}
