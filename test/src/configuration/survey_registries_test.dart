import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/configuration/action_context.dart';
import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/model/content/content.dart';
import 'package:survey_kit/src/model/content/html_content.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';

class _OuterContent extends Content {
  const _OuterContent(this.child) : super(contentType: 'outer');

  final Content child;

  @override
  Map<String, dynamic> toJson() => {'type': contentType};
}

class _InnerContent extends Content {
  const _InnerContent() : super(contentType: 'inner');

  @override
  Map<String, dynamic> toJson() => {'type': contentType};
}

void main() {
  group('SurveyRegistries', () {
    test('resolves registered custom content type', () {
      final registries = SurveyRegistries(
        customContentTypes: {
          'custom_html': (json, {registries}) => HtmlContent.fromJson(json),
        },
      );
      final json = {'type': 'custom_html', 'html': '<p>test</p>'};
      final content = registries.resolveContent(json);
      expect(content, isA<HtmlContent>());
    });

    test('a custom content type resolves a nested custom type', () {
      final registries = SurveyRegistries(
        customContentTypes: {
          'outer': (json, {registries}) => _OuterContent(
            Content.fromJson(
              json['child'] as Map<String, dynamic>,
              registries: registries,
            ),
          ),
          'inner': (json, {registries}) => const _InnerContent(),
        },
      );

      final parsed = Content.fromJson({
        'type': 'outer',
        'child': {'type': 'inner'},
      }, registries: registries);

      expect(parsed, isA<_OuterContent>());
      expect((parsed as _OuterContent).child, isA<_InnerContent>());
    });

    test('returns null for unregistered content type', () {
      const registries = SurveyRegistries();
      final content = registries.resolveContent({'type': 'unknown'});
      expect(content, isNull);
    });

    test('resolves registered custom step type', () {
      // Must not be Step.fromJson itself: that's the dispatching factory, and
      // it consults this same registry, so registering it as its own handler
      // recurses without bound once resolveStep forwards `this`. A factory
      // parses its children, not itself.
      final registries = SurveyRegistries(
        customStepTypes: {
          'custom_step': (json, {registries}) =>
              Step(id: json['id'] as String?, content: const []),
        },
      );
      final json = {'type': 'custom_step', 'id': 'test', 'content': []};
      final step = registries.resolveStep(json);
      expect(step, isA<Step>());
    });

    test('stores and retrieves action handler', () {
      Future<void> handler(ActionContext ctx) async {}
      final registries = SurveyRegistries(
        actionHandlers: {'my_action': handler},
      );
      expect(registries.actionHandlers['my_action'], isNotNull);
    });

    test('stores and retrieves custom navigation rule handler', () {
      String handler(
        List<StepResult> r,
        StepResult? c,
        Map<String, dynamic> v,
      ) => 'next';
      final registries = SurveyRegistries(
        customNavigationRules: {'my_rule': handler},
      );
      expect(registries.customNavigationRules['my_rule'], isNotNull);
    });
  });

  group('Step.fromJson consults the registry', () {
    test('a registered step type is built by its factory', () {
      // resolveStep existed, was exported and documented, and was called by
      // nothing in lib/ — a consumer populating customStepTypes got silence.
      final registries = SurveyRegistries(
        customStepTypes: {
          'wrap_up': (json, {registries}) =>
              Step(id: 'built-by-registry', content: const []),
        },
      );

      final step = Step.fromJson(const <String, dynamic>{
        'id': 'ignored',
        'type': 'wrap_up',
        'content': <dynamic>[],
      }, registries: registries);

      expect(step.id, 'built-by-registry');
    });

    test('an unregistered step type still builds a built-in Step', () {
      // Unlike the other four factories, an absent or unknown discriminator
      // is legitimate here: every built-in step is authored without one.
      final step = Step.fromJson(const <String, dynamic>{
        'id': 'plain',
        'type': 'not_registered',
        'content': <dynamic>[],
      }, registries: const SurveyRegistries());

      expect(step.id, 'plain');
    });

    test('no registry at all still builds a built-in Step', () {
      final step = Step.fromJson(const <String, dynamic>{
        'id': 'plain',
        'content': <dynamic>[],
      });
      expect(step.id, 'plain');
    });
  });
}
