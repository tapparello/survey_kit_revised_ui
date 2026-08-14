import 'package:flutter/foundation.dart';

/// The semantic outcome an answer-feedback dialog conveys.
///
/// The engine decides the tone; the widget layer decides what colour that is.
/// Deliberately not a `Color`: naming one here would drag `dart:ui` into the
/// engine and put a rendering decision inside the state machine.
@internal
enum FeedbackTone {
  /// Rendered green today.
  correct,

  /// Rendered red today.
  incorrect,

  /// Rendered with the ambient dialog background — the uncoloured
  /// MultipleChoiceAnswerWithFeedbackFormat case.
  ///
  /// Maps to a `null` background, NOT to a transparent one. The dialog derives
  /// its text colour from the background's nullness, so `Colors.transparent`
  /// would produce white text on the ambient surface — invisible, and green
  /// against the whole existing suite. See `survey_feedback_dialog.dart`.
  neutral,
}

/// A request to show the answer-feedback dialog, as pure data.
@internal
@immutable
class SurveyFeedback {
  const SurveyFeedback({
    required this.message,
    required this.tone,
    required this.autoDismiss,
  });

  final String message;
  final FeedbackTone tone;

  /// Closes itself after one second instead of showing a tappable button.
  final bool autoDismiss;
}
