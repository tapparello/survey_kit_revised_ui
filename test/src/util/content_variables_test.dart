import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/model/answer/text_choice.dart';
import 'package:survey_kit/src/util/content_variables.dart';

void main() {
  group('extractAnswerValue', () {
    test('TextChoice -> value ?? text', () {
      expect(extractAnswerValue(TextChoice(text: 'Aidan', value: 'Aidan')), 'Aidan');
      expect(extractAnswerValue(TextChoice(text: 'My child is lazy')), 'My child is lazy');
    });

    test('List<TextChoice> -> List<String> (strict typing for {{#list}})', () {
      final r = extractAnswerValue([
        TextChoice(text: 'Morning routine', value: 'Morning routine'),
        TextChoice(text: 'Bedtime routine', value: 'Bedtime routine'),
      ]);
      expect(r, isA<List<String>>());
      expect(r, ['Morning routine', 'Bedtime routine']);
    });

    test('num and String pass through', () {
      expect(extractAnswerValue(7), 7);
      expect(extractAnswerValue('x'), 'x');
    });

    test('null and unsupported types -> null', () {
      expect(extractAnswerValue(null), isNull);
      expect(extractAnswerValue(DateTime(2020)), isNull);
    });

    test('restored single-choice Map (resume path) -> value ?? text', () {
      // valueless choice (e.g. section 4_11 interpretations: only text present)
      expect(extractAnswerValue({'id': 'x', 'text': 'My child is lazy'}), 'My child is lazy');
      // choice with value (e.g. 5_6_2 child selection)
      expect(extractAnswerValue({'id': 'x', 'text': 'Aidan', 'value': 'Aidan'}), 'Aidan');
    });

    test('restored multi-choice List<Map> (resume path) -> List<String>, not Map-stringified', () {
      final r = extractAnswerValue([
        {'id': 'a', 'text': 'Morning routine'},
        {'id': 'b', 'text': 'Bedtime routine', 'value': 'Bedtime routine'},
      ]);
      expect(r, isA<List<String>>());
      expect(r, ['Morning routine', 'Bedtime routine']);
    });
  });

  group('mergeContentVariables', () {
    test('config variables win over step answers on key collision', () {
      final merged = mergeContentVariables(
        {'4_7_22': 'the choice text', 'a': 1},
        {'4_7_22': '<p>SCORE</p>'},
      );
      expect(merged['4_7_22'], '<p>SCORE</p>');
      expect(merged['a'], 1);
    });

    test('step answers fill keys absent from config', () {
      final merged = mergeContentVariables({'4_11_1': 'My child is lazy'}, {});
      expect(merged['4_11_1'], 'My child is lazy');
    });
  });
}
