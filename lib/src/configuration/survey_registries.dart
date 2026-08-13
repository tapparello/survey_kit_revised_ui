import 'package:survey_kit/src/configuration/action_context.dart';
import 'package:survey_kit/src/model/content/content.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';

typedef ContentFactory = Content Function(Map<String, dynamic> json);
typedef StepFactory = Step Function(Map<String, dynamic> json);

/// A handler for a [CustomNavigationRule], returning the id of the next step
/// (or `'end_task'`).
///
/// **This is invoked for read-only probes as well as real advances.**
/// `StepView` calls `hasNextStep` on every render to choose between the Next
/// and Done labels, and that goes through `TaskNavigator.peekNextStep`, which
/// must evaluate this handler because calling it is the only way to learn where
/// the rule leads. On a probe, `currentResult` is **null** and
/// `variables['_currentStepId']` holds the step being probed.
///
/// A handler must therefore be safe to re-run many times per step render, and
/// must not perform side effects beyond deriving variables. If it throws, the
/// failure is reported through `SurveyKit.onHandlerError` and navigation falls
/// back to the next step in the list.
typedef NavigationRuleHandler =
    String Function(
      List<StepResult> results,
      StepResult? currentResult,
      Map<String, dynamic> variables,
    );

/// A handler for an [ActionNavigationRule].
///
/// The returned future is what SurveyKit awaits: the survey does not present
/// the next step until it completes. A handler that starts asynchronous work
/// without returning its future is not awaited.
///
/// `Future<void>` rather than `FutureOr<void>` deliberately. `void` is a top
/// type in Dart, so `FutureOr<void>` would accept a statement-bodied handler
/// that returns null — and `await null` resolves instantly, so the
/// fire-and-forget defect this phase removes would survive the typedef change
/// silently. A handler with no asynchronous work is written `(ctx) async {}`.
typedef ActionHandler = Future<void> Function(ActionContext context);

class SurveyRegistries {
  final Map<String, ContentFactory> customContentTypes;
  final Map<String, StepFactory> customStepTypes;
  final Map<String, NavigationRuleHandler> customNavigationRules;
  final Map<String, ActionHandler> actionHandlers;

  const SurveyRegistries({
    this.customContentTypes = const {},
    this.customStepTypes = const {},
    this.customNavigationRules = const {},
    this.actionHandlers = const {},
  });

  Content? resolveContent(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) return null;
    final factory = customContentTypes[type];
    return factory?.call(json);
  }

  Step? resolveStep(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) return null;
    final factory = customStepTypes[type];
    return factory?.call(json);
  }
}
