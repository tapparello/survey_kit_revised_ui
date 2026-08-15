import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/model/answer/answer_format.dart';
import 'package:survey_kit/src/model/answer/conditional_answer_format.dart';
import 'package:survey_kit/src/model/content/content.dart';
import 'package:survey_kit/src/survey_kit.dart';
import 'package:uuid/uuid.dart';

part 'step.g.dart';

// createFactory: false — Step declares a hand-written fromJson (below) that
// threads `registries`. The generated factory could not pass
// registries, so it parsed content registry-less and forced Content.fromJson to
// keep a shape-inference fallback for it. It had no callers. See ADO #1015.
@JsonSerializable(createFactory: false)
class Step {
  final String id;
  final bool isMandatory;
  final AnswerFormat? answerFormat;

  /// A validated but unresolved conditional directive. Mutually exclusive with
  /// [answerFormat]; `SurveyEngine` resolves it when the step is presented.
  ///
  /// Excluded from codegen: `ConditionalAnswerFormat` is not a serialisable
  /// type, and `toJson` below re-emits it under the `answerFormat` key instead.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final ConditionalAnswerFormat? conditionalAnswerFormat;
  @JsonKey(defaultValue: 'Next', includeIfNull: false)
  final String? buttonText;
  final List<Content> content;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final StepShell? stepShell;

  Step({
    String? id,
    required this.content,
    this.isMandatory = true,
    this.answerFormat,
    this.conditionalAnswerFormat,
    this.buttonText,
    this.stepShell,
  }) : id = id ?? const Uuid().v4(),
       assert(
         answerFormat == null || conditionalAnswerFormat == null,
         'A step has either a concrete answerFormat or a conditional directive, '
         'never both.',
       );

  factory Step.fromJson(
    Map<String, dynamic> json, {
    SurveyRegistries? registries,
  }) {
    // Registry first. Unlike the other dispatching factories, an absent or
    // unrecognised discriminator is not an error here — every built-in step
    // is authored without one — so this falls through rather than throwing.
    // resolveStep already returns null for a null or unregistered type.
    final custom = registries?.resolveStep(json);
    if (custom != null) return custom;

    final rawFormat = json['answerFormat'] as Map<String, dynamic>?;
    final isConditional =
        rawFormat != null &&
        rawFormat['type'] == ConditionalAnswerFormat.discriminator;

    return Step(
      id: json['id'] as String?,
      content: (json['content'] as List<dynamic>)
          .map(
            (e) => Content.fromJson(
              e as Map<String, dynamic>,
              registries: registries,
            ),
          )
          .toList(),
      isMandatory: json['isMandatory'] as bool? ?? true,
      answerFormat: rawFormat == null || isConditional
          ? null
          : AnswerFormat.fromJson(rawFormat),
      conditionalAnswerFormat: isConditional
          ? ConditionalAnswerFormat.fromJson(rawFormat)
          : null,
      buttonText: json['buttonText'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = _$StepToJson(this);
    final directive = conditionalAnswerFormat;
    if (directive != null) {
      // The generator emits null for answerFormat on a conditional step, which
      // would lose the format entirely. Re-emit the authored directive — from
      // the source map, so keys this package has no field for (the consumer's
      // `formatId`) survive.
      json['answerFormat'] = directive.sourceJson;
    }
    return json;
  }

  /// Builds the resolved copy `SurveyEngine` presents: same step, with
  /// [content] expanded and [answerFormat] made concrete.
  ///
  /// Public because `SurveyEngine` calls it from another library. Not
  /// `@protected`: that annotation permits invocation only from the declaring
  /// class or a subclass, and would make `flutter analyze --fatal-infos` fail
  /// at the engine's call site.
  ///
  /// Override this in a `Step` subclass that adds state, or the copy downgrades
  /// to a plain [Step] and that state is lost. The engine logs a warning when
  /// the returned `runtimeType` differs from the input's, so a missing override
  /// is diagnosable rather than silent. A subclass with no conditional content
  /// and no conditional answer format never reaches this path — the engine
  /// short-circuits on identity. (ADO #1045)
  Step copyResolved({
    required List<Content> content,
    required AnswerFormat? answerFormat,
  }) => Step(
    id: id,
    content: content,
    isMandatory: isMandatory,
    answerFormat: answerFormat,
    buttonText: buttonText,
    stepShell: stepShell,
  );
}
