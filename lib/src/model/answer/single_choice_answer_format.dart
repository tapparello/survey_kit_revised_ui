import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/answer/answer_format.dart';
import 'package:survey_kit/src/model/answer/answer_format_type.dart';
import 'package:survey_kit/src/model/answer/text_choice.dart';

part 'single_choice_answer_format.g.dart';

@JsonSerializable()
class SingleChoiceAnswerFormat extends AnswerFormat {
  final List<TextChoice> textChoices;
  final String? choicesFromVariable;
  final TextChoice? defaultSelection;
  final bool shuffleChoices;

  const SingleChoiceAnswerFormat({
    required this.textChoices,
    this.choicesFromVariable,
    this.defaultSelection,
    this.shuffleChoices = false,
    super.question,
  }) : super();

  @override
  @JsonKey(name: 'type', includeToJson: true, includeFromJson: false)
  AnswerFormatType get answerType => AnswerFormatType.single;

  factory SingleChoiceAnswerFormat.fromJson(Map<String, dynamic> json) =>
      _$SingleChoiceAnswerFormatFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SingleChoiceAnswerFormatToJson(this);
}
