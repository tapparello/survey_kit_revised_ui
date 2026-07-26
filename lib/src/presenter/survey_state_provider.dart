import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_html/flutter_html.dart' hide Content;
import 'package:survey_kit/src/util/survey_kit_logger.dart';
import 'package:survey_kit/survey_kit.dart';

// ignore: must_be_immutable
class SurveyStateProvider extends InheritedWidget {
  SurveyStateProvider({
    super.key,
    required this.taskNavigator,
    required this.onResult,
    required super.child,
    required this.navigatorKey,
    this.stepShell,
    required this.results,
    this.localizations,
  }) : _state = LoadingSurveyState(),
       startDate = DateTime.now();

  final TaskNavigator taskNavigator;
  final Function(SurveyResult) onResult;
  final StepShell? stepShell;
  final GlobalKey<NavigatorState> navigatorKey;
  final Map<String, String>? localizations;

  late SurveyState _state;
  SurveyState get state => _state;
  void updateState(SurveyState newState) {
    _state = newState;
    surveyStateStream.add(_state);
  }

  late StreamController<SurveyState> surveyStateStream =
      StreamController<SurveyState>.broadcast();

  static SurveyStateProvider of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<SurveyStateProvider>();
    assert(result != null, 'No SurveyPresenterInherited found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(SurveyStateProvider oldWidget) =>
      taskNavigator != oldWidget.taskNavigator ||
      onResult != oldWidget.onResult ||
      _state != oldWidget._state;

  Set<StepResult> results;
  late final DateTime startDate;

  void onEvent(SurveyEvent event) {
    if (event is StartSurvey) {
      final newState = _handleInitialStep();
      updateState(newState);
      navigatorKey.currentState?.pushNamed('/', arguments: newState);
    } else if (event is NextStep) {
      if (state is PresentingSurveyState) {
        final currentState = state as PresentingSurveyState;
        _addResult(event.questionResult);

        final nextStep = taskNavigator.nextStep(
          step: currentState.currentStep,
          previousResults: results.toList(),
          questionResult: event.questionResult,
        );

        // Advance the survey once any feedback has been acknowledged: present the
        // next step, or — when there is none — finish the survey. Finishing
        // (which calls onResult and pops the host) is deferred into this callback
        // so a feedback dialog on the TERMINAL step is shown and dismissed BEFORE
        // the survey closes, instead of stranding over the screen behind it.
        void proceed() {
          if (nextStep == null) {
            final finished = _handleSurveyFinished(currentState);
            updateState(finished);
            navigatorKey.currentState?.pushNamed('/', arguments: finished);
          } else {
            final presenting = _presentStep(nextStep);
            updateState(presenting);
            navigatorKey.currentState?.pushNamed('/', arguments: presenting);
          }
        }

        final answerFormat = currentState.currentStep.answerFormat;
        if (answerFormat is SingleChoiceAnswerWithFeedbackFormat) {
          final selectedChoice = event.questionResult?.result as TextChoice?;
          final isCorrect = selectedChoice?.value == 'correct';
          _showFeedbackDialog(
            message:
                (isCorrect
                    ? answerFormat.feedbackCorrect
                    : answerFormat.feedbackWrong) ??
                (isCorrect
                    ? 'You selected the correct answer!'
                    : 'You selected the incorrect answer!'),
            backgroundColor: isCorrect ? Colors.green : Colors.red,
            autoDismiss: isCorrect,
            onContinue: proceed,
          );
        } else if (answerFormat is MultipleChoiceAnswerWithFeedbackFormat) {
          final rawChoices = event.questionResult?.result;
          final selectedChoices = rawChoices is List<TextChoice>
              ? rawChoices
              : rawChoices is List
              ? rawChoices.map((item) {
                  if (item is TextChoice) return item;
                  if (item is Map<String, dynamic>) {
                    return TextChoice.fromJson(item);
                  }
                  return TextChoice(
                    text: item.toString(),
                    value: item.toString(),
                  );
                }).toList()
              : <TextChoice>[];

          final hasWrong = selectedChoices.any(
            (choice) => choice.value == 'wrong',
          );
          final colored = answerFormat.coloredFeedback;
          _showFeedbackDialog(
            message:
                (hasWrong
                    ? answerFormat.feedbackWrong
                    : answerFormat.feedbackCorrect) ??
                (hasWrong
                    ? 'You selected the incorrect answers!'
                    : 'You selected the correct answers!'),
            backgroundColor: colored
                ? (hasWrong ? Colors.red : Colors.green)
                : null,
            // Auto-dismiss only the all-correct coloured case (matches prior
            // behaviour); every other case shows a tappable "Next" button.
            autoDismiss: colored && !hasWrong,
            onContinue: proceed,
          );
        } else {
          proceed();
        }
      }
    } else if (event is StepBack) {
      if (state is PresentingSurveyState) {
        final newState = _handleStepBack(event, state as PresentingSurveyState);
        updateState(newState);

        navigatorKey.currentState?.pushReplacementNamed(
          '/',
          arguments: newState,
        );
      }
    } else if (event is CloseSurvey) {
      if (state is PresentingSurveyState) {
        final newState = _handleClose(event, state as PresentingSurveyState);
        updateState(newState);
        navigatorKey.currentState?.pop();
      }
    }
  }

  SurveyState _handleInitialStep() {
    final step = taskNavigator.firstStep();
    if (step != null) {
      // Check if we need to recreate the history
      if (step.id != taskNavigator.task.steps.first.id) {
        var currentStep = taskNavigator.task.steps.first;
        Step? nextStepToVisit;
        SurveyKitLogger.d('Visiting steps starting from: ${currentStep.id}');
        while (currentStep.id != step.id) {
          final questionResult = _getResultByStepIdentifier(currentStep.id);
          // _addResult(questionResult);
          nextStepToVisit = taskNavigator.nextStep(
            step: currentStep,
            previousResults: results.toList(),
            questionResult: questionResult,
          );

          SurveyKitLogger.d('Recorded step: ${currentStep.id}');

          if (nextStepToVisit == null) {
            break;
          }

          currentStep = nextStepToVisit;
        }
      }

      final questionResult = _getResultByStepIdentifier(step.id);

      return PresentingSurveyState(
        currentStep: step,
        questionResults: results,
        steps: taskNavigator.task.steps,
        result: questionResult,
        // result: null,
        currentStepIndex: currentStepIndex(step),
        stepCount: countSteps,
        isInitialStep: true,
      );
    }

    //If not steps are provided we finish the survey
    final taskResult = SurveyResult(
      id: taskNavigator.task.id,
      startTime: startDate,
      endTime: DateTime.now(),
      finishReason: FinishReason.completed,
      results: const [],
    );

    return SurveyResultState(result: taskResult, currentStep: null);
  }

  PresentingSurveyState _presentStep(Step nextStep) {
    final questionResult = _getResultByStepIdentifier(nextStep.id);

    return PresentingSurveyState(
      currentStep: nextStep,
      result: questionResult,
      steps: taskNavigator.task.steps,
      questionResults: results,
      currentStepIndex: currentStepIndex(nextStep),
      stepCount: countSteps,
    );
  }

  SurveyState _handleStepBack(
    StepBack event,
    PresentingSurveyState currentState,
  ) {
    _addResult(event.questionResult);
    final previousStep = taskNavigator.previousInList(currentState.currentStep);

    SurveyKitLogger.d('Ready to visit previous step: ${previousStep?.id}');
    //If theres no previous step we can't go back further
    if (previousStep != null) {
      final questionResult = _getResultByStepIdentifier(previousStep.id);

      SurveyKitLogger.d(
        'Previous step result: ${questionResult?.toJson().toString()}',
      );

      return PresentingSurveyState(
        currentStep: previousStep,
        result: questionResult,
        steps: taskNavigator.task.steps,
        questionResults: results,
        currentStepIndex: currentStepIndex(previousStep),
        isPreviousStep: true,
        stepCount: countSteps,
      );
    }

    return state;
  }

  StepResult? _getResultByStepIdentifier(String? identifier) {
    return results.firstWhereOrNull((element) => element.id == identifier);
  }

  SurveyState _handleClose(
    CloseSurvey event,
    PresentingSurveyState currentState,
  ) {
    _addResult(event.questionResult);

    final stepResults = results.map((e) => e).toList();

    final taskResult = SurveyResult(
      id: taskNavigator.task.id,
      startTime: startDate,
      endTime: DateTime.now(),
      finishReason: FinishReason.discarded,
      results: stepResults,
      lastShownStepId: currentState.currentStep.id,
    );
    onResult(taskResult);
    return SurveyResultState(
      result: taskResult,
      stepResult: currentState.result,
      currentStep: currentState.currentStep,
    );
  }

  //Currently we are only handling one question per step
  SurveyState _handleSurveyFinished(PresentingSurveyState currentState) {
    // ADO #969: `results` may carry seeded answers (initialResults) for steps
    // NOT on the path just taken (a different branch on re-completion, or a
    // branch abandoned via back-navigation). Persist only the steps actually
    // visited — taskNavigator.history is the recorded path — plus the terminal
    // step defensively. Pruning here (completion) only; _handleClose keeps the
    // full set so a partial save can resume with prior answers intact.
    final visitedStepIds = taskNavigator.history.map((step) => step.id).toSet()
      ..add(currentState.currentStep.id);
    final stepResults = results
        .where((result) => visitedStepIds.contains(result.id))
        .toList();

    final taskResult = SurveyResult(
      id: taskNavigator.task.id,
      startTime: startDate,
      endTime: DateTime.now(),
      finishReason: FinishReason.completed,
      results: stepResults,
    );

    onResult(taskResult);
    return SurveyResultState(
      result: taskResult,
      currentStep: currentState.currentStep,
      stepResult: currentState.result,
    );
  }

  void _addResult(StepResult? questionResult) {
    if (questionResult == null) {
      return;
    }
    results
      ..removeWhere((StepResult result) => result.id == questionResult.id)
      ..add(questionResult);
  }

  int get countSteps => taskNavigator.countSteps;
  int currentStepIndex(Step step) {
    return taskNavigator.currentStepIndex(step);
  }

  StepResult? getStepResultById(String id) {
    return results.firstWhereOrNull((element) => element.id == id);
  }

  /// Shows the answer feedback dialog. When [autoDismiss] is true the dialog
  /// closes itself after a short delay and then calls [onContinue]; otherwise it
  /// shows a "Next" button that closes the dialog and calls [onContinue] on tap.
  /// [onContinue] is what advances or finishes the survey, so the survey only
  /// moves on (or closes) AFTER the feedback has been acknowledged.
  void _showFeedbackDialog({
    required String message,
    required Color? backgroundColor,
    required bool autoDismiss,
    required VoidCallback onContinue,
  }) {
    final htmlStyle = <String, Style>{
      'p': Style(
        textAlign: TextAlign.center,
        fontWeight: FontWeight.bold,
        fontSize: FontSize(16.0),
      ),
      'ul': Style(fontSize: FontSize(16.0)),
    };

    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: backgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Html(data: '<strong>$message</strong>', style: htmlStyle),
                const SizedBox(height: 15),
                if (!autoDismiss)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onContinue();
                    },
                    child: Text(
                      localizations?['next'] ?? 'Next',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: (backgroundColor != null)
                            ? Colors.white
                            : Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        );
      },
    );

    if (autoDismiss) {
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(navigatorKey.currentContext!, rootNavigator: true).pop();
        onContinue();
      });
    }
  }
}
