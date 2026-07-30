import 'package:survey_kit/src/model/content/content.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';

typedef ContentFactory = Content Function(Map<String, dynamic> json);
typedef StepFactory = Step Function(Map<String, dynamic> json);
typedef NavigationRuleHandler =
    String Function(
      List<StepResult> results,
      StepResult? currentResult,
      Map<String, dynamic> variables,
    );
typedef ActionHandler =
    void Function(List<StepResult> results, Map<String, dynamic> variables);

class SurveyRegistries {
  final Map<String, ContentFactory> customContentTypes;
  final Map<String, StepFactory> customStepTypes;
  final Map<String, NavigationRuleHandler> customNavigationRules;
  final Map<String, ActionHandler> actionHandlers;

  const SurveyRegistries({
    this.customContentTypes = const {},
    this.customStepTypes = const {},
    this.customNavigationRules = const {},
    this.actionHandlers = const {},
  });

  Content? resolveContent(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) return null;
    final factory = customContentTypes[type];
    return factory?.call(json);
  }

  Step? resolveStep(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) return null;
    final factory = customStepTypes[type];
    return factory?.call(json);
  }
}
