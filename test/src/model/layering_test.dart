// The Phase 3e boundary as a gate rather than a convention: no file that
// models data may reach the widget layer.
//
// Reading source files off disk under `flutter test` works because
// `Directory.current` is the repo root, which matches how
// `.github/workflows/ci.yml` invokes the suite. Same technique as
// test/src/engine/engine_purity_test.dart.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _dartFilesIn(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'));

void main() {
  // The needle → allowlist table. An empty allowlist means "no file, ever".
  //
  // Three of these five are indirect routes that a naive `src/view/` grep
  // misses, and all three were live before Phase 3e:
  //   * the public barrel re-exports twelve view widgets (13 model files used
  //     it, ten of them as their only source of AnswerFormat);
  //   * src/survey_kit.dart imports answer_view.dart, and step.dart imported
  //     it for one typedef;
  //   * flutter/widgets.dart is the obvious back door once material is banned.
  //
  // The rule bans widget-BUILDING libraries, not value-type libraries, so
  // dart:ui and package:flutter/painting.dart stay legal — some models hold a
  // TextAlign or a BoxFit as a field.
  const rules = <String, Set<String>>{
    'package:survey_kit/src/view/': {},
    'package:survey_kit/survey_kit.dart': {},
    'package:survey_kit/src/survey_kit.dart': {},
    // src/view/ is not the only widget directory: src/widget/ holds nine more
    // widget-building files. Banning one and not the other left the rule true
    // by luck rather than by construction.
    'package:survey_kit/src/widget/': {},
    // TimeOfDay has no narrower home than material. Replacing these two held
    // Flutter value types is a follow-up item, deliberately not Phase 3e.
    'package:flutter/material.dart': {
      'time_result.dart',
      'time_answer_format.dart',
    },
    'package:flutter/widgets.dart': {},
  };

  test('no file under lib/src/model reaches the widget layer', () {
    final files = _dartFilesIn('lib/src/model').toList();
    expect(files, isNotEmpty, reason: 'the model directory must exist');

    for (final file in files) {
      final source = file.readAsStringSync();
      final name = file.uri.pathSegments.last;
      for (final entry in rules.entries) {
        if (entry.value.contains(name)) continue;
        expect(
          source.contains(entry.key),
          isFalse,
          reason: '${file.path} imports ${entry.key}',
        );
      }
    }
  });
}
