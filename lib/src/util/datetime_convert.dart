import 'package:json_annotation/json_annotation.dart';

class CustomDateTimeConverter implements JsonConverter<DateTime, String> {
  const CustomDateTimeConverter();

  @override
  DateTime fromJson(String json) {
    // toJson stores the value in UTC; convert back to local time so a
    // round-tripped DateTime compares equal to the original. Dart's
    // DateTime.== also requires a matching isUtc flag, not just the instant.
    return DateTime.parse(json).toLocal();
  }

  @override
  String toJson(DateTime json) {
    //Ignore microseconds
    final date = DateTime(
      json.year,
      json.month,
      json.day,
      json.hour,
      json.minute,
      json.second,
      json.millisecond,
    ).toUtc();

    return date.toIso8601String();
  }
}
