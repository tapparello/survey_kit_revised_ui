import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/content/audio_content.dart';
import 'package:survey_kit/src/model/content/html_content.dart';
import 'package:survey_kit/src/model/content/image_content.dart';
import 'package:survey_kit/src/model/content/lottie_content.dart';
import 'package:survey_kit/src/model/content/markdown_content.dart';
import 'package:survey_kit/src/model/content/separator_content.dart';
import 'package:survey_kit/src/model/content/styled_text_content.dart';
import 'package:survey_kit/src/model/content/text_content.dart';
import 'package:survey_kit/src/model/content/video_content.dart';

@JsonSerializable()
abstract class Content {
  @JsonKey(includeIfNull: false)
  final String? id;
  @JsonKey(name: 'type')
  final String contentType;

  const Content({
    this.id,
    required this.contentType,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    assert(type != null, 'type is required');

    switch (type) {
      case 'audio':
        return AudioContent.fromJson(json);
      case 'text':
        return TextContent.fromJson(json);
      case 'styled_text':
        return StyledTextContent.fromJson(json);
      case 'video':
        return VideoContent.fromJson(json);
      case 'image':
        return ImageContent.fromJson(json);
      case 'markdown':
        return MarkdownContent.fromJson(json);
      case 'lottie':
        return LottieContent.fromJson(json);
      case 'html':
        return HtmlContent.fromJson(json);
      case 'separator':
        return SeparatorContent.fromJson(json);
      default:
        throw Exception('Unknown type: $type');
    }
  }

  Widget createWidget();
}
