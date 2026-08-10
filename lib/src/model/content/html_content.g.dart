// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'html_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HtmlContent _$HtmlContentFromJson(Map<String, dynamic> json) => HtmlContent(
  html: json['html'] as String,
  id: json['id'] as String?,
  separatorAfter: json['separatorAfter'] as bool? ?? true,
);

Map<String, dynamic> _$HtmlContentToJson(HtmlContent instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'type': instance.contentType,
      'separatorAfter': instance.separatorAfter,
      'html': instance.html,
    };
