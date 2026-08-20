import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/answer/answer_format.dart';
import 'package:survey_kit/src/model/answer/answer_format_type.dart';

part 'image_answer_format.g.dart';

@JsonSerializable()
class ImageAnswerFormat extends AnswerFormat {
  final String? defaultValue;
  final String buttonText;

  const ImageAnswerFormat({
    this.defaultValue,
    this.buttonText = 'Image: ',
    super.question,
  }) : super();

  @override
  @JsonKey(name: 'type', includeToJson: true, includeFromJson: false)
  AnswerFormatType get answerType => AnswerFormatType.image;

  factory ImageAnswerFormat.fromJson(Map<String, dynamic> json) =>
      _$ImageAnswerFormatFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ImageAnswerFormatToJson(this);
}
