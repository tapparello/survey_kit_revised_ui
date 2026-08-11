import 'package:flutter/material.dart' hide Step;
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/exception/survey_kit_exception.dart';
import 'package:survey_kit/src/model/answer/answer_format_type.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';

/// Discriminator for the conditional **parse directive**.
///
/// Deliberately not an [AnswerFormatType] member: it selects a format, it is
/// not one. Spelled `conditional` to match [ConditionalContent.type], and
/// deliberately *not* `custom`, which is already `CustomNavigationRule`'s
/// discriminator — one string with two meanings across two factories is what
/// this contract exists to remove.
const _conditionalDiscriminator = 'conditional';

/// Resolves a conditional directive to its concrete variant.
///
/// Parse-time by design. The resolved variant becomes `step.answerFormat`, so
/// `question_answer.dart` stamps the *variant's* discriminator onto every
/// result and `StepResult._convert` can never see `conditional`. Resolving
/// against prior in-section answers instead — as `ContentWidget` does for
/// conditional content — is Phase 3.
AnswerFormat _resolveConditional(
  Map<String, dynamic> json,
  Map<String, dynamic> variables,
) {
  final variable = json['variable'];
  if (variable is! String) {
    throw MalformedValueException(field: 'variable', value: variable);
  }

  final variants = json['variants'];
  if (variants is! Map<String, dynamic>) {
    throw MalformedValueException(field: 'variants', value: variants);
  }

  final defaultKey = json['default'];
  if (defaultKey is! String) {
    throw MalformedValueException(field: 'default', value: defaultKey);
  }
  if (!variants.containsKey(defaultKey)) {
    throw MalformedValueException(field: 'default', value: defaultKey);
  }

  final value = variables[variable]?.toString();
  final selected = (value != null && variants.containsKey(value))
      ? variants[value]
      : variants[defaultKey];

  if (selected is! Map<String, dynamic>) {
    throw MalformedValueException(field: 'variants', value: selected);
  }

  return AnswerFormat.fromJson(selected, variables: variables);
}

abstract class AnswerFormat {
  const AnswerFormat({this.question});

  final String? question;

  /// JSON discriminator identifying this format.
  ///
  /// Write-only by design: consumed by the dispatching [AnswerFormat.fromJson]
  /// factory below and never assigned from JSON. Removing includeToJson
  /// silently drops 'type' from every subclass's generated toJson; removing
  /// includeFromJson makes codegen emit an out-of-scope subclass constant that
  /// will not compile. See ADO #1001.
  ///
  /// A getter rather than a constructor parameter so a caller cannot construct
  /// one format while declaring another: [StepResult] dispatches result
  /// conversion on this value, so a mismatch would convert with the wrong
  /// branch in both directions. Each subclass must repeat the [JsonKey]
  /// annotation on its override, or json_serializable drops the key. (ADO #1012)
  ///
  /// An [AnswerFormatType] rather than a String so that a new format cannot
  /// compile without registering itself in the dispatch table, and so
  /// `StepResult._convert`'s switch can be exhaustive. (ADO #1015)
  @JsonKey(name: 'type', includeToJson: true, includeFromJson: false)
  AnswerFormatType get answerType;

  Map<String, dynamic> toJson();

  Widget createView(Step step, StepResult? stepResult);

  factory AnswerFormat.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic> variables = const {},
  }) {
    final type = json['type'] as String?;
    if (type == _conditionalDiscriminator) {
      return _resolveConditional(json, variables);
    }
    final member = AnswerFormatType.byWireName(type);
    if (member == null) {
      throw UnknownTypeException(
        kind: 'AnswerFormat',
        discriminator: type,
        expected: <String>[
          ...AnswerFormatType.values.map((e) => e.wireName),
          _conditionalDiscriminator,
        ].join(', '),
      );
    }
    return member.fromJson(json);
  }
}
