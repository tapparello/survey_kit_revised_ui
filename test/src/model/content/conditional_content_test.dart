import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/model/content/conditional_content.dart';
import 'package:survey_kit/src/model/content/html_content.dart';

void main() {
  group('ConditionalContent', () {
    test('deserializes from JSON', () {
      final json = {
        'type': 'conditional',
        'variable': 'child_name',
        'options': {
          'Aidan': {'type': 'html', 'html': '<p>Aidan content</p>'},
          'Brayden': {'type': 'html', 'html': '<p>Brayden content</p>'},
        },
      };
      final content = ConditionalContent.fromJson(json);
      expect(content.variable, 'child_name');
      expect(content.options.length, 2);
      expect(content.options['Aidan'], isA<HtmlContent>());
    });

    test('resolves correct option from variables', () {
      final content = ConditionalContent(
        variable: 'child_name',
        options: {
          'Aidan': const HtmlContent(html: '<p>Aidan</p>'),
          'Brayden': const HtmlContent(html: '<p>Brayden</p>'),
        },
      );
      final resolved = content.resolveContent({'child_name': 'Brayden'});
      expect(resolved, isA<HtmlContent>());
      expect((resolved as HtmlContent).html, '<p>Brayden</p>');
    });

    test('returns null when variable not in map', () {
      final content = ConditionalContent(
        variable: 'child_name',
        options: {
          'Aidan': const HtmlContent(html: '<p>Aidan</p>'),
        },
      );
      final resolved = content.resolveContent({});
      expect(resolved, isNull);
    });

    test('returns null when value not in options', () {
      final content = ConditionalContent(
        variable: 'child_name',
        options: {
          'Aidan': const HtmlContent(html: '<p>Aidan</p>'),
        },
      );
      final resolved = content.resolveContent({'child_name': 'Unknown'});
      expect(resolved, isNull);
    });
  });
}
