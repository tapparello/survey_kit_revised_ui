import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/content/content.dart';
import 'package:survey_kit/src/model/content/styled_text_content.dart';
import 'package:survey_kit/src/util/template_resolver.dart';
import 'package:survey_kit/src/view/widget/content/text_widget.dart';

part 'text_content.g.dart';

@JsonSerializable()
class TextContent extends Content {
  static const type = 'text';

  final String text;
  final double fontSize;
  final TextAlign textAlign;

  const TextContent({
    required this.text,
    this.fontSize = 16,
    this.textAlign = TextAlign.center,
    super.id,
  }) : super(contentType: type);

  factory TextContent.fromJson(Map<String, dynamic> json) =>
      _$TextContentFromJson(json);

  Map<String, dynamic> toJson() => _$TextContentToJson(this);

  @override
  Widget createWidget({
    Map<String, dynamic> variables = const {},
    Map<String, StyledTextContent>? contentStyles,
  }) {
    final resolvedText = TemplateResolver.resolve(text, variables);
    return TextWidget(
      textContent: TextContent(
        text: resolvedText,
        fontSize: fontSize,
        textAlign: textAlign,
        id: id,
      ),
    );
  }
}
