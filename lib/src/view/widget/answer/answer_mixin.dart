import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survey_kit/src/model/answer/multi_double.dart';
import 'package:survey_kit/src/model/answer/text_choice.dart';
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

  void onLoad(R? result){
    onValidationChanged = isValid(result);
  }

  void onChange(R? result) {
    onValidationChanged = isValid(result);
    onStepResultChanged = result;
    if (result != null) {
      saveToSharedPreferences(result);
    }
  }

  Future<void> saveToSharedPreferences(R result) async {

    final prefs = await SharedPreferences.getInstance();
    final stepId = QuestionAnswer.of(context).step.id;

    switch (R){
      case TextChoice:
        final choice = (result as TextChoice).text;
        await prefs.setString(stepId, choice);
        break;
      case List<TextChoice>:
        final choices = (result as List<TextChoice>).map((choice) => choice.text).toList();
        await prefs.setStringList(stepId, choices);
        break;
      case List<MultiDouble>:
        final answers = (result as List<MultiDouble>).map((answer) => answer.value.toString()).toList();
        await prefs.setStringList(stepId, answers);
        break;
      default:
        await prefs.setString(stepId, result.toString());
    }
  }

  bool isValid(R? result);

  set onValidationChanged(bool isValid) {
    QuestionAnswer.of(context).setIsValid(isValid);
  }

  set onStepResultChanged(R? stepResult) {
    QuestionAnswer.of(context).setStepResult(stepResult);
  }
}
