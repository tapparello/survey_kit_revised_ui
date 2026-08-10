import 'package:survey_kit/src/exception/survey_kit_exception.dart';
import 'package:survey_kit/src/navigator/rules/action_navigation_rule.dart';
import 'package:survey_kit/src/navigator/rules/conditional_navigation_rule.dart';
import 'package:survey_kit/src/navigator/rules/custom_navigation_rule.dart';
import 'package:survey_kit/src/navigator/rules/direct_navigation_rule.dart';

abstract class NavigationRule {
  const NavigationRule();

  factory NavigationRule.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    if (type == 'conditional') {
      return ConditionalNavigationRule.fromJson(json);
    } else if (type == 'direct') {
      return DirectNavigationRule.fromJson(json);
    } else if (type == 'custom') {
      return CustomNavigationRule.fromJson(json);
    } else if (type == 'action') {
      return ActionNavigationRule.fromJson(json);
    }
    throw RuleNotDefinedException(discriminator: type);
  }
  Map<String, dynamic> toJson();
}
