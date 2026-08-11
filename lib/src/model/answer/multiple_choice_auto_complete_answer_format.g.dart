// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multiple_choice_auto_complete_answer_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MultipleChoiceAutoCompleteAnswerFormat
_$MultipleChoiceAutoCompleteAnswerFormatFromJson(Map<String, dynamic> json) =>
    MultipleChoiceAutoCompleteAnswerFormat(
      textChoices: (json['textChoices'] as List<dynamic>)
          .map((e) => TextChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultSelection:
          (json['defaultSelection'] as List<dynamic>?)
              ?.map((e) => TextChoice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      suggestions:
          (json['suggestions'] as List<dynamic>?)
              ?.map((e) => TextChoice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      otherField: json['otherField'] as bool? ?? false,
      question: json['question'] as String?,
    );

Map<String, dynamic> _$MultipleChoiceAutoCompleteAnswerFormatToJson(
  MultipleChoiceAutoCompleteAnswerFormat instance,
) => <String, dynamic>{
  'question': instance.question,
  'textChoices': instance.textChoices.map((e) => e.toJson()).toList(),
  'defaultSelection': instance.defaultSelection.map((e) => e.toJson()).toList(),
  'suggestions': instance.suggestions.map((e) => e.toJson()).toList(),
  'otherField': instance.otherField,
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
