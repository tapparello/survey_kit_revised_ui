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
  NavigableTaskNavigator(Task task) : super(task);

  @override
  Step? nextStep({required Step step, StepResult? questionResult}) {
    record(step);
    final navigableTask = task as NavigableTask;
    final rule = navigableTask.getRuleByStepIdentifier(step.id);
    if (rule == null) {
      print('rule is empty');
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
          questionResult,
        );
    }
    return nextInList(step);
  }

  @override
  Step? previousInList(Step? step) {
    if (history.isEmpty) {
      return null;
    }
    return history.removeLast();
  }

  Step? evaluateNextStep(
    Step? step,
    ConditionalNavigationRule rule,
    StepResult? questionResult,
  ) {
    if (questionResult == null) {
      return nextInList(step);
    }
    log(json.encode(questionResult.toJson()));
    final dynamic result = questionResult.result;
    if (result == null) {
      return nextInList(step);
    }
    log(json.encode(result.toJson()));
    String? value;
    switch (result.runtimeType){
      case TextChoice:
        value = (result as TextChoice).value;
    }
    final nextStepIdentifier =
        rule.resultToStepIdentifierMapper(value);
    if (nextStepIdentifier == null) {
      return nextInList(step);
    }
    return task.steps.firstWhere((element) => element.id == nextStepIdentifier);
  }

  @override
  Step? firstStep() {
    final previousStep = peekHistory();
    return previousStep == null
        ? task.initalStep ?? task.steps.first
        : nextStep(step: previousStep, questionResult: null);
  }
}
