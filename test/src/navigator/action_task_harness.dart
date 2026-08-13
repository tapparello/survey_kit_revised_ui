// Shared fixtures for the action-rule tests. A NavigableTask whose first step
// carries an ActionNavigationRule, plus counters the tests assert on.
import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/navigator/rules/action_navigation_rule.dart';
import 'package:survey_kit/src/navigator/rules/conditional_navigation_rule.dart';
import 'package:survey_kit/src/navigator/rules/custom_navigation_rule.dart';
import 'package:survey_kit/src/task/navigable_task.dart';

/// s1 --[action 'side_effect']--> s2. The handler bumps `variables['fired']`,
/// so a test can distinguish "not called", "called once" and "called twice".
NavigableTask actionTask() {
  final step1 = Step(id: 's1', content: const []);
  final step2 = Step(id: 's2', content: const []);
  return NavigableTask(
    id: 't',
    steps: [step1, step2],
    navigationRules: const {
      's1': ActionNavigationRule(
        actionId: 'side_effect',
        nextStepIdentifier: 's2',
      ),
    },
  );
}

/// Records what the two consumer-supplied rule callbacks saw.
class RuleProbe {
  int customCalls = 0;
  int conditionalCalls = 0;
  StepResult? lastCustomResult;
  StepResult? lastConditionalInput;
}

/// s1 --[custom 'route']--> s2, s2 --[conditional]--> s3.
///
/// Both callbacks bump [RuleProbe], which is how the probe tests prove that
/// `peekNextStep` still evaluates them — the contract documented in the spec,
/// section 3 — and that it passes them a null `questionResult`.
({NavigableTask task, SurveyRegistries registries, RuleProbe probe})
ruleTask() {
  final probe = RuleProbe();
  final task = NavigableTask(
    id: 't',
    steps: [
      Step(id: 's1', content: const []),
      Step(id: 's2', content: const []),
      Step(id: 's3', content: const []),
    ],
    navigationRules: {
      's1': const CustomNavigationRule(ruleId: 'route'),
      's2': ConditionalNavigationRule(
        resultToStepIdentifierMapper: (results, input) {
          probe.conditionalCalls++;
          probe.lastConditionalInput = input;
          return 's3';
        },
      ),
    },
  );
  final registries = SurveyRegistries(
    customNavigationRules: {
      'route': (results, currentResult, variables) {
        probe.customCalls++;
        probe.lastCustomResult = currentResult;
        return 's2';
      },
    },
  );
  return (task: task, registries: registries, probe: probe);
}
