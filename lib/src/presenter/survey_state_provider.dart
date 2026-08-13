import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_html/flutter_html.dart' hide Content;
import 'package:survey_kit/src/presenter/survey_session.dart';
import 'package:survey_kit/survey_kit.dart';

class SurveyStateProvider extends InheritedWidget {
  @internal
  const SurveyStateProvider({
    super.key,
    required this.taskNavigator,
    required this.onResult,
    required super.child,
    required this.navigatorKey,
    required this.session,
    this.stepShell,
    this.localizations,
  });

  final TaskNavigator taskNavigator;
  final Function(SurveyResult) onResult;
  final StepShell? stepShell;
  final GlobalKey<NavigatorState> navigatorKey;
  final Map<String, String>? localizations;
  @internal
  final SurveySession session;

  // Delegations. Every one of these was a mutable field on this widget until
  // ADO #1033; they stay on the public surface so no `of(context)` call site
  // changed.
  SurveyState get state => session.state;
  Set<StepResult> get results => session.results;
  DateTime get startDate => session.startDate;
  StreamController<SurveyState> get surveyStateStream => session.stateStream;
  void updateState(SurveyState newState) => session.updateState(newState);
  StepResult? getStepResultById(String id) => session.resultById(id);
  ValueListenable<bool> get isAdvancing => session.isAdvancing;

