import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/presenter/survey_state.dart';

/// Mutable state for one run of a survey.
///
/// Owned by `_SurveyKitState`, which outlives every rebuild of the widget tree.
/// It exists because `SurveyStateProvider` is an `InheritedWidget` constructed
/// inside `build`: holding this state there meant a parent rebuild silently
/// reset the session and froze the survey. See ADO #1033.
///
/// Not exported. 3c is expected to absorb this into the engine or delete it.
@internal
class SurveySession {
  SurveySession({Set<StepResult>? initialResults})
      : results = Set<StepResult>.of(initialResults ?? const <StepResult>{}),
        startDate = DateTime.now();

  /// A copy, never the caller's collection: the session owns its own state, and
  /// aliasing meant `SurveyKit(initialResults: Set.unmodifiable(...))` threw on
  /// the first answer.
  final Set<StepResult> results;

  final DateTime startDate;

  final StreamController<SurveyState> stateStream =
      StreamController<SurveyState>.broadcast();

  SurveyState _state = LoadingSurveyState();
  SurveyState get state => _state;

  /// The `isClosed` guard is cheap defence, not a fix for a demonstrated path.
  /// Once [dispose] closes the controller a later `add` would throw, and
  /// `_showFeedbackDialog`'s auto-dismiss branch does resume across a 1s delay
  /// — but probing it crashes earlier on `navigatorKey.currentContext!`
  /// (`survey_state_provider.dart:402`), which is pre-existing and out of scope.
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

  StepResult? resultById(String id) =>
      results.firstWhereOrNull((element) => element.id == id);

  void dispose() => stateStream.close();
}
