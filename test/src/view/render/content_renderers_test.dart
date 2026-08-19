import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/model/content/content_type.dart';
import 'package:survey_kit/src/view/render/content_renderers.dart';
import 'package:survey_kit/src/view/widget/content/audio_widget.dart';
import 'package:survey_kit/src/view/widget/content/lottie_widget.dart';
import 'package:survey_kit/src/view/widget/content/section_widget.dart';
import 'package:survey_kit/survey_kit.dart';

/// A custom content type with children, standing in for a consumer composite.
/// The built-in SectionContent would exercise reentrancy too, but only into one
/// statically known type — this one nests a second custom type, which is the
/// case the registry has to carry.
class _CompositeContent extends Content {
  const _CompositeContent(this.children) : super(contentType: 'composite');

  final List<Content> children;

  @override
  Map<String, dynamic> toJson() => {'type': contentType};

  // Required only until Task 5 deletes Content.createWidget; that task removes
  // this override and the one on _LeafContent below.
  @override
  Widget createWidget({
    Map<String, dynamic> variables = const {},
    Map<String, StyledTextContent>? contentStyles,
  }) => const SizedBox.shrink();
}

class _LeafContent extends Content {
  const _LeafContent() : super(contentType: 'leaf');

  @override
  Map<String, dynamic> toJson() => {'type': contentType};

  @override
  Widget createWidget({
    Map<String, dynamic> variables = const {},
    Map<String, StyledTextContent>? contentStyles,
  }) => const SizedBox.shrink();
}

ContentRenderContext _context({
  Map<String, dynamic> variables = const {},
  Map<String, StyledTextContent>? contentStyles,
  Widget Function(Content)? render,
}) => ContentRenderContext(
  variables: variables,
  contentStyles: contentStyles,
  render: render ?? (_) => const SizedBox.shrink(),
);

void main() {
  group('defaultContentRenderers', () {
    test('covers every built-in discriminator', () {
      expect(
        defaultContentRenderers.keys.toSet(),
        ContentType.values.map((e) => e.wireName).toSet(),
      );
    });

    // Presence is not correctness: 'text': renderImageContent satisfies the
    // pin above. These bind each key to its intended function by identity.
    test('binds each discriminator to its own renderer', () {
      expect(defaultContentRenderers['audio'], equals(renderAudioContent));
      expect(defaultContentRenderers['text'], equals(renderTextContent));
      expect(
        defaultContentRenderers['styled_text'],
        equals(renderStyledTextContent),
      );
      expect(defaultContentRenderers['video'], equals(renderVideoContent));
      expect(defaultContentRenderers['image'], equals(renderImageContent));
      expect(
        defaultContentRenderers['markdown'],
        equals(renderMarkdownContent),
      );
      expect(defaultContentRenderers['lottie'], equals(renderLottieContent));
      expect(defaultContentRenderers['html'], equals(renderHtmlContent));
      expect(
        defaultContentRenderers['separator'],
        equals(renderSeparatorContent),
      );
      expect(defaultContentRenderers['section'], equals(renderSectionContent));
      expect(
        defaultContentRenderers['conditional'],
        equals(renderConditionalContent),
      );
    });
  });

  group('contentRendererFor', () {
    test('falls back to the built-in when no registry is supplied', () {
      expect(
        contentRendererFor('styled_text', null),
        equals(renderStyledTextContent),
      );
    });

    test('a registered renderer shadows a built-in', () {
      Widget custom(Content content, ContentRenderContext context) =>
          const SizedBox.shrink();
      final registries = SurveyRegistries(
        contentRenderers: {'styled_text': custom},
      );

      expect(contentRendererFor('styled_text', registries), equals(custom));
    });

    test('resolves a custom discriminator with no built-in', () {
      Widget custom(Content content, ContentRenderContext context) =>
          const SizedBox.shrink();
      final registries = SurveyRegistries(contentRenderers: {'pdf': custom});

      expect(contentRendererFor('pdf', registries), equals(custom));
    });

    test('throws for a discriminator with no renderer anywhere', () {
      expect(
        () => contentRendererFor('pdf', const SurveyRegistries()),
        throwsA(
          isA<UnregisteredRendererException>()
              .having((e) => e.kind, 'kind', 'Content')
              .having((e) => e.discriminator, 'discriminator', 'pdf'),
        ),
      );
    });
  });

  group('reentrancy', () {
    test('a composite renders nested content through the context', () {
      final rendered = <String>[];
      Widget renderComposite(Content content, ContentRenderContext context) {
        final composite = content as _CompositeContent;
        return Column(
          children: composite.children.map(context.render).toList(),
        );
      }

      Widget renderLeaf(Content content, ContentRenderContext context) {
        rendered.add(content.contentType);
        return const SizedBox.shrink();
      }

      final registries = SurveyRegistries(
        contentRenderers: {'composite': renderComposite, 'leaf': renderLeaf},
      );

      // The closure ContentWidget builds, reproduced here so the test covers
      // the resolution path and not just the callback plumbing.
      Widget render(Content content) => contentRendererFor(
        content.contentType,
        registries,
      )(content, _context(render: render));

      render(
        const _CompositeContent([
          _LeafContent(),
          StyledTextContent(text: 'nested built-in'),
        ]),
      );

      expect(rendered, ['leaf']);
    });
  });

  group('renderSectionContent', () {
    test(
      'takes the SectionWidget shortcut when there is nothing to resolve',
      () {
        const section = SectionContent(
          title: StyledTextContent(text: 'title'),
          subtitle: StyledTextContent(text: 'subtitle'),
          text: StyledTextContent(text: 'text'),
        );

        expect(renderSectionContent(section, _context()), isA<SectionWidget>());
      },
    );

    test('renders children through the context when variables are present', () {
      const section = SectionContent(
        title: StyledTextContent(text: 'title'),
        subtitle: StyledTextContent(text: 'subtitle'),
        text: StyledTextContent(text: 'text'),
      );
      final seen = <Content>[];

      renderSectionContent(
        section,
        _context(
          variables: {'a': 1},
          render: (child) {
            seen.add(child);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(seen, hasLength(3));
    });
  });

  test('renderConditionalContent renders nothing', () {
    // Listed in the spec as behaviour that must not change. Unreachable in
    // practice since ADO #1045 — SurveyEngine resolves conditionals before a
    // step reaches the widget tree — so no widget test can reach this body and
    // it has to be called directly.
    expect(
      renderConditionalContent(
        const ConditionalContent(
          variable: 'x',
          options: {'k': StyledTextContent(text: 'b')},
          defaultOption: 'k',
        ),
        _context(),
      ),
      isA<SizedBox>(),
    );
  });

  group('renderers with no other coverage', () {
    // Audio, lottie and video content appear in json_round_trip_test.dart and
    // content_type_test.dart but are never rendered by any widget test, so
    // these three bodies would otherwise move with zero coverage. Asserting the
    // widget type without pumping keeps them off platform channels.
    test('renderAudioContent builds an AudioWidget', () {
      expect(
        renderAudioContent(const AudioContent(url: 'a.mp3'), _context()),
        isA<AudioWidget>(),
      );
    });

    test('renderLottieContent builds a LottieWidget', () {
      expect(
        renderLottieContent(const LottieContent(asset: 'a.json'), _context()),
        isA<LottieWidget>(),
      );
    });

    test('renderVideoContent builds a VideoWidget', () {
      expect(
        renderVideoContent(const VideoContent(url: 'a.mp4'), _context()),
        isA<VideoWidget>(),
      );
    });
  });
}
