import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

Future<Object?> _pumpAndCatch(
  WidgetTester tester,
  Object? Function(BuildContext context) lookup,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          lookup(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return tester.takeException();
}

void main() {
  testWidgets('SurveyConfiguration.of throws without an ancestor', (
    tester,
  ) async {
    final thrown = await _pumpAndCatch(tester, SurveyConfiguration.of);
    expect(
      thrown,
      isA<SurveyKitScopeException>().having(
        (e) => e.widgetType,
        'widgetType',
        'SurveyConfiguration',
      ),
    );
  });

  testWidgets('SurveyStateProvider.of throws without an ancestor', (
    tester,
  ) async {
    final thrown = await _pumpAndCatch(tester, SurveyStateProvider.of);
    expect(
      thrown,
      isA<SurveyKitScopeException>().having(
        (e) => e.widgetType,
        'widgetType',
        'SurveyStateProvider',
      ),
    );
    // Regression guard: the old message named a class that no longer exists.
    expect(
      (thrown! as SurveyKitScopeException).message,
      isNot(contains('SurveyPresenterInherited')),
    );
  });

  testWidgets('QuestionAnswer.of throws without an ancestor', (tester) async {
    final thrown = await _pumpAndCatch(tester, QuestionAnswer.of);
    expect(
      thrown,
      isA<SurveyKitScopeException>().having(
        (e) => e.widgetType,
        'widgetType',
        'QuestionAnswer',
      ),
    );
    // QuestionAnswer is built by AnswerView inside a single step's content, so
    // "wrap the tree in SurveyKit" would be false advice here.
    expect(
      (thrown! as SurveyKitScopeException).hint,
      isNot(contains('Wrap the widget tree in SurveyKit')),
    );
  });
}
