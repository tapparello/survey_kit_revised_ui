// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'html_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HtmlContent _$HtmlContentFromJson(Map<String, dynamic> json) => HtmlContent(
      html: json['html'] as String,
      id: json['id'] as String?,
    );

Map<String, dynamic> _$HtmlContentToJson(HtmlContent instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['html'] = instance.html;
  val['type'] = 'html';
  return val;
}
