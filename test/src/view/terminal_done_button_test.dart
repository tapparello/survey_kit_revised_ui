// ADO #968: a navigation-terminal step shows the localized "Done" unless it has
// a deliberate completion label; no-buttonText forward buttons localize.
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

void main() {
  // q1 (no buttonText) -> terminal (rule -> end_task, i.e. terminal BY RULE).
  NavigableTask buildTask({String? terminalButtonText}) {
    final q1 = QuestionStep(
      id: 'q1',
      title: 'Q1',
      answerFormat: SingleChoiceAnswerFormat(
        textChoices: [TextChoice(text: 'Yes', value: 'yes')],
      ),
      // no buttonText -> null
    );
    final terminal = QuestionStep(
      id: 'terminal',
      title: 'Terminal',
      answerFormat: SingleChoiceAnswerFormat(
        textChoices: [TextChoice(text: 'OK', value: 'ok')],
      ),
      buttonText: terminalButtonText,
    );
    return NavigableTask(id: 't', steps: [q1, terminal])
      ..addNavigationRule(
        forTriggerStepIdentifier: 'terminal',
        navigationRule: ConditionalNavigationRule(
          resultToStepIdentifierMapper: (_, __) => 'end_task',
        ),
      );
  }

  Future<void> pumpToTerminal(
    WidgetTester tester, {
    String? terminalButtonText,
    Map<String, String> localizations = const {'next': 'Next', 'done': 'Done'},
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SurveyKit(
            task: buildTask(terminalButtonText: terminalButtonText),
            localizations: localizations,
            onResult: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('no-buttonText terminal step shows localized Done', (tester) async {
    await pumpToTerminal(tester);
    // q1 is non-terminal -> forward button localized "Next".
    expect(find.text('Next'), findsOneWidget);
    await tester.tap(find.text('Next')); // advance q1 -> terminal
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
  });

  testWidgets("literal 'Next' (resolved @next) terminal shows Done", (tester) async {
    await pumpToTerminal(tester, terminalButtonText: 'Next');
    await tester.tap(find.text('Next')); // q1's own Next
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('deliberate completion label is honored', (tester) async {
    await pumpToTerminal(tester, terminalButtonText: 'Submit survey');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Submit survey'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('Done/Next localize (es): chrome terminal -> Listo, non-terminal -> Siguiente',
      (tester) async {
    await pumpToTerminal(tester, localizations: {'next': 'Siguiente', 'done': 'Listo'});
    expect(find.text('Siguiente'), findsOneWidget); // q1 non-terminal
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Listo'), findsOneWidget); // terminal localized Done
  });
}
