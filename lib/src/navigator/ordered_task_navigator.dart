import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/navigator/task_navigator.dart';
import 'package:survey_kit/src/task/task.dart';
import 'package:survey_kit/src/util/survey_kit_logger.dart';

class OrderedTaskNavigator extends TaskNavigator {
  OrderedTaskNavigator(Task task) : super(task);

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
    return nextInList(step);
  }

  @override
  Step? previousInList(Step step) {
    final currentIndex = task.steps.indexWhere(
      (element) => element.id == step.id,
    );
    SurveyKitLogger.d('currentIndex: $currentIndex');
    SurveyKitLogger.d(task.steps[currentIndex - 1].id);
    return (currentIndex - 1 < 0) ? null : task.steps[currentIndex - 1];
  }

  @override
  Step? firstStep() {
    final previousStep = peekHistory();
    return previousStep == null
        ? task.initialStep ?? task.steps.first
        : nextInList(previousStep);
  }
}
