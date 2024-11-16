import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:survey_kit/survey_kit.dart';
import 'package:flutter_html/flutter_html.dart' hide Content;

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
  })  : _state = LoadingSurveyState(),
        startDate = DateTime.now();

  final TaskNavigator taskNavigator;
  final Function(SurveyResult) onResult;
  final StepShell? stepShell;
  final GlobalKey<NavigatorState> navigatorKey;

  late SurveyState _state;
  SurveyState get state => _state;
  void updateState(SurveyState newState) {
    _state = newState;
    surveyStateStream.add(_state);
  }

  late StreamController<SurveyState> surveyStateStream =
      StreamController<SurveyState>.broadcast();

  static SurveyStateProvider of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<SurveyStateProvider>();
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
      navigatorKey.currentState?.pushNamed(
        '/',
        arguments: newState,
      );
    } else if (event is NextStep) {
      if (state is PresentingSurveyState) {

        final currentState = state as PresentingSurveyState;

        final newState = _handleNextStep(event, state as PresentingSurveyState);
        updateState(newState);

        // Check if we need to show a dialog
        if (currentState.currentStep.answerFormat is SingleChoiceAnswerWithFeedbackFormat) {
          final answerFormat = currentState.currentStep.answerFormat as SingleChoiceAnswerWithFeedbackFormat?;

          final selectedChoice = event.questionResult?.result as TextChoice?; //getStepResultById(currentState.currentStep.id)?.result as TextChoice?;

          if (selectedChoice?.value == 'correct') {
            Future.delayed(const Duration(seconds: 1), () {
              Navigator.of(navigatorKey.currentContext!, rootNavigator: true).pop();
              navigatorKey.currentState?.pushNamed(
                '/',
                arguments: newState,
              );
            });
            _showDialog(answerFormat?.feedbackCorrect ?? 'You selected the correct answer!', newState, false, Colors.green);
          } else {
            _showDialog(answerFormat?.feedbackWrong ?? 'You selected the incorrect answer!', newState, true, Colors.red);
          }
        } else if (currentState.currentStep.answerFormat is MultipleChoiceAnswerWithFeedbackFormat) {
          final answerFormat = currentState.currentStep.answerFormat as MultipleChoiceAnswerWithFeedbackFormat?;
          final selectedChoices = event.questionResult?.result as List<TextChoice>? ??
              [];

          final answers =
          selectedChoices.map((choice) => choice.value).toList();

          if (answers.contains('wrong')){
            Color? backgroundColor;
            if (answerFormat!.coloredFeedback) {
              backgroundColor = Colors.red;
            }

            _showDialog(answerFormat.feedbackWrong ?? 'You selected the incorrect answers!', newState, true, backgroundColor);

          } else {

            Color? backgroundColor;
            if (answerFormat!.coloredFeedback) {
              backgroundColor = Colors.green;

              Future.delayed(const Duration(seconds: 1), () {
                Navigator.of(navigatorKey.currentContext!, rootNavigator: true).pop();
                navigatorKey.currentState?.pushNamed(
                  '/',
                  arguments: newState,
                );
              });

              _showDialog(answerFormat.feedbackCorrect ?? 'You selected the correct answers!', newState, false, backgroundColor);

            } else {
              _showDialog(answerFormat.feedbackCorrect ?? 'You selected the correct answers!', newState, true, backgroundColor);
            }

          }

        } else {
          navigatorKey.currentState?.pushNamed(
            '/',
            arguments: newState,
          );
        }
      }
    } else if (event is StepBack) {
      if (state is PresentingSurveyState) {
        final newState = _handleStepBack(event, state as PresentingSurveyState);
        updateState(newState);

        // original code:
        // navigatorKey.currentState?.pop();
        // This should handle starting from a generic step in the list
        // if (navigatorKey.currentState?.canPop() == true) {
        //   navigatorKey.currentState?.pop();
        // } else {
        //   navigatorKey.currentState?.pushReplacementNamed(
        //       '/',
        //       arguments: newState,
        //   );
        // }

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
        print('Visiting steps starting from: ${currentStep.id}');
        while (currentStep.id != step.id) {
          final questionResult = _getResultByStepIdentifier(currentStep.id);
          // _addResult(questionResult);
          nextStepToVisit = taskNavigator.nextStep(
            step: currentStep,
            previousResults: results.toList(),
            questionResult: questionResult,
          );

          print('Recorded step: ${currentStep.id}');

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

    return SurveyResultState(
      result: taskResult,
      currentStep: null,
    );
  }

  SurveyState _handleNextStep(
    NextStep event,
    PresentingSurveyState currentState,
  ) {
    _addResult(event.questionResult);
    final nextStep = taskNavigator.nextStep(
      step: currentState.currentStep,
      previousResults: results.toList(),
      questionResult: event.questionResult,
    );

    if (nextStep == null) {
      return _handleSurveyFinished(currentState);
    }

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

    print('Ready to visit previous step: ${previousStep?.id}');
    //If theres no previous step we can't go back further
    if (previousStep != null) {
      final questionResult = _getResultByStepIdentifier(previousStep.id);

      print('Previous step result: ${questionResult?.toJson().toString()}');

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
    return results.firstWhereOrNull(
      (element) => element.id == identifier,
    );
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
    final stepResults = results.map((e) => e).toList();
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
      ..add(
        questionResult,
      );
  }

  int get countSteps => taskNavigator.countSteps;
  int currentStepIndex(Step step) {
    return taskNavigator.currentStepIndex(step);
  }

  StepResult? getStepResultById(String id) {
    return results.firstWhereOrNull((element) => element.id == id);
  }

  void _showDialog(String feedbackMessage, SurveyState newState, bool showNextButton, Color? backgroundColor) {

    final htmlStyle = <String, Style>{
      'p': Style(
        textAlign: TextAlign.center,
        fontWeight: FontWeight.bold,
        fontSize: FontSize(16.0),
      ),
      'ul': Style(
        fontSize: FontSize(16.0),
      ),
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
                Html(data: '<strong>$feedbackMessage</strong>', style: htmlStyle),
                const SizedBox(height: 15),
                if (showNextButton) TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          navigatorKey.currentState?.pushNamed(
                            '/',
                            arguments: newState,
                          );
                        },
                        child: Text('Next', style: TextStyle( fontSize: 16.0, color: (backgroundColor != null) ? Colors.white : Colors.blueAccent, fontWeight: FontWeight.bold)),
                      ) else const SizedBox.shrink(),
              ],
            ),
          ),
        );
      },
    );
  }

}


