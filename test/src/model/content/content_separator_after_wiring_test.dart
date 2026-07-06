import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/model/content/image_content.dart';
import 'package:survey_kit/src/model/content/styled_text_content.dart';
import 'package:survey_kit/src/model/content/text_content.dart';
import 'package:survey_kit/src/model/content/video_content.dart';

void main() {
  test('TextContent round-trips separatorAfter', () {
    final c = TextContent.fromJson({'text': 't', 'separatorAfter': false});
    expect(c.separatorAfter, isFalse);
    expect(c.toJson()['separatorAfter'], isFalse);
    expect(TextContent.fromJson({'text': 't'}).separatorAfter, isTrue);
  });

  test('StyledTextContent round-trips separatorAfter', () {
    final c = StyledTextContent.fromJson({'text': 't', 'separatorAfter': false});
    expect(c.separatorAfter, isFalse);
    expect(c.toJson()['separatorAfter'], isFalse);
    expect(StyledTextContent.fromJson({'text': 't'}).separatorAfter, isTrue);
  });

  test('ImageContent round-trips separatorAfter', () {
    final c = ImageContent.fromJson({'url': 'u', 'separatorAfter': false});
    expect(c.separatorAfter, isFalse);
    expect(c.toJson()['separatorAfter'], isFalse);
    expect(ImageContent.fromJson({'url': 'u'}).separatorAfter, isTrue);
  });

  test('VideoContent round-trips separatorAfter', () {
    final c = VideoContent.fromJson({'url': 'u', 'separatorAfter': false});
    expect(c.separatorAfter, isFalse);
    expect(c.toJson()['separatorAfter'], isFalse);
    expect(VideoContent.fromJson({'url': 'u'}).separatorAfter, isTrue);
  });
}
