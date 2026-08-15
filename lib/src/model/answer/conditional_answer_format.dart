import 'package:survey_kit/src/exception/survey_kit_exception.dart';
import 'package:survey_kit/src/model/answer/answer_format.dart';

/// A conditional answer-format directive, validated but not yet resolved.
///
/// Deliberately **not** an [AnswerFormat] subclass and deliberately absent from
/// `AnswerFormatType`. `question_answer.dart` stamps `step.answerFormat`'s
/// discriminator onto every result and `StepResult._convert` switches on it; a
/// `conditional` member there would be an arm that can only throw. Keeping the
/// directive off the enum means `answerFormat` is **always concrete** wherever a
/// view or a result sees it.
///
/// Shape is validated here, at parse time, so a malformed directive still fails
/// loudly when the task loads. Only the value lookup defers to present time —
/// see [resolve], which cannot fail. (ADO #1045)
class ConditionalAnswerFormat {
  const ConditionalAnswerFormat({
    required this.variable,
    required this.variants,
    required this.defaultKey,
    required this.sourceJson,
  });

  /// The variable whose value selects a variant.
  final String variable;

  /// Every variant, fully parsed. Eager by design: it is what makes [resolve]
  /// total. Before ADO #1045 only the selected variant was parsed, so a broken
  /// never-selected variant loaded fine — see the CHANGELOG.
  final Map<String, AnswerFormat> variants;

  /// A key proven present in [variants] at parse time.
  final String defaultKey;

  /// The directive exactly as authored, kept for `Step.toJson`.
  ///
  /// Reconstructing the wire shape from the fields above is lossy: real
  /// directives carry keys this class has no room for (the consumer's carry
  /// `formatId`). Retaining the source map is cheaper and exact.
  final Map<String, dynamic> sourceJson;

  factory ConditionalAnswerFormat.fromJson(Map<String, dynamic> json) {
    final variable = json['variable'];
    if (variable is! String) {
      throw MalformedValueException(field: 'variable', value: variable);
    }

    final rawVariants = json['variants'];
    if (rawVariants is! Map<String, dynamic>) {
      throw MalformedValueException(field: 'variants', value: rawVariants);
    }

    final defaultKey = json['default'];
    if (defaultKey is! String || !rawVariants.containsKey(defaultKey)) {
      throw MalformedValueException(field: 'default', value: defaultKey);
    }

    final variants = <String, AnswerFormat>{};
    rawVariants.forEach((key, dynamic value) {
      if (value is! Map<String, dynamic>) {
        throw MalformedValueException(field: 'variants', value: value);
      }
      variants[key] = AnswerFormat.fromJson(value);
    });

    return ConditionalAnswerFormat(
      variable: variable,
      variants: variants,
      defaultKey: defaultKey,
      sourceJson: json,
    );
  }

  /// Selects a variant against [variables].
  ///
  /// Total: parse proved [defaultKey] names a variant, so the fallback always
  /// hits. This is the half of the old `_resolveConditional` that moved to
  /// present time.
  AnswerFormat resolve(Map<String, dynamic> variables) {
    final value = variables[variable]?.toString();
    return variants[value] ?? variants[defaultKey]!;
  }
}
