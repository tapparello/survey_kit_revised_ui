// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multiple_choice_answer_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MultipleChoiceAnswerFormat _$MultipleChoiceAnswerFormatFromJson(
  Map<String, dynamic> json,
) => MultipleChoiceAnswerFormat(
  textChoices: (json['textChoices'] as List<dynamic>)
      .map((e) => TextChoice.fromJson(e as Map<String, dynamic>))
      .toList(),
  choicesFromVariable: json['choicesFromVariable'] as String?,
  otherField: json['otherField'] as bool? ?? false,
  defaultSelection: json['defaultSelection'] == null
      ? null
      : TextChoice.fromJson(json['defaultSelection'] as Map<String, dynamic>),
  shuffleChoices: json['shuffleChoices'] as bool? ?? false,
  minRequiredChoices: (json['minRequiredChoices'] as num?)?.toInt() ?? 1,
  maxAllowedChoices: (json['maxAllowedChoices'] as num?)?.toInt() ?? 999,
  maxAllowedChoicesErrorMessage:
      json['maxAllowedChoicesErrorMessage'] as String?,
  noneOption: json['noneOption'] as bool? ?? false,
  noneOptionText: json['noneOptionText'] as String?,
  otherHintText: json['otherHintText'] as String?,
  question: json['question'] as String?,
);

Map<String, dynamic> _$MultipleChoiceAnswerFormatToJson(
  MultipleChoiceAnswerFormat instance,
) => <String, dynamic>{
  'question': instance.question,
  'type': instance.answerType,
  'textChoices': instance.textChoices.map((e) => e.toJson()).toList(),
  'defaultSelection': instance.defaultSelection?.toJson(),
  'choicesFromVariable': instance.choicesFromVariable,
  'minRequiredChoices': instance.minRequiredChoices,
  'maxAllowedChoices': instance.maxAllowedChoices,
  'maxAllowedChoicesErrorMessage': instance.maxAllowedChoicesErrorMessage,
  'shuffleChoices': instance.shuffleChoices,
  'noneOption': instance.noneOption,
  'noneOptionText': instance.noneOptionText,
  'otherField': instance.otherField,
  'otherHintText': instance.otherHintText,
};
