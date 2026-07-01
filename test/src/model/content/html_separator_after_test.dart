import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/model/content/html_content.dart';

void main() {
  test('HtmlContent parses and round-trips separatorAfter', () {
    final off = HtmlContent.fromJson({'html': 'x', 'separatorAfter': false});
    expect(off.separatorAfter, isFalse);
    expect(off.toJson()['separatorAfter'], isFalse);
  });

  test('HtmlContent defaults separatorAfter to true when absent', () {
    expect(HtmlContent.fromJson({'html': 'y'}).separatorAfter, isTrue);
  });
}
