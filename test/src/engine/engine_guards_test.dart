// Criterion 13, second clause: relocated from survey_session_test.dart when
// SurveySession was absorbed into SurveyEngine. Tasks 5 and 6 add the rest of
// this file's cases.
//
// No `package:survey_kit/survey_kit.dart` import yet: nothing here names a
// symbol from the barrel — makeEngine, twoStepTask and FakeSurveyHost all come
// from engine_harness.dart — and an unused import is a warning, which
// `flutter analyze` fails on. Task 6 adds it when its cases need it.
import 'package:flutter_test/flutter_test.dart';

import 'engine_harness.dart';

void main() {
  test('endAdvance after dispose does not throw', () {
    final engine = makeEngine(task: twoStepTask(), host: FakeSurveyHost())
      ..beginAdvance()
      ..dispose();
    expect(engine.endAdvance, returnsNormally);
  });
}
