// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integer_answer_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntegerAnswerFormat _$IntegerAnswerFormatFromJson(Map<String, dynamic> json) =>
    IntegerAnswerFormat(
      defaultValue: (json['defaultValue'] as num?)?.toInt(),
      hint: json['hint'] as String? ?? '',
      min: (json['min'] as num?)?.toInt() ?? minInt,
      max: (json['max'] as num?)?.toInt() ?? maxInt,
      question: json['question'] as String?,
    );

Map<String, dynamic> _$IntegerAnswerFormatToJson(
  IntegerAnswerFormat instance,
) => <String, dynamic>{
  'question': instance.question,
  'defaultValue': instance.defaultValue,
  'hint': instance.hint,
  'min': instance.min,
  'max': instance.max,
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
