// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multiple_choice_answer_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MultipleChoiceAnswerFormat _$MultipleChoiceAnswerFormatFromJson(
        Map<String, dynamic> json) =>
    MultipleChoiceAnswerFormat(
      textChoices: (json['textChoices'] as List<dynamic>)
          .map((e) => TextChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      choicesFromVariable: json['choicesFromVariable'] as String?,
      otherField: json['otherField'] as bool? ?? false,
      shuffleChoices: json['shuffleChoices'] as bool? ?? false,
      minRequiredChoices: json['minRequiredChoices'] as int? ?? 1,
      maxAllowedChoices: json['maxAllowedChoices'] as int? ?? 999,
      maxAllowedChoicesErrorMessage: json['maxAllowedChoicesErrorMessage'] as String?,
      otherHintText: json['otherHintText'] as String?,
      noneOption: json['noneOption'] as bool? ?? false,
      noneOptionText: json['noneOptionText'] as String?,
      defaultSelection: json['defaultSelection'] == null
          ? null
          : TextChoice.fromJson(
              json['defaultSelection'] as Map<String, dynamic>),
      question: json['question'] as String?,
      answerType: json['type'] as String?,
    );

Map<String, dynamic> _$MultipleChoiceAnswerFormatToJson(
        MultipleChoiceAnswerFormat instance) =>
    <String, dynamic>{
      'question': instance.question,
      'type': instance.answerType,
      'textChoices': instance.textChoices,
      'choicesFromVariable': instance.choicesFromVariable,
      'defaultSelection': instance.defaultSelection,
      'otherField': instance.otherField,
      'otherHintText': instance.otherHintText,
      'noneOption': instance.noneOption,
      'noneOptionText': instance.noneOptionText,
      'shuffleChoices' : instance.shuffleChoices,
      'minRequiredChoices': instance.minRequiredChoices,
      'maxAllowedChoices': instance.maxAllowedChoices,
      'maxAllowedChoicesErrorMessage': instance.maxAllowedChoicesErrorMessage,
    };
