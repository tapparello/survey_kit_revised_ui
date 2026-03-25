import 'package:flutter/material.dart' hide Step;
import 'package:survey_kit/src/model/content/conditional_content.dart';
import 'package:survey_kit/src/util/extension.dart';
import 'package:survey_kit/survey_kit.dart';

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
    final variables = config.variables;
    final contentStyles = config.contentStyles;

    final resolvedContent = widget.content.expand((content) {
      if (content is ConditionalContent) {
        final resolved = content.resolveContent(variables);
        return resolved != null ? [resolved] : <Content>[];
      }
      return [content];
    }).toList();

    final contentView = SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: resolvedContent
            .map((e) => e.createWidget(variables: variables, contentStyles: contentStyles))
            .withSeparator(const _Separator(height: 14))
            .toList(),
      ),
    );

    return widget.center ? Center(child: contentView) : contentView;
  }
}

class _Separator extends StatelessWidget {
  const _Separator({
    required this.height,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
    );
  }
}
