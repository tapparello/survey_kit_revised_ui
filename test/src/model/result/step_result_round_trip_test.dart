import 'dart:convert';

import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

/// Round-trips through `StepResult<dynamic>` — the type argument
/// `SurveyResult.fromJson` actually uses, and the one ADO #1009 broke.
///
/// Every case asserts the **runtime type** as well as the value. Asserting the
/// value alone would pass for `String` results even while the defect was live,
/// and asserting `equals()` on the aggregate proves nothing at all:
/// `SurveyResult.==` excludes `results` and `StepResult.==` excludes `result`,
/// which is why the pre-existing suite stayed green while every result was
/// being returned as raw JSON.
StepResult<dynamic> _roundTrip(StepResult<Object?> original) {
  final encoded = jsonDecode(jsonEncode(original.toJson()));
  return StepResult<dynamic>.fromJson(encoded as Map<String, dynamic>);
}

StepResult<T> _make<T>(String answerType, T value) => StepResult<T>(
  id: 'q1',
  answerType: answerType,
  result: value,
  startTime: DateTime(2026, 1, 1, 9),
  endTime: DateTime(2026, 1, 1, 9, 1),
);

void main() {
  group('a result round-trips with its declared type', () {
    test('bool', () {
      final back = _roundTrip(
        _make(BooleanAnswerFormat.type, BooleanResult.positive),
      );
      expect(back.result, isA<BooleanResult>());
      expect(back.result, BooleanResult.positive);
    });

    test('date', () {
      // Local-origin, matching what DateAnswerView's date picker produces.
      final value = DateTime(2026, 3, 4);
      final back = _roundTrip(_make(DateAnswerFormat.type, value));
      expect(back.result, isA<DateTime>());
      expect((back.result as DateTime).toUtc(), value.toUtc());
    });

    test('time', () {
      final back = _roundTrip(
        _make(
          TimeAnswerFormat.type,
          const TimeResult(timeOfDay: TimeOfDay(hour: 9, minute: 30)),
        ),
      );
      expect(back.result, isA<TimeResult>());
      // TimeResult declares no operator== — compare fields.
      expect((back.result as TimeResult).timeOfDay.hour, 9);
      expect((back.result as TimeResult).timeOfDay.minute, 30);
    });

    test('text', () {
      final back = _roundTrip(_make(TextAnswerFormat.type, 'hello'));
      expect(back.result, isA<String>());
      expect(back.result, 'hello');
    });

    test('integer', () {
      final back = _roundTrip(_make(IntegerAnswerFormat.type, 7));
      expect(back.result, isA<int>());
      expect(back.result, 7);
    });

    test('double', () {
      final back = _roundTrip(_make(DoubleAnswerFormat.type, 2.5));
      expect(back.result, isA<double>());
      expect(back.result, 2.5);
    });

    test('scale widens a whole-numbered double back to double', () {
      // jsonEncode(3.0) emits "3.0", but a legacy or hand-written record may
      // carry a bare 3, which decodes as int. The scale arm must widen.
      final back = _roundTrip(_make(ScaleAnswerFormat.type, 3.0));
      expect(back.result, isA<double>());
      expect(back.result, 3.0);
    });

    test('single_choice', () {
      // TextChoice is not const-constructible: its `id` defaults to a uuid.
      final back = _roundTrip(
        _make(SingleChoiceAnswerFormat.type, TextChoice(text: 'A', value: 'a')),
      );
      expect(back.result, isA<TextChoice>());
      expect((back.result as TextChoice).value, 'a');
    });

    test('single_with_feedback', () {
      final back = _roundTrip(
        _make(
          SingleChoiceAnswerWithFeedbackFormat.type,
          TextChoice(text: 'B', value: 'b'),
        ),
      );
      expect(back.result, isA<TextChoice>());
      expect((back.result as TextChoice).value, 'b');
    });

    test('multi', () {
      final back = _roundTrip(
        _make(MultipleChoiceAnswerFormat.type, [
          TextChoice(text: 'A', value: 'a'),
          TextChoice(text: 'B', value: 'b'),
        ]),
      );
      expect(back.result, isA<List<TextChoice>>());
      expect((back.result as List<TextChoice>).map((c) => c.value).toList(), [
        'a',
        'b',
      ]);
    });

    test('multi_with_feedback', () {
      final back = _roundTrip(
        _make(MultipleChoiceAnswerWithFeedbackFormat.type, [
          TextChoice(text: 'A', value: 'a'),
        ]),
      );
      expect(back.result, isA<List<TextChoice>>());
      expect((back.result as List<TextChoice>).single.value, 'a');
    });

    test('multiple_auto_complete', () {
      final back = _roundTrip(
        _make(MultipleChoiceAutoCompleteAnswerFormat.type, [
          TextChoice(text: 'A', value: 'a'),
        ]),
      );
      expect(back.result, isA<List<TextChoice>>());
      expect((back.result as List<TextChoice>).single.value, 'a');
    });

    test('multiple_double', () {
      final back = _roundTrip(
        _make(MultipleDoubleAnswerFormat.type, const [
          MultiDouble(text: 'weight', value: 72.5),
        ]),
      );
      expect(back.result, isA<List<MultiDouble>>());
      expect((back.result as List<MultiDouble>).single.value, 72.5);
    });

    test('a null result round-trips with no conversion', () {
      final back = _roundTrip(_make<String?>(TextAnswerFormat.type, null));
      expect(back.result, isNull);
    });
  });

  group('serialized shape', () {
    test('toJson emits answerType and no step key', () {
      final json = _make(TextAnswerFormat.type, 'x').toJson();
      expect(json.containsKey('step'), isFalse);
      expect(json['answerType'], TextAnswerFormat.type);
    });

    test('a SurveyResult of several results round-trips each one typed', () {
      final result = SurveyResult(
        id: 's1',
        startTime: DateTime(2026, 1, 1, 9),
        endTime: DateTime(2026, 1, 1, 9, 5),
        finishReason: FinishReason.completed,
        results: [
          _make(TextAnswerFormat.type, 'free text'),
          _make(IntegerAnswerFormat.type, 42),
          _make(BooleanAnswerFormat.type, BooleanResult.negative),
        ],
      );

      final back = SurveyResult.fromJson(
        jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>,
      );

      // Per-result assertions: SurveyResult.== ignores `results` entirely.
      expect(back.results, hasLength(3));
      expect(back.results[0].result, 'free text');
      expect(back.results[1].result, isA<int>());
      expect(back.results[2].result, isA<BooleanResult>());
      expect(back.results[2].result, BooleanResult.negative);
    });
  });

  group('an unconvertible record throws so the caller can discard it', () {
    Map<String, dynamic> base() => <String, dynamic>{
      'id': 'q1',
      'result': 'anything',
      'startTime': '2026-01-01T09:00:00.000Z',
      'endTime': '2026-01-01T09:01:00.000Z',
    };

    test('a pre-2b record — carries step, carries no answerType', () {
      final json = base()
        ..['step'] = <String, dynamic>{'id': 'q1', 'content': <dynamic>[]};
      expect(
        () => StepResult<dynamic>.fromJson(json),
        throwsA(
          isA<ResultCodecException>().having(
            (e) => e.answerType,
            'answerType',
            isNull,
          ),
        ),
      );
    });

    test('an unknown answerType', () {
      final json = base()..['answerType'] = 'no-such-format';
      expect(
        () => StepResult<dynamic>.fromJson(json),
        throwsA(
          isA<ResultCodecException>().having(
            (e) => e.answerType,
            'answerType',
            'no-such-format',
          ),
        ),
      );
    });

    test('malformed JSON for a known answerType', () {
      final json = base()
        ..['answerType'] = TimeAnswerFormat.type
        ..['result'] = 'not-a-map';
      expect(
        () => StepResult<dynamic>.fromJson(json),
        throwsA(isA<ResultCodecException>()),
      );
    });

    test('SurveyResult propagates, and a bare catch can discard it', () {
      final json = <String, dynamic>{
        'id': 's1',
        'startTime': '2026-01-01T09:00:00.000Z',
        'endTime': '2026-01-01T09:05:00.000Z',
        'finishReason': 'completed',
        'results': <dynamic>[base()..['answerType'] = 'no-such-format'],
      };
      expect(
        () => SurveyResult.fromJson(json),
        throwsA(isA<ResultCodecException>()),
      );
      // It implements Exception, so the consumer's `catch (_)` catches it.
      expect(
        const ResultCodecException(stepId: 's', answerType: null, cause: 'c'),
        isA<Exception>(),
      );
    });
  });
}
