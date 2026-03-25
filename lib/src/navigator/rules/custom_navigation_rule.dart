import 'package:survey_kit/src/navigator/rules/navigation_rule.dart';

class CustomNavigationRule implements NavigationRule {
  final String ruleId;

  const CustomNavigationRule({required this.ruleId});

  factory CustomNavigationRule.fromJson(Map<String, dynamic> json) {
    return CustomNavigationRule(ruleId: json['ruleId'] as String);
  }

  @override
  Map<String, dynamic> toJson() => {'type': 'custom', 'ruleId': ruleId};
}
