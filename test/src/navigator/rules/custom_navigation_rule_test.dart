import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/navigator/rules/custom_navigation_rule.dart';

void main() {
  group('CustomNavigationRule', () {
    test('stores ruleId', () {
      const rule = CustomNavigationRule(ruleId: 'my_rule');
      expect(rule.ruleId, 'my_rule');
    });

    test('deserializes from JSON', () {
      final rule = CustomNavigationRule.fromJson({
        'type': 'custom',
        'ruleId': 'my_rule',
      });
      expect(rule.ruleId, 'my_rule');
    });

    test('serializes to JSON', () {
      const rule = CustomNavigationRule(ruleId: 'my_rule');
      final json = rule.toJson();
      expect(json['type'], 'custom');
      expect(json['ruleId'], 'my_rule');
    });
  });
}
