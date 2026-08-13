import 'package:survey_kit/src/model/result/step_result.dart';

/// Why an action rule is firing.
enum ActionTrigger {
  /// The user advanced past the trigger step.
  advance,

  /// The survey is replaying a recorded path to reach a resumed step, because
  /// `initialStepId` points past the first step. No user interaction produced
  /// this fire.
  ///
  /// Handlers whose effect is a side effect — writing a PDF, inserting a row —
  /// should return early on this trigger. Handlers that populate a variable a
  /// later step renders must NOT, or the resumed step renders empty.
  replay,
}

/// What an [ActionHandler] is given when its rule fires.
///
/// Note this class is deliberately not `@immutable`: [variables] is the task's
/// live map and handlers are expected to write to it. The object's own fields
/// are final; the map it points at is not.
class ActionContext {
  const ActionContext({
    required this.actionId,
    required this.results,
    required this.variables,
    required this.trigger,
  });

  /// The `actionId` of the rule that fired.
  final String actionId;

  /// Results for steps on the path actually taken, pruned against
  /// `TaskNavigator.history` (ADO #969).
  final List<StepResult> results;

  /// The task's live variables map. Writes are visible to the next step.
  final Map<String, dynamic> variables;

  /// Whether this fire is a user advance or a resume replay.
  final ActionTrigger trigger;
}
