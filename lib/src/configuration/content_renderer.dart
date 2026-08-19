import 'package:flutter/widgets.dart';
import 'package:survey_kit/src/model/content/content.dart';
import 'package:survey_kit/src/model/content/styled_text_content.dart';

/// Everything a [ContentRenderer] receives besides the content itself.
class ContentRenderContext {
  const ContentRenderContext({
    required this.variables,
    required this.contentStyles,
    required this.render,
  });

  /// Values for `{{...}}` interpolation, already merged by `resolveVariables`.
  final Map<String, dynamic> variables;

  /// Named styles from `SurveyConfiguration.contentStyles`.
  final Map<String, StyledTextContent>? contentStyles;

  /// Renders nested content through the same registry this renderer came from.
  ///
  /// Before Phase 3e every `Content` could render any other by calling
  /// `child.createWidget(...)`, because that was a method on the base class.
  /// Moving renderers into a registry would have deleted that capability for
  /// anyone outside `lib/src/view/render/`; this preserves it. There is no
  /// cycle or depth guard — content that renders itself overflows the stack,
  /// exactly as it did before.
  final Widget Function(Content child) render;
}

/// Builds the widget for one [Content].
///
/// Receives the base type and downcasts, because the registry is keyed by the
/// JSON discriminator rather than by `runtimeType`: discriminators are an open
/// set a consumer extends, and a subclass of a built-in inherits its parent's
/// discriminator and so resolves to the parent's renderer.
typedef ContentRenderer =
    Widget Function(Content content, ContentRenderContext context);
