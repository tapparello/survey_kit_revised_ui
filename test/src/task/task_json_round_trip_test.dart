// ADO #1052 / #1007: Task.toJson() -> Task.fromJson() had never worked for
// either task type. This file covers the six base wire fields for both, at
// deliberately non-default values so a dropped field fails rather than
// coincidentally matching a default.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

List<Step> twoSteps() => <Step>[
  Step(id: 's1', content: const []),
  Step(id: 's2', content: const []),
];

/// Non-default on purpose, and each one guards a different mistake:
///   * `initialStepId: 's2'` is NOT the first step, so a writer that emits
///     "the first step" rather than the resolved one still fails.
///   * `stepCount: 99` differs from `steps.length` (2), so a writer that
///     recomputes it instead of carrying the authored override fails. That
///     override is real data: `task_navigator.dart:69` reads
///     `task.stepCount ?? task.steps.length` as the progress denominator.
///   * `variables` is non-empty, so a writer emitting `{}` fails.
const expectedVariables = <String, dynamic>{'child': 'Lilia', 'attempts': 3};

/// Round-trips through actual JSON **text**, not just Dart maps.
///
/// `jsonEncode` is the half that catches a writer emitting a live Dart object —
/// the pre-fix `NavigableTask.toJson` emitted `NavigationRule` instances and
/// threw right here. `jsonDecode` is the half that reproduces production
/// reification: a nested map comes back as `_Map<String, dynamic>` and never as
/// anything more specific, which a Dart map literal would not reproduce.
Task roundTrip(Task task) => Task.fromJson(
  jsonDecode(jsonEncode(task.toJson())) as Map<String, dynamic>,
);

