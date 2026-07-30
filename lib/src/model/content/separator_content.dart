import 'package:flutter/material.dart';
// import 'package:flutter_html/style.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/content/content.dart';
import 'package:survey_kit/src/model/content/styled_text_content.dart';
import 'package:survey_kit/src/view/widget/content/separator_widget.dart';

part 'separator_content.g.dart';

@JsonSerializable()
class SeparatorContent extends Content {
  static const type = 'separator';

  final double height;

  const SeparatorContent({this.height = 14, super.id})
    : super(contentType: type);

  factory SeparatorContent.fromJson(Map<String, dynamic> json) =>
      _$SeparatorContentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SeparatorContentToJson(this);

  @override
  Widget createWidget({
    Map<String, dynamic> variables = const {},
    Map<String, StyledTextContent>? contentStyles,
  }) {
    return SeparatorWidget(separatorContent: this);
  }
}
