import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

// ignore: must_be_immutable
class _UnsupportedTask extends Task {
  _UnsupportedTask() : super(id: 'unsupported-task');

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};
}

void main() {
  group('AnswerFormat.fromJson', () {
    test('throws UnknownTypeException for an unrecognized type', () {
      expect(
        () => AnswerFormat.fromJson(const <String, dynamic>{'type': 'no-such'}),
        throwsA(
          isA<UnknownTypeException>()
              .having((e) => e.discriminator, 'discriminator', 'no-such')
              .having((e) => e.kind, 'kind', 'AnswerFormat'),
        ),
      );
    });

    test('throws UnknownTypeException when type is absent', () {
      // Previously an AssertionError in debug and an untyped Exception in
      // release. Now the same typed exception in both modes.
      expect(
        () => AnswerFormat.fromJson(const <String, dynamic>{}),
        throwsA(
          isA<UnknownTypeException>().having(
            (e) => e.discriminator,
            'discriminator',
            isNull,
          ),
        ),
      );
    });
  });

  group('TimeResult.fromJson', () {
    test('throws MalformedValueException for a null timeOfDay', () {
      expect(
        () => TimeResult.fromJson(const <String, dynamic>{'timeOfDay': null}),
        throwsA(
          isA<MalformedValueException>()
              .having((e) => e.field, 'field', 'timeOfDay')
              .having((e) => e.value, 'value', isNull),
        ),
      );
    });

    test('throws MalformedValueException for an unparseable timeOfDay', () {
      expect(
        () =>
            TimeResult.fromJson(const <String, dynamic>{'timeOfDay': 'ab:cd'}),
        throwsA(
          isA<MalformedValueException>()
              .having((e) => e.field, 'field', 'timeOfDay')
              .having((e) => e.value, 'value', 'ab:cd'),
        ),
      );
    });
  });

  group('SurveyKit', () {
    testWidgets('throws UnsupportedTaskException for an unknown Task subtype', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SurveyKit(task: _UnsupportedTask(), onResult: (_) {}),
        ),
      );

      expect(
        tester.takeException(),
        isA<UnsupportedTaskException>().having(
          (e) => e.taskType,
          'taskType',
          '_UnsupportedTask',
        ),
      );
    });
  });
}
