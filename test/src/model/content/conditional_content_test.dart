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
      const content = ConditionalContent(
        variable: 'child_name',
        options: {
          'Aidan': HtmlContent(html: '<p>Aidan</p>'),
          'Brayden': HtmlContent(html: '<p>Brayden</p>'),
        },
      );
      final resolved = content.resolveContent({'child_name': 'Brayden'});
      expect(resolved, isA<HtmlContent>());
      expect((resolved! as HtmlContent).html, '<p>Brayden</p>');
    });

    test('returns null when variable not in map', () {
      const content = ConditionalContent(
        variable: 'child_name',
        options: {
          'Aidan': HtmlContent(html: '<p>Aidan</p>'),
        },
      );
      final resolved = content.resolveContent({});
      expect(resolved, isNull);
    });

    test('returns null when value not in options', () {
      const content = ConditionalContent(
        variable: 'child_name',
        options: {
          'Aidan': HtmlContent(html: '<p>Aidan</p>'),
        },
      );
      final resolved = content.resolveContent({'child_name': 'Unknown'});
      expect(resolved, isNull);
    });

    test('returns default option when variable absent', () {
      const content = ConditionalContent(
        variable: 'child_name',
        options: {
          'Aidan': HtmlContent(html: '<p>Aidan</p>'),
          'Brayden': HtmlContent(html: '<p>Brayden</p>'),
        },
        defaultOption: 'Aidan',
      );
      expect((content.resolveContent({})! as HtmlContent).html, '<p>Aidan</p>');
    });

    test('returns default option when value not in options', () {
      const content = ConditionalContent(
        variable: 'child_name',
        options: {'Aidan': HtmlContent(html: '<p>Aidan</p>')},
        defaultOption: 'Aidan',
      );
      expect((content.resolveContent({'child_name': 'X'})! as HtmlContent).html, '<p>Aidan</p>');
    });

    test('matched value still wins over default', () {
      const content = ConditionalContent(
        variable: 'child_name',
        options: {
          'Aidan': HtmlContent(html: '<p>Aidan</p>'),
          'Brayden': HtmlContent(html: '<p>Brayden</p>'),
        },
        defaultOption: 'Aidan',
      );
      expect((content.resolveContent({'child_name': 'Brayden'})! as HtmlContent).html, '<p>Brayden</p>');
    });

    test('deserializes default from JSON and round-trips', () {
      final json = {
        'type': 'conditional',
        'variable': 'child_name',
        'default': 'Aidan',
        'options': {'Aidan': {'type': 'html', 'html': '<p>A</p>'}},
      };
      final c = ConditionalContent.fromJson(json);
      expect(c.defaultOption, 'Aidan');
      expect(c.toJson()['default'], 'Aidan');
    });

    test('toJson omits default when null', () {
      const c = ConditionalContent(
        variable: 'v',
        options: {'a': HtmlContent(html: '<p>a</p>')},
      );
      expect(c.toJson().containsKey('default'), isFalse);
    });
  });
}
