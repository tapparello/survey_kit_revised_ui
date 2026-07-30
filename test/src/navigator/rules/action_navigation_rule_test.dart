import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/navigator/rules/action_navigation_rule.dart';

void main() {
  group('ActionNavigationRule', () {
    test('stores actionId and nextStep', () {
      const rule = ActionNavigationRule(
        actionId: 'generate_pdf',
        nextStepIdentifier: 'end_task',
      );
      expect(rule.actionId, 'generate_pdf');
      expect(rule.nextStepIdentifier, 'end_task');
    });

    test('deserializes from JSON', () {
      final rule = ActionNavigationRule.fromJson({
        'type': 'action',
        'actionId': 'generate_pdf',
        'nextStep': 'end_task',
      });
      expect(rule.actionId, 'generate_pdf');
      expect(rule.nextStepIdentifier, 'end_task');
    });

    test('serializes to JSON', () {
      const rule = ActionNavigationRule(
        actionId: 'generate_pdf',
        nextStepIdentifier: 'step_2',
      );
      final json = rule.toJson();
      expect(json['type'], 'action');
      expect(json['actionId'], 'generate_pdf');
      expect(json['nextStep'], 'step_2');
    });
  });
}
