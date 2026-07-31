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
          content.contentType,
          reason: 'discriminator missing for ${content.runtimeType}',
        );

        final back = Content.fromJson(decoded);

        expect(
          back.runtimeType,
          content.runtimeType,
          reason: '${content.runtimeType} degraded to ${back.runtimeType}',
        );
        expect(
          back.contentType,
          content.contentType,
          reason: '${content.runtimeType} contentType changed after decode',
        );
        expect(
          back.toJson(),
          content.toJson(),
          reason:
              '${content.runtimeType} did not round-trip its payload '
              'faithfully',
        );
      });
    }
  });

  group('AnswerFormat discriminator survives a JSON round trip', () {
    final formats = <AnswerFormat>[
      const BooleanAnswerFormat(positiveAnswer: 'y', negativeAnswer: 'n'),
      DateAnswerFormat(),
      const DoubleAnswerFormat(),
      const IntegerAnswerFormat(),
      const ImageAnswerFormat(),
      const TextAnswerFormat(),
      const TimeAnswerFormat(),
      const ScaleAnswerFormat(
        maximumValue: 10,
        minimumValue: 0,
        defaultValue: 5,
        step: 1,
      ),
      const MultipleChoiceAnswerFormat(textChoices: []),
      const MultipleChoiceAnswerWithFeedbackFormat(textChoices: []),
      const MultipleChoiceAutoCompleteAnswerFormat(textChoices: []),
      const SingleChoiceAnswerFormat(textChoices: []),
      const SingleChoiceAnswerWithFeedbackFormat(textChoices: []),
      const MultipleDoubleAnswerFormat(hints: []),
    ];

    for (final format in formats) {
      test('${format.runtimeType}', () {
        final decoded =
            jsonDecode(jsonEncode(format.toJson())) as Map<String, dynamic>;

        expect(
          decoded['type'],
          format.answerType,
          reason: 'discriminator missing for ${format.runtimeType}',
        );

        final back = AnswerFormat.fromJson(decoded);

        expect(
          back.runtimeType,
          format.runtimeType,
          reason: '${format.runtimeType} degraded to ${back.runtimeType}',
        );
        expect(
          back.answerType,
          format.answerType,
          reason: '${format.runtimeType} answerType changed after decode',
        );
        expect(
          back.toJson(),
          format.toJson(),
          reason:
              '${format.runtimeType} did not round-trip its payload '
              'faithfully',
        );
      });
    }
  });
}
