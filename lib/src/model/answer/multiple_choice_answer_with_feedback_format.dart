import 'package:flutter/material.dart' hide Step;
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/survey_kit.dart';

part 'multiple_choice_answer_with_feedback_format.g.dart';

@JsonSerializable()
class MultipleChoiceAnswerWithFeedbackFormat extends AnswerFormat  {
  static const String type = 'multi_with_feedback';

  final List<TextChoice> textChoices;
  final TextChoice? defaultSelection;
  final String? choicesFromVariable;
  final int minRequiredChoices;
  final int maxAllowedChoices;
  final String? maxAllowedChoicesErrorMessage;
  final bool shuffleChoices;
  @JsonKey(defaultValue: false)
  final bool noneOption;
  final String? noneOptionText;
  final String? feedbackCorrect;
  final String? feedbackWrong;
  @JsonKey(defaultValue: false)
  final bool coloredFeedback;

  const MultipleChoiceAnswerWithFeedbackFormat({
    required this.textChoices,
    this.feedbackCorrect,
    this.feedbackWrong,
    this.coloredFeedback = false,
    this.choicesFromVariable,
    this.defaultSelection,
    this.shuffleChoices = false,
    this.minRequiredChoices = 1,
    this.maxAllowedChoices = 999,
    this.maxAllowedChoicesErrorMessage,
    this.noneOption = false,
    this.noneOptionText,
    super.question,
    super.answerType = type,
  }) : super();

  factory MultipleChoiceAnswerWithFeedbackFormat.fromJson(Map<String, dynamic> json) =>
      _$MultipleChoiceAnswerWithFeedbackFormatFromJson(json);

  Map<String, dynamic> toJson() => _$MultipleChoiceAnswerWithFeedbackFormatToJson(this);

  @override
  Widget createView(Step step, StepResult? stepResult) {
    return MultipleChoiceAnswerWithFeedbackView(
      questionStep: step,
      result: stepResult,
    );
  }
}
