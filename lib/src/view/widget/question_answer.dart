// foundation.dart is imported for `@internal`: `flutter/material.dart` does NOT
// re-export it (widgets.dart re-exports only a filtered subset of foundation),
// so material alone does not compile. Verified in Task 1, which hit exactly this
// on survey_state_provider.dart. Do NOT use package:meta here — foundation is
// already a Flutter import in this file's dependency chain.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:survey_kit/src/view/widget/answer/answer_session.dart';
import 'package:survey_kit/survey_kit.dart';

class QuestionAnswer<R> extends InheritedWidget {
  @internal
  const QuestionAnswer({
    super.key,
    required super.child,
    required this.session,
  });

  final AnswerSession<R> session;

  // Delegations. All of these were mutable fields on this widget until ADO
  // #1033; they stay so no QuestionAnswer.of(context) call site changed.
  Step get step => session.step;
  DateTime get startTime => session.startTime;
  ValueNotifier<bool> get isValid => session.isValid;
  StepResult<R?>? get stepResult => session.stepResult;

  // ignore: avoid_positional_boolean_parameters
  void setIsValid(bool isValid) => session.setIsValid(isValid);
  void setStepResult(R? result) => session.setStepResult(result);

  static QuestionAnswer of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<QuestionAnswer>();
    if (result == null) {
      throw const SurveyKitScopeException(
        widgetType: 'QuestionAnswer',
        hint:
            'QuestionAnswer is only available inside an answer view build '
            'subtree, not anywhere under SurveyKit.',
      );
    }
    return result;
  }

  @override
  bool updateShouldNotify(QuestionAnswer oldWidget) =>
      session != oldWidget.session;
}
