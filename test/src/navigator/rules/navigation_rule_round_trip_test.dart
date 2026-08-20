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
}
