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
  test('no file under lib/src/model imports the internal app file', () {
    // src/survey_kit.dart declares SurveyKit and imports answer_view.dart, so
    // importing it for one typedef drags the whole widget layer in behind it.
    const needle = 'package:survey_kit/src/survey_kit.dart';

    final files = _dartFilesIn('lib/src/model').toList();
    expect(files, isNotEmpty, reason: 'the model directory must exist');

    for (final file in files) {
      expect(
        file.readAsStringSync().contains(needle),
        isFalse,
        reason: '${file.path} imports $needle',
      );
    }
  });
}
