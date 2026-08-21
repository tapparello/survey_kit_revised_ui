import 'package:collection/collection.dart';
import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/navigator/rules/navigation_rule.dart';
import 'package:survey_kit/src/task/task.dart';

/// Definition of task which can handle routing between [Tasks]
/// The [navigationRules] defines on which Step [StepIdentifier] which next Step
/// is called. The logic which [Step] is called is defined in the
/// [NavigationRule]
class NavigableTask extends Task {
  final Map<String, NavigationRule> navigationRules;

  NavigableTask({
    String? id,
    List<Step> steps = const [],
    String? initialStepId,
    Map<String, NavigationRule>? navigationRules,
    Map<String, dynamic>? variables,
    int? stepCount,
  }) : navigationRules = navigationRules ?? {},
       super(
         id: id,
         steps: steps,
         initialStep: steps.firstWhereOrNull(
           (step) => step.id == initialStepId,
         ),
         variables: variables,
         stepCount: stepCount,
       );

  /// Adds a [NavigationRule] to the [navigationRule] Map
  /// It only adds the [NavigationRule] if none is already set for the
  /// [StepIdentifier]
  void addNavigationRule({
    required String forTriggerStepIdentifier,
    required NavigationRule navigationRule,
  }) {
    navigationRules.putIfAbsent(forTriggerStepIdentifier, () => navigationRule);
  }

  /// Gets the [NavigationRule] which is defined for the given [StepIndentifier]
  /// Returns null if none is defined
  NavigationRule? getRuleByStepIdentifier(String? stepIdentifier) {
    return navigationRules[stepIdentifier];
  }

  factory NavigableTask.fromJson(
    Map<String, dynamic> json, {
    SurveyRegistries? registries,
  }) {
    final navigationRules = <String, NavigationRule>{};

    if (json['rules'] != null) {
      final rules = json['rules'] as List;
      for (final rule in rules) {
        navigationRules.putIfAbsent(
          ((rule as Map<String, dynamic>)['triggerStepIdentifier']
                  as Map<String, dynamic>)['id']
              as String,
          () => NavigationRule.fromJson(rule),
        );
      }
    }

    final variables = (json['variables'] as Map<String, dynamic>?) ?? {};

    return NavigableTask(
      id: json['id'] as String,
      steps: json['steps'] != null
          ? (json['steps'] as List)
                .map(
                  (dynamic step) => Step.fromJson(
                    step as Map<String, dynamic>,
                    registries: registries,
                  ),
                )
                .toList()
          : [],
      initialStepId: json['initialStepId'] as String?,
      navigationRules: navigationRules,
      variables: variables,
      stepCount: json['stepCount'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson('navigable'),
    // The trigger id lives in the navigationRules KEY, not on the rule — no
    // rule class has a field for it — so it is re-attached here, in the nested
    // shape `fromJson` above reads. A List rather than a Map because that is
    // what `json['rules'] as List` needs; the key this replaces
    // (`navigationRules`) held live objects that no reader ever looked at and
    // that jsonEncode threw on.
    'rules': navigationRules.entries
        .map(
          (entry) => <String, dynamic>{
            ...entry.value.toJson(),
            'triggerStepIdentifier': <String, dynamic>{'id': entry.key},
          },
        )
        .toList(),
  };
}
