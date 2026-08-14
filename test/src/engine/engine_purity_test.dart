// Decision 1 of the Phase 3c spec, as a gate rather than a convention.
//
// Reading source files off disk under `flutter test` works because
// `Directory.current` is the repo root, which matches how
// `.github/workflows/ci.yml` invokes the suite.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _dartFilesIn(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'));

void main() {
  test('no file under lib/src/engine imports the widget layer', () {
    // The barrel is the important one, and the easiest to carry in by
    // accident: survey_state_provider.dart imported it, so a character-
    // identical body move brings it along and satisfies a naive check.
    const banned = <String>[
      'package:flutter/material.dart',
      'package:flutter/widgets.dart',
      'package:flutter_html',
      'package:survey_kit/survey_kit.dart',
    ];

    final files = _dartFilesIn('lib/src/engine').toList();
    expect(files, isNotEmpty, reason: 'the engine directory must exist');

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final needle in banned) {
        expect(
          source.contains(needle),
          isFalse,
          reason: '${file.path} imports $needle',
        );
      }
    }
  });

  test('no engine test drives a tree', () {
    // "Unit-testable without a widget tree" as something falsifiable.
    //
    // The needles are split across adjacent string literals so this file does
    // not match its own check — and they are named constants rather than
    // inline list elements because `no_adjacent_strings_in_list`
    // (analysis_options.yaml:86) forbids the inline form, and its quick-fix
    // ("add a comma between the strings") would silently turn the needles into
    // four useless fragments. Do not accept that fix. Note the test's own name
    // and this comment avoid both whole needles for the same reason.
    const testWidgetsNeedle =
        'testWidgets'
        '(';
    const pumpNeedle =
        'pump'
        'Widget';
    const banned = <String>[testWidgetsNeedle, pumpNeedle];

    final files = _dartFilesIn('test/src/engine').toList();
    expect(files, isNotEmpty);

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final needle in banned) {
        expect(
          source.contains(needle),
          isFalse,
          reason: '${file.path} contains $needle',
        );
      }
    }
  });
}
