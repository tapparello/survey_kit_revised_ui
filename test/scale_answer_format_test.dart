import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

void main() {
  // A 1–12 vertical scale, optionally constrained to an accepted sub-range.
  ScaleAnswerFormat buildFormat({double? acceptedMin, double? acceptedMax}) {
    return ScaleAnswerFormat(
      minimumValue: 1,
      maximumValue: 12,
      defaultValue: 1,
      step: 1,
      acceptedMinimumValue: acceptedMin,
      acceptedMaximumValue: acceptedMax,
    );
  }

  group('ScaleAnswerFormat.isWithinAcceptedRange', () {
    test('returns true for any value when no accepted range is set', () {
      final format = buildFormat();
      expect(format.isWithinAcceptedRange(1), isTrue);
      expect(format.isWithinAcceptedRange(6.5), isTrue);
      expect(format.isWithinAcceptedRange(12), isTrue);
      expect(format.isWithinAcceptedRange(-100), isTrue);
      expect(format.isWithinAcceptedRange(1000), isTrue);
    });

    test('returns true only within the inclusive accepted range (Average 6–9)', () {
      final format = buildFormat(acceptedMin: 6, acceptedMax: 9);
      expect(format.isWithinAcceptedRange(5), isFalse); // just below
      expect(format.isWithinAcceptedRange(6), isTrue);  // lower bound inclusive
      expect(format.isWithinAcceptedRange(7), isTrue);  // interior
      expect(format.isWithinAcceptedRange(9), isTrue);  // upper bound inclusive
      expect(format.isWithinAcceptedRange(10), isFalse); // just above
    });

    test('supports a single-value accepted range (Well Below Average = 1)', () {
      final format = buildFormat(acceptedMin: 1, acceptedMax: 1);
      expect(format.isWithinAcceptedRange(1), isTrue);
      expect(format.isWithinAcceptedRange(2), isFalse);
      expect(format.isWithinAcceptedRange(0), isFalse);
    });

    test('treats a partially-specified range (only one bound) as no range', () {
      expect(buildFormat(acceptedMin: 6).isWithinAcceptedRange(1), isTrue);
      expect(buildFormat(acceptedMax: 9).isWithinAcceptedRange(12), isTrue);
    });
  });

  group('ScaleAnswerFormat JSON round-trip', () {
    test('parses bare int accepted-range literals into doubles', () {
      final format = ScaleAnswerFormat.fromJson(<String, dynamic>{
        'type': 'scale',
        'minimumValue': 1,
        'maximumValue': 12,
        'defaultValue': 1,
        'step': 1,
        'acceptedMinimumValue': 6,
        'acceptedMaximumValue': 9,
      });
      expect(format.acceptedMinimumValue, 6.0);
      expect(format.acceptedMaximumValue, 9.0);
      expect(format.isWithinAcceptedRange(7), isTrue);
      expect(format.isWithinAcceptedRange(5), isFalse);
    });

    test('leaves accepted range null when keys are absent', () {
      final format = ScaleAnswerFormat.fromJson(<String, dynamic>{
        'type': 'scale',
        'minimumValue': 1,
        'maximumValue': 12,
        'defaultValue': 1,
        'step': 1,
      });
      expect(format.acceptedMinimumValue, isNull);
      expect(format.acceptedMaximumValue, isNull);
      expect(format.isWithinAcceptedRange(12), isTrue);
    });
  });
}
