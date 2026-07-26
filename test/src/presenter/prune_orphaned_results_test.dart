// ADO #969: on completion the persisted SurveyResult must contain only the
// steps on the path actually taken — orphaned-branch answers seeded from a
// prior run (initialResults) must be pruned.
//
// Harness notes:
//   1. IntegerAnswerFormat is avoided: its autofocus: true text field triggers
//      the software keyboard whose slide-in animation never settles in the test
//      harness, causing pumpAndSettle to time out. SingleChoiceAnswerFormat is
//      used instead; the pruning behaviour under test is identical.
//   2. After the final button tap the survey transitions to SurveyResultState,
//      which the inner Navigator renders as a CircularProgressIndicator — an
//      infinite animation that would also hang pumpAndSettle. A bounded
//      pump(Duration(seconds:1)) is used there instead; onResult has already
//      been called synchronously before that frame, so `captured` is populated.
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

void main() {
  // Build a branching task: q1 (A/B) routes to aStep or bStep; both -> endStep.
  NavigableTask buildBranchingTask() {
    final q1 = QuestionStep(
      id: 'q1',
      title: 'Pick',
      answerFormat: SingleChoiceAnswerFormat(
        textChoices: [
          TextChoice(text: 'A', value: 'a'),
          TextChoice(text: 'B', value: 'b'),
        ],
      ),
      buttonText: 'Next',
    );
    final aStep = InstructionStep(
      id: 'aStep',
      title: 'Branch A',
      text: '',
      buttonText: 'Next',
    );
    final bStep = QuestionStep(
      id: 'bStep',
      title: 'Branch B',
      answerFormat: SingleChoiceAnswerFormat(
        textChoices: [
          TextChoice(text: 'Yes', value: 'yes'),
          TextChoice(text: 'No', value: 'no'),
        ],
      ),
      buttonText: 'Next',
    );
    final endStep = InstructionStep(
      id: 'endStep',
      title: 'Done',
      text: '',
      buttonText: 'Submit',
    );

    final task = NavigableTask(id: 't1', steps: [q1, aStep, bStep, endStep])
      ..addNavigationRule(
        forTriggerStepIdentifier: 'q1',
        navigationRule: ConditionalNavigationRule(
          resultToStepIdentifierMapper: (results, input) {
            final r = input?.result;
            final value = r is TextChoice ? r.value : null;
            return value == 'b' ? 'bStep' : 'aStep';
          },
        ),
      )
      ..addNavigationRule(
        forTriggerStepIdentifier: 'aStep',
        navigationRule: DirectNavigationRule('endStep'),
      )
      ..addNavigationRule(
        forTriggerStepIdentifier: 'bStep',
        navigationRule: DirectNavigationRule('endStep'),
      );
    return task;
  }

  StepResult seed(String id, Step step, dynamic result) {
    final t = DateTime.now();
    return StepResult(
      id: id,
      result: result,
      step: step,
      startTime: t,
      endTime: t,
    );
  }

  testWidgets('re-completing a different branch prunes the orphaned branch result', (
    WidgetTester tester,
  ) async {
    final task = buildBranchingTask();
    final q1 = task.steps.firstWhere((s) => s.id == 'q1');
    final aStep = task.steps.firstWhere((s) => s.id == 'aStep');

    // Seed a prior run that took branch A (q1=A, plus an answer on aStep).
    final seeded = <StepResult>{
      // NOTE: TextChoice is NOT const (it generates a uuid id), so no `const`.
      seed('q1', q1, TextChoice(text: 'A', value: 'a')),
      seed('aStep', aStep, 'stale-A-answer'),
    };

    SurveyResult? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SurveyKit(
            task: task,
            initialResults: seeded,
            onResult: (r) => captured = r,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Walk branch B instead: choose B on q1, then advance through bStep to end.
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next')); // q1 -> (conditional) bStep
    await tester.pumpAndSettle();
    expect(find.text('Branch B'), findsOneWidget);
    await tester.tap(find.text('Yes')); // select an answer on bStep
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next')); // bStep -> endStep
    await tester.pumpAndSettle();
    // After Submit, onResult fires and the navigator pushes a SurveyResultState
    // which renders a CircularProgressIndicator (infinite animation). Use a
    // bounded pump instead of pumpAndSettle to avoid the infinite-settle hang.
    await tester.tap(find.text('Submit')); // endStep -> finish
    await tester.pump(const Duration(seconds: 1));

    expect(captured, isNotNull, reason: 'survey should have completed');
    final ids = captured!.results.map((r) => r.id).toSet();
    expect(ids.contains('bStep'), isTrue, reason: 'new branch B answer kept');
    expect(ids.contains('q1'), isTrue, reason: 'revisited q1 answer kept');
    expect(
      ids.contains('aStep'),
      isFalse,
      reason: 'orphaned branch A answer must be pruned',
    );
  });

  testWidgets(
    'action handlers receive only on-path results (seeded orphans pruned)',
    (WidgetTester tester) async {
      final s1 = QuestionStep(
        id: 's1',
        title: 'Step 1',
        answerFormat: SingleChoiceAnswerFormat(
          textChoices: [TextChoice(text: 'Yes', value: 'yes')],
        ),
        buttonText: 'Next',
      );
      final endStep = InstructionStep(
        id: 'endStep',
        title: 'Done',
        text: '',
        buttonText: 'Submit',
      );
      final task = NavigableTask(id: 'ta', steps: [s1, endStep])
        ..addNavigationRule(
          forTriggerStepIdentifier: 's1',
          navigationRule: const ActionNavigationRule(
            actionId: 'capture',
            nextStepIdentifier: 'endStep',
          ),
        );

      // A step that is NOT on the path; its result is seeded (as if from a prior run).
      final orphanStep = InstructionStep(
        id: 'orphan',
        title: 'Orphan',
        text: '',
        buttonText: 'x',
      );
      List<StepResult>? captured;
      final registries = SurveyRegistries(
        actionHandlers: {'capture': (results, variables) => captured = results},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurveyKit(
              task: task,
              registries: registries,
              initialResults: {seed('orphan', orphanStep, 'stale-orphan')},
              onResult: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Next'),
      ); // leave s1 -> Action 'capture' fires -> endStep
      await tester.pumpAndSettle();

      expect(captured, isNotNull, reason: 'action handler should have run');
      final ids = captured!.map((r) => r.id).toSet();
      expect(
        ids.contains('orphan'),
        isFalse,
        reason:
            'seeded off-path result must not reach the action handler (PDF)',
      );
      expect(
        ids.contains('s1'),
        isTrue,
        reason: 'on-path answer should still reach the handler',
      );
    },
  );

  testWidgets('linear path keeps every answer (no over-pruning)', (
    WidgetTester tester,
  ) async {
    // Both steps are QuestionSteps so they both produce a StepResult.
    // InstructionStep is avoided because it has no answer and therefore no
    // StepResult is ever added to the results set (see _addResult null-guard).
    final l1 = QuestionStep(
      id: 'l1',
      title: 'One',
      answerFormat: SingleChoiceAnswerFormat(
        textChoices: [
          TextChoice(text: 'Alpha', value: 'alpha'),
          TextChoice(text: 'Beta', value: 'beta'),
        ],
      ),
      buttonText: 'Next',
    );
    final l2 = QuestionStep(
      id: 'l2',
      title: 'Two',
      answerFormat: SingleChoiceAnswerFormat(
        textChoices: [
          TextChoice(text: 'One', value: 'one'),
          TextChoice(text: 'Two', value: 'two'),
        ],
      ),
      buttonText: 'Submit',
    );
    final task = NavigableTask(id: 't2', steps: [l1, l2]);

    SurveyResult? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SurveyKit(task: task, onResult: (r) => captured = r),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alpha')); // select an answer on l1
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next')); // l1 -> l2
    await tester.pumpAndSettle();
    await tester.tap(find.text('One')); // select an answer on l2
    await tester.pumpAndSettle();
    // Same bounded-pump rationale: Submit transitions to SurveyResultState
    // which shows a CircularProgressIndicator (infinite animation).
    await tester.tap(find.text('Submit')); // l2 -> finish
    await tester.pump(const Duration(seconds: 1));

    expect(captured, isNotNull);
    final ids = captured!.results.map((r) => r.id).toSet();
    expect(
      ids.containsAll({'l1', 'l2'}),
      isTrue,
      reason: 'linear path: all answers retained',
    );
  });
}
