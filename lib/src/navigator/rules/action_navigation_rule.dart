import 'package:survey_kit/src/navigator/rules/navigation_rule.dart';

class ActionNavigationRule implements NavigationRule {
  final String actionId;
  final String? nextStepIdentifier;

  const ActionNavigationRule({required this.actionId, this.nextStepIdentifier});

  factory ActionNavigationRule.fromJson(Map<String, dynamic> json) {
    return ActionNavigationRule(
      actionId: json['actionId'] as String,
      nextStepIdentifier:
          (json['nextStep'] ?? json['nextStepIdentifier']) as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'action',
    'actionId': actionId,
    'nextStep': nextStepIdentifier,
  };
}
