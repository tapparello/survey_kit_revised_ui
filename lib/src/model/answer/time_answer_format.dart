import 'package:flutter/material.dart' hide Step;
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/answer/answer_format.dart';
import 'package:survey_kit/src/model/answer/answer_format_type.dart';

part 'time_answer_format.g.dart';

@JsonSerializable()
class TimeAnswerFormat extends AnswerFormat {
  @_TimeOfDayJsonConverter()
  final TimeOfDay? defaultValue;

  const TimeAnswerFormat({this.defaultValue, super.question}) : super();

  @override
  @JsonKey(name: 'type', includeToJson: true, includeFromJson: false)
  AnswerFormatType get answerType => AnswerFormatType.time;

  factory TimeAnswerFormat.fromJson(Map<String, dynamic> json) =>
      _$TimeAnswerFormatFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$TimeAnswerFormatToJson(this);
}

class _TimeOfDayJsonConverter
    implements JsonConverter<TimeOfDay?, Map<String, dynamic>> {
  const _TimeOfDayJsonConverter();

  @override
  TimeOfDay? fromJson(Map<String, dynamic> json) {
    if (json['hour'] == null || json['minute'] == null) {
      return null;
    }
    return TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int);
  }

  @override
  Map<String, dynamic> toJson(TimeOfDay? timeOfDay) => <String, dynamic>{
    'hour': timeOfDay?.hour,
    'minute': timeOfDay?.minute,
  };
}
