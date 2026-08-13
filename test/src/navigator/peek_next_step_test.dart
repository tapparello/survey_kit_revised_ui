import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/navigator/navigable_task_navigator.dart';
import 'package:survey_kit/src/navigator/ordered_task_navigator.dart';
import 'package:survey_kit/src/navigator/rules/action_navigation_rule.dart';
import 'package:survey_kit/src/task/navigable_task.dart';
import 'package:survey_kit/src/task/ordered_task.dart';

import 'action_task_harness.dart';

/// The probe is NOT side-effect free, and that is deliberate: evaluating a
/// custom rule or a conditional mapper is the only way to learn where those
/// rules lead. Suppressing them would mean guessing nextInList, which mislabels
/// Next/Done on exactly the branching steps where the label matters. See the
/// spec, section 3. These tests pin the contract so a later change to
/// hasNextStep cannot silently break FMF Connect's 13 rule handlers.
void main() {
  test('peekNextStep evaluates a CustomNavigationRule with a null result', () {
    final fixture = ruleTask();
    final navigator = NavigableTaskNavigator(
      fixture.task,
      registries: fixture.registries,
    );

    final next = navigator.peekNextStep(
      step: fixture.task.steps.first,
      previousResults: const [],
    );

    expect(next?.id, 's2');
    expect(fixture.probe.customCalls, 1);
    expect(fixture.probe.lastCustomResult, isNull);
    expect(navigator.history, isEmpty);
  });

  test('peekNextStep evaluates a ConditionalNavigationRule mapper', () {
    final fixture = ruleTask();
    final navigator = NavigableTaskNavigator(
      fixture.task,
      registries: fixture.registries,
    );

    final next = navigator.peekNextStep(
      step: fixture.task.steps[1],
      previousResults: const [],
    );

    expect(next?.id, 's3');
    expect(fixture.probe.conditionalCalls, 1);
    expect(fixture.probe.lastConditionalInput, isNull);
  });

  test('an end_task action rule peeks to null without firing', () {
    // 10 of FMF Connect's 21 action rules terminate the survey, so this is the
    // majority path in the consumer — and it is the only test that reaches
    // _destinationOf's `end_task` branch. Without it, StepView would silently
    // stop showing 'Done' on a terminal step behind an action rule.
    final task = NavigableTask(
      id: 't',
      steps: [
        Step(id: 's1', content: const []),
        Step(id: 's2', content: const []),
      ],
      navigationRules: const {
        's1': ActionNavigationRule(
          actionId: 'side_effect',
          nextStepIdentifier: 'end_task',
        ),
      },
    );
    final navigator = NavigableTaskNavigator(
      task,
      registries: SurveyRegistries(
        actionHandlers: {
          'side_effect': (results, variables) => variables['fired'] = true,
        },
      ),
    );

    expect(
      navigator.peekNextStep(step: task.steps.first, previousResults: const []),
      isNull,
    );
    expect(navigator.hasNextStep(task.steps.first, const []), isFalse);
    expect(task.variables['fired'], isNull);
    expect(navigator.history, isEmpty);
  });

  test('OrderedTaskNavigator.peekNextStep advances nothing', () {
    final task = OrderedTask(
      id: 't',
      steps: [
        Step(id: 'a', content: const []),
        Step(id: 'b', content: const []),
      ],
    );
    final navigator = OrderedTaskNavigator(task);

    final next = navigator.peekNextStep(
      step: task.steps.first,
      previousResults: const [],
    );

    expect(next?.id, 'b');
    expect(navigator.history, isEmpty);
  });
}
