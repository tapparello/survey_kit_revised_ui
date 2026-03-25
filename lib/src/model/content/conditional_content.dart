import 'package:flutter/widgets.dart';
import 'package:survey_kit/src/model/content/content.dart';
import 'package:survey_kit/src/model/content/styled_text_content.dart';

class ConditionalContent extends Content {
  static const type = 'conditional';

  final String variable;
  final Map<String, Content> options;

  const ConditionalContent({
    required this.variable,
    required this.options,
  }) : super(contentType: type);

  factory ConditionalContent.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'] as Map<String, dynamic>;
    final options = optionsJson.map(
      (key, value) =>
          MapEntry(key, Content.fromJson(value as Map<String, dynamic>)),
    );
    return ConditionalContent(
      variable: json['variable'] as String,
      options: options,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'variable': variable,
        'options': options.map(
          (key, value) => MapEntry(key, (value as dynamic).toJson()),
        ),
      };

  /// Resolves which content to display based on [variables] map.
  /// Returns null if the variable is absent or the value has no matching option.
  Content? resolveContent(Map<String, dynamic> variables) {
    final value = variables[variable]?.toString();
    if (value == null) return null;
    return options[value];
  }

  @override
  Widget createWidget({
    Map<String, dynamic> variables = const {},
    Map<String, StyledTextContent>? contentStyles,
  }) {
    // Default: returns empty widget. Actual resolution happens in ContentWidget.
    return const SizedBox.shrink();
  }
}
