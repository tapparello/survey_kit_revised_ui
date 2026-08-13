import 'package:collection/collection.dart';
import 'package:survey_kit/src/configuration/action_context.dart';
import 'package:survey_kit/src/configuration/survey_handler_failure.dart';
import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/exception/survey_kit_exception.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/navigator/rules/action_navigation_rule.dart';
import 'package:survey_kit/src/navigator/rules/conditional_navigation_rule.dart';
import 'package:survey_kit/src/navigator/rules/custom_navigation_rule.dart';
import 'package:survey_kit/src/navigator/rules/direct_navigation_rule.dart';
import 'package:survey_kit/src/navigator/rules/navigation_rule.dart';
import 'package:survey_kit/src/navigator/task_navigator.dart';
import 'package:survey_kit/src/task/navigable_task.dart';
import 'package:survey_kit/src/task/task.dart';
import 'package:survey_kit/src/util/survey_kit_logger.dart';

class NavigableTaskNavigator extends TaskNavigator {
  final SurveyRegistries? _registries;
  final SurveyHandlerErrorCallback? _onHandlerError;

  NavigableTaskNavigator(
    Task task, {
    SurveyRegistries? registries,
    SurveyHandlerErrorCallback? onHandlerError,
  }) : _registries = registries,
       _onHandlerError = onHandlerError,
       super(task) {
    _init();
  }

  void _init() {
    SurveyKitLogger.d('NavigableTaskNavigator');
  }

  @override
  Future<Step?> nextStep({
    required Step step,
    required List<StepResult> previousResults,
    StepResult? questionResult,
    ActionTrigger trigger = ActionTrigger.advance,
  }) async {
    record(step);
    final rule = (task as NavigableTask).getRuleByStepIdentifier(step.id);
    if (rule is ActionNavigationRule) {
      await _fireAction(rule, previousResults, trigger);
      return _destinationOf(rule);
    }
    return _resolveWithoutAction(step, rule, previousResults, questionResult);
  }

  @override
  Step? peekNextStep({
    required Step step,
    required List<StepResult> previousResults,
    StepResult? questionResult,
  }) {
    final rule = (task as NavigableTask).getRuleByStepIdentifier(step.id);
    // An ActionNavigationRule's destination is a literal, so the probe can
    // answer it without firing. The other rule families' destinations are not.
    if (rule is ActionNavigationRule) {
      return _destinationOf(rule);
    }
    return _resolveWithoutAction(step, rule, previousResults, questionResult);
  }

  /// Every rule family except [ActionNavigationRule]. Shared by the advance and
  /// the probe, because these arms behave identically in both.
  Step? _resolveWithoutAction(
    Step step,
    NavigationRule? rule,
    List<StepResult> previousResults,
    StepResult? questionResult,
  ) {
    if (rule == null) {
      return nextInList(step);
    }
    if (rule is DirectNavigationRule) {
      return task.steps.firstWhereOrNull(
        (e) => e.id == rule.destinationStepIdentifier,
      );
    }
    if (rule is ConditionalNavigationRule) {
      return evaluateNextStep(step, rule, previousResults, questionResult);
    }
    if (rule is CustomNavigationRule) {
      return _evaluateCustomRule(step, rule, previousResults, questionResult);
    }
    return nextInList(step);
  }

  Step? _destinationOf(ActionNavigationRule rule) {
    if (rule.nextStepIdentifier == 'end_task') return null;
    return task.steps.firstWhereOrNull((s) => s.id == rule.nextStepIdentifier);
  }

  /// Reports and returns. Never rethrows: every caller's contract is to keep
  /// navigating.
  void _report(
    SurveyHandlerKind kind,
    String handlerId,
    Object error,
    StackTrace stackTrace, {
    ActionTrigger? trigger,
  }) {
    final failure = SurveyHandlerFailure(
      kind: kind,
      handlerId: handlerId,
      error: error,
      stackTrace: stackTrace,
      trigger: trigger,
    );
    final callback = _onHandlerError;
    if (callback == null) {
      SurveyKitLogger.e(
        '${kind.name} handler "$handlerId" failed',
        error,
        stackTrace,
      );
      return;
    }
    callback(failure);
  }

