// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'separator_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeparatorContent _$SeparatorContentFromJson(Map<String, dynamic> json) =>
    SeparatorContent(
      height: (json['height'] as num).toDouble(),
      id: json['id'] as String?,
    );

Map<String, dynamic> _$SeparatorContentToJson(SeparatorContent instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['height'] = instance.height;
  return val;
}
