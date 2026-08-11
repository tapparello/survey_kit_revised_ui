import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/model/content/audio_content.dart';
import 'package:survey_kit/src/model/content/conditional_content.dart';
import 'package:survey_kit/src/model/content/content.dart';
import 'package:survey_kit/src/model/content/html_content.dart';
import 'package:survey_kit/src/model/content/image_content.dart';
import 'package:survey_kit/src/model/content/lottie_content.dart';
import 'package:survey_kit/src/model/content/markdown_content.dart';
import 'package:survey_kit/src/model/content/section_content.dart';
import 'package:survey_kit/src/model/content/separator_content.dart';
import 'package:survey_kit/src/model/content/styled_text_content.dart';
import 'package:survey_kit/src/model/content/text_content.dart';
import 'package:survey_kit/src/model/content/video_content.dart';

// Adapters rather than factory tearoffs. The field type must accept
// `registries:` so ConditionalContent receives it, but Dart function subtyping
// only tolerates *extra* optional named parameters, not missing ones — a plain
// `Content Function(Map)` is not assignable to the registry-carrying type. A
// lambda is not an option either: enum constant arguments must be constant
// expressions, and a function literal is not one. See ADO #1015.
Content _audio(Map<String, dynamic> j, {SurveyRegistries? registries}) =>
    AudioContent.fromJson(j);
Content _text(Map<String, dynamic> j, {SurveyRegistries? registries}) =>
    TextContent.fromJson(j);
Content _styledText(Map<String, dynamic> j, {SurveyRegistries? registries}) =>
    StyledTextContent.fromJson(j);
Content _video(Map<String, dynamic> j, {SurveyRegistries? registries}) =>
    VideoContent.fromJson(j);
Content _image(Map<String, dynamic> j, {SurveyRegistries? registries}) =>
    ImageContent.fromJson(j);
Content _markdown(Map<String, dynamic> j, {SurveyRegistries? registries}) =>
    MarkdownContent.fromJson(j);
Content _lottie(Map<String, dynamic> j, {SurveyRegistries? registries}) =>
    LottieContent.fromJson(j);
Content _html(Map<String, dynamic> j, {SurveyRegistries? registries}) =>
    HtmlContent.fromJson(j);
Content _separator(Map<String, dynamic> j, {SurveyRegistries? registries}) =>
    SeparatorContent.fromJson(j);
Content _section(Map<String, dynamic> j, {SurveyRegistries? registries}) =>
    SectionContent.fromJson(j);
Content _conditional(Map<String, dynamic> j, {SurveyRegistries? registries}) =>
    ConditionalContent.fromJson(j, registries: registries);

/// The complete set of built-in [Content] discriminators.
///
/// Deliberately **not** exported from `survey_kit.dart`, unlike
/// [AnswerFormatType]: [Content.contentType] must stay a `String` so consumers
/// can register their own types (FMF Connect registers `pdf`), so this enum is
/// an internal dispatch mechanism rather than public API. It lives in its own
/// unexported file because `content.dart` *is* exported — a public declaration
/// there would join the barrel, and a private one would be unreachable from
/// `test/`.
///
/// Unlike answer formats, content subclasses keep their `static const type`:
/// they pass it to a `const` super-constructor call, which requires a
/// compile-time constant, and an enum member's field is not one. The two copies
/// are pinned together by `content_type_test.dart`.
enum ContentType {
  audio('audio', _audio),
  text('text', _text),
  styledText('styled_text', _styledText),
  video('video', _video),
  image('image', _image),
  markdown('markdown', _markdown),
  lottie('lottie', _lottie),
  html('html', _html),
  separator('separator', _separator),
  section('section', _section),
  conditional('conditional', _conditional);

  const ContentType(this.wireName, this.fromJson);

  /// The JSON `type` value.
  final String wireName;

  /// Builds the concrete content, forwarding [registries] to any nested parse.
  final Content Function(
    Map<String, dynamic> json, {
    SurveyRegistries? registries,
  })
  fromJson;

  static final Map<String, ContentType> _byWireName = {
    for (final member in ContentType.values) member.wireName: member,
  };

  /// The member for [name], or null when [name] is null or unrecognised.
  static ContentType? byWireName(String? name) =>
      name == null ? null : _byWireName[name];
}
