// Coverage gap: json_round_trip_test.dart iterates AnswerFormatType, and
// ConditionalAnswerFormat is deliberately not a member of that enum (it is not
// an AnswerFormat — see conditional_answer_format.dart), so a conditional step
// is structurally excluded from that file's round trip. A Step-level re-emit
// test exists at conditional_answer_format_test.dart:118, but nothing
// round-trips a whole TASK containing one. This file closes that gap for both
// concrete Task types.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

/// A step JSON literal carrying a conditional directive with two variants.
/// Kept separate from `plainStepJson` so a reader can see at a glance which
/// step in a fixture is the one under test.
///
/// `isMandatory` is spelled out explicitly (rather than left to
/// `Step.fromJson`'s `?? true` default), because `Step.toJson` ALWAYS emits it
/// — generated with no `includeIfNull`/omit-on-default behaviour, unlike
/// `buttonText`. Leaving it out of this fixture would make every "byte
/// identical to authored" comparison below fail on a key that has nothing to
/// do with conditional formats.
Map<String, dynamic> conditionalStepJson(String id) => <String, dynamic>{
  'id': id,
  'isMandatory': true,
  'content': <dynamic>[],
  'answerFormat': <String, dynamic>{
    'type': 'conditional',
    'variable': 'child',
    'default': 'Caroline',
    'variants': <String, dynamic>{
      'Caroline': <String, dynamic>{'type': 'text'},
      'Lilia': <String, dynamic>{'type': 'integer'},
    },
  },
};

Map<String, dynamic> plainStepJson(String id) => <String, dynamic>{
  'id': id,
  'isMandatory': true,
  'content': <dynamic>[],
  'answerFormat': <String, dynamic>{'type': 'text'},
};

/// Asserts the directive survived parsing intact, on whatever step is handed
/// in — shared by every test below so the same checks aren't retyped four
/// times.
void expectDirectiveIntact(Step step) {
  expect(step.answerFormat, isNull);
  final directive = step.conditionalAnswerFormat;
  expect(directive, isNotNull);
  expect(directive!.variable, 'child');
  expect(directive.defaultKey, 'Caroline');
  expect(directive.variants.keys, <String>{'Caroline', 'Lilia'});
  expect(directive.variants['Lilia'], isA<IntegerAnswerFormat>());
  expect(directive.variants['Caroline'], isA<TextAnswerFormat>());
}

