import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/view/render/answer_renderers.dart';
import 'package:survey_kit/survey_kit.dart';

void main() {
  test('defaultAnswerRenderers covers every AnswerFormatType', () {
    expect(
      defaultAnswerRenderers.keys.toSet(),
      AnswerFormatType.values.toSet(),
    );
  });

  // Presence is not correctness: binding AnswerFormatType.text to the image
  // view satisfies the pin above. These bind each member by identity.
  test('binds each format to its own renderer', () {
    expect(
      defaultAnswerRenderers[AnswerFormatType.boolean],
      equals(renderBooleanAnswer),
    );
    expect(
      defaultAnswerRenderers[AnswerFormatType.date],
      equals(renderDateAnswer),
    );
    expect(
      defaultAnswerRenderers[AnswerFormatType.doubleValue],
      equals(renderDoubleAnswer),
    );
    expect(
      defaultAnswerRenderers[AnswerFormatType.integer],
      equals(renderIntegerAnswer),
    );
    expect(
      defaultAnswerRenderers[AnswerFormatType.image],
      equals(renderImageAnswer),
    );
    expect(
      defaultAnswerRenderers[AnswerFormatType.text],
      equals(renderTextAnswer),
    );
    expect(
      defaultAnswerRenderers[AnswerFormatType.time],
      equals(renderTimeAnswer),
    );
    expect(
      defaultAnswerRenderers[AnswerFormatType.scale],
      equals(renderScaleAnswer),
    );
    expect(
      defaultAnswerRenderers[AnswerFormatType.single],
      equals(renderSingleChoiceAnswer),
    );
    expect(
      defaultAnswerRenderers[AnswerFormatType.singleWithFeedback],
      equals(renderSingleChoiceWithFeedbackAnswer),
    );
    expect(
      defaultAnswerRenderers[AnswerFormatType.multi],
      equals(renderMultipleChoiceAnswer),
    );
    expect(
      defaultAnswerRenderers[AnswerFormatType.multiWithFeedback],
      equals(renderMultipleChoiceWithFeedbackAnswer),
    );
    expect(
      defaultAnswerRenderers[AnswerFormatType.multipleAutoComplete],
      equals(renderMultipleChoiceAutoCompleteAnswer),
    );
    expect(
      defaultAnswerRenderers[AnswerFormatType.multipleDouble],
      equals(renderMultipleDoubleAnswer),
    );
  });

  test('answerRendererFor returns the table entry for every member', () {
    // Not `returnsNormally`: the presence pin above already guarantees the `!`
    // cannot fail, so a throws-check would re-assert a fact and catch nothing.
    // Asserting the returned function IS the table entry is what proves the
    // resolver reads the table rather than computing an answer some other way.
    for (final member in AnswerFormatType.values) {
      expect(answerRendererFor(member), equals(defaultAnswerRenderers[member]));
    }
  });
}
