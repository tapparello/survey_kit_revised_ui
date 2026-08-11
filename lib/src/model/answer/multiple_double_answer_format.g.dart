// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multiple_double_answer_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MultipleDoubleAnswerFormat _$MultipleDoubleAnswerFormatFromJson(
  Map<String, dynamic> json,
) => MultipleDoubleAnswerFormat(
  defaultValues: (json['defaultValues'] as List<dynamic>?)
      ?.map((e) => MultiDouble.fromJson(e as Map<String, dynamic>))
      .toList(),
  hints:
      (json['hints'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  question: json['question'] as String?,
);

Map<String, dynamic> _$MultipleDoubleAnswerFormatToJson(
  MultipleDoubleAnswerFormat instance,
) => <String, dynamic>{
  'question': instance.question,
  'defaultValues': instance.defaultValues?.map((e) => e.toJson()).toList(),
  'hints': instance.hints,
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
