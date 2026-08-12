import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:survey_kit/src/util/survey_kit_logger.dart';
import 'package:survey_kit/src/view/widget/question_answer.dart';

mixin AnswerMixin<T extends StatefulWidget, R> on State<T> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      //onChange(QuestionAnswer.of(context).stepResult?.result as R?);
      onLoad(QuestionAnswer.of(context).stepResult?.result as R?);
    });
  }

  void onLoad(R? result) {
    onValidationChanged = isValid(result);
    SurveyKitLogger.d('onLoad - ${isValid(result)} - $result');
  }

  void onChange(R? result) {
    onValidationChanged = isValid(result);
    onStepResultChanged = result;
  }

  bool isValid(R? result);

  set onValidationChanged(bool isValid) {
    if (!mounted) return;
    SurveyKitLogger.d('onValidationChanged - $isValid');
    QuestionAnswer.of(context).setIsValid(isValid);
  }

  set onStepResultChanged(R? stepResult) {
    if (!mounted) return;
    QuestionAnswer.of(context).setStepResult(stepResult);
  }
}
