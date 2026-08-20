import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/model/content/content.dart';

class ConditionalContent extends Content {
  static const type = 'conditional';

  final String variable;
  final Map<String, Content> options;
  final String? defaultOption;

  const ConditionalContent({
    required this.variable,
    required this.options,
    this.defaultOption,
  }) : super(contentType: type);

  factory ConditionalContent.fromJson(
    Map<String, dynamic> json, {
    SurveyRegistries? registries,
  }) {
    final optionsJson = json['options'] as Map<String, dynamic>;
    final options = optionsJson.map(
      (key, value) => MapEntry(
        key,
        Content.fromJson(value as Map<String, dynamic>, registries: registries),
      ),
    );
    return ConditionalContent(
      variable: json['variable'] as String,
      options: options,
      defaultOption: json['default'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'variable': variable,
    if (defaultOption != null) 'default': defaultOption,
    'options': options.map(
      (key, value) => MapEntry(key, (value as dynamic).toJson()),
    ),
  };

  /// Resolves which content to display based on [variables].
  /// Falls back to [defaultOption] when the variable is absent or unmatched.
  Content? resolveContent(Map<String, dynamic> variables) {
    final value = variables[variable]?.toString();
    final match = value != null ? options[value] : null;
    if (match != null) return match;
    if (defaultOption != null) return options[defaultOption];
    return null;
  }
}
