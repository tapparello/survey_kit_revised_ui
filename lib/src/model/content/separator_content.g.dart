// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'separator_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeparatorContent _$SeparatorContentFromJson(Map<String, dynamic> json) =>
    SeparatorContent(
      height: (json['height'] as num?)?.toDouble() ?? 14,
      id: json['id'] as String?,
    );

Map<String, dynamic> _$SeparatorContentToJson(SeparatorContent instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'type': instance.contentType,
      'height': instance.height,
    };
