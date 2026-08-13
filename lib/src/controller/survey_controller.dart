import 'package:flutter/widgets.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/presenter/survey_event.dart';
import 'package:survey_kit/src/presenter/survey_state_provider.dart';

class SurveyController {
  /// Defines what should happen if the next step is called
  /// Default behavior is:
  /// ```dart
  /// BlocProvider.of<SurveyPresenter>(context).add(
  ///    NextStep(
  ///      resultFunction.call(),
  ///    ),
  /// );
  /// ```
  final Function(BuildContext context, StepResult? stepResult)? onNextStep;

  /// Defines what should happen if the previous step is called
  /// Default behavior is:
  /// ```dart
  /// BlocProvider.of<SurveyPresenter>(context).add(
  ///    StepBack(
  ///      resultFunction.call(),
  ///    ),
  /// );
  /// ```
  final Function(BuildContext context, StepResult? stepResult)? onStepBack;

  /// Defines what should happen if the survey should be closed
  /// Default behavior is:
  /// ```dart
  /// BlocProvider.of<SurveyPresenter>(context).add(
  ///    CloseSurvey(
  ///      resultFunction.call(),
  ///    ),
  /// );
  /// ```
  final Function(BuildContext context, StepResult? stepResult)? onCloseSurvey;

  SurveyController({this.onNextStep, this.onStepBack, this.onCloseSurvey});

  Future<void> nextStep(BuildContext context, StepResult? stepResult) async {
    if (onNextStep != null) {
      await onNextStep!(context, stepResult);
      return;
    }
    await SurveyStateProvider.of(context).onEvent(NextStep(stepResult));
  }

  Future<void> stepBack({
    required BuildContext context,
    StepResult? stepResult,
  }) async {
    if (onStepBack != null) {
      await onStepBack!(context, stepResult);
      return;
    }
    await SurveyStateProvider.of(context).onEvent(StepBack(stepResult));
  }

  Future<void> closeSurvey({
    required BuildContext context,
    StepResult? stepResult,
  }) async {
    if (onCloseSurvey != null) {
      await onCloseSurvey!(context, stepResult);
      return;
    }
    await SurveyStateProvider.of(context).onEvent(CloseSurvey(stepResult));
  }
}
