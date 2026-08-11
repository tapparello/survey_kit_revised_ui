import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/model/content/content_type.dart';
import 'package:survey_kit/survey_kit.dart';

void main() {
  test('every member carries the discriminator its subclass declares', () {
    // Content subclasses keep their `static const type` because they pass it to
    // a const super-constructor call, which an enum member's field cannot
    // satisfy. This pins the two copies together.
    final expected = <ContentType, String>{
      ContentType.audio: AudioContent.type,
      ContentType.text: TextContent.type,
      ContentType.styledText: StyledTextContent.type,
      ContentType.video: VideoContent.type,
      ContentType.image: ImageContent.type,
      ContentType.markdown: MarkdownContent.type,
      ContentType.lottie: LottieContent.type,
      ContentType.html: HtmlContent.type,
      ContentType.separator: SeparatorContent.type,
      ContentType.section: SectionContent.type,
      ContentType.conditional: ConditionalContent.type,
    };

    expect(ContentType.values.length, 11);
    expect(expected.length, 11);
    for (final member in ContentType.values) {
      expect(member.wireName, expected[member], reason: member.name);
    }
  });

  test('byWireName round-trips every member and rejects the rest', () {
    for (final member in ContentType.values) {
      expect(ContentType.byWireName(member.wireName), member);
    }
    expect(ContentType.byWireName('pdf'), isNull);
    expect(ContentType.byWireName(null), isNull);
  });

  group('Content.fromJson', () {
    test('resolves a section, which previously degraded silently', () {
      // ADO #1006: 'section' had no case, so it became TextContent('').
      final content = Content.fromJson(const <String, dynamic>{
        'type': 'section',
        'title': {'type': 'styled_text', 'text': 't'},
        'subtitle': {'type': 'styled_text', 'text': 's'},
        'text': {'type': 'styled_text', 'text': 'b'},
      });
      expect(content, isA<SectionContent>());
    });

    test('throws for an unrecognised type instead of degrading', () {
      expect(
        () => Content.fromJson(const <String, dynamic>{'type': 'pdf'}),
        throwsA(
          isA<UnknownTypeException>()
              .having((e) => e.kind, 'kind', 'Content')
              .having((e) => e.discriminator, 'discriminator', 'pdf'),
        ),
      );
    });

    test('throws when type is absent instead of inferring from shape', () {
      // The shape-inference fallback existed only for the persisted-result
      // re-parse path that 2b deleted. It is unreachable now.
      expect(
        () => Content.fromJson(const <String, dynamic>{'html': '<p>hi</p>'}),
        throwsA(
          isA<UnknownTypeException>()
              .having((e) => e.kind, 'kind', 'Content')
              .having((e) => e.discriminator, 'discriminator', isNull),
        ),
      );
    });

    test('a registered custom type still wins over the built-ins', () {
      final registries = SurveyRegistries(
        customContentTypes: {
          'pdf': (json) => const TextContent(text: 'stand-in for pdf'),
        },
      );
      final content = Content.fromJson(const <String, dynamic>{
        'type': 'pdf',
      }, registries: registries);
      expect(content, isA<TextContent>());
    });

    test('a conditional passes the registry down to its options', () {
      // Regression guard: a uniform factory field that dropped `registries`
      // would compile and silently lose the custom type nested here, which
      // the new throw-on-unknown would then surface as a load failure.
      final registries = SurveyRegistries(
        customContentTypes: {
          'pdf': (json) => const TextContent(text: 'nested pdf'),
        },
      );
      final content =
          Content.fromJson(const <String, dynamic>{
                'type': 'conditional',
                'variable': 'x',
                'options': {
                  '1': {'type': 'pdf'},
                },
              }, registries: registries)
              as ConditionalContent;
      expect(content.options['1'], isA<TextContent>());
      expect((content.options['1']! as TextContent).text, 'nested pdf');
    });
  });
}
