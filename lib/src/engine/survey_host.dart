import 'package:flutter/foundation.dart';
import 'package:survey_kit/src/engine/survey_feedback.dart';
import 'package:survey_kit/src/model/result/survey_result.dart';
import 'package:survey_kit/src/presenter/survey_state.dart';

/// The widget-layer services [SurveyEngine] needs but cannot perform itself.
///
/// Implemented by `_SurveyKitState`, which owns the inner `Navigator`'s key and
/// outlives every rebuild of the tree.
///
/// Every method is called from inside a transition. Implementations must not
/// throw: `SurveyEngine.handleEvent` catches and reports, but a host that
/// throws turns a navigation into a logged failure.
///
/// **Implementations must never read `context` or `mounted`.** Every method
/// here can be called from a suspension that outlives the `State` — a
/// `Future`-returning action handler completing after `SurveyKit` unmounts is
/// the ordinary case, not the edge one. The contract is "deliver, or no-op
/// harmlessly", never "no-op if still mounted". Measured on `56473c4`: a
/// terminal advance suspended across an unmount DOES still fire `onResult`
/// today, and a `mounted` guard here would silently lose the user's answers.
@internal
abstract interface class SurveyHost {
  /// Presents [state] on a new route. Maps to `pushNamed`.
  void pushState(SurveyState state);

  /// Replaces the current route with [state]. Maps to
  /// `pushReplacementNamed`, and is used only for back-navigation.
  void replaceState(SurveyState state);

  /// Pops the survey's inner navigator. Maps to `pop()`.
  void popSurvey();

  /// Hands the finished or discarded result to the consumer's `onResult`.
  ///
  /// Resolved at call time, never captured: `SurveyKit.onResult` is re-read
  /// from `widget` on every build.
  void deliverResult(SurveyResult result);

  /// Shows [feedback] and completes when it has been acknowledged.
  ///
  /// The returned future MUST complete on **every** dismissal path, including
  /// the Android hardware back button. A resume tied only to the tap handler
  /// and the auto-dismiss timer freezes the survey permanently, because
  /// `barrierDismissible: false` blocks the barrier tap but not
  /// `ModalRoute.popDisposition`. (ADO #1040, review A1 — verified on device.)
  Future<void> showFeedback(SurveyFeedback feedback);
}
