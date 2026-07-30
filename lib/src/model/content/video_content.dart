import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/content/content.dart';
import 'package:survey_kit/src/model/content/styled_text_content.dart';
import 'package:survey_kit/src/view/widget/content/video_widget.dart';

part 'video_content.g.dart';

@JsonSerializable()
class VideoContent extends Content {
  static const type = 'video';

  final String url;
  final bool autoPlay;
  final bool loop;
  final double? width;
  final double? height;
  final String? title;
  final String? subtitle;
  final String? externalLink;

  const VideoContent({
    required this.url,
    super.id,
    this.autoPlay = false,
    this.loop = false,
    this.width,
    this.height,
    this.title,
    this.subtitle,
    this.externalLink,
    super.separatorAfter,
  }) : super(contentType: type);

  factory VideoContent.fromJson(Map<String, dynamic> json) =>
      _$VideoContentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$VideoContentToJson(this);

  @override
  Widget createWidget({
    Map<String, dynamic> variables = const {},
    Map<String, StyledTextContent>? contentStyles,
  }) {
    return VideoWidget(videoContent: this);
  }
}
