// The merged map both ContentWidget and SurveyEngine resolve conditionals
// against. Lifted verbatim out of ContentWidget.build by ADO #1045 so the two
// cannot drift apart.
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/util/content_variables.dart';
import 'package:survey_kit/survey_kit.dart';

// The real constructor is startTime/endTime (step_result.dart:16-22), and
// `result` is required — NOT startDate/endDate, which belong to SurveyEngine.
StepResult<dynamic> answer(String id, dynamic value) => StepResult<dynamic>(
  id: id,
  result: value,
  startTime: DateTime(2026),
  endTime: DateTime(2026),
  valueIdentifier: '$value',
);

void main() {
  test('keys step answers by step id', () {
    final variables = resolveVariables(<StepResult>{
      answer('s1', 'Lilia'),
    }, const <String, dynamic>{});
    expect(variables['s1'], 'Lilia');
  });

  test('config variables win on collision', () {
    final variables = resolveVariables(
      <StepResult>{answer('child', 'FromAnswer')},
      const <String, dynamic>{'child': 'FromConfig'},
    );
    expect(variables['child'], 'FromConfig');
  });

  test('skips results whose answer has no representable value', () {
    final variables = resolveVariables(<StepResult>{
      answer('s1', null),
    }, const <String, dynamic>{});
    expect(variables.containsKey('s1'), isFalse);
  });
}
