import 'package:flutter/material.dart' hide Step;
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/exception/survey_kit_exception.dart';
import 'package:survey_kit/src/model/answer/boolean_answer_format.dart';
import 'package:survey_kit/src/model/answer/date_answer_format.dart';
import 'package:survey_kit/src/model/answer/double_answer_format.dart';
import 'package:survey_kit/src/model/answer/image_answer_format.dart';
import 'package:survey_kit/src/model/answer/integer_answer_format.dart';
import 'package:survey_kit/src/model/answer/multi_double.dart';
import 'package:survey_kit/src/model/answer/multiple_choice_answer_format.dart';
import 'package:survey_kit/src/model/answer/multiple_choice_answer_with_feedback_format.dart';
import 'package:survey_kit/src/model/answer/multiple_choice_auto_complete_answer_format.dart';
import 'package:survey_kit/src/model/answer/multiple_double_answer_format.dart';
import 'package:survey_kit/src/model/answer/scale_answer_format.dart';
import 'package:survey_kit/src/model/answer/single_choice_answer_format.dart';
import 'package:survey_kit/src/model/answer/single_choice_answer_with_feedback_format.dart';
import 'package:survey_kit/src/model/answer/text_answer_format.dart';
import 'package:survey_kit/src/model/answer/text_choice.dart';
import 'package:survey_kit/src/model/answer/time_answer_format.dart';
import 'package:survey_kit/src/model/result/time_result.dart';
import 'package:survey_kit/src/util/datetime_convert.dart';

part 'step_result.g.dart';

@immutable
@JsonSerializable(genericArgumentFactories: true)
@CustomDateTimeConverter()
class StepResult<T> {
  const StepResult({
    required this.id,
    required this.result,
    required this.startTime,
    required this.endTime,
    this.answerType,
    this.valueIdentifier,
  });

  /// Id of the `Step` this result belongs to.
  final String id;

  /// Discriminator of the `AnswerFormat` that produced [result], e.g. `'time'`.
  ///
  /// Selects the conversion applied to [result] in both directions. Null only
  /// for a step with no answer format, which yields no result either — and for
  /// records written before this field existed, which is why an absent value on
  /// a non-null result is an error rather than a fallback.
  @JsonKey(includeIfNull: false)
  final String? answerType;

  final T? result;
  final DateTime startTime;
  final DateTime endTime;

  /// Reserved: distinguishes several answers recorded within a single step.
  ///
  /// Never set by the library today — one step yields exactly one result, and
  /// every lookup keys on [id] alone. Composite `(id, valueIdentifier)` keying
  /// would need to be threaded through the presenter's dedupe, its lookups and
  /// the completion-time pruning; that is Phase 3 work. The field is retained so
  /// the name is not reused for something else.
  @JsonKey(includeIfNull: false)
  final String? valueIdentifier;

  factory StepResult.fromJson(Map<String, dynamic> json) {
    // Normalize id: an old format stored {"id": "..."} rather than a string.
    final rawId = json['id'];
    var normalized = json;
    if (rawId is Map<String, dynamic>) {
      normalized = Map<String, dynamic>.from(json);
      normalized['id'] = rawId['id'] as String;
    }

    // Captured in a closure: the generated fromJsonT callback receives only the
    // value, never the enclosing map, so the discriminator cannot be read from
    // inside the conversion without closing over it here.
    final answerType = normalized['answerType'] as String?;
    final id = normalized['id'] as String;

    return _$StepResultFromJson<T>(
      normalized,
      (value) => _convert(id, answerType, value, out: false) as T,
    );
  }

  Map<String, dynamic> toJson() => _$StepResultToJson(
    this,
    (value) => _convert(id, answerType, value, out: true),
  );

  /// Converts [value] between its in-memory and serialized forms.
  ///
  /// [out] true encodes, false decodes. Dispatches on [answerType] — the answer
  /// format's discriminator — rather than on the reified type argument, which is
  /// `dynamic` for every result reached through `SurveyResult` and so made the
  /// old `if (value is S) return value` short-circuit always match, returning
  /// raw JSON. That was ADO #1009.
  ///
  /// Throws [ResultCodecException] for an absent, unknown or mismatched
  /// [answerType]. There is deliberately no fallback: a caller that cannot
  /// convert a record should discard it rather than receive an untyped value.
  static Object? _convert(
    String id,
    String? answerType,
    Object? value, {
    required bool out,
  }) {
    if (value == null) return null;
    try {
      switch (answerType) {
        case BooleanAnswerFormat.type:
          return out
              ? (value as BooleanResult).name
              : BooleanResult.values.byName(value as String);
        case DateAnswerFormat.type:
          return out
              ? const CustomDateTimeConverter().toJson(value as DateTime)
              : const CustomDateTimeConverter().fromJson(value as String);
        case TimeAnswerFormat.type:
          return out
              ? (value as TimeResult).toJson()
              : TimeResult.fromJson(Map<String, dynamic>.from(value as Map));
        case SingleChoiceAnswerFormat.type:
        case SingleChoiceAnswerWithFeedbackFormat.type:
          return out
              ? (value as TextChoice).toJson()
              : TextChoice.fromJson(Map<String, dynamic>.from(value as Map));
        case MultipleChoiceAnswerFormat.type:
        case MultipleChoiceAnswerWithFeedbackFormat.type:
        case MultipleChoiceAutoCompleteAnswerFormat.type:
          return out
              ? (value as List<TextChoice>).map((c) => c.toJson()).toList()
              : (value as List)
                    .map(
                      (e) => TextChoice.fromJson(
                        Map<String, dynamic>.from(e as Map),
                      ),
                    )
                    .toList();
        case MultipleDoubleAnswerFormat.type:
          return out
              ? (value as List<MultiDouble>).map((d) => d.toJson()).toList()
              : (value as List)
                    .map(
                      (e) => MultiDouble.fromJson(
                        Map<String, dynamic>.from(e as Map),
                      ),
                    )
                    .toList();
        case TextAnswerFormat.type:
        case ImageAnswerFormat.type:
          return value as String;
        case IntegerAnswerFormat.type:
          return out ? value as int : (value as num).toInt();
        case DoubleAnswerFormat.type:
        case ScaleAnswerFormat.type:
          // JSON may carry a whole-numbered double as an int; widen on the way
          // in so the views' `is double` guards see what they expect.
          return out ? value as double : (value as num).toDouble();
        default:
          throw ResultCodecException(
            stepId: id,
            answerType: answerType,
            cause: answerType == null
                ? 'the record carries no answerType'
                : 'no conversion is registered for it',
          );
      }
    } on ResultCodecException {
      rethrow;
    } catch (e) {
      throw ResultCodecException(
        stepId: id,
        answerType: answerType,
        cause: '$e',
      );
    }
  }

  @override
  int get hashCode => id.hashCode ^ startTime.hashCode ^ endTime.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StepResult &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            startTime == other.startTime &&
            endTime == other.endTime;
  }
}
