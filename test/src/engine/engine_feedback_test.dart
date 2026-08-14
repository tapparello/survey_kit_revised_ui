// Criterion 11: feedback resolves BEFORE the action handler starts (ADO #1040's
// behaviour change 5, which had no live consumer case).
// Criterion 12, engine half: the three FeedbackTone values.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/engine/survey_feedback.dart';
import 'package:survey_kit/survey_kit.dart';

import 'engine_harness.dart';

void main() {
  StepResult<TextChoice> choiceResult(String id, String value) =>
      StepResult<TextChoice>(
        id: id,
        result: TextChoice(text: value, value: value),
        answerType: AnswerFormatType.singleWithFeedback,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      );

  NavigableTask feedbackTask(AnswerFormat format, {bool withAction = false}) =>
      NavigableTask(
        id: 't',
        steps: [
          Step(
            id: 's1',
            content: const [TextContent(text: 'first')],
            answerFormat: format,
          ),
          Step(
            id: 's2',
            content: const [TextContent(text: 'second')],
          ),
        ],
        navigationRules: withAction
            ? const {
                's1': ActionNavigationRule(
                  actionId: 'act',
                  nextStepIdentifier: 's2',
                ),
              }
            : const {},
      );

  test(
    'the action handler does not start until feedback is acknowledged',
    () async {
      final fired = <int>[];
      final host = FakeSurveyHost()..feedbackGate = Completer<void>();
      final engine = makeEngine(
        task: feedbackTask(
          const SingleChoiceAnswerWithFeedbackFormat(textChoices: []),
          withAction: true,
        ),
        host: host,
        registries: SurveyRegistries(
          // A block body, not `async =>`: an expression-bodied async handler
          // returning a non-void value compiles but reads as if it awaits
          // something, and every existing handler fixture in the suite uses a
          // block.
          actionHandlers: {
            'act': (ctx) async {
              fired.add(fired.length);
            },
          },
        ),
      );

      await engine.handleEvent(StartSurvey());
      final advance = engine.handleEvent(
        NextStep(choiceResult('s1', 'correct')),
      );
      await drain();

      expect(host.calls, <String>['pushState', 'showFeedback']);
      expect(
        fired,
        isEmpty,
        reason: 'the handler must not run behind an open dialog',
      );

      host.feedbackGate!.complete();
      await advance;

      expect(fired, hasLength(1));
      expect(host.calls, <String>['pushState', 'showFeedback', 'pushState']);

      engine.dispose();
    },
  );

  test(
    'a correct single choice asks for a green, auto-dismissing dialog',
    () async {
      final host = FakeSurveyHost();
      final engine = makeEngine(
        task: feedbackTask(
          const SingleChoiceAnswerWithFeedbackFormat(textChoices: []),
        ),
        host: host,
      );

      await engine.handleEvent(StartSurvey());
      await engine.handleEvent(NextStep(choiceResult('s1', 'correct')));

      expect(host.shownFeedback, hasLength(1));
      expect(host.shownFeedback.single.tone, FeedbackTone.correct);
      expect(host.shownFeedback.single.autoDismiss, isTrue);

      engine.dispose();
    },
  );

  test('a wrong single choice asks for a red, tappable dialog', () async {
    final host = FakeSurveyHost();
    final engine = makeEngine(
      task: feedbackTask(
        const SingleChoiceAnswerWithFeedbackFormat(textChoices: []),
      ),
      host: host,
    );

    await engine.handleEvent(StartSurvey());
    await engine.handleEvent(NextStep(choiceResult('s1', 'wrong')));

    expect(host.shownFeedback.single.tone, FeedbackTone.incorrect);
    expect(host.shownFeedback.single.autoDismiss, isFalse);

    engine.dispose();
  });

  test('an uncoloured multiple choice asks for a neutral dialog', () async {
    final host = FakeSurveyHost();
    final engine = makeEngine(
      task: feedbackTask(
        const MultipleChoiceAnswerWithFeedbackFormat(
          textChoices: [],
          coloredFeedback: false,
        ),
      ),
      host: host,
    );

    await engine.handleEvent(StartSurvey());
    await engine.handleEvent(
      NextStep(
        StepResult<List<TextChoice>>(
          id: 's1',
          result: const [],
          // `multiWithFeedback`, not `multipleWithFeedback` — the enum member
          // is named for its wire string 'multi_with_feedback'.
          answerType: AnswerFormatType.multiWithFeedback,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        ),
      ),
    );

    expect(host.shownFeedback.single.tone, FeedbackTone.neutral);
    expect(host.shownFeedback.single.autoDismiss, isFalse);

    engine.dispose();
  });
}
