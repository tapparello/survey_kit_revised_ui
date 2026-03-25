import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/model/answer/answer_format.dart';
import 'package:survey_kit/src/model/content/content.dart';
import 'package:survey_kit/src/survey_kit.dart';
import 'package:uuid/uuid.dart';

part 'step.g.dart';

@JsonSerializable()
class Step {
  final String id;
  final bool isMandatory;
  final AnswerFormat? answerFormat;
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
    this.buttonText,
    this.stepShell,
  }) : id = id ?? const Uuid().v4();

  factory Step.fromJson(Map<String, dynamic> json, {SurveyRegistries? registries}) {
    return Step(
      id: json['id'] as String?,
      content: (json['content'] as List<dynamic>)
          .map((e) => Content.fromJson(e as Map<String, dynamic>, registries: registries))
          .toList(),
      isMandatory: json['isMandatory'] as bool? ?? true,
      answerFormat: json['answerFormat'] == null
          ? null
          : AnswerFormat.fromJson(json['answerFormat'] as Map<String, dynamic>),
      buttonText: json['buttonText'] as String? ?? 'Next',
    );
  }

  Map<String, dynamic> toJson() => _$StepToJson(this);
}
