// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'single_choice_answer_with_feedback_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SingleChoiceAnswerWithFeedbackFormat
_$SingleChoiceAnswerWithFeedbackFormatFromJson(Map<String, dynamic> json) =>
    SingleChoiceAnswerWithFeedbackFormat(
      textChoices: (json['textChoices'] as List<dynamic>)
          .map((e) => TextChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      feedbackCorrect: json['feedbackCorrect'] as String?,
      feedbackWrong: json['feedbackWrong'] as String?,
      defaultSelection: json['defaultSelection'] == null
          ? null
          : TextChoice.fromJson(
              json['defaultSelection'] as Map<String, dynamic>,
            ),
      shuffleChoices: json['shuffleChoices'] as bool? ?? false,
      question: json['question'] as String?,
    );

Map<String, dynamic> _$SingleChoiceAnswerWithFeedbackFormatToJson(
  SingleChoiceAnswerWithFeedbackFormat instance,
) => <String, dynamic>{
  'question': instance.question,
  'textChoices': instance.textChoices.map((e) => e.toJson()).toList(),
  'defaultSelection': instance.defaultSelection?.toJson(),
  'shuffleChoices': instance.shuffleChoices,
  'feedbackCorrect': instance.feedbackCorrect,
  'feedbackWrong': instance.feedbackWrong,
  'type': instance.answerType,
};
