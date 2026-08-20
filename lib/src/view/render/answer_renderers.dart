import 'package:flutter/widgets.dart';
import 'package:survey_kit/src/model/answer/answer_format_type.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/view/widget/answer/boolean_answer_view.dart';
import 'package:survey_kit/src/view/widget/answer/date_answer_view.dart';
import 'package:survey_kit/src/view/widget/answer/double_answer_view.dart';
import 'package:survey_kit/src/view/widget/answer/image_answer_view.dart';
import 'package:survey_kit/src/view/widget/answer/integer_answer_view.dart';
import 'package:survey_kit/src/view/widget/answer/multiple_choice_answer_view.dart';
import 'package:survey_kit/src/view/widget/answer/multiple_choice_answer_with_feedback_view.dart';
import 'package:survey_kit/src/view/widget/answer/multiple_choice_auto_complete_answer_view.dart';
import 'package:survey_kit/src/view/widget/answer/multiple_double_answer_view.dart';
import 'package:survey_kit/src/view/widget/answer/scale_answer_view.dart';
import 'package:survey_kit/src/view/widget/answer/single_choice_answer_view.dart';
import 'package:survey_kit/src/view/widget/answer/single_choice_answer_with_feedback_view.dart';
import 'package:survey_kit/src/view/widget/answer/text_answer_view.dart';
import 'package:survey_kit/src/view/widget/answer/time_answer_view.dart';

/// Builds the answer view for one step.
///
/// Takes the step rather than the format: every view reads the format back off
/// `step.answerFormat`, so a `format` parameter would be unused in all fourteen
/// implementations. Internal and unexported — `SurveyRegistries` ships no
/// `answerRenderers` override map, so no consumer supplies one of these.
typedef AnswerRenderer = Widget Function(Step step, StepResult? result);

Widget renderBooleanAnswer(Step step, StepResult? result) =>
    BooleanAnswerView(questionStep: step, result: result);

Widget renderDateAnswer(Step step, StepResult? result) =>
    DateAnswerView(questionStep: step, result: result);

Widget renderDoubleAnswer(Step step, StepResult? result) =>
    DoubleAnswerView(questionStep: step, result: result);

Widget renderIntegerAnswer(Step step, StepResult? result) =>
    IntegerAnswerView(questionStep: step, result: result);

Widget renderImageAnswer(Step step, StepResult? result) =>
    ImageAnswerView(questionStep: step, result: result);

Widget renderTextAnswer(Step step, StepResult? result) =>
    TextAnswerView(questionStep: step, result: result);

Widget renderTimeAnswer(Step step, StepResult? result) =>
    TimeAnswerView(questionStep: step, result: result);

Widget renderScaleAnswer(Step step, StepResult? result) =>
    ScaleAnswerView(questionStep: step, result: result);

Widget renderSingleChoiceAnswer(Step step, StepResult? result) =>
    SingleChoiceAnswerView(questionStep: step, result: result);

Widget renderSingleChoiceWithFeedbackAnswer(Step step, StepResult? result) =>
    SingleChoiceAnswerWithFeedbackView(questionStep: step, result: result);

Widget renderMultipleChoiceAnswer(Step step, StepResult? result) =>
    MultipleChoiceAnswerView(questionStep: step, result: result);

Widget renderMultipleChoiceWithFeedbackAnswer(Step step, StepResult? result) =>
    MultipleChoiceAnswerWithFeedbackView(questionStep: step, result: result);

Widget renderMultipleChoiceAutoCompleteAnswer(Step step, StepResult? result) =>
    MultipleChoiceAutoCompleteAnswerView(questionStep: step, result: result);

Widget renderMultipleDoubleAnswer(Step step, StepResult? result) =>
    MultipleDoubleAnswerView(questionStep: step, result: result);

/// The renderer for every built-in [AnswerFormat], keyed by discriminator.
///
/// Keyed by the [AnswerFormatType] enum rather than a `String`, unlike the
/// content table: answer discriminators are a **closed** set. There is no
/// `customAnswerFormats` registry, so a fifteenth format cannot exist without
/// adding an enum member — which `answer_renderers_test.dart` then forces to be
/// registered here.
final Map<AnswerFormatType, AnswerRenderer> defaultAnswerRenderers = {
  AnswerFormatType.boolean: renderBooleanAnswer,
  AnswerFormatType.date: renderDateAnswer,
  AnswerFormatType.doubleValue: renderDoubleAnswer,
  AnswerFormatType.integer: renderIntegerAnswer,
  AnswerFormatType.image: renderImageAnswer,
  AnswerFormatType.text: renderTextAnswer,
  AnswerFormatType.time: renderTimeAnswer,
  AnswerFormatType.scale: renderScaleAnswer,
  AnswerFormatType.single: renderSingleChoiceAnswer,
  AnswerFormatType.singleWithFeedback: renderSingleChoiceWithFeedbackAnswer,
  AnswerFormatType.multi: renderMultipleChoiceAnswer,
  AnswerFormatType.multiWithFeedback: renderMultipleChoiceWithFeedbackAnswer,
  AnswerFormatType.multipleAutoComplete: renderMultipleChoiceAutoCompleteAnswer,
  AnswerFormatType.multipleDouble: renderMultipleDoubleAnswer,
};

/// Resolves the renderer for [answerType].
///
/// Total by construction: [AnswerFormatType] is closed and
/// [defaultAnswerRenderers] covers every member, which
/// `answer_renderers_test.dart` pins. The `!` cannot fail while that test
/// passes, and there is no registry to consult first.
AnswerRenderer answerRendererFor(AnswerFormatType answerType) =>
    defaultAnswerRenderers[answerType]!;
