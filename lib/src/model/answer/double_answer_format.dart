// by Antonio Bruno, Giacomo Ignesti and Massimo Martinelli

import 'package:flutter/material.dart' hide Step;
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/answer/answer_format.dart';
import 'package:survey_kit/src/model/answer/answer_format_type.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/view/widget/answer/double_answer_view.dart';

part 'double_answer_format.g.dart';

@JsonSerializable()
class DoubleAnswerFormat extends AnswerFormat {
  final double? defaultValue;
  final String hint;

  const DoubleAnswerFormat({this.defaultValue, this.hint = '', super.question})
    : super();

  @override
  @JsonKey(name: 'type', includeToJson: true, includeFromJson: false)
  AnswerFormatType get answerType => AnswerFormatType.doubleValue;

  factory DoubleAnswerFormat.fromJson(Map<String, dynamic> json) =>
      _$DoubleAnswerFormatFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DoubleAnswerFormatToJson(this);

  @override
  Widget createView(Step step, StepResult? stepResult) {
    return DoubleAnswerView(questionStep: step, result: stepResult);
  }
}
