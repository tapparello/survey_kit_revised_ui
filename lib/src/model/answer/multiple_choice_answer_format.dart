import 'package:flutter/material.dart' hide Step;
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/survey_kit.dart';

part 'multiple_choice_answer_format.g.dart';

@JsonSerializable()
class MultipleChoiceAnswerFormat extends AnswerFormat {
  static const String type = 'multi';

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
  @JsonKey(defaultValue: false)
  final bool otherField;
  final String? otherHintText;

  const MultipleChoiceAnswerFormat({
    required this.textChoices,
    this.choicesFromVariable,
    this.otherField = false,
    this.defaultSelection,
    this.shuffleChoices = false,
    this.minRequiredChoices = 1,
    this.maxAllowedChoices = 999,
    this.maxAllowedChoicesErrorMessage,
    this.noneOption = false,
    this.noneOptionText,
    this.otherHintText,
    super.question,
  }) : super();

  @override
  @JsonKey(name: 'type', includeToJson: true, includeFromJson: false)
  String get answerType => type;

  factory MultipleChoiceAnswerFormat.fromJson(Map<String, dynamic> json) =>
      _$MultipleChoiceAnswerFormatFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MultipleChoiceAnswerFormatToJson(this);

  @override
  Widget createView(Step step, StepResult? stepResult) {
    return MultipleChoiceAnswerView(questionStep: step, result: stepResult);
  }
}
