import 'package:flutter/material.dart' hide Step;
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/answer/date_answer_format.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/util/datetime_convert.dart';

part 'step_result.g.dart';

@immutable
@JsonSerializable(genericArgumentFactories: true)
@CustomDateTimeConverter()
class StepResult<T> {
  final String id;
  final Step step;
  final T? result;
  final DateTime startTime;
  final DateTime endTime;
  @JsonKey(includeIfNull: false)
  final String? valueIdentifier;

  const StepResult({
    required this.id,
    required this.result,
    required this.startTime,
    required this.endTime,
    required this.step,
    this.valueIdentifier,
  });

  factory StepResult.fromQuestion({required StepResult questionResult}) {
    return StepResult(
      id: questionResult.id,
      step: questionResult.step,
      startTime: questionResult.startTime,
      endTime: questionResult.endTime,
      result: questionResult as T?,
      valueIdentifier: questionResult.valueIdentifier,
    );
  }

  factory StepResult.fromJson(Map<String, dynamic> json) {
    // Normalize id: old format stored {"id": "..."}, new format is plain string
    final rawId = json['id'];
    var normalized = json;
    if (rawId is Map<String, dynamic>) {
      normalized = Map<String, dynamic>.from(json);
      normalized['id'] = rawId['id'] as String;
    }

    final answerType = (normalized['step']
        as Map<String, dynamic>?)?['answerFormat']?['type'] as String?;

    return _$StepResultFromJson(normalized, (value) {
      // Date results are serialized as ISO strings — parse back to DateTime
      if (answerType == DateAnswerFormat.type && value is String) {
        return DateTime.parse(value) as T;
      }
      return value as T;
    });
  }

  Map<String, dynamic> toJson() => _$StepResultToJson(this, _encodeResult);

  static Object? _encodeResult(dynamic value) {
    if (value == null) return null;
    if (value is num || value is String || value is bool) return value;
    if (value is DateTime) return const CustomDateTimeConverter().toJson(value);
    if (value is List) return value.map(_encodeResult).toList();
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _encodeResult(v)));
    }
    try {
      return (value as dynamic).toJson();
    } catch (_) {
      return value.toString();
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
