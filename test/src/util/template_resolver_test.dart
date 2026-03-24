import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/util/template_resolver.dart';

void main() {
  group('TemplateResolver', () {
    test('resolves simple string placeholder', () {
      final result = TemplateResolver.resolve(
        'Hello {{name}}!',
        {'name': 'World'},
      );
      expect(result, 'Hello World!');
    });

    test('resolves multiple placeholders', () {
      final result = TemplateResolver.resolve(
        '{{greeting}} {{name}}!',
        {'greeting': 'Hi', 'name': 'Alice'},
      );
      expect(result, 'Hi Alice!');
    });

    test('resolves list placeholder as li items', () {
      final result = TemplateResolver.resolve(
        '<ul>{{#list items}}</ul>',
        {'items': ['Apple', 'Banana']},
      );
      expect(result, '<ul><li>Apple</li><li>Banana</li></ul>');
    });

    test('replaces unresolved placeholder with empty string', () {
      final result = TemplateResolver.resolve(
        'Hello {{missing}}!',
        {},
      );
      expect(result, 'Hello !');
    });

    test('returns original text when no placeholders', () {
      final result = TemplateResolver.resolve('No placeholders', {});
      expect(result, 'No placeholders');
    });

    test('handles empty variables map', () {
      final result = TemplateResolver.resolve('{{key}}', {});
      expect(result, '');
    });

    test('resolves list placeholder with single item', () {
      final result = TemplateResolver.resolve(
        '{{#list items}}',
        {'items': ['Only']},
      );
      expect(result, '<li>Only</li>');
    });

    test('resolves list placeholder with empty list', () {
      final result = TemplateResolver.resolve(
        '{{#list items}}',
        {'items': <String>[]},
      );
      expect(result, '');
    });

    test('handles mixed string and list placeholders', () {
      final result = TemplateResolver.resolve(
        '<p>{{title}}</p><ul>{{#list items}}</ul>',
        {'title': 'My List', 'items': ['A', 'B']},
      );
      expect(result, '<p>My List</p><ul><li>A</li><li>B</li></ul>');
    });
  });
}
