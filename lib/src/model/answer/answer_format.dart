import 'package:flutter/material.dart' hide Step;
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/exception/survey_kit_exception.dart';
import 'package:survey_kit/src/model/answer/boolean_answer_format.dart';
import 'package:survey_kit/src/model/answer/date_answer_format.dart';
import 'package:survey_kit/src/model/answer/double_answer_format.dart';
import 'package:survey_kit/src/model/answer/image_answer_format.dart';
import 'package:survey_kit/src/model/answer/integer_answer_format.dart';
import 'package:survey_kit/src/model/answer/multiple_choice_answer_format.dart';
import 'package:survey_kit/src/model/answer/multiple_choice_answer_with_feedback_format.dart';
import 'package:survey_kit/src/model/answer/multiple_choice_auto_complete_answer_format.dart';
import 'package:survey_kit/src/model/answer/multiple_double_answer_format.dart';
import 'package:survey_kit/src/model/answer/scale_answer_format.dart';
import 'package:survey_kit/src/model/answer/single_choice_answer_format.dart';
import 'package:survey_kit/src/model/answer/single_choice_answer_with_feedback_format.dart';
import 'package:survey_kit/src/model/answer/text_answer_format.dart';
import 'package:survey_kit/src/model/answer/time_answer_format.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';

abstract class AnswerFormat {
  const AnswerFormat({this.question});

  final String? question;

  /// JSON discriminator identifying this format, e.g. `'time'`.
  ///
  /// Write-only by design: the discriminator is consumed by the dispatching
  /// [AnswerFormat.fromJson] factory below and is never assigned from JSON.
  /// Removing includeToJson silently drops 'type' from every subclass's
  /// generated toJson; removing includeFromJson makes codegen emit an
  /// out-of-scope subclass constant that will not compile. See ADO #1001.
  ///
  /// A getter rather than a constructor parameter so a caller cannot construct
  /// one format while declaring another: [StepResult] dispatches result
  /// conversion on this value, so a mismatch would convert with the wrong
  /// branch in both directions. Each subclass must repeat the [JsonKey]
  /// annotation on its override, or json_serializable drops the key. (ADO #1012)
  @JsonKey(name: 'type', includeToJson: true, includeFromJson: false)
  String? get answerType;

  Map<String, dynamic> toJson();

  Widget createView(Step step, StepResult? stepResult);

  factory AnswerFormat.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;

    switch (type) {
      case MultipleChoiceAnswerFormat.type:
        return MultipleChoiceAnswerFormat.fromJson(json);
      case MultipleChoiceAnswerWithFeedbackFormat.type:
        return MultipleChoiceAnswerWithFeedbackFormat.fromJson(json);
      case SingleChoiceAnswerFormat.type:
        return SingleChoiceAnswerFormat.fromJson(json);
      case SingleChoiceAnswerWithFeedbackFormat.type:
        return SingleChoiceAnswerWithFeedbackFormat.fromJson(json);
      case BooleanAnswerFormat.type:
        return BooleanAnswerFormat.fromJson(json);
      case DateAnswerFormat.type:
        return DateAnswerFormat.fromJson(json);
      case DoubleAnswerFormat.type:
        return DoubleAnswerFormat.fromJson(json);
      case IntegerAnswerFormat.type:
        return IntegerAnswerFormat.fromJson(json);
      case ImageAnswerFormat.type:
        return ImageAnswerFormat.fromJson(json);
      case TextAnswerFormat.type:
        return TextAnswerFormat.fromJson(json);
      case TimeAnswerFormat.type:
        return TimeAnswerFormat.fromJson(json);
      case ScaleAnswerFormat.type:
        return ScaleAnswerFormat.fromJson(json);
      case MultipleChoiceAutoCompleteAnswerFormat.type:
        return MultipleChoiceAutoCompleteAnswerFormat.fromJson(json);
      case MultipleDoubleAnswerFormat.type:
        return MultipleDoubleAnswerFormat.fromJson(json);
      default:
        throw UnknownTypeException(kind: 'AnswerFormat', discriminator: type);
    }
  }
}
