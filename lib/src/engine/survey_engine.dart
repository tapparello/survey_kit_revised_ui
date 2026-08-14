import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:survey_kit/src/configuration/action_context.dart';
import 'package:survey_kit/src/engine/survey_feedback.dart';
import 'package:survey_kit/src/engine/survey_host.dart';
import 'package:survey_kit/src/model/answer/answer_format.dart';
import 'package:survey_kit/src/model/answer/multiple_choice_answer_with_feedback_format.dart';
import 'package:survey_kit/src/model/answer/single_choice_answer_with_feedback_format.dart';
import 'package:survey_kit/src/model/answer/text_choice.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/result/survey_result.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/navigator/task_navigator.dart';
import 'package:survey_kit/src/presenter/survey_event.dart';
import 'package:survey_kit/src/presenter/survey_state.dart';
import 'package:survey_kit/src/util/survey_kit_logger.dart';

/// The survey state machine, and the mutable state for one run of a survey.
///
/// Owned by `_SurveyKitState`, which outlives every rebuild of the widget tree
/// and implements [SurveyHost] on its behalf. It exists outside the widget
/// layer so the machine can be driven and asserted on without pumping a tree.
///
/// Absorbs the whole of the former `SurveySession` (ADO #1033) — holding that
/// state on `SurveyStateProvider`, an `InheritedWidget` constructed inside
/// `build`, meant a parent rebuild silently reset the run and froze the survey.
///
/// Not exported. (ADO #1041)
@internal
class SurveyEngine {
  SurveyEngine({
    required this.taskNavigator,
    required SurveyHost host,
    Set<StepResult>? initialResults,
  }) : _host = host,
       results = Set<StepResult>.of(initialResults ?? const <StepResult>{}),
       startDate = DateTime.now();

  final TaskNavigator taskNavigator;

  final SurveyHost _host;

  /// A copy, never the caller's collection: the engine owns its own state, and
  /// aliasing meant `SurveyKit(initialResults: Set.unmodifiable(...))` threw on
  /// the first answer.
  final Set<StepResult> results;

  final DateTime startDate;

  final StreamController<SurveyState> stateStream =
      StreamController<SurveyState>.broadcast();

  SurveyState _state = LoadingSurveyState();
  SurveyState get state => _state;

  /// The `isClosed` guard is cheap defence, not a fix for a demonstrated path.
  /// Once [dispose] closes the controller a later `add` would throw, and the
  /// feedback dialog's auto-dismiss branch does resume across a 1s delay — but
  /// probing it crashes earlier on `navigatorKey.currentContext!`
  /// (`survey_feedback_dialog.dart`), which is pre-existing and out of scope.
  void updateState(SurveyState newState) {
    _state = newState;
    if (!stateStream.isClosed) {
      stateStream.add(_state);
    }
  }

  void addResult(StepResult? questionResult) {
    if (questionResult == null) {
      return;
    }
    results
      ..removeWhere((StepResult result) => result.id == questionResult.id)
      ..add(questionResult);
  }

  /// [id] is nullable because this absorbed the null guard from the former
  /// `_getResultByStepIdentifier` wrapper. Every internal call site passes a
  /// non-null `Step.id`; the guard is preserved rather than removed because
  /// removing it would be a behaviour change, not a simplification.
  StepResult? resultById(String? id) => id == null
      ? null
      : results.firstWhereOrNull((element) => element.id == id);

  /// True while an advance is in flight.
  ///
  /// `StepView` disables its Next button off this, and [handleEvent] ignores
  /// StartSurvey/NextStep/StepBack while it is set. CloseSurvey is deliberately
  /// NOT guarded.
  final ValueNotifier<bool> isAdvancing = ValueNotifier<bool>(false);

  bool _disposed = false;

  /// Sets [isAdvancing]. Returns false if an advance is already in flight, in
  /// which case the caller must not proceed.
  bool beginAdvance() {
    if (_disposed || isAdvancing.value) return false;
    isAdvancing.value = true;
    return true;
  }

