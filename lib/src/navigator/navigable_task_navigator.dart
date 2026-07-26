import 'package:collection/collection.dart';
import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/navigator/rules/action_navigation_rule.dart';
import 'package:survey_kit/src/navigator/rules/conditional_navigation_rule.dart';
import 'package:survey_kit/src/navigator/rules/custom_navigation_rule.dart';
import 'package:survey_kit/src/navigator/rules/direct_navigation_rule.dart';
import 'package:survey_kit/src/navigator/task_navigator.dart';
import 'package:survey_kit/src/task/navigable_task.dart';
import 'package:survey_kit/src/task/task.dart';
import 'package:survey_kit/src/util/survey_kit_logger.dart';

class NavigableTaskNavigator extends TaskNavigator {
  final SurveyRegistries? _registries;

  NavigableTaskNavigator(Task task, {SurveyRegistries? registries})
      : _registries = registries,
        super(task) {
    _init();
  }

  void _init() {
    SurveyKitLogger.d('NavigableTaskNavigator');
  }

  @override
  Step? nextStep({
    required Step step,
    required List<StepResult> previousResults,
    StepResult? questionResult,
    bool recordStep = true,
  }) {
    if (recordStep) {
      record(step);
    }
    final navigableTask = task as NavigableTask;
    final rule = navigableTask.getRuleByStepIdentifier(step.id);
    if (rule == null) {
      return nextInList(step);
    }
    if (rule is DirectNavigationRule) {
      return task.steps.firstWhereOrNull((e) => e.id == rule.destinationStepIdentifier);
    }
    if (rule is ConditionalNavigationRule) {
      return evaluateNextStep(step, rule, previousResults, questionResult);
    }
    if (rule is CustomNavigationRule) {
      return _evaluateCustomRule(step, rule, previousResults, questionResult);
    }
    if (rule is ActionNavigationRule) {
      // recordStep is false for the read-only hasNextStep probe (step_view
      // evaluates the next step to pick the Next/Done label). Do not fire the
      // side-effecting action handler during that probe — the destination is
      // fixed regardless, so only fire it on real forward navigation (#976).
      return _evaluateActionRule(step, rule, previousResults,
          fireAction: recordStep);
    }
    return nextInList(step);
  }

  @override
  Step? previousInList(Step? step) {
    SurveyKitLogger.d('previousInList for ${step?.id}');
    if (history.isEmpty) {
      SurveyKitLogger.d('history is empty');
      return null;
    }
    SurveyKitLogger.d('previousInList is ${history.last.id}');
    return history.removeLast();
  }

  Step? evaluateNextStep(
    Step? step,
    ConditionalNavigationRule rule,
    List<StepResult> previousResults,
    StepResult? questionResult,
  ) {
    final nextStepIdentifier = rule.resultToStepIdentifierMapper(previousResults, questionResult);
    if (nextStepIdentifier == null) {
      return nextInList(step);
    }

    if (nextStepIdentifier == 'end_task') {
      return null;
    }

    return task.steps.firstWhereOrNull((element) => element.id == nextStepIdentifier);
  }

  Step? _evaluateCustomRule(
    Step step,
    CustomNavigationRule rule,
    List<StepResult> previousResults,
    StepResult? questionResult,
  ) {
    final handler = _registries?.customNavigationRules[rule.ruleId];
    if (handler == null) {
      SurveyKitLogger.d('No handler registered for custom rule: ${rule.ruleId}');
      return nextInList(step);
    }
    task.variables['_currentStepId'] = step.id;
    final nextStepId = handler(previousResults, questionResult, task.variables);
    if (nextStepId == 'end_task') return null;
    return task.steps.firstWhereOrNull((s) => s.id == nextStepId);
  }

  Step? _evaluateActionRule(
    Step step,
    ActionNavigationRule rule,
    List<StepResult> previousResults, {
    bool fireAction = true,
  }) {
    if (fireAction) {
      final handler = _registries?.actionHandlers[rule.actionId];
      if (handler != null) {
        // ADO #969: action handlers (e.g. exercise-PDF generation) aggregate
        // step results. The action fires mid-survey, before completion pruning,
        // so feed the handler only results for steps on the path actually taken
        // (history) — otherwise answers seeded from a prior run for off-path
        // steps leak into the PDF. Routing below uses rule.nextStepIdentifier
        // (fixed), so pruning the handler's input cannot change navigation.
        final visitedStepIds = history.map((s) => s.id).toSet();
        final onPathResults = previousResults
            .where((r) => visitedStepIds.contains(r.id))
            .toList();
        try {
          handler(onPathResults, task.variables);
        } catch (e) {
          SurveyKitLogger.d('Action handler "${rule.actionId}" threw: $e');
        }
      } else {
        SurveyKitLogger.d('No action handler registered for: ${rule.actionId}');
      }
    }
    if (rule.nextStepIdentifier == 'end_task') return null;
    return task.steps.firstWhereOrNull((s) => s.id == rule.nextStepIdentifier);
  }

  @override
  Step? firstStep() {
    final previousStep = peekHistory();

    return previousStep == null
        ? task.initialStep ?? task.steps.first
        : nextStep(
            step: previousStep,
            previousResults: [],
            questionResult: null,
          );
  }
}
