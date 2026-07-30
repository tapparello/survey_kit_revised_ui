import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/model/content/html_content.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';

void main() {
  group('SurveyRegistries', () {
    test('resolves registered custom content type', () {
      const registries = SurveyRegistries(
        customContentTypes: {'custom_html': HtmlContent.fromJson},
      );
      final json = {'type': 'custom_html', 'html': '<p>test</p>'};
      final content = registries.resolveContent(json);
      expect(content, isA<HtmlContent>());
    });

    test('returns null for unregistered content type', () {
      const registries = SurveyRegistries();
      final content = registries.resolveContent({'type': 'unknown'});
      expect(content, isNull);
    });

    test('resolves registered custom step type', () {
      const registries = SurveyRegistries(
        customStepTypes: {'custom_step': Step.fromJson},
      );
      final json = {'type': 'custom_step', 'id': 'test', 'content': []};
      final step = registries.resolveStep(json);
      expect(step, isA<Step>());
    });

    test('stores and retrieves action handler', () {
      void handler(List<StepResult> r, Map<String, dynamic> v) {}
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
}
