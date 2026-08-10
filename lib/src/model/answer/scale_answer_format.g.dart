// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scale_answer_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScaleAnswerFormat _$ScaleAnswerFormatFromJson(Map<String, dynamic> json) =>
    ScaleAnswerFormat(
      maximumValue: (json['maximumValue'] as num).toDouble(),
      minimumValue: (json['minimumValue'] as num).toDouble(),
      defaultValue: (json['defaultValue'] as num).toDouble(),
      step: (json['step'] as num).toDouble(),
      maximumValueDescription: json['maximumValueDescription'] as String? ?? '',
      minimumValueDescription: json['minimumValueDescription'] as String? ?? '',
      isVertical: json['isVertical'] as bool? ?? false,
      isAge: json['isAge'] as bool? ?? false,
      acceptedMinimumValue: (json['acceptedMinimumValue'] as num?)?.toDouble(),
      acceptedMaximumValue: (json['acceptedMaximumValue'] as num?)?.toDouble(),
      bands:
          (json['bands'] as List<dynamic>?)
              ?.map((e) => ScaleBand.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      question: json['question'] as String?,
    );

Map<String, dynamic> _$ScaleAnswerFormatToJson(ScaleAnswerFormat instance) =>
    <String, dynamic>{
      'question': instance.question,
      'maximumValue': instance.maximumValue,
      'minimumValue': instance.minimumValue,
      'defaultValue': instance.defaultValue,
      'step': instance.step,
      'maximumValueDescription': instance.maximumValueDescription,
      'minimumValueDescription': instance.minimumValueDescription,
      'isVertical': instance.isVertical,
      'isAge': instance.isAge,
      'acceptedMinimumValue': instance.acceptedMinimumValue,
      'acceptedMaximumValue': instance.acceptedMaximumValue,
      'bands': instance.bands.map((e) => e.toJson()).toList(),
      'type': instance.answerType,
    };
