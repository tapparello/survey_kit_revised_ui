import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/exception/survey_kit_exception.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/task/navigable_task.dart';
import 'package:survey_kit/src/task/ordered_task.dart';
import 'package:uuid/uuid.dart';

/// Abstract definition of survey task
///
/// If you want to create a custom task:
///  * Inherit from Task
///  * If you want to use JSON override [fromJson] and add your type
@immutable
abstract class Task {
  late final String id;
  @JsonKey(defaultValue: <Step>[])
  final List<Step> steps;
  final Step? initialStep;
  @JsonKey(defaultValue: <String, dynamic>{})
  final Map<String, dynamic> variables;

  /// Optional override for the total step count shown in the progress bar.
  /// When null, defaults to `steps.length`.
  final int? stepCount;

  Task({
    String? id,
    this.steps = const [],
    this.initialStep,
    Map<String, dynamic>? variables,
    this.stepCount,
  }) : id = id ?? const Uuid().v4(),
       variables = variables ?? {};

  /// Creates a task from a Map. The task needs a `type` of either 'ordered' —
  /// [OrderedTask] — or 'navigable' — [NavigableTask]. If neither, it throws
  /// an [UnknownTypeException].
  factory Task.fromJson(
    Map<String, dynamic> json, {
    SurveyRegistries? registries,
  }) {
    final type = json['type'] as String?;
    if (type == 'ordered') {
      return OrderedTask.fromJson(json, registries: registries);
    }
    if (type == 'navigable') {
      return NavigableTask.fromJson(json, registries: registries);
    }
    throw UnknownTypeException(
      kind: 'Task',
      discriminator: type,
      expected: 'ordered or navigable',
    );
  }

  /// The wire fields every task shares. Subclasses spread this and add their
  /// own.
  ///
  /// `initialStepId` is derived rather than stored: [initialStep] holds a
  /// resolved [Step], and the id is the key [Task.fromJson] reads back. Both
  /// readers do `json['id'] as String` — a non-null cast — so emitting `id`
  /// unconditionally is load-bearing, not cosmetic.
  @protected
  Map<String, dynamic> baseJson(String type) => <String, dynamic>{
    'type': type,
    'id': id,
    'steps': steps.map((step) => step.toJson()).toList(),
    'initialStepId': initialStep?.id,
    // Copied, not aliased: the field is final but the map is not — the
    // constructor above defaults it to a growable `{}` — so emitting it
    // directly would hand a caller a live handle to this task's own state via
    // `task.toJson()['variables']`. The generated writer this replaces aliased.
    'variables': Map<String, dynamic>.from(variables),
    'stepCount': stepCount,
  };

  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) => other is Task && other.id == id;
  @override
  int get hashCode => id.hashCode ^ steps.hashCode;
}
