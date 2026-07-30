import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

void main() {
  group('ScaleBand.fromJson', () {
    test('parses bare int literals into doubles and reads name', () {
      final band = ScaleBand.fromJson(<String, dynamic>{
        'min': 6,
        'max': 9,
        'name': 'Average for age',
        'labelAt': 7,
      });
      expect(band.min, 6.0);
      expect(band.max, 9.0);
      expect(band.labelAt, 7.0);
      expect(band.name, 'Average for age');
    });

    test('round-trips through toJson', () {
      const band = ScaleBand(
        min: 1,
        max: 1,
        name: 'Well below average for age',
        labelAt: 1,
      );
      final restored = ScaleBand.fromJson(band.toJson());
      expect(restored.min, 1.0);
      expect(restored.name, 'Well below average for age');
      expect(restored.labelAt, 1.0);
    });
  });
}
