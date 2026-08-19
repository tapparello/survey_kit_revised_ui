import 'package:survey_kit/src/configuration/action_context.dart';
import 'package:survey_kit/src/configuration/content_renderer.dart';
import 'package:survey_kit/src/model/content/content.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';

/// Builds a custom [Content] from JSON.
///
/// [registries] is forwarded so a custom type can resolve nested content —
/// `Content.fromJson(json['child'], registries: registries)` — including other
/// custom types, to any depth.
///
/// The `{registries}` shape is not optional: Dart function subtyping tolerates
/// *extra* optional named parameters but not missing ones, so a plain
/// `Content Function(Map)` is not assignable to the registry-carrying type.
/// `ContentType.fromJson` already carries this signature for the same reason.
/// See ADO #1015.
typedef ContentFactory =
    Content Function(Map<String, dynamic> json, {SurveyRegistries? registries});

/// Builds a custom [Step] from JSON.
///
/// Carries [registries] for the same reason as [ContentFactory]: a custom step
/// parses its own `content` list and must be able to resolve custom types in it.
typedef StepFactory =
    Step Function(Map<String, dynamic> json, {SurveyRegistries? registries});

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

  /// Renderers for content types, consulted before the built-in table.
  ///
  /// Independent of [customContentTypes] rather than bundled with it: a parse
  /// site that never renders — a JSON validation test, or a resolver that only
  /// calls `Task.fromJson` — would otherwise have to supply a renderer it never
  /// invokes. The cost is that a registered type can lack a renderer, which
  /// `UnregisteredRendererException` reports.
  final Map<String, ContentRenderer> contentRenderers;

  const SurveyRegistries({
    this.customContentTypes = const {},
    this.customStepTypes = const {},
    this.customNavigationRules = const {},
    this.actionHandlers = const {},
    this.contentRenderers = const {},
  });

  Content? resolveContent(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) return null;
    final factory = customContentTypes[type];
    // Forwarding `this`, not a parameter, is what closes the loop: the factory
    // can call Content.fromJson on a child with the same registries, so nested
    // custom types resolve to any depth. The flip side: a factory that re-enters
    // Content.fromJson with the *same* json hits this same registry entry and
    // recurses without bound. A factory parses its children, not itself.
    return factory?.call(json, registries: this);
  }

  Step? resolveStep(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) return null;
    final factory = customStepTypes[type];
    // See resolveContent: forwarding `this` lets a factory parse its children
    // through the registry, but a factory that re-enters Step.fromJson with the
    // same json recurses without bound.
    return factory?.call(json, registries: this);
  }
}
