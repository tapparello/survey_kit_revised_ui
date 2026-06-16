// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scale_band.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScaleBand _$ScaleBandFromJson(Map<String, dynamic> json) => ScaleBand(
  min: (json['min'] as num).toDouble(),
  max: (json['max'] as num).toDouble(),
  name: json['name'] as String,
  labelAt: (json['labelAt'] as num).toDouble(),
);

Map<String, dynamic> _$ScaleBandToJson(ScaleBand instance) => <String, dynamic>{
  'min': instance.min,
  'max': instance.max,
  'name': instance.name,
  'labelAt': instance.labelAt,
};
