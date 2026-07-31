// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ordered_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$OrderedTaskToJson(OrderedTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'steps': instance.steps.map((e) => e.toJson()).toList(),
      'initialStep': instance.initialStep?.toJson(),
      'variables': instance.variables,
      'stepCount': instance.stepCount,
      'hashCode': instance.hashCode,
    };
