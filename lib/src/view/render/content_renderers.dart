import 'package:flutter/material.dart';
import 'package:survey_kit/src/configuration/content_renderer.dart';
import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/exception/survey_kit_exception.dart';
import 'package:survey_kit/src/model/content/audio_content.dart';
import 'package:survey_kit/src/model/content/content.dart';
import 'package:survey_kit/src/model/content/html_content.dart';
import 'package:survey_kit/src/model/content/image_content.dart';
import 'package:survey_kit/src/model/content/lottie_content.dart';
import 'package:survey_kit/src/model/content/markdown_content.dart';
import 'package:survey_kit/src/model/content/section_content.dart';
import 'package:survey_kit/src/model/content/separator_content.dart';
import 'package:survey_kit/src/model/content/styled_text_content.dart';
import 'package:survey_kit/src/model/content/text_content.dart';
import 'package:survey_kit/src/model/content/video_content.dart';
import 'package:survey_kit/src/util/template_resolver.dart';
import 'package:survey_kit/src/view/widget/content/audio_widget.dart';
import 'package:survey_kit/src/view/widget/content/html_widget.dart';
import 'package:survey_kit/src/view/widget/content/image_widget.dart';
import 'package:survey_kit/src/view/widget/content/lottie_widget.dart';
import 'package:survey_kit/src/view/widget/content/markdown_widget.dart';
import 'package:survey_kit/src/view/widget/content/section_widget.dart';
import 'package:survey_kit/src/view/widget/content/separator_widget.dart';
import 'package:survey_kit/src/view/widget/content/styled_text_widget.dart';
import 'package:survey_kit/src/view/widget/content/text_widget.dart';
import 'package:survey_kit/src/view/widget/content/video_widget.dart';

Widget renderAudioContent(Content content, ContentRenderContext context) =>
    AudioWidget(audioContent: content as AudioContent);

Widget renderTextContent(Content content, ContentRenderContext context) {
  final text = content as TextContent;
  final resolvedText = TemplateResolver.resolve(text.text, context.variables);
  return TextWidget(
    textContent: TextContent(
      text: resolvedText,
      fontSize: text.fontSize,
      textAlign: text.textAlign,
      id: text.id,
    ),
  );
}

Widget renderStyledTextContent(Content content, ContentRenderContext context) {
  final styled = content as StyledTextContent;
  final resolvedText = TemplateResolver.resolve(styled.text, context.variables);
  final contentStyles = context.contentStyles;
  if (styled.style != null &&
      contentStyles != null &&
      contentStyles.containsKey(styled.style)) {
    final namedStyle = contentStyles[styled.style]!;
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
      fontSize: styled.fontSize,
      bold: styled.bold,
      italic: styled.italic,
      underlined: styled.underlined,
      center: styled.center,
    ),
  );
}

Widget renderVideoContent(Content content, ContentRenderContext context) =>
    VideoWidget(videoContent: content as VideoContent);

Widget renderImageContent(Content content, ContentRenderContext context) =>
    ImageWidget(imageContent: content as ImageContent);

Widget renderMarkdownContent(Content content, ContentRenderContext context) {
  final markdown = content as MarkdownContent;
  final resolvedText = TemplateResolver.resolve(
    markdown.text,
    context.variables,
  );
  return MarkdownWidget(
    markdownContent: MarkdownContent(text: resolvedText, id: markdown.id),
  );
}

Widget renderLottieContent(Content content, ContentRenderContext context) =>
    LottieWidget(lottieContent: content as LottieContent);

Widget renderHtmlContent(Content content, ContentRenderContext context) {
  final html = content as HtmlContent;
  final resolvedHtml = TemplateResolver.resolve(html.html, context.variables);
  return HtmlWidget(
    htmlContent: HtmlContent(html: resolvedHtml, id: html.id),
  );
}

Widget renderSeparatorContent(Content content, ContentRenderContext context) =>
    SeparatorWidget(separatorContent: content as SeparatorContent);

Widget renderSectionContent(Content content, ContentRenderContext context) {
  final section = content as SectionContent;
  if (context.variables.isEmpty && context.contentStyles == null) {
    return SectionWidget(sectionContent: section);
  }
  // Pass variables and styles through to each child
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: section.toList.map(context.render).toList(),
  );
}

Widget renderConditionalContent(Content content, ContentRenderContext context) {
  // Never rendered directly: SurveyEngine resolves a step's ConditionalContent
  // before the step reaches the state. Reaching here means a ConditionalContent
  // nested as a value in another ConditionalContent's `options`, which
  // resolution does not descend into — resolution is a single pass over the
  // top-level list. A pre-existing limitation, unchanged by ADO #1045.
  return const SizedBox.shrink();
}

/// The renderer for every built-in [Content], keyed by JSON discriminator.
///
/// Keyed by `String` rather than `Type` because content discriminators are an
/// open set: a consumer registers its own, and a subclass of a built-in
/// inherits its parent's discriminator through the `const` super-call and so
/// resolves to the parent's renderer. `content_renderers_test.dart` pins this
/// table against `ContentType.values` in both directions.
final Map<String, ContentRenderer> defaultContentRenderers = {
  'audio': renderAudioContent,
  'text': renderTextContent,
  'styled_text': renderStyledTextContent,
  'video': renderVideoContent,
  'image': renderImageContent,
  'markdown': renderMarkdownContent,
  'lottie': renderLottieContent,
  'html': renderHtmlContent,
  'separator': renderSeparatorContent,
  'section': renderSectionContent,
  'conditional': renderConditionalContent,
};

/// Resolves the renderer for [contentType].
///
/// Registry before built-ins: a consumer that registers a discriminator has
/// done so deliberately, and shadowing a built-in stays possible. Same
/// precedence as `Content.fromJson`.
ContentRenderer contentRendererFor(
  String contentType,
  SurveyRegistries? registries,
) {
  final custom = registries?.contentRenderers[contentType];
  if (custom != null) return custom;
  final builtIn = defaultContentRenderers[contentType];
  if (builtIn != null) return builtIn;
  throw UnregisteredRendererException(
    kind: 'Content',
    discriminator: contentType,
  );
}
