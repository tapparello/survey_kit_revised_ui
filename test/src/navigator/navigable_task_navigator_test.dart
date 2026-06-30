import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/navigator/navigable_task_navigator.dart';
import 'package:survey_kit/src/navigator/rules/action_navigation_rule.dart';
import 'package:survey_kit/src/task/navigable_task.dart';

/// Guards ADO #976: step_view evaluates the next step at build time (via
/// hasNextStep) to choose the Next vs Done button label. hasNextStep calls
/// nextStep(recordStep: false) — a read-only probe. An ActionNavigationRule
/// must NOT fire its (side-effecting, e.g. PDF-generating) handler during that
/// probe, otherwise the action runs on every rebuild of the trigger step.
/// Real forward navigation (recordStep: true) must still fire it.
void main() {
  NavigableTaskNavigator buildNavigator() {
    final step1 = Step(id: 's1', content: const []);
    final step2 = Step(id: 's2', content: const []);
    final task = NavigableTask(
      id: 't',
      steps: [step1, step2],
      navigationRules: const {
        's1': ActionNavigationRule(
          actionId: 'side_effect',
          nextStepIdentifier: 's2',
        ),
      },
    );
    final registries = SurveyRegistries(
      actionHandlers: {
        'side_effect': (results, variables) {
          variables['fired'] = (variables['fired'] as int? ?? 0) + 1;
        },
      },
    );
    return NavigableTaskNavigator(task, registries: registries);
  }

  test('hasNextStep probe does NOT fire the action handler but sees the next step',
      () {
    final navigator = buildNavigator();
    final step1 = navigator.task.steps.first;

    final hasNext = navigator.hasNextStep(step1, const []);

    expect(hasNext, isTrue, reason: 's2 follows s1');
    expect(navigator.task.variables['fired'], isNull,
        reason: 'action handler must not run during the read-only probe');
  });

  test('real forward navigation (recordStep: true) fires the action handler once',
      () {
    final navigator = buildNavigator();
    final step1 = navigator.task.steps.first;

    final next = navigator.nextStep(step: step1, previousResults: const []);

    expect(next?.id, 's2');
    expect(navigator.task.variables['fired'], 1);
  });
}
