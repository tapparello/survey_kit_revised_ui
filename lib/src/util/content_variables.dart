import 'package:survey_kit/src/model/answer/text_choice.dart';

/// Extracts a single step result's answer into a template-friendly value
/// (`String`, `List<String>`, `num`, `bool`) or `null` if it cannot be
/// represented. Mirrors the app's CrossSectionDataProvider._extractAnswer
/// (`value ?? text`) so cross-section and in-section answers agree.
dynamic extractAnswerValue(dynamic result) {
  if (result is TextChoice) return result.value ?? result.text;
  // Restored single-choice answer (StepResult<dynamic> from initialResults)
  // arrives as a raw Map. 4_11-style choices have no 'value' (only 'text'),
  // so match on either key and return value ?? text.
  if (result is Map && (result.containsKey('value') || result.containsKey('text'))) {
    return (result['value'] ?? result['text'])?.toString();
  }
  if (result is List) {
    return <String>[
      for (final item in result)
        if (item is TextChoice)
          (item.value ?? item.text)
        else if (item is Map && (item.containsKey('value') || item.containsKey('text')))
          ((item['value'] ?? item['text'])?.toString() ?? '')
        else if (item != null)
          item.toString(),
    ];
  }
  if (result is num || result is String || result is bool) return result;
  return null;
}

/// Builds the variables map a content widget resolves against: pre-populated
/// [configVariables] (cross-section / derived / rule-computed) overlaid OVER
/// current-section [stepAnswers] — config wins on key collisions.
Map<String, dynamic> mergeContentVariables(
  Map<String, dynamic> stepAnswers,
  Map<String, dynamic> configVariables,
) {
  return {...stepAnswers, ...configVariables};
}
