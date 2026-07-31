import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

/// Guards the JSON `type` discriminator against regeneration regressions.
///
/// `Content.fromJson` dispatches on `json['type']` and falls back to shape
/// inference when it is absent, so a missing discriminator does not throw -
/// it silently returns the wrong subclass. See ADO #1001.
void main() {
  group('Content discriminator survives a JSON round trip', () {
    final contents = <Content>[
      const TextContent(text: 'hi'),
      const StyledTextContent(text: 'hi'),
      const MarkdownContent(text: '# hi'),
      const HtmlContent(html: '<p>hi</p>'),
      const ImageContent(url: 'u'),
      const VideoContent(url: 'u'),
      const AudioContent(url: 'u'),
      const LottieContent(url: 'u'),
      const SeparatorContent(),
      const ConditionalContent(
        variable: 'x',
        options: {'1': TextContent(text: 'inner')},
      ),
    ];

    for (final content in contents) {
      test('${content.runtimeType}', () {
        final decoded =
            jsonDecode(jsonEncode(content.toJson())) as Map<String, dynamic>;

        expect(
          decoded['type'],
          isNotNull,
          reason: 'discriminator missing for ${content.runtimeType}',
        );

        final back = Content.fromJson(decoded);

        expect(
          back.runtimeType,
          content.runtimeType,
          reason: '${content.runtimeType} degraded to ${back.runtimeType}',
        );
        expect(back.contentType, content.contentType);
      });
    }
  });
}
