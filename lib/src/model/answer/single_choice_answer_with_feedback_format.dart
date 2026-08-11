import 'package:flutter/material.dart' hide Step;
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/survey_kit.dart';

part 'single_choice_answer_with_feedback_format.g.dart';

@JsonSerializable()
class SingleChoiceAnswerWithFeedbackFormat extends AnswerFormat {
  final List<TextChoice> textChoices;
  final TextChoice? defaultSelection;
  final bool shuffleChoices;
  final String? feedbackCorrect;
  final String? feedbackWrong;

  const SingleChoiceAnswerWithFeedbackFormat({
    required this.textChoices,
    this.feedbackCorrect,
    this.feedbackWrong,
    this.defaultSelection,
    this.shuffleChoices = false,
    super.question,
  }) : super();

  @override
  @JsonKey(name: 'type', includeToJson: true, includeFromJson: false)
  AnswerFormatType get answerType => AnswerFormatType.singleWithFeedback;

  factory SingleChoiceAnswerWithFeedbackFormat.fromJson(
    Map<String, dynamic> json,
  ) => _$SingleChoiceAnswerWithFeedbackFormatFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$SingleChoiceAnswerWithFeedbackFormatToJson(this);

  @override
  Widget createView(Step step, StepResult? stepResult) {
    return SingleChoiceAnswerWithFeedbackView(
      questionStep: step,
      result: stepResult,
    );
  }
}
