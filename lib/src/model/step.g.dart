// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'step.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$StepToJson(Step instance) => <String, dynamic>{
  'id': instance.id,
  'isMandatory': instance.isMandatory,
  'answerFormat': instance.answerFormat?.toJson(),
  'buttonText': ?instance.buttonText,
  'content': instance.content.map((e) => e.toJson()).toList(),
};
