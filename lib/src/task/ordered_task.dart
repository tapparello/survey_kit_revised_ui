import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/task/task.dart';

part 'ordered_task.g.dart';

/// Defines a [Task] which handles its steps in the order of the [steps] list.
@JsonSerializable(createFactory: false)
class OrderedTask extends Task {
  OrderedTask({
    required String id,
    required List<Step> steps,
    String? initialStepId,
    Map<String, dynamic>? variables,
  }) : super(
          id: id,
          steps: steps,
          initialStep: steps.firstWhereOrNull((step) => step.id == initialStepId),
          variables: variables,
        );

  factory OrderedTask.fromJson(Map<String, dynamic> json) {
    final variables = (json['variables'] as Map<String, dynamic>?) ?? {};
    return OrderedTask(
      id: json['id'] as String,
      steps: json['steps'] != null
          ? (json['steps'] as List)
              .map(
                (dynamic step) => Step.fromJson(step as Map<String, dynamic>),
              )
              .toList()
          : [],
      initialStepId: json['initialStepId'] as String?,
      variables: variables,
    );
  }



  @override
  Map<String, dynamic> toJson() => _$OrderedTaskToJson(this);
}
