// ADO #1052: NavigationRule.fromJson(rule.toJson()) is the rule-layer half of
// the Task round trip. `action` and `custom` worked; `direct` never emitted its
// `type` discriminator and threw on the way back.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

/// Through JSON text, matching how a rule actually reaches `fromJson` in
/// production — a parsed task, never a Dart map handed across in memory.
NavigationRule roundTrip(NavigationRule rule) => NavigationRule.fromJson(
  jsonDecode(jsonEncode(rule.toJson())) as Map<String, dynamic>,
);

void main() {
  group('every serializable rule type survives its own toJson', () {
    test('direct', () {
      final rule = DirectNavigationRule('s2');

      // The discriminator is what NavigationRule.fromJson dispatches on, so
      // asserting it directly says WHY the round trip below works.
      expect(rule.toJson()['type'], 'direct');

      final back = roundTrip(rule);
      expect(back, isA<DirectNavigationRule>());
      expect((back as DirectNavigationRule).destinationStepIdentifier, 's2');
    });

    test('action', () {
      const rule = ActionNavigationRule(
        actionId: 'a1',
        nextStepIdentifier: 's3',
      );
      expect(rule.toJson()['type'], 'action');

      final back = roundTrip(rule);
      expect(back, isA<ActionNavigationRule>());
      expect((back as ActionNavigationRule).actionId, 'a1');
      // Its reader accepts `nextStep` OR `nextStepIdentifier`; the writer emits
      // the former. Asserting the value proves the two agree on which.
      expect(back.nextStepIdentifier, 's3');
    });

    test('action with no next step', () {
      // nextStepIdentifier is nullable and the writer emits it unconditionally,
      // so a null has to survive as a null rather than becoming absent-and-then
      // something else.
      const rule = ActionNavigationRule(actionId: 'a1');
      final back = roundTrip(rule);
      expect((back as ActionNavigationRule).nextStepIdentifier, isNull);
    });

    test('custom', () {
      const rule = CustomNavigationRule(ruleId: 'r1');
      expect(rule.toJson()['type'], 'custom');

      final back = roundTrip(rule);
      expect(back, isA<CustomNavigationRule>());
      expect((back as CustomNavigationRule).ruleId, 'r1');
    });

    test('conditional, parsed from JSON', () {
      // Through jsonDecode, NOT a Dart map literal. A literal nested in a
      // Map<String, dynamic> reifies its inner map as _Map<String, String>,
      // so an `as Map<String, String>` cast inside fromJson would SUCCEED here
      // and throw in production. Decoding real JSON text is what reproduces
      // production reification (_Map<String, dynamic>).
      final authored =
          jsonDecode('{"type":"conditional","values":{"yes":"s2","no":"s3"}}')
              as Map<String, dynamic>;
      final rule = ConditionalNavigationRule.fromJson(authored);

      expect(rule.toJson()['type'], 'conditional');
      expect(rule.toJson()['values'], <String, String>{
        'yes': 's2',
        'no': 's3',
      });

      final back = roundTrip(rule) as ConditionalNavigationRule;
      expect(back.values, <String, String>{'yes': 's2', 'no': 's3'});
    });
  });

  test('DirectNavigationRule still reads the nested destination form', () {
    // The hand-written factory tolerates both a bare string and a nested
    // {'id': ...} object, which authored assets use and the deleted generated
    // reader could not handle. Deleting the .g.dart must not lose that.
    final nested = DirectNavigationRule.fromJson(<String, dynamic>{
      'type': 'direct',
      'destinationStepIdentifier': <String, dynamic>{'id': 's9'},
    });
    expect(nested.destinationStepIdentifier, 's9');

    final bare = DirectNavigationRule.fromJson(<String, dynamic>{
      'type': 'direct',
      'destinationStepIdentifier': 's9',
    });
    expect(bare.destinationStepIdentifier, 's9');
  });

  group('a conditional rule carries its authored mapping, or admits it cannot', () {
    test('the parsed closure still navigates by the stored map', () {
      // Behaviour parity, not just data retention: the closure now reads the
      // stored map instead of closing over a separate local, so the two cannot
      // diverge. Today's loop over entries returning the matching value IS a
      // map lookup, so the result must be identical.
      final rule = ConditionalNavigationRule.fromJson(
        jsonDecode('{"type":"conditional","values":{"yes":"s2"}}')
            as Map<String, dynamic>,
      );

      // StepResult is generic and its date fields are startTime/endTime.
      // _extractValue falls back to `result?.toString()`, so a plain String
      // result is all this needs — no answerType, no TextChoice.
      final match = StepResult<String>(
        id: 's1',
        result: 'yes',
        startTime: DateTime(2026),
        endTime: DateTime(2026),
      );
      final miss = StepResult<String>(
        id: 's1',
        result: 'maybe',
        startTime: DateTime(2026),
        endTime: DateTime(2026),
      );

      expect(rule.resultToStepIdentifierMapper(const [], match), 's2');
      expect(rule.resultToStepIdentifierMapper(const [], miss), isNull);
      // A probe passes null as the second argument and must be safe.
      expect(rule.resultToStepIdentifierMapper(const [], null), isNull);
    });

    test('a closure-built rule throws rather than emitting an empty map', () {
      // `(_, __)` matches the style of the six existing closure uses, e.g.
      // terminal_done_button_test.dart:29. Do not modernise them.
      final rule = ConditionalNavigationRule(
        resultToStepIdentifierMapper: (_, __) => 'end_task',
      );

      expect(rule.values, isNull);
      // The old toJson returned {'values': {}} — not lossy but actively wrong,
      // asserting there was no mapping. A rule that navigated correctly
      // round-tripped into one that navigates nowhere.
      // A tearoff, not `() => rule.toJson()`: `unnecessary_lambdas` is enabled
      // and `--fatal-infos` makes it fatal.
      expect(
        rule.toJson,
        throwsA(
          isA<UnserializableRuleException>().having(
            (e) => e.ruleType,
            'ruleType',
            'ConditionalNavigationRule',
          ),
        ),
      );
    });

    test('a task containing a closure-built rule throws from toJson', () {
      // The throw has to propagate: a caller serializing a whole task must not
      // get a task JSON with one silently-empty rule in it.
      final task = NavigableTask(
        id: 't',
        steps: <Step>[Step(id: 's1', content: const [])],
        navigationRules: <String, NavigationRule>{
          's1': ConditionalNavigationRule(
            resultToStepIdentifierMapper: (_, __) => 'end_task',
          ),
        },
      );

      expect(task.toJson, throwsA(isA<UnserializableRuleException>()));
    });
  });
}
