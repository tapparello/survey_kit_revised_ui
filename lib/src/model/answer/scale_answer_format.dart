import 'package:flutter/material.dart' hide Step;
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/survey_kit.dart';

part 'scale_answer_format.g.dart';

@JsonSerializable()
class ScaleAnswerFormat extends AnswerFormat {
  static const String type = 'scale';

  final double maximumValue;
  final double minimumValue;
  final double defaultValue;
  final double step;
  final String maximumValueDescription;
  final String minimumValueDescription;
  final bool isVertical;
  final bool isAge;

  /// Optional inclusive lower bound of the *accepted* sub-range (a band within
  /// [minimumValue]..[maximumValue]). When null, the step is un-gated.
  final double? acceptedMinimumValue;

  /// Optional inclusive upper bound of the *accepted* sub-range. When null, the
  /// step is un-gated.
  final double? acceptedMaximumValue;

  const ScaleAnswerFormat({
    required this.maximumValue,
    required this.minimumValue,
    required this.defaultValue,
    required this.step,
    this.maximumValueDescription = '',
    this.minimumValueDescription = '',
    this.isVertical = false,
    this.isAge = false,
    this.acceptedMinimumValue,
    this.acceptedMaximumValue,
    super.question,
    super.answerType = type,
  }) : super();

  /// Whether [value] falls within the inclusive accepted sub-range, if one is
  /// configured. Returns true when no accepted range is set (either bound null)
  /// — preserving the un-gated default behavior for every existing scale step.
  bool isWithinAcceptedRange(double value) {
    final min = acceptedMinimumValue;
    final max = acceptedMaximumValue;
    if (min == null || max == null) return true;
    return value >= min && value <= max;
  }

  factory ScaleAnswerFormat.fromJson(Map<String, dynamic> json) => _$ScaleAnswerFormatFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ScaleAnswerFormatToJson(this);

  @override
  Widget createView(Step step, StepResult? stepResult) {
    return ScaleAnswerView(
      questionStep: step,
      result: stepResult,
    );
  }
}
