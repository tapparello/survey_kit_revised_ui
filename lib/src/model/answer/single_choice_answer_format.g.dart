// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'single_choice_answer_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SingleChoiceAnswerFormat _$SingleChoiceAnswerFormatFromJson(
  Map<String, dynamic> json,
) => SingleChoiceAnswerFormat(
  textChoices: (json['textChoices'] as List<dynamic>)
      .map((e) => TextChoice.fromJson(e as Map<String, dynamic>))
      .toList(),
  choicesFromVariable: json['choicesFromVariable'] as String?,
  defaultSelection: json['defaultSelection'] == null
      ? null
      : TextChoice.fromJson(json['defaultSelection'] as Map<String, dynamic>),
  shuffleChoices: json['shuffleChoices'] as bool? ?? false,
  question: json['question'] as String?,
);

Map<String, dynamic> _$SingleChoiceAnswerFormatToJson(
  SingleChoiceAnswerFormat instance,
) => <String, dynamic>{
  'question': instance.question,
  'textChoices': instance.textChoices.map((e) => e.toJson()).toList(),
  'choicesFromVariable': instance.choicesFromVariable,
  'defaultSelection': instance.defaultSelection?.toJson(),
  'shuffleChoices': instance.shuffleChoices,
  'type': _$AnswerFormatTypeEnumMap[instance.answerType]!,
};

const _$AnswerFormatTypeEnumMap = {
  AnswerFormatType.boolean: 'bool',
  AnswerFormatType.date: 'date',
  AnswerFormatType.doubleValue: 'double',
  AnswerFormatType.integer: 'integer',
  AnswerFormatType.image: 'image',
  AnswerFormatType.text: 'text',
  AnswerFormatType.time: 'time',
  AnswerFormatType.scale: 'scale',
  AnswerFormatType.single: 'single',
  AnswerFormatType.singleWithFeedback: 'single_with_feedback',
  AnswerFormatType.multi: 'multi',
  AnswerFormatType.multiWithFeedback: 'multi_with_feedback',
  AnswerFormatType.multipleAutoComplete: 'multiple_auto_complete',
  AnswerFormatType.multipleDouble: 'multiple_double',
};
