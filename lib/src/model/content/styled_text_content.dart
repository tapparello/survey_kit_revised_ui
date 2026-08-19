import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/content/content.dart';

part 'styled_text_content.g.dart';

@JsonSerializable()
class StyledTextContent extends Content {
  static const type = 'styled_text';

  final String text;
  final double fontSize;
  final bool bold;
  final bool italic;
  final bool underlined;
  final bool center;
  @JsonKey(includeIfNull: false)
  final String? style;

  const StyledTextContent({
    required this.text,
    this.fontSize = 16,
    this.bold = false,
    this.italic = false,
    this.underlined = false,
    this.center = false,
    this.style,
    super.separatorAfter,
  }) : super(contentType: type);

  factory StyledTextContent.fromJson(Map<String, dynamic> json) =>
      _$StyledTextContentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StyledTextContentToJson(this);
}
