import 'package:flutter/material.dart' hide Step;
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/survey_kit.dart';

part 'single_choice_answer_format.g.dart';

@JsonSerializable(explicitToJson: true)
class SingleChoiceAnswerFormat extends AnswerFormat {
  static const String type = 'single';

  final List<TextChoice> textChoices;
  final String? choicesFromVariable;
  final TextChoice? defaultSelection;
  final bool shuffleChoices;

  const SingleChoiceAnswerFormat({
    required this.textChoices,
    this.choicesFromVariable,
    this.defaultSelection,
    this.shuffleChoices = false,
    super.question,
    super.answerType = type,
  }) : super();

  factory SingleChoiceAnswerFormat.fromJson(Map<String, dynamic> json) =>
      _$SingleChoiceAnswerFormatFromJson(json);

  Map<String, dynamic> toJson() => _$SingleChoiceAnswerFormatToJson(this);

  @override
  Widget createView(Step step, StepResult? stepResult) {
    return SingleChoiceAnswerView(
      questionStep: step,
      result: stepResult,
    );
  }
}
