// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'single_choice_answer_with_feedback_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SingleChoiceAnswerWithFeedbackFormat _$SingleChoiceAnswerWithFeedbackFormatFromJson(
        Map<String, dynamic> json) =>
    SingleChoiceAnswerWithFeedbackFormat(
      textChoices: (json['textChoices'] as List<dynamic>)
          .map((e) => TextChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      shuffleChoices: json['shuffleChoices'] as bool? ?? false,
      defaultSelection: json['defaultSelection'] == null
          ? null
          : TextChoice.fromJson(
              json['defaultSelection'] as Map<String, dynamic>),
      question: json['question'] as String?,
      answerType: json['type'] as String?,
      feedbackCorrect: json['feedbackCorrect'] as String?,
      feedbackWrong: json['feedbackWrong'] as String?,
    );

Map<String, dynamic> _$SingleChoiceAnswerWithFeedbackFormatToJson(
    SingleChoiceAnswerWithFeedbackFormat instance) =>
    <String, dynamic>{
      'question': instance.question,
      'type': instance.answerType,
      'textChoices': instance.textChoices.map((e) => e.toJson()).toList(),
      'shuffleChoices' : instance.shuffleChoices,
      'defaultSelection': instance.defaultSelection?.toJson(),
      'feedbackCorrect': instance.feedbackCorrect,
      'feedbackWrong': instance.feedbackWrong,
    };
