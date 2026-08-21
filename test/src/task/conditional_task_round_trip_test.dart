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
        // Round-trip through actual JSON text, and back in through the public
        // Task.fromJson DISPATCHER. The comment this replaces said the
        // dispatcher could not be used because neither toJson emitted `type`;
        // both do now, and using it is the point of ADO #1007.
        final decoded =
            jsonDecode(jsonEncode(firstJson)) as Map<String, dynamic>;
        final back = Task.fromJson(decoded);
        expect(back.runtimeType, task.runtimeType);
        expectDirectiveIntact(back.steps.first);

        final secondJson = back.toJson();
        // The WHOLE map, not just `steps`. The narrowing this replaces existed
        // because OrderedTask's generated writer also emitted `hashCode`, which
        // is not stable across instances. With that gone a full comparison is
        // possible, and it is strictly stronger: it catches any field the wire
        // format gets wrong, not only the steps list.
        expect(secondJson, firstJson);
      });
    }
  });

  group('a conditional-format step used AS initialStep — the path nothing '
      'used to touch', () {
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

    // These two measured the loss on purpose before ADO #1052; the assertions
    // are flipped rather than deleted, so the file still names exactly what
    // used to break.
    test('NavigableTask: initialStep survives toJson -> fromJson', () {
      final task = NavigableTask(
        id: 't',
        steps: [
          Step.fromJson(conditionalStepJson('s1')),
          Step.fromJson(plainStepJson('s2')),
        ],
        initialStepId: 's1',
        // Non-empty on purpose: NavigableTask.toJson dropped `variables`
        // entirely, and a presence-only check (`containsKey`) would be
        // satisfied by a writer emitting a hardcoded `{}`.
        variables: const <String, dynamic>{'child': 'Lilia'},
      );
      expect(task.initialStep?.id, 's1', reason: 'fixture guard');

      // NavigableTask.toJson used to emit only id/steps/navigationRules — it
      // had never emitted initialStepId or variables, for any task.
      final json = task.toJson();
      expect(json['type'], 'navigable');
      expect(json['initialStepId'], 's1');
      expect(json['variables'], <String, dynamic>{'child': 'Lilia'});
      expect(
        json.containsKey('navigationRules'),
        isFalse,
        reason: 'the live-object key no reader ever read is gone',
      );

      final back = NavigableTask.fromJson(json);
      expect(back.initialStep?.id, 's1');
      expect(back.variables, <String, dynamic>{'child': 'Lilia'});
      expectDirectiveIntact(back.initialStep!);
    });

    test('OrderedTask: initialStep survives toJson -> fromJson', () {
      final task = OrderedTask(
        id: 't',
        steps: [
          Step.fromJson(conditionalStepJson('s1')),
          Step.fromJson(plainStepJson('s2')),
        ],
        initialStepId: 's1',
      );
      expect(task.initialStep?.id, 's1', reason: 'fixture guard');

      // The generated writer emitted the resolved step itself under
      // `initialStep` (a full nested object) while fromJson read a DIFFERENT
      // key, `initialStepId` (a bare string). That asymmetry dated from the
      // codegen regeneration of ADO #1001. Both writers now go through
      // Task.baseJson, so the two cannot disagree again.
      final json = task.toJson();
      expect(json['type'], 'ordered');
      expect(json['initialStepId'], 's1');
      expect(json.containsKey('initialStep'), isFalse);
      expect(json.containsKey('hashCode'), isFalse);

      final back = OrderedTask.fromJson(json);
      expect(back.initialStep?.id, 's1');
      expectDirectiveIntact(back.initialStep!);
    });
  });
}
