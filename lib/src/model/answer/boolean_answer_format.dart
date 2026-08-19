import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/answer/answer_format.dart';
import 'package:survey_kit/src/model/answer/answer_format_type.dart';

part 'boolean_answer_format.g.dart';

@JsonSerializable()
class BooleanAnswerFormat extends AnswerFormat {
  final String positiveAnswer;
  final String negativeAnswer;
  final BooleanResult result;

  const BooleanAnswerFormat({
    required this.positiveAnswer,
    required this.negativeAnswer,
    this.result = BooleanResult.none,
    super.question,
  }) : super();

  @override
  @JsonKey(name: 'type', includeToJson: true, includeFromJson: false)
  AnswerFormatType get answerType => AnswerFormatType.boolean;

  factory BooleanAnswerFormat.fromJson(Map<String, dynamic> json) =>
      _$BooleanAnswerFormatFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$BooleanAnswerFormatToJson(this);
}

@JsonEnum()
enum BooleanResult { none, positive, negative }