  /// Clears [isAdvancing]. No-ops after [dispose].
  ///
  /// The guard is not defensive tidiness: this runs in a `finally` that can
  /// execute after `SurveyKit` unmounts, and `ValueNotifier`'s value setter
  /// calls `notifyListeners()`, which asserts the notifier is not disposed.
  void endAdvance() {
    if (_disposed) return;
    isAdvancing.value = false;
  }

  void dispose() {
    _disposed = true;
    isAdvancing.dispose();
    stateStream.close();
  }

  int get countSteps => taskNavigator.countSteps;
  int currentStepIndex(Step step) {
    return taskNavigator.currentStepIndex(step);
  }

  Future<void> handleEvent(SurveyEvent event) async {
    try {
      if (event is StartSurvey) {
        if (!beginAdvance()) return;
        try {
          final newState = await _handleInitialStep();
          updateState(newState);
          _host.pushState(newState);
        } finally {
          endAdvance();
        }
      } else if (event is NextStep) {
        if (state is PresentingSurveyState) {
          if (!beginAdvance()) return;
          try {
            await _handleNextStep(event, state as PresentingSurveyState);
          } finally {
            endAdvance();
          }
        }
      } else if (event is StepBack) {
        if (state is PresentingSurveyState) {
          if (!beginAdvance()) return;
          try {
            final newState = _handleStepBack(
              event,
              state as PresentingSurveyState,
            );
            updateState(newState);
            _host.replaceState(newState);
          } finally {
            endAdvance();
          }
        }
      } else if (event is CloseSurvey) {
        if (state is PresentingSurveyState) {
          final newState = _handleClose(event, state as PresentingSurveyState);
          updateState(newState);
          _host.popSurvey();
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
    addResult(event.questionResult);

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
      _host.pushState(finished);
    } else {
      final presenting = _presentStep(next);
      updateState(presenting);
      _host.pushState(presenting);
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
      return _host.showFeedback(
        SurveyFeedback(
          message:
              (isCorrect
                  ? answerFormat.feedbackCorrect
                  : answerFormat.feedbackWrong) ??
              (isCorrect
                  ? 'You selected the correct answer!'
                  : 'You selected the incorrect answer!'),
          tone: isCorrect ? FeedbackTone.correct : FeedbackTone.incorrect,
          autoDismiss: isCorrect,
        ),
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
      return _host.showFeedback(
        SurveyFeedback(
          message:
              (hasWrong
                  ? answerFormat.feedbackWrong
                  : answerFormat.feedbackCorrect) ??
              (hasWrong
                  ? 'You selected the incorrect answers!'
                  : 'You selected the correct answers!'),
          tone: colored
              ? (hasWrong ? FeedbackTone.incorrect : FeedbackTone.correct)
              : FeedbackTone.neutral,
          // Auto-dismiss only the all-correct coloured case (matches prior
          // behaviour); every other case shows a tappable "Next" button.
          autoDismiss: colored && !hasWrong,
        ),
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
          final questionResult = resultById(currentStep.id);
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

      final questionResult = resultById(step.id);

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
    final questionResult = resultById(nextStep.id);

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
    addResult(event.questionResult);
    final previousStep = taskNavigator.previousInList(currentState.currentStep);

    SurveyKitLogger.d('Ready to visit previous step: ${previousStep?.id}');
    //If theres no previous step we can't go back further
    if (previousStep != null) {
      final questionResult = resultById(previousStep.id);

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

  SurveyState _handleClose(
    CloseSurvey event,
    PresentingSurveyState currentState,
  ) {
    addResult(event.questionResult);

    final stepResults = results.map((e) => e).toList();

    final taskResult = SurveyResult(
      id: taskNavigator.task.id,
      startTime: startDate,
      endTime: DateTime.now(),
      finishReason: FinishReason.discarded,
      results: stepResults,
      lastShownStepId: currentState.currentStep.id,
    );
    _host.deliverResult(taskResult);
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

    _host.deliverResult(taskResult);
    return SurveyResultState(
      result: taskResult,
      currentStep: currentState.currentStep,
      stepResult: currentState.result,
    );
  }
}