  Future<void> _fireAction(
    ActionNavigationRule rule,
    List<StepResult> previousResults,
    ActionTrigger trigger,
  ) async {
    final handler = _registries?.actionHandlers[rule.actionId];
    if (handler == null) {
      // Nothing threw, so there is no captured trace.
      _report(
        SurveyHandlerKind.action,
        rule.actionId,
        UnregisteredActionException(actionId: rule.actionId),
        StackTrace.current,
        trigger: trigger,
      );
      return;
    }
    // ADO #969: action handlers (e.g. exercise-PDF generation) aggregate step
    // results. The action fires mid-survey, before completion pruning, so feed
    // the handler only results for steps on the path actually taken (history) —
    // otherwise answers seeded from a prior run for off-path steps leak into
    // the PDF. Routing uses rule.nextStepIdentifier (fixed), so pruning the
    // handler's input cannot change navigation.
    final visitedStepIds = history.map((s) => s.id).toSet();
    final onPathResults = previousResults
        .where((r) => visitedStepIds.contains(r.id))
        .toList();
    try {
      await handler(
        ActionContext(
          actionId: rule.actionId,
          results: onPathResults,
          variables: task.variables,
          trigger: trigger,
        ),
      );
    } catch (e, s) {
      // Report and advance. The destination is rule.nextStepIdentifier
      // regardless of the handler's outcome, and halting would strand the user
      // on a step whose Next keeps failing with no retry affordance.
      //
      // The bare `catch` now covers the handler's whole async body, Errors
      // included — deliberately. An action handler is consumer code running
      // mid-navigation, and letting an Error escape puts the survey back in the
      // frozen state ADO #1033 removed.
      _report(SurveyHandlerKind.action, rule.actionId, e, s, trigger: trigger);
    }
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
    final nextStepIdentifier = rule.resultToStepIdentifierMapper(
      previousResults,
      questionResult,
    );
    if (nextStepIdentifier == null) {
      return nextInList(step);
    }

    if (nextStepIdentifier == 'end_task') {
      return null;
    }

    return task.steps.firstWhereOrNull(
      (element) => element.id == nextStepIdentifier,
    );
  }

  Step? _evaluateCustomRule(
    Step step,
    CustomNavigationRule rule,
    List<StepResult> previousResults,
    StepResult? questionResult,
  ) {
    final handler = _registries?.customNavigationRules[rule.ruleId];
    if (handler == null) {
      SurveyKitLogger.d(
        'No handler registered for custom rule: ${rule.ruleId}',
      );
      return nextInList(step);
    }
    task.variables['_currentStepId'] = step.id;
    final String? nextStepId;
    try {
      nextStepId = handler(previousResults, questionResult, task.variables);
    } catch (e, s) {
      _report(SurveyHandlerKind.navigationRule, rule.ruleId, e, s);
      return nextInList(step);
    }
    if (nextStepId == 'end_task') return null;
    return task.steps.firstWhereOrNull((s) => s.id == nextStepId);
  }

  @override
  Step? firstStep() {
    final previousStep = peekHistory();

    // peekNextStep, not nextStep: previousStep IS history.last, so advancing
    // would record it a second time and corrupt currentStepIndex (which uses
    // history.length when task.stepCount is set), and would re-fire an action
    // the user has already passed. Unreachable through SurveyKit's own dispatch
    // — history is empty when StartSurvey fires — but reachable by a consumer
    // dispatching StartSurvey twice, since SurveyEvent and onEvent are exported.
    return previousStep == null
        ? task.initialStep ?? task.steps.first
        : peekNextStep(step: previousStep, previousResults: const []);
  }
}
