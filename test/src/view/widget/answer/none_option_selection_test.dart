import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/model/answer/text_choice.dart';
import 'package:survey_kit/src/view/widget/answer/none_option_selection.dart';

/// Guards ADO #977: multi-choice questions with a "None" option must always
/// keep at least one selection. NoneOptionSelection holds the pure invariant
/// logic so it can be unit-tested away from the AnswerMixin widgets.
void main() {
  final none = TextChoice(id: 'None', text: 'None of these', value: 'None of these');
  final optionA = TextChoice(id: 'a', text: 'A', value: 'A');
  final optionB = TextChoice(id: 'b', text: 'B', value: 'B');

  group('initial', () {
    test('no previous result + None option enabled => defaults to None', () {
      final result = NoneOptionSelection.initial(null, none: none, hasNoneOption: true);
      expect(result, [none]);
    });

    test('empty previous result + None option enabled => defaults to None', () {
      final result = NoneOptionSelection.initial(const [], none: none, hasNoneOption: true);
      expect(result, [none]);
    });

    test('no previous result + None option disabled => empty', () {
      final result = NoneOptionSelection.initial(null, none: none, hasNoneOption: false);
      expect(result, isEmpty);
    });

    test('existing selection is preserved (not replaced by None)', () {
      final result = NoneOptionSelection.initial([optionA, optionB], none: none, hasNoneOption: true);
      expect(result, [optionA, optionB]);
    });

    test("returns a copy, not the caller's list", () {
      final previous = [optionA];
      NoneOptionSelection.initial(previous, none: none, hasNoneOption: true).add(optionB);
      expect(previous, [optionA]);
    });
  });

  group('ensureNotEmpty', () {
    test('empty selection + None option enabled => selects None', () {
      final result = NoneOptionSelection.ensureNotEmpty(const [], none: none, hasNoneOption: true);
      expect(result, [none]);
    });

    test('empty selection + None option disabled => stays empty', () {
      final result = NoneOptionSelection.ensureNotEmpty(const [], none: none, hasNoneOption: false);
      expect(result, isEmpty);
    });

    test('non-empty selection is left unchanged', () {
      final result = NoneOptionSelection.ensureNotEmpty([optionA], none: none, hasNoneOption: true);
      expect(result, [optionA]);
    });
  });
}
