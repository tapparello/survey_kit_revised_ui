import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/exception/survey_kit_exception.dart';
import 'package:survey_kit/src/model/content/content_type.dart';
import 'package:survey_kit/src/model/content/styled_text_content.dart';

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

    // Registry before built-ins: a consumer that registers a discriminator has
    // done so deliberately, and shadowing a built-in stays possible.
    if (registries != null) {
      final custom = registries.resolveContent(json);
      if (custom != null) return custom;
    }

    final member = ContentType.byWireName(type);
    if (member == null) {
      throw UnknownTypeException(kind: 'Content', discriminator: type);
    }
    return member.fromJson(json, registries: registries);
  }

  Map<String, dynamic> toJson();

  Widget createWidget({
    Map<String, dynamic> variables = const {},
    Map<String, StyledTextContent>? contentStyles,
  });
}
