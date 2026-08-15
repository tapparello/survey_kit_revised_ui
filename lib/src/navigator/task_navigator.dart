import 'dart:collection';

import 'package:survey_kit/src/configuration/action_context.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/task/task.dart';

abstract class TaskNavigator {
  final Task task;
  final ListQueue<Step> history = ListQueue();

  TaskNavigator(this.task);

  Step? firstStep();

  /// Advances past [step]: records it in [history], then fires and **awaits**
  /// the handler for any [ActionNavigationRule] on it.
  Future<Step?> nextStep({
    required Step step,
    required List<StepResult> previousResults,
    StepResult? questionResult,
    ActionTrigger trigger = ActionTrigger.advance,
  });

  /// Resolves the destination without advancing. Does not record [step] in
  /// [history] and does not fire an action handler.
  ///
  /// It is **not** side-effect free, and the name is `peek`, not `preview`, for
  /// that reason. It evaluates `CustomNavigationRule` and
  /// `ConditionalNavigationRule` handlers — consumer code, and the only way to
  /// learn where those rules lead — passing a null `questionResult`. It also
  /// writes `task.variables['_currentStepId']`.
  Step? peekNextStep({
    required Step step,
    required List<StepResult> previousResults,
    StepResult? questionResult,
  });

  Step? previousInList(Step step);

  Step? nextInList(Step? step) {
    final currentIndex = task.steps.indexWhere(
      (element) => element.id == step?.id,
    );
    return (currentIndex + 1 > task.steps.length - 1)
        ? null
        : task.steps[currentIndex + 1];
  }

  Step? peekHistory() {
    if (history.isEmpty) {
      return null;
    }
    return history.last;
  }

  bool hasNextStep(Step step, List<StepResult> previousResults) =>
      peekNextStep(step: step, previousResults: previousResults) != null;

  bool hasPreviousStep() {
    final step = peekHistory();
    return step != null;
  }

  void record(Step step) {
    history.add(step);
  }

  int get countSteps => task.stepCount ?? task.steps.length;
  int currentStepIndex(Step step) {
    if (task.stepCount != null) {
      // When stepCount is overridden (variant branching), use history length
      // so the index reflects the user's actual position in the flow.
      return history.length;
    }
    // By id, not by identity: SurveyEngine presents a resolved COPY of a
    // conditional step and Step has no value equality, so indexOf would return
    // -1. Every other member of this class already compares by id. (ADO #1045)
    return task.steps.indexWhere((s) => s.id == step.id);
  }
}
