// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multiple_choice_answer_with_feedback_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MultipleChoiceAnswerWithFeedbackFormat
_$MultipleChoiceAnswerWithFeedbackFormatFromJson(Map<String, dynamic> json) =>
    MultipleChoiceAnswerWithFeedbackFormat(
      textChoices: (json['textChoices'] as List<dynamic>)
          .map((e) => TextChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      feedbackCorrect: json['feedbackCorrect'] as String?,
      feedbackWrong: json['feedbackWrong'] as String?,
      coloredFeedback: json['coloredFeedback'] as bool? ?? false,
      choicesFromVariable: json['choicesFromVariable'] as String?,
      defaultSelection: json['defaultSelection'] == null
          ? null
          : TextChoice.fromJson(
              json['defaultSelection'] as Map<String, dynamic>,
            ),
      shuffleChoices: json['shuffleChoices'] as bool? ?? false,
      minRequiredChoices: (json['minRequiredChoices'] as num?)?.toInt() ?? 1,
      maxAllowedChoices: (json['maxAllowedChoices'] as num?)?.toInt() ?? 999,
      maxAllowedChoicesErrorMessage:
          json['maxAllowedChoicesErrorMessage'] as String?,
      noneOption: json['noneOption'] as bool? ?? false,
      noneOptionText: json['noneOptionText'] as String?,
      question: json['question'] as String?,
    );

Map<String, dynamic> _$MultipleChoiceAnswerWithFeedbackFormatToJson(
  MultipleChoiceAnswerWithFeedbackFormat instance,
) => <String, dynamic>{
  'question': instance.question,
  'textChoices': instance.textChoices.map((e) => e.toJson()).toList(),
  'defaultSelection': instance.defaultSelection?.toJson(),
  'choicesFromVariable': instance.choicesFromVariable,
  'minRequiredChoices': instance.minRequiredChoices,
  'maxAllowedChoices': instance.maxAllowedChoices,
  'maxAllowedChoicesErrorMessage': instance.maxAllowedChoicesErrorMessage,
  'shuffleChoices': instance.shuffleChoices,
  'noneOption': instance.noneOption,
  'noneOptionText': instance.noneOptionText,
  'feedbackCorrect': instance.feedbackCorrect,
  'feedbackWrong': instance.feedbackWrong,
  'coloredFeedback': instance.coloredFeedback,
  'type': instance.answerType,
};
