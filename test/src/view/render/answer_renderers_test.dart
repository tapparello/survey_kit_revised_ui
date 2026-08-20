import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/view/render/answer_renderers.dart';
import 'package:survey_kit/src/view/widget/answer/boolean_answer_view.dart';
import 'package:survey_kit/src/view/widget/answer/multiple_choice_auto_complete_answer_view.dart';
import 'package:survey_kit/src/view/widget/answer/multiple_double_answer_view.dart';
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

  // The pins above prove which function each member is bound to; they never run
  // one. A renderer rewritten to build a different view keeps its identity and
  // so survives them - which is the mutation this catches. Constructing a view
  // is enough: every one reads its format in initState, not in the constructor,
  // so no format and no pumping are needed here.
  test('every answer renderer builds its own view', () {
    final step = Step(id: 'probe', content: const []);
    final expected = <AnswerFormatType, Matcher>{
      AnswerFormatType.boolean: isA<BooleanAnswerView>(),
      AnswerFormatType.date: isA<DateAnswerView>(),
      AnswerFormatType.doubleValue: isA<DoubleAnswerView>(),
      AnswerFormatType.integer: isA<IntegerAnswerView>(),
      AnswerFormatType.image: isA<ImageAnswerView>(),
      AnswerFormatType.text: isA<TextAnswerView>(),
      AnswerFormatType.time: isA<TimeAnswerView>(),
      AnswerFormatType.scale: isA<ScaleAnswerView>(),
      AnswerFormatType.single: isA<SingleChoiceAnswerView>(),
      AnswerFormatType.singleWithFeedback:
          isA<SingleChoiceAnswerWithFeedbackView>(),
      AnswerFormatType.multi: isA<MultipleChoiceAnswerView>(),
      AnswerFormatType.multiWithFeedback:
          isA<MultipleChoiceAnswerWithFeedbackView>(),
      AnswerFormatType.multipleAutoComplete:
          isA<MultipleChoiceAutoCompleteAnswerView>(),
      AnswerFormatType.multipleDouble: isA<MultipleDoubleAnswerView>(),
    };

    // Every member, so a new format cannot be added without a body assertion.
    expect(expected.keys.toSet(), AnswerFormatType.values.toSet());

    for (final entry in expected.entries) {
      expect(
        defaultAnswerRenderers[entry.key]!(step, null),
        entry.value,
        reason: '${entry.key} built the wrong view',
      );
    }
  });
}
