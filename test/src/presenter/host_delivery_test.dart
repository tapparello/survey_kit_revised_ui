// Criterion 17: onResult is resolved at call time, not captured at engine
// construction. Criterion 18: and it is still delivered across an unmount.
import 'dart:async';

import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

/// Swaps which callback is passed as `onResult`, between builds.
///
/// Two distinct function objects, selected in `build`. A single closure that
/// read `_useSecond` at call time would route to the second sink even if the
/// closure itself were stale, which would make this test vacuous. Passing the
/// tear-off directly also keeps `unnecessary_lambdas`
/// (`analysis_options.yaml:155`) quiet, which `flutter analyze --fatal-infos`
/// counts as an issue.
class SwapHost extends StatefulWidget {
  const SwapHost({
    super.key,
    required this.task,
    required this.first,
    required this.second,
  });

  final Task task;
  final void Function(SurveyResult) first;
  final void Function(SurveyResult) second;

  @override
  State<SwapHost> createState() => SwapHostState();
}

class SwapHostState extends State<SwapHost> {
  bool _useSecond = false;

  void swap() => setState(() => _useSecond = true);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SurveyKit(
          task: widget.task,
          onResult: _useSecond ? widget.second : widget.first,
        ),
      ),
    );
  }
}

/// Mounts SurveyKit over a single-step task whose action handler is gated.
class TerminalHost extends StatelessWidget {
  const TerminalHost({
    super.key,
    required this.task,
    required this.registries,
    required this.onResult,
  });

  final Task task;
  final SurveyRegistries registries;
  final void Function(SurveyResult) onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SurveyKit(task: task, registries: registries, onResult: onResult),
      ),
    );
  }
}

void main() {
  testWidgets('17: the result goes to the current onResult, not a captured one', (
    tester,
  ) async {
    final toFirst = <SurveyResult>[];
    final toSecond = <SurveyResult>[];
    final key = GlobalKey<SwapHostState>();

    await tester.pumpWidget(
      SwapHost(
        key: key,
        task: NavigableTask(
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
        ),
        first: toFirst.add,
        second: toSecond.add,
      ),
    );
    await tester.pumpAndSettle();

    key.currentState!.swap();
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    // NOT pumpAndSettle: closing pops back to the pre-StartSurvey route, whose
    // arguments are null, so SurveyKit renders an adaptive spinner there whose
    // ticker never settles.
    await tester.pump(const Duration(seconds: 1));

    expect(toSecond, hasLength(1));
    expect(
      toFirst,
      isEmpty,
      reason: 'an onResult captured at construction would land here',
    );
  });

  testWidgets('18: a terminal advance across an unmount still delivers', (
    tester,
  ) async {
    // The gate for decision 4. It passes against a correct implementation and
    // fails against the `if (!mounted) return;` version an implementer reaches
    // for by reflex — which no other test in the suite can catch.
    final gate = Completer<void>();
    SurveyResult? received;

    await tester.pumpWidget(
      TerminalHost(
        // Single step: the action fires, the rule names no next step, so the
        // advance terminates and _handleSurveyFinished calls deliverResult.
        task: NavigableTask(
          id: 't',
          steps: [
            Step(
              id: 's1',
              content: const [TextContent(text: 'only')],
            ),
          ],
          navigationRules: const {'s1': ActionNavigationRule(actionId: 'slow')},
        ),
        registries: SurveyRegistries(
          actionHandlers: {
            'slow': (ctx) async {
              await gate.future;
            },
          },
        ),
        onResult: (result) => received = result,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(received, isNull, reason: 'still suspended in the handler');

    await tester.pumpWidget(const SizedBox());
    gate.complete();
    await tester.pumpAndSettle();

    expect(
      received,
      isNotNull,
      reason: 'a mounted guard in deliverResult would lose the whole survey',
    );
    expect(received!.finishReason, FinishReason.completed);
    expect(tester.takeException(), isNull);
  });
}
