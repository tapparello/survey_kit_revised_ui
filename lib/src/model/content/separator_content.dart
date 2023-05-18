import 'package:flutter/material.dart';
import 'package:flutter_html/style.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/content/content.dart';
import 'package:survey_kit/src/view/widget/content/html_widget.dart';
import 'package:survey_kit/src/view/widget/content/separator_widget.dart';

part 'separator_content.g.dart';

@JsonSerializable()
class SeparatorContent extends Content {
  static const type = 'separator';

  final double height;

  const SeparatorContent({
    required this.height,
    super.id,
  }) : super(contentType: type);

  factory SeparatorContent.fromJson(Map<String, dynamic> json) =>
      _$SeparatorContentFromJson(json);

  Map<String, dynamic> toJson() => _$SeparatorContentToJson(this);

  @override
  Widget createWidget() {
    return SeparatorWidget(separatorContent: this);
  }
}