  static SurveyStateProvider of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<SurveyStateProvider>();
    if (result == null) {
      throw const SurveyKitScopeException(
        widgetType: 'SurveyStateProvider',
        hint: 'Wrap the widget tree in SurveyKit.',
      );
    }
    return result;
  }

  /// Compares what dependents actually read from this widget.
  ///
  /// `onResult` is deliberately absent: no dependent reads it, and every real
  /// call site passes an inline closure whose identity changes on every build,
  /// so comparing it notified constantly — which is what destroyed the
  /// in-progress answer before ADO #1033.
  ///
  /// `stepShell` stays because `AnswerView` reads it — but note it is a function
  /// compared by identity, so a consumer passing an inline `stepShell` closure
  /// still gets a notification on every parent rebuild. That is now harmless:
  /// `AnswerSession` holds the answer, not `QuestionAnswer`.
  ///
  /// `localizations` is **not** compared here. Nothing reads it from this
  /// widget except `_showFeedbackDialog`, which reads it at call time. See (b).
  @override
  bool updateShouldNotify(SurveyStateProvider oldWidget) =>
      taskNavigator != oldWidget.taskNavigator ||
      session != oldWidget.session ||
      stepShell != oldWidget.stepShell;

  Future<void> onEvent(SurveyEvent event) async {
    try {
      if (event is StartSurvey) {
        if (!session.beginAdvance()) return;
        try {
          final newState = await _handleInitialStep();
          updateState(newState);
          unawaited(
            navigatorKey.currentState?.pushNamed('/', arguments: newState),
          );
        } finally {
          session.endAdvance();
        }
      } else if (event is NextStep) {
        if (state is PresentingSurveyState) {
          if (!session.beginAdvance()) return;
          try {
            await _handleNextStep(event, state as PresentingSurveyState);
          } finally {
            session.endAdvance();
          }
        }
      } else if (event is StepBack) {
        if (state is PresentingSurveyState) {
          if (!session.beginAdvance()) return;
          try {
            final newState = _handleStepBack(
              event,
              state as PresentingSurveyState,
            );
            updateState(newState);
            unawaited(
              navigatorKey.currentState?.pushReplacementNamed(
                '/',
                arguments: newState,
              ),
            );
          } finally {
            session.endAdvance();
          }
        }
      } else if (event is CloseSurvey) {
        if (state is PresentingSurveyState) {
          final newState = _handleClose(event, state as PresentingSurveyState);
          updateState(newState);
          navigatorKey.currentState?.pop();
        }
      }
    } catch (e, s) {
      // onEvent's Future is discarded at every dispatch site (survey_kit.dart,
      // step_view.dart, survey_app_bar.dart), so a throw past the first
      // suspension would become an unhandled ASYNC error and vanish — the exact
      // defect this phase removes from the navigator. Before 3b these throws
      // were synchronous and reached FlutterError.onError.
      SurveyKitLogger.e('SurveyKit failed to handle $event', e, s);
    }
  }

  Future<void> _handleNextStep(
    NextStep event,
    PresentingSurveyState currentState,
  ) async {
    _addResult(event.questionResult);

    // Feedback BEFORE the action, reversing the pre-3b order. Awaiting the
    // action first would stall the dialog behind (e.g.) PDF generation. Safe
    // because an action handler's writes are consumed by the NEXT step's
    // content, which renders after acknowledgement either way, and nothing
    // observes history in between: hasNextStep goes through peekNextStep, which
    // does not record, and SurveyProgress reads the state, not the navigator.
    await _showFeedbackIfAny(
      currentState.currentStep.answerFormat,
      event.questionResult,
    );

    final next = await taskNavigator.nextStep(
      step: currentState.currentStep,
      previousResults: results.toList(),
      questionResult: event.questionResult,
    );

    // CloseSurvey is deliberately NOT blocked while an advance is in flight, so
    // the state can have moved on across the two awaits above. Publishing now
    // would emit a PresentingSurveyState AFTER a terminal SurveyResultState on
    // the public stream, and push onto a popped route.
    if (!identical(state, currentState)) {
      return;
    }

    if (next == null) {
      final finished = _handleSurveyFinished(currentState);
      updateState(finished);
      unawaited(navigatorKey.currentState?.pushNamed('/', arguments: finished));
    } else {
      final presenting = _presentStep(next);
      updateState(presenting);
      unawaited(
        navigatorKey.currentState?.pushNamed('/', arguments: presenting),
      );
    }
  }

  /// Shows the feedback dialog for the two feedback answer formats and completes
  /// when it has been acknowledged. Completes immediately for every other
  /// format.
  Future<void> _showFeedbackIfAny(
    AnswerFormat? answerFormat,
    StepResult? questionResult,
  ) {
    if (answerFormat is SingleChoiceAnswerWithFeedbackFormat) {
      final selectedChoice = questionResult?.result as TextChoice?;
      final isCorrect = selectedChoice?.value == 'correct';
      return _showFeedbackDialog(
        message:
            (isCorrect
                ? answerFormat.feedbackCorrect
                : answerFormat.feedbackWrong) ??
            (isCorrect
                ? 'You selected the correct answer!'
                : 'You selected the incorrect answer!'),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        autoDismiss: isCorrect,
      );
    }

    if (answerFormat is MultipleChoiceAnswerWithFeedbackFormat) {
      final rawChoices = questionResult?.result;
      final selectedChoices = rawChoices is List<TextChoice>
          ? rawChoices
          : rawChoices is List
          ? rawChoices.map((item) {
              if (item is TextChoice) return item;
              if (item is Map<String, dynamic>) {
                return TextChoice.fromJson(item);
              }
              return TextChoice(text: item.toString(), value: item.toString());
            }).toList()
          : <TextChoice>[];

      final hasWrong = selectedChoices.any((choice) => choice.value == 'wrong');
      final colored = answerFormat.coloredFeedback;
      return _showFeedbackDialog(
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
      );
    }

    return Future<void>.value();
  }

  Future<SurveyState> _handleInitialStep() async {
    final step = taskNavigator.firstStep();
    if (step != null) {
      // Check if we need to recreate the history
      if (step.id != taskNavigator.task.steps.first.id) {
        var currentStep = taskNavigator.task.steps.first;
        Step? nextStepToVisit;
        SurveyKitLogger.d('Visiting steps starting from: ${currentStep.id}');
        while (currentStep.id != step.id) {
          final questionResult = _getResultByStepIdentifier(currentStep.id);
          try {
            nextStepToVisit = await taskNavigator.nextStep(
              step: currentStep,
              previousResults: results.toList(),
              questionResult: questionResult,
              trigger: ActionTrigger.replay,
            );
          } catch (e, s) {
            // A replay that cannot finish must not leave the survey on the
            // startup spinner forever: the inner Navigator renders
            // CircularProgressIndicator until the route arguments become a
            // PresentingSurveyState, and onEvent's Future is discarded by the
            // post-frame callback, so an escaping throw would be invisible.
            // Report and present the furthest step reached.
            SurveyKitLogger.e('Replay failed at step ${currentStep.id}', e, s);
            break;
          }

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

  StepResult? _getResultByStepIdentifier(String? identifier) =>
      identifier == null ? null : session.resultById(identifier);

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

  void _addResult(StepResult? questionResult) =>
      session.addResult(questionResult);

  int get countSteps => taskNavigator.countSteps;
  int currentStepIndex(Step step) {
    return taskNavigator.currentStepIndex(step);
  }

  /// Shows the answer feedback dialog and completes when it closes.
  ///
  /// The returned future is `showDialog`'s own, NOT a Completer resolved from
  /// the tap handler and the auto-dismiss timer. `barrierDismissible: false`
  /// disables the barrier TAP only; the Android hardware back button still pops
  /// the dialog route without running either. A Completer would therefore never
  /// complete on a back-dismissal — hanging this await forever and, once Task 4
  /// adds the re-entrancy guard, freezing the survey permanently. `showDialog`'s
  /// future completes on every dismissal path.
  Future<void> _showFeedbackDialog({
    required String message,
    required Color? backgroundColor,
    required bool autoDismiss,
  }) {
    final htmlStyle = <String, Style>{
      'p': Style(
        textAlign: TextAlign.center,
        fontWeight: FontWeight.bold,
        fontSize: FontSize(16.0),
      ),
      'ul': Style(fontSize: FontSize(16.0)),
    };

    final dialogClosed = showDialog<void>(
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
                    onPressed: () => Navigator.of(context).pop(),
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

    // Scheduled AFTER showDialog, preserving the pre-3b ordering. Scheduling it
    // before would start the timer before the route exists.
    //
    // The `closed` check is NOT belt-and-braces. On the autoDismiss branch
    // the dialog renders SizedBox.shrink() instead of a button, so the timer and
    // the hardware back button are its only two exits — and 3b promotes back
    // dismissal to a supported path. Without the check, a back press at t=0.5s
    // pops the dialog and advances the survey, and then at t=1.0s this pops
    // AGAIN, this time taking the host's own route with it.
    if (autoDismiss) {
      var closed = false;
      unawaited(dialogClosed.whenComplete(() => closed = true));
      unawaited(
        Future.delayed(const Duration(seconds: 1), () {
          if (closed) return;
          final context = navigatorKey.currentContext;
          if (context == null) return;
          Navigator.of(context, rootNavigator: true).pop();
        }),
      );
    }

    return dialogClosed;
  }
}
