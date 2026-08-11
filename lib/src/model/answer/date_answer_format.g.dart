// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'date_answer_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DateAnswerFormat _$DateAnswerFormatFromJson(Map<String, dynamic> json) =>
    DateAnswerFormat(
      defaultDate: json['defaultDate'] == null
          ? null
          : DateTime.parse(json['defaultDate'] as String),
      minDate: json['minDate'] == null
          ? null
          : DateTime.parse(json['minDate'] as String),
      maxDate: json['maxDate'] == null
          ? null
          : DateTime.parse(json['maxDate'] as String),
      futureOnly: json['futureOnly'] as bool? ?? false,
      question: json['question'] as String?,
    );

Map<String, dynamic> _$DateAnswerFormatToJson(DateAnswerFormat instance) =>
    <String, dynamic>{
      'question': instance.question,
      'defaultDate': instance.defaultDate?.toIso8601String(),
      'minDate': instance.minDate?.toIso8601String(),
      'maxDate': instance.maxDate?.toIso8601String(),
      'futureOnly': instance.futureOnly,
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
