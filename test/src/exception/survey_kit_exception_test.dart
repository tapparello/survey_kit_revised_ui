import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

/// Exhaustive over [SurveyKitException] with no `default`.
///
/// This is a COMPILE-TIME guard, and it is meant to churn: adding a subtype in
/// Phase 2b or 2c breaks this function with `non_exhaustive_switch_expression`
/// until the new case is added. That is the tripwire working, not a regression.
String describe(SurveyKitException e) => switch (e) {
  MissingAnswerFormatException() => 'missing',
  AnswerFormatMismatchException() => 'mismatch',
  SurveyKitScopeException() => 'scope',
  MalformedValueException() => 'malformed',
  UnsupportedTaskException() => 'unsupported',
  UnknownTypeException() => 'unknown',
  ResultCodecException() => 'resultCodec',
  UnregisteredActionException() => 'unregisteredAction',
  UnregisteredRendererException() => 'unregisteredRenderer',
  UnserializableRuleException() => 'unserializableRule',
};

void main() {
  group('SurveyKitException', () {
    test('toString names the concrete type and carries the message', () {
      const e = MissingAnswerFormatException(
        stepId: 'step-1',
        expected: 'BooleanAnswerFormat',
      );
      expect(e.toString(), startsWith('MissingAnswerFormatException:'));
      expect(e.toString(), contains('step-1'));
      expect(e.toString(), contains('BooleanAnswerFormat'));
    });

    test('every subtype is an Exception and a SurveyKitException', () {
      const subtypes = <SurveyKitException>[
        MissingAnswerFormatException(stepId: 's', expected: 'E'),
        AnswerFormatMismatchException(stepId: 's', expected: 'E', actual: 'A'),
        SurveyKitScopeException(widgetType: 'W', hint: 'H'),
        MalformedValueException(field: 'f', value: null),
        UnsupportedTaskException(taskType: 'T'),
        UnknownTypeException(kind: 'K'),
        ResultCodecException(stepId: 's', answerType: 'text', cause: 'c'),
        UnregisteredActionException(actionId: 'a'),
        UnregisteredRendererException(kind: 'Content', discriminator: 'pdf'),
        UnserializableRuleException(ruleType: 'ConditionalNavigationRule'),
      ];
      for (final e in subtypes) {
        expect(e, isA<Exception>());
        expect(e, isA<SurveyKitException>());
        expect(e.message, isNotEmpty);
        expect(describe(e), isNotEmpty);
      }
    });

    test('mismatch carries expected and actual separately', () {
      const e = AnswerFormatMismatchException(
        stepId: 'step-2',
        expected: 'TextAnswerFormat',
        actual: 'BooleanAnswerFormat',
      );
      expect(e.stepId, 'step-2');
      expect(e.expected, 'TextAnswerFormat');
      expect(e.actual, 'BooleanAnswerFormat');
      expect(e.message, contains('TextAnswerFormat'));
      expect(e.message, contains('BooleanAnswerFormat'));
    });

    test('MalformedValueException accepts a null value', () {
      const e = MalformedValueException(field: 'timeOfDay', value: null);
      expect(e.value, isNull);
      expect(e.message, contains('timeOfDay'));
    });

    test('ResultCodecException names the step and the discriminator', () {
      const e = ResultCodecException(
        stepId: 'q1',
        answerType: 'time',
        cause: 'boom',
      );
      expect(e.stepId, 'q1');
      expect(e.answerType, 'time');
      expect(e.message, contains('q1'));
      expect(e.message, contains('time'));
      expect(e.message, contains('boom'));
    });

    test('ResultCodecException tolerates a missing discriminator', () {
      const e = ResultCodecException(
        stepId: 'q1',
        answerType: null,
        cause: 'no answerType',
      );
      expect(e.answerType, isNull);
      expect(e.message, contains('q1'));
      expect(e.message, contains('no answerType'));
    });

    test('UnknownTypeException distinguishes absent from unrecognized', () {
      const absent = UnknownTypeException(kind: 'AnswerFormat');
      const wrong = UnknownTypeException(
        kind: 'AnswerFormat',
        discriminator: 'nope',
      );
      expect(absent.discriminator, isNull);
      expect(wrong.discriminator, 'nope');
      expect(wrong.message, contains('nope'));
      expect(absent.message, isNot(contains('nope')));
    });

    test('UnserializableRuleException names the rule class and the cause', () {
      const e = UnserializableRuleException(
        ruleType: 'ConditionalNavigationRule',
      );
      expect(e.ruleType, 'ConditionalNavigationRule');
      expect(e.message, contains('ConditionalNavigationRule'));
      // The message has to say WHY, not just what: a consumer hitting this
      // needs to know the fix is to author the rule as JSON.
      expect(e.message, contains('closure'));
      expect(e.message, contains('JSON'));
    });
  });
}
