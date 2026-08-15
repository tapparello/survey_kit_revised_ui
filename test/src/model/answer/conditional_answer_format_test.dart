// The conditional directive's place in the PARSE pipeline. Selection itself is
// tested in conditional_answer_format_parse_test.dart (unit) and
// test/src/engine/engine_conditional_test.dart (end to end).
//
// Before ADO #1045 this file asserted that parsing RESOLVED the directive. It
// no longer can: resolution moved to present time, and AnswerFormat.fromJson
// cannot even return the directive type.
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

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

Map<String, dynamic> stepJson() => <String, dynamic>{
  'id': 's1',
  'content': <dynamic>[],
  'answerFormat': conditional(),
};

void main() {
  test('AnswerFormat.fromJson rejects a bare directive', () {
    // It returns AnswerFormat and structurally cannot return the directive
    // type, so the dispatch lives in Step.fromJson. Reaching this arm means a
    // directive was parsed outside a step.
    expect(
      () => AnswerFormat.fromJson(conditional()),
      throwsA(isA<MalformedValueException>()),
    );
  });

  test('Step.fromJson stores the directive and leaves answerFormat null', () {
    // The invariant that used to hold by timing now holds by type:
    // question_answer.dart stamps step.answerFormat's discriminator onto every
    // result, and StepResult._convert has no 'conditional' branch. A directive
    // is not an AnswerFormat, so it cannot reach either.
    final step = Step.fromJson(stepJson());

    expect(step.answerFormat, isNull);
    expect(step.conditionalAnswerFormat, isNotNull);
    expect(step.conditionalAnswerFormat!.variable, 'child');
  });

  test('a non-conditional answer format still parses concretely', () {
    final step = Step.fromJson(<String, dynamic>{
      'id': 's1',
      'content': <dynamic>[],
      'answerFormat': <String, dynamic>{'type': 'integer'},
    });

    expect(step.answerFormat, isA<IntegerAnswerFormat>());
    expect(step.conditionalAnswerFormat, isNull);
  });

  group('Task.fromJson carries the directive onto its steps', () {
    // Replaces the old 'threads its variables' group, which guarded a link that
    // no longer exists. The equivalent end-to-end guard — that a variant is
    // actually selected — moved to engine_conditional_test.dart.
    test('an OrderedTask', () {
      final task = Task.fromJson(<String, dynamic>{
        'type': 'ordered',
        'id': 'ordered-task',
        'variables': const <String, dynamic>{'child': 'Lilia'},
        'steps': <dynamic>[stepJson()],
      });

      expect(task.steps.single.conditionalAnswerFormat, isNotNull);
      expect(task.steps.single.answerFormat, isNull);
      expect(task.variables, <String, dynamic>{'child': 'Lilia'});
    });

    test('a NavigableTask', () {
      final task = Task.fromJson(<String, dynamic>{
        'type': 'navigable',
        'id': 'navigable-task',
        'variables': const <String, dynamic>{'child': 'Lilia'},
        'steps': <dynamic>[stepJson()],
      });

      expect(task.steps.single.conditionalAnswerFormat, isNotNull);
      expect(task.steps.single.answerFormat, isNull);
      expect(task.variables, <String, dynamic>{'child': 'Lilia'});
    });
  });

  test('a malformed directive still fails loudly at Task.fromJson', () {
    // The end-to-end loudness property. The per-case validation lives in
    // conditional_answer_format_parse_test.dart; this asserts the failure still
    // surfaces when the task LOADS, not mid-survey.
    expect(
      () => Task.fromJson(<String, dynamic>{
        'type': 'ordered',
        'id': 'ordered-task',
        'steps': <dynamic>[
          <String, dynamic>{
            'id': 's1',
            'content': const <dynamic>[],
            'answerFormat': conditional(defaultKey: 'Nobody'),
          },
        ],
      }),
      throwsA(isA<MalformedValueException>()),
    );
  });

  test('Step.toJson re-emits the directive verbatim', () {
    // Generated toJson would emit null here, losing the format. The override
    // patches the one key from the retained source map, so formatId survives —
    // which reconstructing from the parsed fields could not do.
    final json = Step.fromJson(stepJson()).toJson();
    final format = json['answerFormat'] as Map<String, dynamic>;

    expect(format['type'], 'conditional');
    expect(format['formatId'], 'child_function_answer');
    expect(format['variants'], isA<Map<String, dynamic>>());
  });
}
