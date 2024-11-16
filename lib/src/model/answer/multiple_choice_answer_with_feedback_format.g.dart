// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multiple_choice_answer_with_feedback_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MultipleChoiceAnswerWithFeedbackFormat _$MultipleChoiceAnswerWithFeedbackFormatFromJson(
        Map<String, dynamic> json) =>
    MultipleChoiceAnswerWithFeedbackFormat(
      textChoices: (json['textChoices'] as List<dynamic>)
          .map((e) => TextChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      feedbackCorrect: json['feedbackCorrect'] as String?,
      feedbackWrong: json['feedbackWrong'] as String?,
      choicesFromVariable: json['choicesFromVariable'] as String?,
      shuffleChoices: json['shuffleChoices'] as bool? ?? false,
      coloredFeedback: json['coloredFeedback'] as bool? ?? false,
      minRequiredChoices: json['minRequiredChoices'] as int? ?? 1,
      maxAllowedChoices: json['maxAllowedChoices'] as int? ?? 999,
      maxAllowedChoicesErrorMessage: json['maxAllowedChoicesErrorMessage'] as String?,
      noneOption: json['noneOption'] as bool? ?? false,
      noneOptionText: json['noneOptionText'] as String?,
      defaultSelection: json['defaultSelection'] == null
          ? null
          : TextChoice.fromJson(
              json['defaultSelection'] as Map<String, dynamic>),
      question: json['question'] as String?,
      answerType: json['type'] as String?,

    );

Map<String, dynamic> _$MultipleChoiceAnswerWithFeedbackFormatToJson(
      MultipleChoiceAnswerWithFeedbackFormat instance) =>
    <String, dynamic>{
      'question': instance.question,
      'type': instance.answerType,
      'textChoices': instance.textChoices,
      'feedbackCorrect': instance.feedbackCorrect,
      'feedbackWrong': instance.feedbackWrong,
      'coloredFeedback': instance.coloredFeedback,
      'choicesFromVariable': instance.choicesFromVariable,
      'defaultSelection': instance.defaultSelection,
      'noneOption': instance.noneOption,
      'noneOptionText': instance.noneOptionText,
      'shuffleChoices' : instance.shuffleChoices,
      'minRequiredChoices': instance.minRequiredChoices,
      'maxAllowedChoices': instance.maxAllowedChoices,
      'maxAllowedChoicesErrorMessage': instance.maxAllowedChoicesErrorMessage,
    };
