import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/navigator/navigable_task_navigator.dart';

import 'action_task_harness.dart';

/// Guards ADO #976 through the ADO #1040 API. step_view evaluates the next step
/// at build time (via hasNextStep) to choose the Next vs Done button label.
/// hasNextStep now calls peekNextStep — a probe that must NOT fire a
/// side-effecting ActionNavigationRule handler and must NOT record the step.
/// Real forward navigation (nextStep) must still do both.
void main() {
  NavigableTaskNavigator buildNavigator() {
    final registries = SurveyRegistries(
      actionHandlers: {
        'side_effect': (ctx) async {
          ctx.variables['fired'] = (ctx.variables['fired'] as int? ?? 0) + 1;
        },
      },
    );
    return NavigableTaskNavigator(actionTask(), registries: registries);
  }

  test('hasNextStep probe does NOT fire the action handler but sees s2', () {
    final navigator = buildNavigator();
    final step1 = navigator.task.steps.first;

    expect(
      navigator.hasNextStep(step1, const []),
      isTrue,
      reason: 's2 follows s1',
    );
    expect(
      navigator.task.variables['fired'],
      isNull,
      reason: 'action handler must not run during the read-only probe',
    );
  });

  test('peekNextStep resolves the destination without recording', () {
    final navigator = buildNavigator();

    final next = navigator.peekNextStep(
      step: navigator.task.steps.first,
      previousResults: const [],
    );

    expect(next?.id, 's2', reason: 'the destination is a literal on the rule');
    expect(navigator.history, isEmpty);
  });

  test('nextStep fires the action handler once and records the step', () async {
    final navigator = buildNavigator();

    final next = await navigator.nextStep(
      step: navigator.task.steps.first,
      previousResults: const [],
    );

    expect(next?.id, 's2');
    expect(navigator.task.variables['fired'], 1);
    expect(navigator.history.map((s) => s.id), ['s1']);
  });
}
