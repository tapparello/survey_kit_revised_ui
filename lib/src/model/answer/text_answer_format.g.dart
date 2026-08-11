// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_answer_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextAnswerFormat _$TextAnswerFormatFromJson(Map<String, dynamic> json) =>
    TextAnswerFormat(
      maxLines: (json['maxLines'] as num?)?.toInt(),
      hint: json['hint'] as String? ?? '',
      validationRegEx: json['validationRegEx'] as String? ?? r'^(?!s*$).+',
      question: json['question'] as String?,
    );

Map<String, dynamic> _$TextAnswerFormatToJson(TextAnswerFormat instance) =>
    <String, dynamic>{
      'question': instance.question,
      'maxLines': instance.maxLines,
      'hint': instance.hint,
      'validationRegEx': instance.validationRegEx,
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
