import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/model/answer/date_answer_format.dart';

void main() {
  group('DateAnswerFormat futureOnly', () {
    test('defaults to false when absent from JSON', () {
      final format = DateAnswerFormat.fromJson({
        'type': 'date',
        'question': 'When?',
      });
      expect(format.futureOnly, isFalse);
    });

    test('parses futureOnly:true from JSON', () {
      final format = DateAnswerFormat.fromJson({
        'type': 'date',
        'futureOnly': true,
        'question': 'Check back on...',
      });
      expect(format.futureOnly, isTrue);
    });

    test('round-trips futureOnly through toJson', () {
      final format = DateAnswerFormat(futureOnly: true, question: 'x');
      expect(format.toJson()['futureOnly'], isTrue);
      expect(DateAnswerFormat.fromJson(format.toJson()).futureOnly, isTrue);
    });
  });
}
