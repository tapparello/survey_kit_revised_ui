// Criterion 16: the app-bar Cancel button, in all four windows.
// Criterion 19: and under a tree that rebuilds constantly.
import 'dart:async';

import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

/// A host with its own rebuild hook and its own progress configuration.
///
/// Deliberately not `action_harness.dart`: that file is pre-existing and this
/// phase's budget for editing pre-existing test files is spent elsewhere.
class CancelHost extends StatefulWidget {
  const CancelHost({
    super.key,
    required this.task,
    this.registries,
    this.showCloseButton = true,
  });

  final Task task;
  final SurveyRegistries? registries;
  final bool showCloseButton;

  @override
  State<CancelHost> createState() => CancelHostState();
}

class CancelHostState extends State<CancelHost> {
  int _tick = 0;

  // Held, not built in build(): SurveyProgressConfiguration declares no
  // operator==, so a fresh instance per build would make
  // SurveyConfiguration.updateShouldNotify true every time and rebuild the app
  // bar for a reason unrelated to what criterion 19 is measuring.
  late final SurveyProgressConfiguration _progress =
      SurveyProgressConfiguration(showCloseButton: widget.showCloseButton);

  void rebuild() => setState(() => _tick++);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SurveyKit(
          task: widget.task,
          registries: widget.registries,
          surveyProgressbarConfiguration: _progress,
          onResult: (result) {},
        ),
      ),
    );
  }
}

final cancel = find.widgetWithText(TextButton, 'Cancel');

NavigableTask twoStepTask() => NavigableTask(
  id: 't',
  steps: [
    Step(
      id: 's1',
      content: const [TextContent(text: 'first')],
    ),
    Step(
      id: 's2',
      content: const [TextContent(text: 'second')],
    ),
  ],
);

void main() {
  testWidgets('16a: absent while the survey is still starting up', (
    tester,
  ) async {
    // Gated on a genuinely slow StartSurvey — an action handler on the replayed
    // path held open by a Completer — not on frame timing. This clause fails
    // against 56473c4, where mid-replay measures Cancel=1, spinner=1.
    final gate = Completer<void>();
    final task = NavigableTask(
      id: 't',
      steps: [
        Step(
          id: 's1',
          content: const [TextContent(text: 'first')],
        ),
        Step(
          id: 's2',
          content: const [TextContent(text: 'second')],
        ),
      ],
      navigationRules: const {
        's1': ActionNavigationRule(actionId: 'slow', nextStepIdentifier: 's2'),
      },
      initialStepId: 's2',
    );

    await tester.pumpWidget(
      CancelHost(
        task: task,
        registries: SurveyRegistries(
          actionHandlers: {
            'slow': (ctx) async {
              await gate.future;
            },
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byType(CircularProgressIndicator),
      findsOneWidget,
      reason: 'the fixture must actually be inside the startup window',
    );
    expect(cancel, findsNothing, reason: 'the button is inert here');

    gate.complete();
    await tester.pumpAndSettle();
    expect(cancel, findsOneWidget, reason: 'and live again once s2 renders');
  });

  testWidgets('16b: present once the first step renders', (tester) async {
    await tester.pumpWidget(CancelHost(task: twoStepTask()));
    await tester.pumpAndSettle();

    expect(find.text('first'), findsOneWidget);
    expect(cancel, findsOneWidget);
  });

  testWidgets('16c: still present after the survey terminates', (tester) async {
    // The clause that discriminates this predicate from `is
    // PresentingSurveyState`. Without it both implementations pass, and the
    // rejected one silently closes a second window this phase does not own.
    await tester.pumpWidget(
      CancelHost(
        task: NavigableTask(
          id: 't',
          steps: [
            Step(
              id: 's1',
              content: const [TextContent(text: 'only')],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    // NOT pumpAndSettle: the terminal route renders
    // CircularProgressIndicator.adaptive(), whose ticker never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      cancel,
      findsOneWidget,
      reason: 'the post-terminal window is a separate decision, not this one',
    );
  });

  testWidgets('16d: absent throughout with showCloseButton: false', (
    tester,
  ) async {
    // The consumer's actual path — fmf_connect_flutter sets this in both of its
    // progress configurations — pinned as unaffected.
    await tester.pumpWidget(
      CancelHost(task: twoStepTask(), showCloseButton: false),
    );
    await tester.pump();
    expect(cancel, findsNothing);

    await tester.pumpAndSettle();
    expect(cancel, findsNothing);
  });

  testWidgets('19: the gated Cancel survives repeated parent rebuilds', (
    tester,
  ) async {
    // The new rebuild surface is the third StreamBuilder in the app bar.
    // StreamController.broadcast().stream returns a fresh object per access,
    // but _ControllerStream overrides == by controller identity, so
    // StreamBuilder.didUpdateWidget does not resubscribe. That soundness rests
    // on a Flutter-internal == override, and the tree keeps notifying in
    // production, so it is worth six lines to pin.
    final key = GlobalKey<CancelHostState>();
    await tester.pumpWidget(CancelHost(key: key, task: twoStepTask()));
    await tester.pumpAndSettle();
    expect(cancel, findsOneWidget);

    // Bounded, not "every frame": a host that rebuilds forever never settles.
    for (var i = 0; i < 5; i++) {
      key.currentState!.rebuild();
      await tester.pump();
      expect(cancel, findsOneWidget, reason: 'gone after rebuild $i');
    }
  });
}
