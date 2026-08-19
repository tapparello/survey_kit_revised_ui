import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/exception/survey_kit_exception.dart';
import 'package:survey_kit/src/model/answer/answer_format_type.dart';
import 'package:survey_kit/src/model/answer/conditional_answer_format.dart';

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

  factory AnswerFormat.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == ConditionalAnswerFormat.discriminator) {
      // Reaching here means a directive was parsed outside a step. It selects a
      // format, it is not one, so this factory cannot return it — Step.fromJson
      // owns that dispatch. (ADO #1045)
      throw MalformedValueException(field: 'type', value: type);
    }
    final member = AnswerFormatType.byWireName(type);
    if (member == null) {
      throw UnknownTypeException(
        kind: 'AnswerFormat',
        discriminator: type,
        expected: <String>[
          ...AnswerFormatType.values.map((e) => e.wireName),
          ConditionalAnswerFormat.discriminator,
        ].join(', '),
      );
    }
    return member.fromJson(json);
  }
}
