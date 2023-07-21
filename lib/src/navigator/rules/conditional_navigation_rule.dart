import 'dart:developer';

import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/navigator/rules/navigation_rule.dart';

class ConditionalNavigationRule implements NavigationRule {
  final String? Function(String?) resultToStepIdentifierMapper;

  ConditionalNavigationRule({required this.resultToStepIdentifierMapper});

  factory ConditionalNavigationRule.fromJson(Map<String, dynamic> json) {
    final inputValues = json['values'] as Map<String, dynamic>;
    return ConditionalNavigationRule(
      resultToStepIdentifierMapper: (input) {
        print('Input is $input');
        for (final MapEntry entry in inputValues.entries) {
          print(entry);
          if (entry.key == input) {
            return entry.value as String;
          }
        }
        return null;
      },
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'values': <String, dynamic>{},
      };
}
