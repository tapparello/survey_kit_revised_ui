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

    test(
      'returns true only within the inclusive accepted range (Average 6–9)',
      () {
        final format = buildFormat(acceptedMin: 6, acceptedMax: 9);
        expect(format.isWithinAcceptedRange(5), isFalse); // just below
        expect(
          format.isWithinAcceptedRange(6),
          isTrue,
        ); // lower bound inclusive
        expect(format.isWithinAcceptedRange(7), isTrue); // interior
        expect(
          format.isWithinAcceptedRange(9),
          isTrue,
        ); // upper bound inclusive
        expect(format.isWithinAcceptedRange(10), isFalse); // just above
      },
    );

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

  group('ScaleAnswerFormat.hasAcceptedRange', () {
    test('false when no/partial range, true when both bounds set', () {
      expect(buildFormat().hasAcceptedRange, isFalse);
      expect(buildFormat(acceptedMin: 6).hasAcceptedRange, isFalse);
      expect(buildFormat(acceptedMax: 9).hasAcceptedRange, isFalse);
      expect(
        buildFormat(acceptedMin: 6, acceptedMax: 9).hasAcceptedRange,
        isTrue,
      );
    });

    test('inverted range (min > max) matches no value', () {
      final format = buildFormat(acceptedMin: 9, acceptedMax: 6);
      expect(format.isWithinAcceptedRange(7), isFalse);
      expect(format.isWithinAcceptedRange(6), isFalse);
      expect(format.isWithinAcceptedRange(9), isFalse);
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

  group('ScaleAnswerFormat.bands JSON', () {
    test('parses a bands array', () {
      final format = ScaleAnswerFormat.fromJson(<String, dynamic>{
        'type': 'scale',
        'minimumValue': 1,
        'maximumValue': 12,
        'defaultValue': 1,
        'step': 1,
        'bands': [
          {
            'min': 1,
            'max': 1,
            'name': 'Well below average for age',
            'labelAt': 1,
          },
          {'min': 6, 'max': 9, 'name': 'Average for age', 'labelAt': 7},
        ],
      });
      expect(format.bands.length, 2);
      expect(format.bands.first.name, 'Well below average for age');
      expect(format.bands[1].labelAt, 7.0);
    });

    test('defaults to empty list when bands key is absent', () {
      final format = ScaleAnswerFormat.fromJson(<String, dynamic>{
        'type': 'scale',
        'minimumValue': 1,
        'maximumValue': 12,
        'defaultValue': 1,
        'step': 1,
      });
      expect(format.bands, isEmpty);
    });
  });

  group('ScaleAnswerFormat band lookup', () {
    ScaleAnswerFormat standard() => const ScaleAnswerFormat(
      minimumValue: 1,
      maximumValue: 12,
      defaultValue: 1,
      step: 1,
      bands: [
        ScaleBand(
          min: 1,
          max: 1,
          name: 'Well below average for age',
          labelAt: 1,
        ),
        ScaleBand(min: 2, max: 3, name: 'Below average for age', labelAt: 3),
        ScaleBand(min: 4, max: 5, name: 'Low average for age', labelAt: 4),
        ScaleBand(min: 6, max: 9, name: 'Average for age', labelAt: 7),
        ScaleBand(min: 10, max: 11, name: 'High average for age', labelAt: 10),
        ScaleBand(min: 12, max: 12, name: 'Above average for age', labelAt: 12),
      ],
    );

    test('tooltipName returns the band covering a value, incl. boundaries', () {
      final f = standard();
      expect(f.tooltipName(1.0), 'Well below average for age');
      expect(f.tooltipName(3.0), 'Below average for age');
      expect(f.tooltipName(4.0), 'Low average for age');
      expect(f.tooltipName(6.0), 'Average for age');
      expect(f.tooltipName(9.0), 'Average for age');
      expect(f.tooltipName(10.0), 'High average for age');
      expect(f.tooltipName(12.0), 'Above average for age');
    });

    test('tooltipName returns null when no bands', () {
      const f = ScaleAnswerFormat(
        minimumValue: 1,
        maximumValue: 12,
        defaultValue: 1,
        step: 1,
      );
      expect(f.tooltipName(5.0), isNull);
    });

    test('labelName returns the name only at the labelAt tick', () {
      final f = standard();
      expect(f.labelName(1.0), 'Well below average for age');
      expect(f.labelName(3.0), 'Below average for age');
      expect(f.labelName(7.0), 'Average for age');
      expect(f.labelName(2.0), isNull); // not a labelAt tick
      expect(f.labelName(5.0), isNull);
      expect(f.labelName(11.0), isNull);
    });

    test('labelName returns null when no bands', () {
      const f = ScaleAnswerFormat(
        minimumValue: 1,
        maximumValue: 12,
        defaultValue: 1,
        step: 1,
      );
      expect(f.labelName(7.0), isNull);
    });
  });
}
