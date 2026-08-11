import 'package:flutter/foundation.dart' show objectRuntimeType;

/// The root of every failure `survey_kit` throws.
///
/// This hierarchy is **sealed**: every subtype is declared in this library, so a
/// `switch` over a [SurveyKitException] can be exhaustive. Consumers needing
/// their own failure types should declare them independently rather than
/// extending this one.
sealed class SurveyKitException implements Exception {
  const SurveyKitException(this.message);

  /// Human-readable description of what failed.
  ///
  /// Diagnostic, not a stable contract — do not parse it. The structured fields
  /// on each subtype are the supported way to branch on a failure.
  final String message;

  /// Note this names the concrete subtype in **debug** builds only.
  /// [objectRuntimeType] resolves the real type inside an `assert`, so profile
  /// and release builds report the `SurveyKitException` fallback for every
  /// subtype. Branch on the type or the structured fields, not on this string.
  @override
  String toString() =>
      '${objectRuntimeType(this, 'SurveyKitException')}: $message';
}

/// A step reached an answer view without declaring an answer format.
final class MissingAnswerFormatException extends SurveyKitException {
  const MissingAnswerFormatException({
    required this.stepId,
    required this.expected,
  }) : super(
         "Step '$stepId' declares no answerFormat, but $expected is required "
         'to render it.',
       );

  /// Id of the step that is missing its format.
  final String stepId;

  /// Name of the `AnswerFormat` subtype the view requires.
  final String expected;
}

/// A step declared an answer format of the wrong subtype for its view.
final class AnswerFormatMismatchException extends SurveyKitException {
  const AnswerFormatMismatchException({
    required this.stepId,
    required this.expected,
    required this.actual,
  }) : super(
         "Step '$stepId' declares an answerFormat of type $actual, but "
         '$expected is required to render it.',
       );

  /// Id of the step whose format does not match its view.
  final String stepId;

  /// Name of the `AnswerFormat` subtype the view requires.
  final String expected;

  /// Name of the `AnswerFormat` subtype the step actually declares.
  final String actual;
}

/// An `of(context)` lookup found no matching ancestor in the widget tree.
final class SurveyKitScopeException extends SurveyKitException {
  const SurveyKitScopeException({required this.widgetType, required this.hint})
    : super(
        '$widgetType.of() was called with a BuildContext that has no '
        '$widgetType ancestor. $hint',
      );

  /// Name of the InheritedWidget that was looked up and not found.
  final String widgetType;

  /// Call-site-specific remedy.
  ///
  /// Required rather than defaulted, because the lookup sites have genuinely
  /// different fixes: `SurveyConfiguration` and `SurveyStateProvider` wrap
  /// SurveyKit's whole subtree, while `QuestionAnswer` exists only inside a
  /// single step's answer view.
  final String hint;
}

/// A serialized value could not be parsed into its model type.
final class MalformedValueException extends SurveyKitException {
  const MalformedValueException({required this.field, required this.value})
    : super("Could not parse '$field' from the serialized value: $value");

  /// Name of the JSON field that could not be parsed.
  final String field;

  /// The offending value, as it appeared in JSON. May be null.
  final Object? value;
}

/// A task that is neither `OrderedTask` nor `NavigableTask` reached `SurveyKit`.
final class UnsupportedTaskException extends SurveyKitException {
  const UnsupportedTaskException({required this.taskType})
    : super(
        '$taskType is not a supported Task. SurveyKit can present OrderedTask '
        'and NavigableTask only.',
      );

  /// Runtime type name of the unsupported task.
  final String taskType;
}

/// A JSON `type` discriminator matched no known implementation.
final class UnknownTypeException extends SurveyKitException {
  const UnknownTypeException({
    required this.kind,
    this.discriminator,
    this.expected,
  }) : super(
         discriminator == null
             ? 'No $kind implementation matched: the JSON carries no type '
                   'discriminator.'
                   '${expected == null ? '' : ' Expected $expected.'}'
             : 'No $kind implementation matched the type discriminator '
                   "'$discriminator'."
                   '${expected == null ? '' : ' Expected $expected.'}',
       );

  /// The abstract family being resolved, e.g. `'AnswerFormat'`.
  final String kind;

  /// The unmatched discriminator, or null when the JSON carried none.
  final String? discriminator;

  /// Human-readable list of the discriminators this family accepts, e.g.
  /// `'ordered or navigable'`.
  ///
  /// A `String?` rather than a `List<String>`: [message] is built in a `const`
  /// super-initializer, and a list cannot be interpolated there.
  final String? expected;
}

/// A step result could not be converted to or from its serialized form.
///
/// Thrown rather than yielding an untyped value, so a caller that cannot decode
/// a persisted record discards it instead of receiving raw JSON. Records written
/// before Phase 2b carry no `answerType` and always fail this way.
final class ResultCodecException extends SurveyKitException {
  const ResultCodecException({
    required this.stepId,
    required this.answerType,
    required this.cause,
  }) : super(
         answerType == null
             ? "Result for step '$stepId' carries no answerType, so it cannot "
                   'be converted: $cause'
             : "Result for step '$stepId' with answerType '$answerType' could "
                   'not be converted: $cause',
       );

  /// Id of the step whose result failed to convert.
  final String stepId;

  /// The result's declared answer-format discriminator, or null when the
  /// serialized record carried none.
  ///
  /// The discriminator rather than a Dart type name: it is one of a fixed set of
  /// authored constants and so survives `--obfuscate`, and it is what a reader
  /// can act on.
  final String? answerType;

  /// Description of the underlying failure.
  final String cause;
}
