import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/model/content/content_type.dart';
import 'package:survey_kit/survey_kit.dart';

/// Guards the JSON `type` discriminator against regeneration regressions.
///
/// Both groups iterate their discriminator enum rather than a hand-written
/// list, so a new member with no fixture fails here by name. That is the
/// difference between narrowing the hole and closing it: the previous version
/// of this file listed 10 of 11 content types, and the missing one — section —
/// was ADO #1006.
void main() {
  group('Content discriminator survives a JSON round trip', () {
    final samples = <ContentType, Content>{
      ContentType.audio: const AudioContent(url: 'u'),
      ContentType.text: const TextContent(text: 'hi'),
      ContentType.styledText: const StyledTextContent(text: 'hi'),
      ContentType.video: const VideoContent(url: 'u'),
      ContentType.image: const ImageContent(url: 'u'),
      ContentType.markdown: const MarkdownContent(text: '# hi'),
      ContentType.lottie: const LottieContent(url: 'u'),
      ContentType.html: const HtmlContent(html: '<p>hi</p>'),
      ContentType.separator: const SeparatorContent(),
      ContentType.section: const SectionContent(
        title: StyledTextContent(text: 't'),
        subtitle: StyledTextContent(text: 's'),
        text: StyledTextContent(text: 'b'),
      ),
      ContentType.conditional: const ConditionalContent(
        variable: 'x',
        options: {'1': TextContent(text: 'inner')},
      ),
    };

    test('every ContentType member has a fixture', () {
      for (final member in ContentType.values) {
        expect(
          samples[member],
          isNotNull,
          reason: 'no fixture: ${member.name}',
        );
      }
    });

    for (final member in ContentType.values) {
      test(member.name, () {
        final content = samples[member]!;
        final decoded =
            jsonDecode(jsonEncode(content.toJson())) as Map<String, dynamic>;

        expect(
          decoded['type'],
          member.wireName,
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
    final samples = <AnswerFormatType, AnswerFormat>{
      AnswerFormatType.boolean: const BooleanAnswerFormat(
        positiveAnswer: 'y',
        negativeAnswer: 'n',
      ),
      // DateAnswerFormat's constructor is not const.
      AnswerFormatType.date: DateAnswerFormat(),
      AnswerFormatType.doubleValue: const DoubleAnswerFormat(),
      AnswerFormatType.integer: const IntegerAnswerFormat(),
      AnswerFormatType.image: const ImageAnswerFormat(),
      AnswerFormatType.text: const TextAnswerFormat(),
      AnswerFormatType.time: const TimeAnswerFormat(),
      AnswerFormatType.scale: const ScaleAnswerFormat(
        maximumValue: 10,
        minimumValue: 0,
        defaultValue: 5,
        step: 1,
      ),
      AnswerFormatType.single: const SingleChoiceAnswerFormat(textChoices: []),
      AnswerFormatType.singleWithFeedback:
          const SingleChoiceAnswerWithFeedbackFormat(textChoices: []),
      AnswerFormatType.multi: const MultipleChoiceAnswerFormat(textChoices: []),
      AnswerFormatType.multiWithFeedback:
          const MultipleChoiceAnswerWithFeedbackFormat(textChoices: []),
      AnswerFormatType.multipleAutoComplete:
          const MultipleChoiceAutoCompleteAnswerFormat(textChoices: []),
      AnswerFormatType.multipleDouble: const MultipleDoubleAnswerFormat(
        hints: [],
      ),
    };

    test('every AnswerFormatType member has a fixture', () {
      for (final member in AnswerFormatType.values) {
        expect(
          samples[member],
          isNotNull,
          reason: 'no fixture: ${member.name}',
        );
      }
    });

    for (final member in AnswerFormatType.values) {
      test(member.name, () {
        final format = samples[member]!;
        final decoded =
            jsonDecode(jsonEncode(format.toJson())) as Map<String, dynamic>;

        expect(
          decoded['type'],
          member.wireName,
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
