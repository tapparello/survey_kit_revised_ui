import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/util/datetime_convert.dart';

void main() {
  const converter = CustomDateTimeConverter();

  test('a UTC DateTime round-trips to the same instant', () {
    // Regression guard: toJson used to rebuild the value with the local
    // DateTime(...) constructor regardless of isUtc and then call toUtc(),
    // so an already-UTC value had its wall-clock fields taken as local and
    // shifted by the zone offset. Latent until Phase 2b routed date answers
    // through this converter. (ADO #1012)
    final value = DateTime.utc(2026, 3, 4);
    expect(converter.fromJson(converter.toJson(value)).toUtc(), value);
  });

  test('a local DateTime round-trips to the same instant', () {
    final value = DateTime(2026, 3, 4, 13, 45);
    expect(converter.fromJson(converter.toJson(value)).toUtc(), value.toUtc());
  });

  test('microseconds are dropped, milliseconds preserved', () {
    final value = DateTime(2026, 3, 4, 13, 45, 30, 123, 456);
    final back = converter.fromJson(converter.toJson(value));
    expect(back.millisecond, 123);
    expect(back.microsecond, 0);
  });
}
