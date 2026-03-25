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
      return _evaluateActionRule(step, rule, previousResults);
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

    // log(json.encode(questionResult.toJson()));
    // final dynamic result = questionResult.result;
    // if (result == null) {
    //   return nextInList(step);
    // }
    // log(json.encode(result.toJson()));
    // String? value;
    // switch (result.runtimeType){
    //   case TextChoice:
    //     value = (result as TextChoice).value;
    // }
    // final nextStepIdentifier =
    //     rule.resultToStepIdentifierMapper(value);
    // if (nextStepIdentifier == null) {
    //   return nextInList(step);
    // }
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
    final nextStepId = handler(previousResults, questionResult, task.variables);
    if (nextStepId == 'end_task') return null;
    return task.steps.firstWhereOrNull((s) => s.id == nextStepId);
  }

  Step? _evaluateActionRule(
    Step step,
    ActionNavigationRule rule,
    List<StepResult> previousResults,
  ) {
    final handler = _registries?.actionHandlers[rule.actionId];
    if (handler != null) {
      try {
        handler(previousResults, task.variables);
      } catch (e) {
        SurveyKitLogger.d('Action handler "${rule.actionId}" threw: $e');
      }
    } else {
      SurveyKitLogger.d('No action handler registered for: ${rule.actionId}');
    }
    if (rule.nextStepIdentifier == 'end_task') return null;
    return task.steps.firstWhereOrNull((s) => s.id == rule.nextStepIdentifier);
  }

  @override
  Step? firstStep() {
    final previousStep = peekHistory();

    //
    // if (previousStep == null) {
    //   if (task.initialStep != null && task.initialStep!.id != task.steps.first.id) {
    //     // Re-generate the history in case the task is restarted from a different initial step
    //     var currentStep = task.steps.first;
    //     Step? step;
    //     SurveyKitLogger.d('Recorded step: ${currentStep.id}');
    //     while (currentStep.id != task.initialStep!.id) {
    //       step = nextStep(
    //         step: currentStep,
    //         previousResults: [],
    //         questionResult: null,
    //       );
    //
    //       SurveyKitLogger.d('Recorded step: ${step?.id}');
    //       if (step == null) {
    //         break;
    //       }
    //
    //       currentStep = step;
    //     }
    //
    //     return task.initialStep;
    //   } else {
    //     return task.steps.first;
    //   }
    //
    // } else { // There is a previous step in the history
    //   return nextStep(
    //     step: previousStep,
    //     previousResults: [],
    //     questionResult: null,
    //   );
    // }

    return previousStep == null
        ? task.initialStep ?? task.steps.first
        : nextStep(
            step: previousStep,
            previousResults: [],
            questionResult: null,
          );
  }
}
