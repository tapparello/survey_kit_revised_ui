import 'package:survey_kit/src/util/survey_kit_logger.dart';

class TemplateResolver {
  static final _stringPattern = RegExp(r'\{\{(?!#)([^}]+)\}\}');
  static final _listPattern = RegExp(r'\{\{#list\s+([^}]+)\}\}');

  /// Resolves all `{{key}}` and `{{#list key}}` placeholders in [text]
  /// using values from [variables].
  ///
  /// - `{{key}}` is replaced with the string value for `key`
  /// - `{{#list key}}` is replaced with `<li>item</li>` for each item in the list
  /// - Unresolved placeholders are replaced with empty string
  static String resolve(String text, Map<String, dynamic> variables) {
    var result = text;

    // Resolve list placeholders first (more specific pattern)
    result = result.replaceAllMapped(_listPattern, (match) {
      final key = match.group(1)!.trim();
      final value = variables[key];
      if (value is List<String>) {
        return value.map((item) => '<li>$item</li>').join();
      }
      SurveyKitLogger.d('TemplateResolver: unresolved list key "$key"');
      return '';
    });

    // Resolve string placeholders
    result = result.replaceAllMapped(_stringPattern, (match) {
      final key = match.group(1)!.trim();
      final value = variables[key];
      if (value != null) {
        return value.toString();
      }
      SurveyKitLogger.d('TemplateResolver: unresolved key "$key"');
      return '';
    });

    return result;
  }
}
