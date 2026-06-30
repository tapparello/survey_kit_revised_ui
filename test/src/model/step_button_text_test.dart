// ADO #968: an absent buttonText must parse to null (not the literal 'Next'),
// so step_view can fall back to the localized 'next'/'done'.
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

void main() {
  Map<String, dynamic> stepJson({String? buttonText}) => {
        'id': 'x',
        'content': [
          {'type': 'text', 'text': 'hi'},
        ],
        if (buttonText != null) 'buttonText': buttonText,
      };

  test('absent buttonText parses to null', () {
    final step = Step.fromJson(stepJson());
    expect(step.buttonText, isNull);
  });

  test('explicit buttonText is preserved', () {
    final step = Step.fromJson(stepJson(buttonText: 'Custom'));
    expect(step.buttonText, 'Custom');
  });
}
