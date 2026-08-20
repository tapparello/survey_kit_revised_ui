// import 'package:flutter_html/style.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/content/content.dart';

part 'html_content.g.dart';

@JsonSerializable()
class HtmlContent extends Content {
  static const type = 'html';

  final String html;
  // final double fontSize;
  // final TextAlign textAlign;

  const HtmlContent({required this.html, super.id, super.separatorAfter})
    : super(contentType: type);

  factory HtmlContent.fromJson(Map<String, dynamic> json) =>
      _$HtmlContentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$HtmlContentToJson(this);
}
