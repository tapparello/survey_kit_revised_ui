// The recording host every engine test drives. There is no widget tree in this
// directory and `engine_purity_test.dart` enforces that.
import 'dart:async';

import 'package:survey_kit/src/engine/survey_engine.dart';
import 'package:survey_kit/src/engine/survey_feedback.dart';
import 'package:survey_kit/src/engine/survey_host.dart';
import 'package:survey_kit/survey_kit.dart';

/// Records every [SurveyHost] call, in dispatch order.
///
/// The ordered [calls] list is the point: several criteria are about WHEN a
/// host call happens relative to another, which a set of per-method lists
/// cannot express.
class FakeSurveyHost implements SurveyHost {
  /// Method names in dispatch order: 'pushState', 'replaceState', 'popSurvey',
  /// 'deliverResult', 'showFeedback'.
  final List<String> calls = <String>[];

  final List<SurveyState> pushed = <SurveyState>[];
  final List<SurveyState> replaced = <SurveyState>[];
  final List<SurveyResult> delivered = <SurveyResult>[];
  final List<SurveyFeedback> shownFeedback = <SurveyFeedback>[];
  int popCount = 0;

  /// When set, [showFeedback] returns this Completer's future instead of one
  /// that is already complete — which is what lets a test assert on what has
  /// and has not happened INSIDE the feedback window.
  Completer<void>? feedbackGate;

  @override
  void pushState(SurveyState state) {
    calls.add('pushState');
    pushed.add(state);
  }

  @override
  void replaceState(SurveyState state) {
    calls.add('replaceState');
    replaced.add(state);
  }

  @override
  void popSurvey() {
    calls.add('popSurvey');
    popCount++;
  }

  @override
  void deliverResult(SurveyResult result) {
    calls.add('deliverResult');
    delivered.add(result);
  }

  @override
  Future<void> showFeedback(SurveyFeedback feedback) {
    calls.add('showFeedback');
    shownFeedback.add(feedback);
    return feedbackGate?.future ?? Future<void>.value();
  }
}

/// Builds an engine over [task], with no widget tree anywhere.
SurveyEngine makeEngine({
  required Task task,
  required SurveyHost host,
  Set<StepResult>? initialResults,
  SurveyRegistries? registries,
  SurveyHandlerErrorCallback? onHandlerError,
}) => SurveyEngine(
  taskNavigator: NavigableTaskNavigator(
    task,
    registries: registries,
    onHandlerError: onHandlerError,
  ),
  host: host,
  initialResults: initialResults,
);

/// A two-step task with no answer formats: s1 then s2, ordered.
NavigableTask twoStepTask() => NavigableTask(
  id: 't',
  steps: [
    Step(
      id: 's1',
      content: const [TextContent(text: 'first')],
    ),
    Step(
      id: 's2',
      content: const [TextContent(text: 'second')],
    ),
  ],
);