void main() {
  group('a conditional-format step inside `steps` survives a whole-task '
      'JSON round trip', () {
    // Both task types go through the public Task.fromJson dispatcher here —
    // the discriminator-driven path a real consumer uses — rather than
    // calling NavigableTask.fromJson/OrderedTask.fromJson directly.
    //
    // "Byte identical to authored" is checked against the task's OWN first
    // toJson() output, not against the hand-written literal below — matching
    // json_round_trip_test.dart's own pattern (`back.toJson()` compared to
    // `content.toJson()`, never to a literal). A hand-written literal leaves
    // out fields that have a default (e.g. TextAnswerFormat's `hint`,
    // `validationRegEx`; Step's `isMandatory`), and `toJson()` always spells
    // defaults out — so comparing against a literal would fail on noise that
    // has nothing to do with whether the CONDITIONAL DIRECTIVE round-trips,
    // which is what this test exists to guard.
    for (final type in <String>['ordered', 'navigable']) {
      test(type, () {
        final authored = <String, dynamic>{
          'type': type,
          'id': 'whole-task-$type',
          'steps': <dynamic>[conditionalStepJson('s1'), plainStepJson('s2')],
        };

        final task = Task.fromJson(authored);
        expectDirectiveIntact(task.steps.first);

        final firstJson = task.toJson();
        // Round-trip through actual JSON text, not just Dart maps, then
        // through the CONCRETE type's fromJson — Task.fromJson's dispatcher
        // needs a `type` key that neither toJson() emits (a pre-existing gap,
        // unrelated to conditional formats, noted in the coverage-gap
        // report), so this is the honest way back in.
        final decoded =
            jsonDecode(jsonEncode(firstJson)) as Map<String, dynamic>;
        final back = type == 'ordered'
            ? OrderedTask.fromJson(decoded)
            : NavigableTask.fromJson(decoded);
        expectDirectiveIntact(back.steps.first);

        final secondJson = back.toJson();
        // The directive intact AND byte-identical across a WHOLE-TASK round
        // trip, at exactly the granularity Gap 2 is about: the `steps` list.
        expect(secondJson['steps'], firstJson['steps']);
      });
    }
  });

  group('a conditional-format step used AS initialStep — the path nothing '
      'currently touches', () {
    test('NavigableTask: the directive is intact immediately after parse', () {
      final authored = <String, dynamic>{
        'type': 'navigable',
        'id': 't',
        'initialStepId': 's1',
        'steps': <dynamic>[conditionalStepJson('s1'), plainStepJson('s2')],
      };

      final task = Task.fromJson(authored) as NavigableTask;
      expect(task.initialStep?.id, 's1');
      expectDirectiveIntact(task.initialStep!);
    });

    test('OrderedTask: the directive is intact immediately after parse', () {
      final authored = <String, dynamic>{
        'type': 'ordered',
        'id': 't',
        'initialStepId': 's1',
        'steps': <dynamic>[conditionalStepJson('s1'), plainStepJson('s2')],
      };

      final task = Task.fromJson(authored) as OrderedTask;
      expect(task.initialStep?.id, 's1');
      expectDirectiveIntact(task.initialStep!);
    });

    // MEASURED, not assumed — same discipline as the back-navigation gap.
    // Both of the following pin a REAL, OBSERVED result, not an expectation
    // written in advance. Both fail the "round trip" half of this group's
    // name for reasons that have nothing to do with conditional formats —
    // see the coverage-gap report for the full explanation and why this is
    // reported as a finding rather than patched here (test-only branch).
    test('NavigableTask: initialStep does NOT survive toJson -> fromJson '
        '(pre-existing, unrelated to conditional formats)', () {
      final task = NavigableTask(
        id: 't',
        steps: [
          Step.fromJson(conditionalStepJson('s1')),
          Step.fromJson(plainStepJson('s2')),
        ],
        initialStepId: 's1',
      );
      expect(task.initialStep?.id, 's1', reason: 'fixture guard');

      // NavigableTask.toJson() (hand-written) emits only id/steps/
      // navigationRules — it has never emitted initialStepId (or
      // variables), for any task, conditional or not.
      final json = task.toJson();
      expect(json.containsKey('initialStepId'), isFalse);

      final back = NavigableTask.fromJson(json);
      expect(
        back.initialStep,
        isNull,
        reason:
            'MEASURED: initialStep information is silently dropped by '
            'NavigableTask.toJson(), so a round trip always loses it — '
            'unrelated to this branch, flagged in the coverage-gap '
            'report',
      );
    });

    test('OrderedTask: initialStep does NOT survive toJson -> fromJson '
        '(pre-existing, unrelated to conditional formats)', () {
      final task = OrderedTask(
        id: 't',
        steps: [
          Step.fromJson(conditionalStepJson('s1')),
          Step.fromJson(plainStepJson('s2')),
        ],
        initialStepId: 's1',
      );
      expect(task.initialStep?.id, 's1', reason: 'fixture guard');

      // The generated toJson() emits the resolved step itself under the
      // key `initialStep` (a full nested object); fromJson reads a
      // DIFFERENT key, `initialStepId` (a bare string). That asymmetry —
      // present since the codegen regeneration of ADO #1001, long before
      // #1045 — means the key fromJson needs is never the key toJson
      // produced.
      final json = task.toJson();
      expect(json.containsKey('initialStep'), isTrue);
      expect(json.containsKey('initialStepId'), isFalse);

      final back = OrderedTask.fromJson(json);
      expect(
        back.initialStep,
        isNull,
        reason:
            'MEASURED: toJson emits `initialStep`, fromJson reads '
            '`initialStepId` — the two never meet, so a round trip '
            'always loses it, independent of conditional formats',
      );
    });
  });
}
