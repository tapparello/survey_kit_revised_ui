import 'package:survey_kit/src/model/answer/text_choice.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/navigator/rules/navigation_rule.dart';

class ConditionalNavigationRule implements NavigationRule {
  /// Chooses the next step's id from the results so far.
  ///
  /// The `fromJson` factory supplies a pure closure over an authored value map,
  /// but this is a public constructor field: a rule built in Dart carries
  /// arbitrary consumer code. Like [NavigationRuleHandler], it is invoked for
  /// read-only probes as well as real advances, with a **null** second argument
  /// on a probe, so it must be safe to re-run and free of side effects.
  final String? Function(List<StepResult>, StepResult?)
  resultToStepIdentifierMapper;

  ConditionalNavigationRule({required this.resultToStepIdentifierMapper});

  factory ConditionalNavigationRule.fromJson(Map<String, dynamic> json) {
    final inputValues = json['values'] as Map<String, dynamic>;
    return ConditionalNavigationRule(
      resultToStepIdentifierMapper: (results, input) {
        if (input == null) return null;
        final answerValue = _extractValue(input.result);
        for (final MapEntry entry in inputValues.entries) {
          if (entry.key == answerValue) {
            return entry.value as String;
          }
        }
        return null;
      },
    );
  }

  static String? _extractValue(dynamic result) {
    if (result is TextChoice) return result.value;
    if (result is Map<String, dynamic>) return result['value']?.toString();
    return result?.toString();
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'values': <String, dynamic>{},
  };
}
