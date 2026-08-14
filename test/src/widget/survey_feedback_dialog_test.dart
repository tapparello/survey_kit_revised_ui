// Criterion 12, widget half: the FeedbackTone -> Color? mapping.
//
// `neutral` MUST map to null, not to Colors.transparent. The dialog derives its
// text colour from `backgroundColor != null`, so transparent would render white
// text on the ambient surface — invisible, and undetectable by every other test
// in the suite.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/src/engine/survey_feedback.dart';
import 'package:survey_kit/src/widget/survey_feedback_dialog.dart';

void main() {
  Future<GlobalKey<NavigatorState>> pumpHost(WidgetTester tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          key: key,
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: SizedBox.shrink()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return key;
  }

  // autoDismiss: false throughout, including for `correct`, which production
  // pairs with autoDismiss: true. This test is about the colour mapping only,
  // and the tappable button is what makes the text colour observable.
  Future<void> show(
    WidgetTester tester,
    GlobalKey<NavigatorState> key,
    FeedbackTone tone,
  ) async {
    unawaited(
      showSurveyFeedbackDialog(
        navigatorKey: key,
        feedback: SurveyFeedback(
          message: 'hello',
          tone: tone,
          autoDismiss: false,
        ),
        localizations: null,
      ),
    );
    await tester.pumpAndSettle();
  }

  Color? backgroundOf(WidgetTester tester) =>
      tester.widget<Dialog>(find.byType(Dialog)).backgroundColor;

  Color? buttonTextColorOf(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(
          of: find.byType(TextButton),
          matching: find.byType(Text),
        ),
      )
      .style
      ?.color;

  testWidgets('correct renders a green dialog', (tester) async {
    final key = await pumpHost(tester);
    await show(tester, key, FeedbackTone.correct);

    expect(backgroundOf(tester), Colors.green);
    expect(buttonTextColorOf(tester), Colors.white);
  });

  testWidgets('incorrect renders a red dialog', (tester) async {
    final key = await pumpHost(tester);
    await show(tester, key, FeedbackTone.incorrect);

    expect(backgroundOf(tester), Colors.red);
    expect(buttonTextColorOf(tester), Colors.white);
  });

  testWidgets('neutral renders no background and readable text', (
    tester,
  ) async {
    final key = await pumpHost(tester);
    await show(tester, key, FeedbackTone.neutral);

    expect(
      backgroundOf(tester),
      isNull,
      reason: 'Colors.transparent would give white text on the ambient surface',
    );
    expect(
      buttonTextColorOf(tester),
      Colors.blueAccent,
      reason: 'the uncoloured case reads its text colour off a null background',
    );
  });

  testWidgets('the returned future completes when the button is tapped', (
    tester,
  ) async {
    final key = await pumpHost(tester);
    var completed = false;
    unawaited(
      showSurveyFeedbackDialog(
        navigatorKey: key,
        feedback: const SurveyFeedback(
          message: 'hello',
          tone: FeedbackTone.neutral,
          autoDismiss: false,
        ),
        localizations: null,
      ).then((_) => completed = true),
    );
    await tester.pumpAndSettle();
    expect(completed, isFalse);

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
  });
}
