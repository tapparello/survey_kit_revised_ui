import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/model/content/audio_content.dart';
import 'package:survey_kit/src/model/content/conditional_content.dart';
import 'package:survey_kit/src/model/content/html_content.dart';
import 'package:survey_kit/src/model/content/image_content.dart';
import 'package:survey_kit/src/model/content/lottie_content.dart';
import 'package:survey_kit/src/model/content/markdown_content.dart';
import 'package:survey_kit/src/model/content/separator_content.dart';
import 'package:survey_kit/src/model/content/styled_text_content.dart';
import 'package:survey_kit/src/model/content/text_content.dart';
import 'package:survey_kit/src/model/content/video_content.dart';

abstract class Content {
  @JsonKey(includeIfNull: false)
  final String? id;
  // Write-only by design: the discriminator is consumed by the dispatching
  // Content.fromJson factory below and is never assigned from JSON. Removing
  // includeToJson silently drops 'type' from every subclass's generated
  // toJson; removing includeFromJson makes codegen emit an out-of-scope
  // subclass constant that will not compile. See ADO #1001.
  @JsonKey(name: 'type', includeToJson: true, includeFromJson: false)
  final String contentType;

  /// Whether a default 14px separator is rendered AFTER this content in
  /// ContentWidget. Default true = existing behavior. Set false to make the
  /// next content block hug this one. See ADO #972.
  final bool separatorAfter;

  const Content({
    this.id,
    required this.contentType,
    this.separatorAfter = true,
  });

  factory Content.fromJson(
    Map<String, dynamic> json, {
    SurveyRegistries? registries,
  }) {
    final type = json['type'] as String?;

    // Check custom registry first
    if (registries != null) {
      final custom = registries.resolveContent(json);
      if (custom != null) return custom;
    }

    // If type is missing (e.g., from previously serialized results),
    // try to infer from the JSON shape or return a text placeholder
    if (type == null) {
      if (json.containsKey('html')) {
        return HtmlContent.fromJson(json);
      }
      if (json.containsKey('text')) {
        return StyledTextContent.fromJson(json);
      }
      return const TextContent(text: '');
    }

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
      case 'conditional':
        return ConditionalContent.fromJson(json, registries: registries);
      default:
        // Unknown types (e.g., custom content from app registries) may appear
        // when deserializing saved results without registries. Return a
        // placeholder instead of crashing.
        return const TextContent(text: '');
    }
  }

  Map<String, dynamic> toJson();

  Widget createWidget({
    Map<String, dynamic> variables = const {},
    Map<String, StyledTextContent>? contentStyles,
  });
}
