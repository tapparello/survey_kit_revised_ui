import 'package:flutter/material.dart' hide Step;
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/answer/boolean_answer_format.dart';
import 'package:survey_kit/src/model/answer/multi_double.dart';
import 'package:survey_kit/src/model/answer/text_choice.dart';
import 'package:survey_kit/src/model/result/time_result.dart';
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

    return _$StepResultFromJson<T>(
      normalized,
      (value) => _decodeResult<T>(value),
    );
  }

  /// Reverses [_encodeResult] for every result type the library uses.
  ///
  /// Results are serialized type-erased (enums as their name, objects via
  /// `toJson`, dates as ISO strings), so deserialization reconstructs the
  /// concrete type from the reified type argument [S].
  static S _decodeResult<S>(Object? value) {
    if (value is S) return value;

    // JSON numbers decode as int; widen when a double is expected.
    if (value is num && S == double) return value.toDouble() as S;

    if (value is String) {
      if (S == DateTime) return DateTime.parse(value).toLocal() as S;
      if (S == BooleanResult) return BooleanResult.values.byName(value) as S;
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      if (S == TimeResult) return TimeResult.fromJson(map) as S;
      if (S == TextChoice) return TextChoice.fromJson(map) as S;
      if (S == MultiDouble) return MultiDouble.fromJson(map) as S;
    }

    if (value is List) {
      if (S == List<TextChoice>) {
        return value
            .map((e) => TextChoice.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() as S;
      }
      if (S == List<MultiDouble>) {
        return value
            .map((e) => MultiDouble.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() as S;
      }
    }

    return value as S;
  }

  Map<String, dynamic> toJson() => _$StepResultToJson(this, _encodeResult);

  static Object? _encodeResult(dynamic value) {
    if (value == null) return null;
    if (value is num || value is String || value is bool) return value;
    if (value is Enum) return value.name;
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
        other is StepResult && runtimeType == other.runtimeType && id == other.id && startTime == other.startTime && endTime == other.endTime;
  }
}
