// Conditional resolution at present time (ADO #1045). The first two tests
// CANNOT pass before this change: before it, a conditional answer format
// resolved at parse against a map with no answers in it, so it always took
// `default`, and the state carried the unresolved ConditionalContent.
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:survey_kit/src/engine/survey_engine.dart';
import 'package:survey_kit/survey_kit.dart';

import 'engine_harness.dart';

/// A directive branching on the answer to step [variable].
Map<String, dynamic> conditionalFormat(String variable) => <String, dynamic>{
  'type': 'conditional',
  'variable': variable,
  'default': 'Caroline',
  'variants': <String, dynamic>{
    'Caroline': <String, dynamic>{'type': 'text'},
    'Lilia': <String, dynamic>{'type': 'integer'},
  },
};

/// s1 is a plain question; s2's answer format branches on s1's answer.
Task branchingTask({Map<String, dynamic> variables = const {}}) =>
    Task.fromJson(<String, dynamic>{
      'type': 'navigable',
      'id': 't',
      'variables': variables,
      'steps': <dynamic>[
        const <String, dynamic>{
          'id': 's1',
          'content': <dynamic>[],
          'answerFormat': <String, dynamic>{'type': 'text'},
        },
        <String, dynamic>{
          'id': 's2',
          'content': const <dynamic>[],
          'answerFormat': conditionalFormat('s1'),
        },
      ],
    });

PresentingSurveyState presenting(SurveyEngine engine) =>
    engine.state as PresentingSurveyState;

void main() {
  test('a conditional answer format branches on a STEP ANSWER', () async {
    // The red test. Parse time cannot see s1's answer, so before ADO #1045
    // this resolved to the 'Caroline' default and produced a TextAnswerFormat.
    final engine = makeEngine(task: branchingTask(), host: FakeSurveyHost());

    await engine.handleEvent(StartSurvey());
    await engine.handleEvent(NextStep(textResult('s1', 'Lilia')));
    await drain();

    expect(presenting(engine).currentStep.id, 's2');
    expect(
      presenting(engine).currentStep.answerFormat,
      isA<IntegerAnswerFormat>(),
    );

    engine.dispose();
  });

  test('resolved content reaches the state, not just the tree', () async {
    // The second red test. Before ADO #1045 the state carried the unresolved
    // ConditionalContent and only ContentWidget's build resolved it, so nothing
    // outside the widget tree could see the resolved content.
    final task = NavigableTask(
      id: 't',
      steps: [
        Step(
          id: 's1',
          content: const [
            ConditionalContent(
              variable: 'who',
              options: {'Lilia': TextContent(text: 'for Lilia')},
              defaultOption: 'Lilia',
            ),
          ],
        ),
      ],
      variables: const {'who': 'Lilia'},
    );
    final engine = makeEngine(task: task, host: FakeSurveyHost());

    await engine.handleEvent(StartSurvey());
    await drain();

    final content = presenting(engine).currentStep.content;
    expect(content, hasLength(1));
    expect(content.single, isA<TextContent>());
    expect((content.single as TextContent).text, 'for Lilia');

    engine.dispose();
  });

  test('a config variable still selects its variant', () async {
    // The migrated guard. conditional_answer_format_test.dart used to assert
    // this at parse time, guarding a `variables:` threading that no longer
    // exists. Same intent, one layer down the pipeline.
    final engine = makeEngine(
      task: branchingTask(variables: const {'s1': 'Lilia'}),
      host: FakeSurveyHost(),
    );

    await engine.handleEvent(StartSurvey());
    await engine.handleEvent(NextStep(textResult('s1', 'ignored')));
    await drain();

    // Config variables win the merge, so the config value decides even though
    // the step answer names no variant.
    expect(
      presenting(engine).currentStep.answerFormat,
      isA<IntegerAnswerFormat>(),
    );

    engine.dispose();
  });

  test('the resolved copy reports its AUTHORED index', () async {
    // Only observable with stepCount unset: with it, currentStepIndex returns
    // history.length and never compares steps at all. The consumer sets
    // stepCount, which is exactly why a -1 here would ship invisibly.
    final engine = makeEngine(task: branchingTask(), host: FakeSurveyHost());

    await engine.handleEvent(StartSurvey());
    await engine.handleEvent(NextStep(textResult('s1', 'Lilia')));
    await drain();

    expect(
      engine.taskNavigator.task.stepCount,
      isNull,
      reason: 'fixture guard',
    );
    expect(presenting(engine).currentStepIndex, 1);

    engine.dispose();
  });

  test('the copy carries every authored field forward', () async {
    // isMandatory defaults true and buttonText defaults 'Next', so a dropped
    // field still looks right unless the fixture sets them non-default.
    Widget shell(Step step, Widget? answerWidget, BuildContext context) =>
        answerWidget ?? const SizedBox();

    final task = NavigableTask(
      id: 't',
      steps: [
        Step(
          id: 'authored',
          isMandatory: false,
          buttonText: 'Continue',
          stepShell: shell,
          content: const [
            ConditionalContent(
              variable: 'who',
              options: {'x': TextContent(text: 'resolved')},
              defaultOption: 'x',
            ),
          ],
        ),
      ],
    );
    final engine = makeEngine(task: task, host: FakeSurveyHost());

    await engine.handleEvent(StartSurvey());
    await drain();

    final step = presenting(engine).currentStep;
    expect(step.id, 'authored');
    expect(step.isMandatory, isFalse);
    expect(step.buttonText, 'Continue');
    expect(step.stepShell, same(shell));

    engine.dispose();
  });

  test('a subclass that does not override copyResolved is warned about', () {
    final lines = <String>[];
    void listener(OutputEvent event) => lines.addAll(event.lines);
    Logger.addOutputListener(listener);
    addTearDown(() => Logger.removeOutputListener(listener));

    final task = NavigableTask(
      id: 't',
      steps: [
        DowngradingStep(
          id: 's1',
          content: const [
            ConditionalContent(
              variable: 'who',
              options: {'x': TextContent(text: 'resolved')},
              defaultOption: 'x',
            ),
          ],
        ),
      ],
    );
    final engine = makeEngine(task: task, host: FakeSurveyHost());

    return engine.handleEvent(StartSurvey()).then((_) {
      expect(presenting(engine).currentStep, isNot(isA<DowngradingStep>()));
      expect(
        lines.join('\n'),
        contains('copyResolved'),
        reason: 'the downgrade must be diagnosable, not silent',
      );
      engine.dispose();
    });
  });

  test('history records authored steps, never resolved copies', () async {
    // NavigableTaskNavigator.previousInList returns history.last, so a copy in
    // history would make back-navigation replay a STALE resolution instead of
    // re-resolving against the current answers.
    final task = branchingTask();
    final engine = makeEngine(task: task, host: FakeSurveyHost());

    await engine.handleEvent(StartSurvey());
    await engine.handleEvent(NextStep(textResult('s1', 'Lilia')));
    await drain();

    expect(engine.taskNavigator.history.first, same(task.steps.first));

    engine.dispose();
  });
}

/// Adds state and does NOT override copyResolved, so resolution downgrades it.
class DowngradingStep extends Step {
  DowngradingStep({required super.id, required super.content});
}
