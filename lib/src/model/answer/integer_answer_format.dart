import 'package:flutter/material.dart' hide Step;
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/util/int_extension.dart';
import 'package:survey_kit/survey_kit.dart';

part 'integer_answer_format.g.dart';

@JsonSerializable()
class IntegerAnswerFormat extends AnswerFormat {
  final int? defaultValue;
  final String hint;
  final int min;
  final int max;

  const IntegerAnswerFormat({
    this.defaultValue,
    this.hint = '',
    this.min = minInt,
    this.max = maxInt,
    super.question,
  }) : super();

  @override
  @JsonKey(name: 'type', includeToJson: true, includeFromJson: false)
  AnswerFormatType get answerType => AnswerFormatType.integer;

  factory IntegerAnswerFormat.fromJson(Map<String, dynamic> json) =>
      _$IntegerAnswerFormatFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$IntegerAnswerFormatToJson(this);

  @override
  Widget createView(Step step, StepResult? stepResult) {
    return IntegerAnswerView(questionStep: step, result: stepResult);
  }
}
