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
  TaskNotDefinedException() => 'task',
  RuleNotDefinedException() => 'rule',
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
        TaskNotDefinedException(),
        RuleNotDefinedException(),
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
  });

  group('reparented legacy types', () {
    test('stay const-constructible with zero arguments and canonicalize', () {
      const a = TaskNotDefinedException();
      const b = TaskNotDefinedException();
      expect(identical(a, b), isTrue);

      const c = RuleNotDefinedException();
      const d = RuleNotDefinedException();
      expect(identical(c, d), isTrue);
    });

    test('carry the discriminator when one is supplied', () {
      const e = TaskNotDefinedException(discriminator: 'nonsense');
      expect(e.discriminator, 'nonsense');
      expect(e.message, contains('nonsense'));
    });

    test('say nothing about subclassing or nextStepIdentifier', () {
      const rule = RuleNotDefinedException();
      expect(rule.message, isNot(contains('nextStepIdentifier')));
      expect(rule.message, isNot(contains('subclass')));
    });
  });

  group('legacy throw sites still fire', () {
    test('Task.fromJson throws TaskNotDefinedException with the type', () {
      expect(
        () => Task.fromJson(const <String, dynamic>{'type': 'nonsense'}),
        throwsA(
          isA<TaskNotDefinedException>().having(
            (e) => e.discriminator,
            'discriminator',
            'nonsense',
          ),
        ),
      );
    });

    test('NavigationRule.fromJson throws RuleNotDefinedException', () {
      expect(
        () => NavigationRule.fromJson(const <String, dynamic>{
          'type': 'nonsense',
        }),
        throwsA(
          isA<RuleNotDefinedException>().having(
            (e) => e.discriminator,
            'discriminator',
            'nonsense',
          ),
        ),
      );
    });
  });
}
