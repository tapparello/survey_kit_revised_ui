import 'package:survey_kit/src/exception/survey_kit_exception.dart';
import 'package:survey_kit/src/navigator/rules/action_navigation_rule.dart';
import 'package:survey_kit/src/navigator/rules/conditional_navigation_rule.dart';
import 'package:survey_kit/src/navigator/rules/custom_navigation_rule.dart';
import 'package:survey_kit/src/navigator/rules/direct_navigation_rule.dart';

abstract class NavigationRule {
  const NavigationRule();

  factory NavigationRule.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'conditional':
        return ConditionalNavigationRule.fromJson(json);
      case 'direct':
        return DirectNavigationRule.fromJson(json);
      case 'custom':
        return CustomNavigationRule.fromJson(json);
      case 'action':
        return ActionNavigationRule.fromJson(json);
    }
    throw UnknownTypeException(
      kind: 'NavigationRule',
      discriminator: type,
      expected: 'conditional, direct, custom or action',
    );
  }
  Map<String, dynamic> toJson();
}
