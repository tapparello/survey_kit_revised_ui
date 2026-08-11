// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'double_answer_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DoubleAnswerFormat _$DoubleAnswerFormatFromJson(Map<String, dynamic> json) =>
    DoubleAnswerFormat(
      defaultValue: (json['defaultValue'] as num?)?.toDouble(),
      hint: json['hint'] as String? ?? '',
      question: json['question'] as String?,
    );

Map<String, dynamic> _$DoubleAnswerFormatToJson(DoubleAnswerFormat instance) =>
    <String, dynamic>{
      'question': instance.question,
      'defaultValue': instance.defaultValue,
      'hint': instance.hint,
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
