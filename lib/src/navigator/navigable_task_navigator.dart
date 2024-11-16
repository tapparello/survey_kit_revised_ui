import 'dart:convert';
import 'dart:developer';

import 'package:survey_kit/src/model/answer/text_choice.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/navigator/rules/conditional_navigation_rule.dart';
import 'package:survey_kit/src/navigator/rules/direct_navigation_rule.dart';
import 'package:survey_kit/src/navigator/task_navigator.dart';
import 'package:survey_kit/src/task/navigable_task.dart';
import 'package:survey_kit/src/task/task.dart';

class NavigableTaskNavigator extends TaskNavigator {

  NavigableTaskNavigator(Task task) : super(task){
    _init();
  }

  void _init() {
    print('NavigableTaskNavigator');
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
    switch (rule.runtimeType) {
      case DirectNavigationRule:
        return task.steps.firstWhere(
          (element) =>
              element.id ==
              (rule as DirectNavigationRule).destinationStepIdentifier,
        );
      case ConditionalNavigationRule:
        return evaluateNextStep(
          step,
          rule as ConditionalNavigationRule,
          previousResults,
          questionResult,
        );
    }
    return nextInList(step);
  }

  @override
  Step? previousInList(Step? step) {
    print('previousInList for ${step?.id}');
    if (history.isEmpty) {
      print('history is empty');
      return null;
    }
    print('previousInList is ${history.last.id}');
    return history.removeLast();
  }

  Step? evaluateNextStep(
    Step? step,
    ConditionalNavigationRule rule,
    List<StepResult> previousResults,
    StepResult? questionResult,
  ) {
    final nextStepIdentifier =
        rule.resultToStepIdentifierMapper(previousResults, questionResult);
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
    return task.steps.firstWhere((element) => element.id == nextStepIdentifier);
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
    //     print('Recorded step: ${currentStep.id}');
    //     while (currentStep.id != task.initialStep!.id) {
    //       step = nextStep(
    //         step: currentStep,
    //         previousResults: [],
    //         questionResult: null,
    //       );
    //
    //       print('Recorded step: ${step?.id}');
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
