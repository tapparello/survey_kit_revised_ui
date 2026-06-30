import 'package:survey_kit/src/model/answer/text_choice.dart';

/// Pure selection logic for multi-choice questions that offer a "None" option
/// (ADO #977). Enforces the invariant: when the None option is enabled the
/// question always keeps at least one selection — "None" is the default on a
/// fresh load and the fallback whenever every real option is deselected. "None"
/// is mutually exclusive with the real options (handled by the views, which
/// drop "None" when a real option is chosen).
class NoneOptionSelection {
  const NoneOptionSelection._();

  /// The selection to show when the question first loads. Honors an existing
  /// (seeded or resumed) selection; otherwise falls back to [none] when the
  /// None option is enabled, or an empty selection when it is not.
  static List<TextChoice> initial(
    List<TextChoice>? previous, {
    required TextChoice none,
    required bool hasNoneOption,
  }) {
    if (previous != null && previous.isNotEmpty) {
      return List<TextChoice>.of(previous);
    }
    return hasNoneOption ? <TextChoice>[none] : <TextChoice>[];
  }

  /// Re-asserts the invariant after a mutation: if the None option is enabled
  /// and nothing is selected, fall back to [none]. Returns the input unchanged
  /// when the None option is disabled or something is already selected.
  static List<TextChoice> ensureNotEmpty(
    List<TextChoice> selection, {
    required TextChoice none,
    required bool hasNoneOption,
  }) {
    if (hasNoneOption && selection.isEmpty) {
      return <TextChoice>[...selection, none];
    }
    return selection;
  }
}
