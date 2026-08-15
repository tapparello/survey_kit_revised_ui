// Unit tests for the directive in isolation. The behaviour these pin used to
// live inside AnswerFormat._resolveConditional and ran at parse time; ADO #1045
// splits it into shape validation here and value selection in SurveyEngine.
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

/// A well-formed directive. Mirrors the consumer's real shape, including the
/// `formatId` key that neither this class nor AnswerFormat has a field for.
Map<String, dynamic> conditional({
  Object? defaultKey = 'Caroline',
  Map<String, dynamic>? variants,
}) => <String, dynamic>{
  'type': 'conditional',
  'variable': 'child',
  'formatId': 'child_function_answer',
  if (defaultKey != null) 'default': defaultKey,
  'variants':
      variants ??
      <String, dynamic>{
        'Caroline': <String, dynamic>{'type': 'text'},
        'Lilia': <String, dynamic>{'type': 'integer'},
      },
};

void main() {
  group('fromJson', () {
    test('parses a well-formed directive and keeps its source', () {
      final directive = ConditionalAnswerFormat.fromJson(conditional());

      expect(directive.variable, 'child');
      expect(directive.defaultKey, 'Caroline');
      expect(directive.variants.keys, <String>['Caroline', 'Lilia']);
      expect(directive.variants['Lilia'], isA<IntegerAnswerFormat>());
      // The whole point of retaining the source: formatId has no field here and
      // would be lost by any reconstruction from the parsed fields.
      expect(directive.sourceJson['formatId'], 'child_function_answer');
    });

    test('missing variable throws MalformedValueException', () {
      final json = conditional()..remove('variable');
      expect(
        () => ConditionalAnswerFormat.fromJson(json),
        throwsA(isA<MalformedValueException>()),
      );
    });

    test('missing variants throws MalformedValueException', () {
      final json = conditional()..remove('variants');
      expect(
        () => ConditionalAnswerFormat.fromJson(json),
        throwsA(isA<MalformedValueException>()),
      );
    });

    test('a null default throws MalformedValueException', () {
      expect(
        () => ConditionalAnswerFormat.fromJson(conditional(defaultKey: null)),
        throwsA(isA<MalformedValueException>()),
      );
    });

    test('a default naming an absent key throws MalformedValueException', () {
      expect(
        () =>
            ConditionalAnswerFormat.fromJson(conditional(defaultKey: 'Nobody')),
        throwsA(isA<MalformedValueException>()),
      );
    });

    test('a variant that is not an object throws MalformedValueException', () {
      final json = conditional(
        variants: <String, dynamic>{'Caroline': 'not-an-object'},
      );
      expect(
        () => ConditionalAnswerFormat.fromJson(json),
        throwsA(isA<MalformedValueException>()),
      );
    });

    test('an unknown variant type throws UnknownTypeException', () {
      final json = conditional(
        variants: <String, dynamic>{
          'Caroline': <String, dynamic>{'type': 'no-such-format'},
        },
      );
      expect(
        () => ConditionalAnswerFormat.fromJson(json),
        throwsA(isA<UnknownTypeException>()),
      );
    });

    test('a malformed NON-DEFAULT variant throws too', () {
      // The discriminating case for eager validation. Before ADO #1045 only the
      // selected variant was ever parsed, so a broken never-selected variant was
      // inert dead JSON. Every pre-existing malformed test puts its bad shape
      // under the `default` key, so this is the only case that can tell eager
      // and lazy parsing apart.
      final json = conditional(
        variants: <String, dynamic>{
          'Caroline': <String, dynamic>{'type': 'text'},
          'Lilia': <String, dynamic>{'type': 'no-such-format'},
        },
      );
      expect(
        () => ConditionalAnswerFormat.fromJson(json),
        throwsA(isA<UnknownTypeException>()),
      );
    });
  });

  group('resolve', () {
    test('selects the variant named by the variable', () {
      final directive = ConditionalAnswerFormat.fromJson(conditional());
      expect(
        directive.resolve(<String, dynamic>{'child': 'Lilia'}),
        isA<IntegerAnswerFormat>(),
      );
    });

    test('falls back to default when the variable is absent', () {
      final directive = ConditionalAnswerFormat.fromJson(conditional());
      expect(
        directive.resolve(const <String, dynamic>{}),
        isA<TextAnswerFormat>(),
      );
    });

    test('falls back to default when the value names no variant', () {
      final directive = ConditionalAnswerFormat.fromJson(conditional());
      expect(
        directive.resolve(<String, dynamic>{'child': 'Nobody'}),
        isA<TextAnswerFormat>(),
      );
    });

    test('stringifies non-string variable values', () {
      final directive = ConditionalAnswerFormat.fromJson(
        conditional(
          defaultKey: '1',
          variants: <String, dynamic>{
            '1': <String, dynamic>{'type': 'text'},
            '2': <String, dynamic>{'type': 'integer'},
          },
        ),
      );
      expect(
        directive.resolve(<String, dynamic>{'child': 2}),
        isA<IntegerAnswerFormat>(),
      );
    });
  });
}
