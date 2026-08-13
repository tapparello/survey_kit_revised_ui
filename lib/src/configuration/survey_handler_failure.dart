import 'package:survey_kit/src/configuration/action_context.dart';

/// Which registry the failing handler came from.
enum SurveyHandlerKind {
  /// An `ActionHandler` from `SurveyRegistries.actionHandlers`, or a rule
  /// naming an action id with no registered handler.
  action,

  /// A `NavigationRuleHandler` from `SurveyRegistries.customNavigationRules`.
  navigationRule,
}

/// A consumer-registered handler failed while the survey was navigating.
class SurveyHandlerFailure {
  const SurveyHandlerFailure({
    required this.kind,
    required this.handlerId,
    required this.error,
    required this.stackTrace,
    this.trigger,
  });

  final SurveyHandlerKind kind;

  /// `actionId` for [SurveyHandlerKind.action], `ruleId` for
  /// [SurveyHandlerKind.navigationRule].
  final String handlerId;

  final Object error;
  final StackTrace stackTrace;

  /// Non-null only when [kind] is [SurveyHandlerKind.action]. Present because
  /// "the PDF failed while resuming" and "the PDF failed when the user tapped
  /// Next" warrant different responses.
  final ActionTrigger? trigger;
}

/// Reports a handler failure. Navigation proceeds either way: an action rule
/// advances to its `nextStepIdentifier`, a failed navigation rule falls back to
/// the next step in the list.
///
/// Must not throw and must not be `async`. It is invoked from inside the
/// navigator's own failure path, and a throwing or fire-and-forget reporter
/// would recreate the swallow this callback exists to remove.
typedef SurveyHandlerErrorCallback =
    void Function(SurveyHandlerFailure failure);
