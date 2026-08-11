import 'package:flutter/material.dart' hide Step;
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/survey_kit.dart';

part 'scale_answer_format.g.dart';

@JsonSerializable()
class ScaleAnswerFormat extends AnswerFormat {
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

  /// The localizable bands driving the vertical slider tooltip and static
  /// labels. Empty when not configured (e.g. horizontal sliders).
  final List<ScaleBand> bands;

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
    this.bands = const [],
    super.question,
  }) : super();

  @override
  @JsonKey(name: 'type', includeToJson: true, includeFromJson: false)
  AnswerFormatType get answerType => AnswerFormatType.scale;

  /// Whether a complete accepted sub-range is configured (both bounds set).
  bool get hasAcceptedRange =>
      acceptedMinimumValue != null && acceptedMaximumValue != null;

  /// Whether [value] falls within the inclusive accepted sub-range, if one is
  /// configured. Returns true when no accepted range is set (either bound null)
  /// — preserving the un-gated default behavior for every existing scale step.
  ///
  /// Bounds must satisfy `acceptedMinimumValue <= acceptedMaximumValue`; an
  /// inverted range matches no value (the step can never be satisfied).
  bool isWithinAcceptedRange(double value) {
    final min = acceptedMinimumValue;
    final max = acceptedMaximumValue;
    if (min == null || max == null) return true;
    return value >= min && value <= max;
  }

  /// The band name to show in the tooltip for [value], or null if no band
  /// covers it (including when [bands] is empty).
  String? tooltipName(double value) {
    for (final band in bands) {
      if (value >= band.min && value <= band.max) return band.name;
    }
    return null;
  }

  /// The static-label name for [value] — only the band whose [labelAt] tick
  /// matches (within a 0.5 tolerance) shows its name; null otherwise.
  String? labelName(double value) {
    for (final band in bands) {
      if ((value - band.labelAt).abs() < 0.5) return band.name;
    }
    return null;
  }

  factory ScaleAnswerFormat.fromJson(Map<String, dynamic> json) =>
      _$ScaleAnswerFormatFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ScaleAnswerFormatToJson(this);

  @override
  Widget createView(Step step, StepResult? stepResult) {
    return ScaleAnswerView(questionStep: step, result: stepResult);
  }
}
