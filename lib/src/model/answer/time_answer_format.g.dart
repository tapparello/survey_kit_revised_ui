// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_answer_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeAnswerFormat _$TimeAnswerFormatFromJson(Map<String, dynamic> json) =>
    TimeAnswerFormat(
      defaultValue: _$JsonConverterFromJson<Map<String, dynamic>, TimeOfDay?>(
        json['defaultValue'],
        const _TimeOfDayJsonConverter().fromJson,
      ),
      question: json['question'] as String?,
    );

Map<String, dynamic> _$TimeAnswerFormatToJson(
  TimeAnswerFormat instance,
) => <String, dynamic>{
  'question': instance.question,
  'defaultValue': const _TimeOfDayJsonConverter().toJson(instance.defaultValue),
  'type': _$AnswerFormatTypeEnumMap[instance.answerType]!,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

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
