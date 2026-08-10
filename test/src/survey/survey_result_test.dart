import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

void main() {
  final tQuestionResults = <StepResult>[
    StepResult<void>(
      id: 'example1_intro',
      startTime: DateTime(2022, 8, 12, 16, 4),
      endTime: DateTime(2022, 8, 12, 16, 5),
      result: null,
    ),
    StepResult<BooleanResult>(
      id: 'example1_boolean',
      answerType: BooleanAnswerFormat.type,
      startTime: DateTime(2022, 8, 12, 16, 5),
      endTime: DateTime(2022, 8, 12, 16, 10),
      valueIdentifier: 'bool1',
      result: BooleanResult.negative,
    ),
    StepResult<String>(
      id: 'example1_text',
      answerType: TextAnswerFormat.type,
      startTime: DateTime(2022, 8, 12, 16, 10),
      endTime: DateTime(2022, 8, 12, 16, 12),
      result: 'free text',
    ),
  ];

  // Previously this nested `tQuestionResults` as a single StepResult's `result`
  // value — a List<StepResult> as an answer, which no conversion can represent.
  // It only survived because results were never actually decoded (ADO #1009).
  final tSurveyResult = SurveyResult(
    id: 'example1',
    startTime: DateTime(2022, 8, 12, 16, 4),
    endTime: DateTime(2022, 8, 12, 16, 14),
    finishReason: FinishReason.completed,
    results: tQuestionResults,
  );

  group('serialisation', () {
    test('round-trips the survey envelope', () {
      final decoded = SurveyResult.fromJson(tSurveyResult.toJson());
      expect(decoded.id, tSurveyResult.id);
      expect(decoded.startTime, tSurveyResult.startTime);
      expect(decoded.endTime, tSurveyResult.endTime);
      expect(decoded.finishReason, FinishReason.completed);
    });

    test('round-trips every result with its declared type', () {
      // Asserted per-result on purpose: SurveyResult.== excludes `results` and
      // StepResult.== excludes `result`, so `expect(original, decoded)` passes
      // even when every value has been mangled. That is exactly how ADO #1009
      // stayed hidden behind this test.
      final decoded = SurveyResult.fromJson(tSurveyResult.toJson());

      expect(decoded.results, hasLength(3));

      expect(decoded.results[0].id, 'example1_intro');
      expect(decoded.results[0].result, isNull);

      expect(decoded.results[1].id, 'example1_boolean');
      expect(decoded.results[1].result, isA<BooleanResult>());
      expect(decoded.results[1].result, BooleanResult.negative);
      expect(decoded.results[1].valueIdentifier, 'bool1');

      expect(decoded.results[2].id, 'example1_text');
      expect(decoded.results[2].result, isA<String>());
      expect(decoded.results[2].result, 'free text');
    });
  });
}
