import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/exception/survey_kit_exception.dart';

part 'time_result.g.dart';

@JsonSerializable()
class TimeResult {
  @_TimeOfDayConverter()
  final TimeOfDay timeOfDay;

  const TimeResult({required this.timeOfDay});

  factory TimeResult.fromJson(Map<String, dynamic> json) =>
      _$TimeResultFromJson(json);

  Map<String, dynamic> toJson() => _$TimeResultToJson(this);
}

class _TimeOfDayConverter extends JsonConverter<TimeOfDay, String?> {
  const _TimeOfDayConverter();

  @override
  TimeOfDay fromJson(String? json) {
    if (json == null) {
      throw const MalformedValueException(field: 'timeOfDay', value: null);
    }

    String _removeLeadingZeroIfNeeded(String value) {
      if (value.startsWith('0')) {
        const indexOfSecondCharacter = 1;
        return value.substring(indexOfSecondCharacter);
      } else {
        return value;
      }
    }

    final elements = json.split(':');
    final hourString = _removeLeadingZeroIfNeeded(elements.first);
    final minuteString = _removeLeadingZeroIfNeeded(elements.last);

    final hour = int.tryParse(hourString);
    final minute = int.tryParse(minuteString);

    if (hour != null && minute != null) {
      return TimeOfDay(hour: hour, minute: minute);
    }
    throw MalformedValueException(field: 'timeOfDay', value: json);
  }

  @override
  String toJson(TimeOfDay object) {
    String _addLeadingZeroIfNeeded(int value) {
      if (value < 10) {
        return '0$value';
      }
      return value.toString();
    }

    final hourLabel = _addLeadingZeroIfNeeded(object.hour);
    final minuteLabel = _addLeadingZeroIfNeeded(object.minute);

    return '$hourLabel:$minuteLabel';
  }
}
