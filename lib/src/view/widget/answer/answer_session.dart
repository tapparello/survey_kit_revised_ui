// `package:flutter/foundation.dart` re-exports `@internal`, so importing
// package:meta here as well would trip `unnecessary_import`.
import 'package:flutter/foundation.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';

/// Mutable state for the answer being given to one step.
///
/// Owned by `_AnswerViewState`, which survives a parent rebuild. It exists
/// because `QuestionAnswer` is an `InheritedWidget` rebuilt inside
/// `_AnswerViewState.build`: holding the answer there meant any notification
/// from `SurveyStateProvider` silently discarded it, while the answer view's own
/// `State` kept rendering it as selected. See ADO #1033.
///
/// Not exported.
@internal
class AnswerSession<R> {
  AnswerSession({required this.step}) : startTime = DateTime.now();

  final Step step;
  final DateTime startTime;
  final ValueNotifier<bool> isValid = ValueNotifier<bool>(true);

  StepResult<R?>? _stepResult;
  StepResult<R?>? get stepResult => _stepResult;

  // ignore: avoid_positional_boolean_parameters, use_setters_to_change_properties
  void setIsValid(bool value) => isValid.value = value;

  void setStepResult(R? result) {
    _stepResult = StepResult<R>(
      id: step.id,
      answerType: step.answerFormat?.answerType,
      result: result,
      startTime: startTime,
      endTime: DateTime.now(),
    );
  }

  void dispose() => isValid.dispose();
}
