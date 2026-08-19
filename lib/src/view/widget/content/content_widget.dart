import 'package:flutter/material.dart' hide Step;
import 'package:survey_kit/src/util/content_variables.dart';
import 'package:survey_kit/src/view/render/content_renderers.dart';
import 'package:survey_kit/survey_kit.dart';

/// Renders a list of [Content].
///
/// Expects [content] to already be resolved: `SurveyEngine` resolves any
/// `ConditionalContent` before a step reaches the widget tree. Constructed
/// directly with unresolved `ConditionalContent`, a conditional branch renders
/// as `SizedBox.shrink()`. (ADO #1045)
class ContentWidget extends StatefulWidget {
  const ContentWidget({
    super.key,
    required this.content,
    this.center = true,
    this.padding = const EdgeInsets.all(16),
  });
  final List<Content> content;
  final bool center;
  final EdgeInsets padding;

  @override
  State<ContentWidget> createState() => _ContentWidgetState();
}

class _ContentWidgetState extends State<ContentWidget> {
  @override
  Widget build(BuildContext context) {
    final config = SurveyConfiguration.of(context);
    final contentStyles = config.contentStyles;

    // Overlay current-section step answers (keyed by step id) UNDER the
    // pre-populated config variables, so {{stepId}} / conditional variable:"stepId"
    // resolve to prior in-section answers. Config variables win on collisions.
    final variables = resolveVariables(
      SurveyStateProvider.of(context).results,
      config.variables,
    );

    // One closure, reused for every content in this build and handed to each
    // renderer as `context.render`, so a composite content resolves its
    // children through the same registry it was resolved from.
    Widget renderContent(Content content) =>
        contentRendererFor(content.contentType, config.registries)(
          content,
          ContentRenderContext(
            variables: variables,
            contentStyles: contentStyles,
            render: renderContent,
          ),
        );

    // No conditional resolution here: SurveyEngine resolves the step before it
    // reaches the state, so widget.content is already concrete. `variables` is
    // still needed below for {{...}} interpolation. (ADO #1045)
    final children = <Widget>[];
    for (final content in widget.content) {
      children.add(renderContent(content));
      // Append the 14px separator AFTER each content unless it opts out.
      // Default separatorAfter==true reproduces the previous behavior exactly
      // (including the trailing separator after the last content).
      if (content.separatorAfter) {
        children.add(const ContentSeparator(height: 14));
      }
    }

    final contentView = SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: children,
      ),
    );

    return widget.center ? Center(child: contentView) : contentView;
  }
}

class ContentSeparator extends StatelessWidget {
  const ContentSeparator({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}
