import 'package:survey_kit/src/exception/survey_kit_exception.dart';
import 'package:survey_kit/src/model/answer/answer_format.dart';
import 'package:survey_kit/src/model/step.dart';

/// Returns [step]'s `answerFormat` narrowed to [T].
///
/// Throws [MissingAnswerFormatException] when the step declares no format, and
/// [AnswerFormatMismatchException] when it declares one of the wrong subtype.
/// Both replace what were previously an untyped `Exception` and an unchecked
/// cast raising a bare `TypeError`.
///
/// Type names in the messages come from `Type` interpolation and are mangled by
/// `--obfuscate`; they are diagnostic only. Branch on the exception's structured
/// fields instead.
T requireAnswerFormat<T extends AnswerFormat>(Step step) {
  final format = step.answerFormat;
  if (format == null) {
    throw MissingAnswerFormatException(stepId: step.id, expected: '$T');
  }
  if (format is! T) {
    throw AnswerFormatMismatchException(
      stepId: step.id,
      expected: '$T',
      actual: '${format.runtimeType}',
    );
  }
  return format;
}
