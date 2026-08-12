// ADO #1033 Defect 1: a parent rebuild used to replace the whole session,
// which froze the survey because every onEvent branch gates on
// PresentingSurveyState and StartSurvey only ever fires once.
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

import 'rebuild_harness.dart';

void main() {
  testWidgets('a parent rebuild preserves the whole session', (tester) async {
    final key = GlobalKey<RebuildHostState>();
    await tester.pumpWidget(
      RebuildHost(key: key, task: twoStepTask(), onResult: (_) {}),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Two'), findsOneWidget);

    final before = providerFrom(tester, find.text('Two'));
    final resultsBefore = before.results.map((r) => r.id).toSet();
    final streamBefore = before.surveyStateStream;
    final startBefore = before.startDate;

    key.currentState!.rebuild();
    await tester.pump();

    final after = providerFrom(tester, find.text('Two'));
    expect(after.results.map((r) => r.id).toSet(), resultsBefore,
        reason: 'results must survive');
    expect(after.state, isA<PresentingSurveyState>(),
        reason: 'state must not reset to Loading');
    expect(after.startDate, startBefore, reason: 'startDate must not reset');
    expect(identical(after.surveyStateStream, streamBefore), isTrue,
        reason: 'the controller must not be replaced');
  });

  testWidgets('after a parent rebuild, Next still advances', (tester) async {
    final key = GlobalKey<RebuildHostState>();
    await tester.pumpWidget(
      RebuildHost(key: key, task: twoStepTask(), onResult: (_) {}),
    );
    await tester.pumpAndSettle();

    key.currentState!.rebuild();
    await tester.pump();

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget,
        reason: 'the survey froze: onEvent gates on PresentingSurveyState');
  });

  testWidgets('after a parent rebuild, Cancel still fires onResult',
      (tester) async {
    SurveyResult? captured;
    final key = GlobalKey<RebuildHostState>();
    await tester.pumpWidget(
      RebuildHost(key: key, task: twoStepTask(), onResult: (r) => captured = r),
    );
    await tester.pumpAndSettle();

    key.currentState!.rebuild();
    await tester.pump();

    // 'Cancel' matches TWO widgets on a non-terminal step: the app bar's
    // TextButton and StepView's save-and-close OutlinedButton. Disambiguate.
    await tester.tap(find.widgetWithText(TextButton, 'Cancel').first);
    await tester.pump(const Duration(seconds: 1));

    expect(captured, isNotNull,
        reason: 'onResult never fired, so the consumer can never pop');
  });

  testWidgets('disposing SurveyKit closes the stream', (tester) async {
    await tester.pumpWidget(
      RebuildHost(task: twoStepTask(), onResult: (_) {}),
    );
    await tester.pumpAndSettle();

    // Capture before unmounting: of(context) cannot reach it afterwards.
    final stream = providerFrom(tester, find.text('One')).surveyStateStream;
    expect(stream.isClosed, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(stream.isClosed, isTrue, reason: 'the controller leaked');
  });

  testWidgets('an unmodifiable initialResults no longer crashes', (tester) async {
    await tester.pumpWidget(
      RebuildHost(
        task: twoStepTask(),
        onResult: (_) {},
        initialResults: Set<StepResult>.unmodifiable(const <StepResult>{}),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget);
  });
}
