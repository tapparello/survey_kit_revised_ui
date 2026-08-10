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
    // Drop microseconds without reinterpreting the value's time zone.
    //
    // This used to rebuild the value with the local DateTime(...) constructor
    // from its own field values and then call toUtc(). For an already-UTC input
    // that takes UTC wall-clock numbers as local time and shifts the instant by
    // the zone offset — DateTime.utc(2026, 3, 4) came back as 05:00Z in EST.
    // It stayed latent while the only values passed through here were
    // startTime / endTime, which always come from DateTime.now() and so are
    // local-origin. Phase 2b routes date *answers* through it too. (ADO #1012)
    final truncated = json.subtract(Duration(microseconds: json.microsecond));

    return truncated.toUtc().toIso8601String();
  }
}
