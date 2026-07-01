import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/view/widget/content/styled_text_widget.dart';
import 'package:survey_kit/survey_kit.dart';

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

  factory StyledTextContent.fromJson(Map<String, dynamic> json) => _$StyledTextContentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StyledTextContentToJson(this);

  @override
  Widget createWidget({
    Map<String, dynamic> variables = const {},
    Map<String, StyledTextContent>? contentStyles,
  }) {
    final resolvedText = TemplateResolver.resolve(text, variables);
    if (style != null && contentStyles != null && contentStyles.containsKey(style)) {
      final namedStyle = contentStyles[style]!;
      return StyledTextWidget(
        content: StyledTextContent(
          text: resolvedText,
          fontSize: namedStyle.fontSize,
          bold: namedStyle.bold,
          italic: namedStyle.italic,
          underlined: namedStyle.underlined,
          center: namedStyle.center,
        ),
      );
    }
    return StyledTextWidget(
      content: StyledTextContent(
        text: resolvedText,
        fontSize: fontSize,
        bold: bold,
        italic: italic,
        underlined: underlined,
        center: center,
      ),
    );
  }
}
