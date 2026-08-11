// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boolean_answer_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BooleanAnswerFormat _$BooleanAnswerFormatFromJson(Map<String, dynamic> json) =>
    BooleanAnswerFormat(
      positiveAnswer: json['positiveAnswer'] as String,
      negativeAnswer: json['negativeAnswer'] as String,
      result:
          $enumDecodeNullable(_$BooleanResultEnumMap, json['result']) ??
          BooleanResult.none,
      question: json['question'] as String?,
    );

Map<String, dynamic> _$BooleanAnswerFormatToJson(
  BooleanAnswerFormat instance,
) => <String, dynamic>{
  'question': instance.question,
  'positiveAnswer': instance.positiveAnswer,
  'negativeAnswer': instance.negativeAnswer,
  'result': _$BooleanResultEnumMap[instance.result]!,
  'type': _$AnswerFormatTypeEnumMap[instance.answerType]!,
};

const _$BooleanResultEnumMap = {
  BooleanResult.none: 'none',
  BooleanResult.positive: 'positive',
  BooleanResult.negative: 'negative',
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