void main() {
  group('every base wire field survives Task.toJson -> Task.fromJson', () {
    test('OrderedTask', () {
      final task = OrderedTask(
        id: 'ordered-1',
        steps: twoSteps(),
        initialStepId: 's2',
        variables: expectedVariables,
        stepCount: 99,
      );

      // The DISPATCHER, not OrderedTask.fromJson. Routing through
      // Task.fromJson is what proves the `type` discriminator is emitted, and
      // that is the whole of #1007.
      final back = roundTrip(task);

      expect(back, isA<OrderedTask>());
      expect(back.id, 'ordered-1');
      expect(back.steps.map((s) => s.id), <String>['s1', 's2']);
      expect(back.initialStep?.id, 's2');
      expect(back.variables, expectedVariables);
      expect(back.stepCount, 99);
    });

    // `variables` and `stepCount` already round-tripped for OrderedTask before
    // this change — the generated writer emitted both and ordered_task.dart:46
    // reads both. For NavigableTask they were dropped outright, so this case is
    // where those two assertions are load-bearing. Both types are asserted
    // anyway: the point of the shared helper is that neither can drift again.
    test('NavigableTask', () {
      final task = NavigableTask(
        id: 'navigable-1',
        steps: twoSteps(),
        initialStepId: 's2',
        variables: expectedVariables,
        stepCount: 99,
      );

      final back = roundTrip(task);

      expect(back, isA<NavigableTask>());
      expect(back.id, 'navigable-1');
      expect(back.steps.map((s) => s.id), <String>['s1', 's2']);
      expect(back.initialStep?.id, 's2');
      expect(back.variables, expectedVariables);
      expect(back.stepCount, 99);
    });
  });

  group('the wire format drops what was never data', () {
    test('OrderedTask no longer emits initialStep or hashCode', () {
      final json = OrderedTask(
        id: 't',
        steps: twoSteps(),
        initialStepId: 's1',
      ).toJson();

      expect(json['type'], 'ordered');
      // `initialStep` was a whole nested Step under a key fromJson never read.
      // `hashCode` is not data and is not stable across instances — it is also
      // why the existing round-trip test could only compare `steps`.
      expect(json.containsKey('initialStep'), isFalse);
      expect(json.containsKey('hashCode'), isFalse);
      expect(json['initialStepId'], 's1');
    });

    test('both task types emit the same base keys', () {
      final ordered = OrderedTask(id: 't', steps: twoSteps()).toJson();
      final navigable = NavigableTask(id: 't', steps: twoSteps()).toJson();
      const baseKeys = <String>{
        'type',
        'id',
        'steps',
        'initialStepId',
        'variables',
        'stepCount',
      };

      expect(ordered.keys.toSet(), baseKeys);
      // Exactly one addition, and it is `rules`. This is the assertion that
      // fails if a field is ever added to one writer and not the other — the
      // ADO #1001 drift that caused this bug in the first place, when
      // `variables` and `stepCount` reached the generated OrderedTask writer
      // and the hand-written NavigableTask one never tracked it.
      expect(navigable.keys.toSet(), <String>{...baseKeys, 'rules'});
    });

    test('an absent initialStepId and stepCount stay absent', () {
      // Every other fixture in this file SETS both fields, so none of them can
      // distinguish a writer that resolves the fallbacks into the wire format:
      //
      //   'initialStepId': initialStep?.id ?? steps.firstOrNull?.id,
      //   'stepCount': stepCount ?? steps.length,
      //
      // That writer passes every other assertion here and is wrong twice over.
      // `stepCount` is an authored OVERRIDE and task_navigator.dart:69 applies
      // `?? steps.length` at READ time, so freezing a value into the wire pins
      // a denominator that should track the list. And a null `initialStep` is a
      // real state, distinct from "starts at the first step" — the engine
      // treats them differently. Both fixtures below have two steps, so either
      // fallback would produce a non-null value and fail.
      final ordered = OrderedTask(id: 't', steps: twoSteps()).toJson();
      final navigable = NavigableTask(id: 't', steps: twoSteps()).toJson();

      for (final json in <Map<String, dynamic>>[ordered, navigable]) {
        expect(json['initialStepId'], isNull);
        expect(json['stepCount'], isNull);
      }

      // And null survives the trip as null, rather than being backfilled on the
      // way back in.
      final back = roundTrip(NavigableTask(id: 't', steps: twoSteps()));
      expect(back.initialStep, isNull);
      expect(back.stepCount, isNull);
    });
  });

  group('NavigableTask emits rules as a list with the trigger re-attached', () {
    // Only `action` and `custom` here: those are the two rule types whose
    // toJson already emits a `type` discriminator. `direct` and `conditional`
    // are covered in navigation_rule_round_trip_test.dart once their writers
    // are fixed.
    test('shape and identity', () {
      final task = NavigableTask(
        id: 't',
        steps: twoSteps(),
        // `const` on the whole literal, not on each value: `Task` is
        // `@immutable`, so `prefer_const_literals_to_create_immutables` fires
        // on a const-eligible literal passed to its constructor, and the
        // per-value `const` keywords would then trip `unnecessary_const`. Both
        // lints are enabled and `--fatal-infos` makes them fatal.
        navigationRules: const <String, NavigationRule>{
          's1': ActionNavigationRule(actionId: 'a1', nextStepIdentifier: 's2'),
          's2': CustomNavigationRule(ruleId: 'r1'),
        },
      );

      final json = task.toJson();
      // A List, not a Map: NavigableTask.fromJson:55 does `json['rules'] as
      // List`. The pre-fix writer emitted a Map of live objects under
      // `navigationRules`, a key no reader has ever looked at.
      expect(json['rules'], isA<List<dynamic>>());
      expect(json.containsKey('navigationRules'), isFalse);

      final rules = (json['rules'] as List).cast<Map<String, dynamic>>();
      expect(rules, hasLength(2));
      for (final rule in rules) {
        // No rule CLASS has a triggerStepIdentifier field — that information
        // lives only in the navigationRules map key — so the writer has to
        // re-attach it, in the nested shape fromJson reads.
        expect(rule['triggerStepIdentifier'], isA<Map<String, dynamic>>());
      }

      final back = roundTrip(task) as NavigableTask;
      expect(back.navigationRules.keys.toSet(), <String>{'s1', 's2'});
      final first = back.getRuleByStepIdentifier('s1');
      final second = back.getRuleByStepIdentifier('s2');
      expect(first, isA<ActionNavigationRule>());
      expect(second, isA<CustomNavigationRule>());
      expect((first! as ActionNavigationRule).actionId, 'a1');
      expect((first as ActionNavigationRule).nextStepIdentifier, 's2');
      expect((second! as CustomNavigationRule).ruleId, 'r1');
    });
  });

  test('toJson copies variables rather than aliasing them', () {
    // `const` because Task is @immutable and the lint requires it. The mutation
    // below runs on `json['variables']`, which is baseJson's fresh copy, so a
    // const source map is fine. If the copy is ever removed this test still
    // fails — just with an UnsupportedError from mutating a const map instead
    // of a clean expect failure. Either way the writer cannot regress silently.
    final task = OrderedTask(
      id: 't',
      steps: twoSteps(),
      variables: const <String, dynamic>{'a': 1},
    );

    final json = task.toJson();
    (json['variables'] as Map<String, dynamic>)['a'] = 999;

    // toJson must not hand a caller a live handle to the task's own state.
    expect(task.variables['a'], 1);
  });

  group('a rules-bearing NavigableTask round-trips exactly', () {
    // One rule of every serializable type, each on its own trigger. The
    // conditional one is PARSED, not closure-built: a closure-built rule throws
    // from toJson by design, which navigation_rule_round_trip_test.dart covers.
    NavigableTask fixture() => NavigableTask(
      id: 'rules-1',
      steps: <Step>[
        Step(id: 's1', content: const []),
        Step(id: 's2', content: const []),
        Step(id: 's3', content: const []),
        Step(id: 's4', content: const []),
      ],
      // 's3', not 's1': an initialStepId equal to the first step's id would
      // also match a writer that wrongly emits "the first step" instead of the
      // resolved one.
      initialStepId: 's3',
      // `const` — Task is @immutable and the lint requires it.
      variables: const <String, dynamic>{'child': 'Lilia'},
      stepCount: 9,
      // Insertion order is deliberately NOT sorted order. With 's1'..'s4'
      // inserted in sequence the two coincide, and a writer that sorted by key
      // — say `SplayTreeMap.from(navigationRules)` — would emit byte-identical
      // output and pass the strict comparison below. Shuffled, it cannot.
      // (This literal is not const-eligible: DirectNavigationRule's
      // constructor is not const and the conditional rule is parsed.)
      navigationRules: <String, NavigationRule>{
        's3': const CustomNavigationRule(ruleId: 'r1'),
        's1': DirectNavigationRule('s2'),
        's4': ConditionalNavigationRule.fromJson(
          jsonDecode('{"type":"conditional","values":{"yes":"s2"}}')
              as Map<String, dynamic>,
        ),
        's2': const ActionNavigationRule(
          actionId: 'a1',
          nextStepIdentifier: 's3',
        ),
      },
    );

    test('every rule lands back under its own trigger', () {
      final back = roundTrip(fixture()) as NavigableTask;

      expect(back.navigationRules.keys.toSet(), <String>{
        's1',
        's2',
        's3',
        's4',
      });

      final s1 = back.getRuleByStepIdentifier('s1');
      final s2 = back.getRuleByStepIdentifier('s2');
      final s3 = back.getRuleByStepIdentifier('s3');
      final s4 = back.getRuleByStepIdentifier('s4');

      expect(s1, isA<DirectNavigationRule>());
      expect(s2, isA<ActionNavigationRule>());
      expect(s3, isA<CustomNavigationRule>());
      expect(s4, isA<ConditionalNavigationRule>());

      // Types alone would survive a writer that shuffled the triggers, so pin
      // one payload per rule as well.
      expect((s1! as DirectNavigationRule).destinationStepIdentifier, 's2');
      expect((s2! as ActionNavigationRule).actionId, 'a1');
      expect((s3! as CustomNavigationRule).ruleId, 'r1');
      expect((s4! as ConditionalNavigationRule).values, <String, String>{
        'yes': 's2',
      });
    });

    test('the whole map is stable across a second trip', () {
      // The strict comparison on a fixture that actually HAS rules.
      // conditional_task_round_trip_test.dart's fixtures author only
      // type/id/steps, so its whole-map assertion only ever compares
      // `rules: []` — a rules-list ordering or shape bug would slip past it.
      final task = fixture();
      final firstJson = task.toJson();

      // The emitted order, asserted DIRECTLY rather than only through the
      // self-comparison below. `expect(second, first)` compares one writer
      // against itself, so a writer that sorted by trigger key would be
      // self-consistent and pass it. This pins insertion order instead:
      // navigationRules is insertion-ordered, and fromJson putIfAbsent's the
      // list in sequence (navigable_task.dart:54-64), so the order survives.
      final triggers = (firstJson['rules'] as List)
          .cast<Map<String, dynamic>>()
          .map(
            (rule) =>
                (rule['triggerStepIdentifier'] as Map<String, dynamic>)['id'],
          )
          .toList();
      expect(triggers, <String>['s3', 's1', 's4', 's2']);

      expect(roundTrip(task).toJson(), firstJson);
    });
  });

  test('a step with populated content and a concrete answerFormat', () {
    // Every other fixture here and in conditional_task_round_trip_test.dart
    // uses `content: []`, so Step.toJson's nested-content path is unproven at
    // TASK level. This is ADO #1007's stated coverage concern. Its cited
    // fixture — test/src/result/question/mock.dart, `sampleStep` — no longer
    // exists: Phase 2b removed it when StepResult stopped embedding Step, so
    // the gap is closed here instead.
    final authored = <String, dynamic>{
      'type': 'ordered',
      'id': 'content-1',
      'initialStepId': 's1',
      'steps': <dynamic>[
        <String, dynamic>{
          'id': 's1',
          'isMandatory': true,
          'answerFormat': <String, dynamic>{'type': 'text'},
          // `id` spelled out: Content.id would otherwise be a fresh Uuid, and
          // while a round trip preserves it, an explicit value keeps a failure
          // here readable.
          'content': <dynamic>[
            <String, dynamic>{
              'type': 'text',
              'id': 'c1',
              'text': 'How are you?',
            },
          ],
        },
      ],
    };

    final task = Task.fromJson(authored);
    final firstJson = task.toJson();
    final back = roundTrip(task);

    expect(back.steps.single.content, hasLength(1));
    expect(back.steps.single.content.single, isA<TextContent>());
    expect(
      (back.steps.single.content.single as TextContent).text,
      'How are you?',
    );
    expect(back.steps.single.answerFormat, isA<TextAnswerFormat>());
    // Compared against the task's own first output, never the authored literal
    // above: toJson always spells out defaults (TextContent's fontSize and
    // textAlign, TextAnswerFormat's hint and validationRegEx) that the literal
    // omits, so a literal comparison would fail on noise.
    expect(back.toJson(), firstJson);
  });
}
