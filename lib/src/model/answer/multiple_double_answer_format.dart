import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/answer/answer_format.dart';
import 'package:survey_kit/src/model/answer/answer_format_type.dart';
import 'package:survey_kit/src/model/answer/multi_double.dart';

part 'multiple_double_answer_format.g.dart';

@JsonSerializable()
class MultipleDoubleAnswerFormat extends AnswerFormat {
  final List<MultiDouble>? defaultValues;
  @JsonKey(defaultValue: <String>[])
  final List<String> hints;

  const MultipleDoubleAnswerFormat({
    this.defaultValues,
    required this.hints,
    super.question,
  }) : super();

  @override
  @JsonKey(name: 'type', includeToJson: true, includeFromJson: false)
  AnswerFormatType get answerType => AnswerFormatType.multipleDouble;

  factory MultipleDoubleAnswerFormat.fromJson(Map<String, dynamic> json) =>
      _$MultipleDoubleAnswerFormatFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MultipleDoubleAnswerFormatToJson(this);
}
