import 'package:flutter/material.dart';
// import 'package:flutter_html/style.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/content/content.dart';
import 'package:survey_kit/src/model/content/styled_text_content.dart';
import 'package:survey_kit/src/util/template_resolver.dart';
import 'package:survey_kit/src/view/widget/content/html_widget.dart';

part 'html_content.g.dart';

@JsonSerializable()
class HtmlContent extends Content {
  static const type = 'html';

  final String html;
  // final double fontSize;
  // final TextAlign textAlign;

  const HtmlContent({
    required this.html,
    super.id,
  }) : super(contentType: type);

  factory HtmlContent.fromJson(Map<String, dynamic> json) => _$HtmlContentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$HtmlContentToJson(this);

  @override
  Widget createWidget({
    Map<String, dynamic> variables = const {},
    Map<String, StyledTextContent>? contentStyles,
  }) {
    final resolvedHtml = TemplateResolver.resolve(html, variables);
    return HtmlWidget(htmlContent: HtmlContent(html: resolvedHtml, id: id));
  }
}
