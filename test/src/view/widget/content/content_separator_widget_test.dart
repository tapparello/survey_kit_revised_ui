// Guards ADO #972: ContentWidget inserts a 14px separator after each content
// only when its `separatorAfter` is true (default), so authors can suppress the
// gap between two blocks.
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart'; // exports ContentSeparator (do NOT also import content_widget.dart — redundant, trips analyze)

Widget _app(List<Content> content) => MaterialApp(
  home: Scaffold(
    body: SurveyKit(
      task: OrderedTask(
        id: 't',
        steps: [
          Step(id: 's', content: content, buttonText: 'Next'),
          CompletionStep(title: 'Done', text: 'x', buttonText: 'Submit'),
        ],
      ),
      onResult: (_) {},
    ),
  ),
);

void main() {
  testWidgets('default: separator after every content (incl. trailing)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app([
        const HtmlContent(html: '<p>A</p>'),
        const HtmlContent(html: '<p>B</p>'),
      ]),
    );
    await tester.pumpAndSettle();
    // [A, sep, B, sep] -> 2 separators
    expect(find.byType(ContentSeparator), findsNWidgets(2));
  });

  testWidgets('separatorAfter:false on first suppresses the gap after it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app([
        const HtmlContent(html: '<p>A</p>', separatorAfter: false),
        const HtmlContent(html: '<p>B</p>'),
      ]),
    );
    await tester.pumpAndSettle();
    // [A, B, sep] -> only the trailing separator remains
    expect(find.byType(ContentSeparator), findsOneWidget);
  });

  testWidgets('flag on content before a conditional suppresses that gap', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app([
        const HtmlContent(html: '<p>A</p>', separatorAfter: false),
        const ConditionalContent(
          variable: 'x',
          options: {'k': HtmlContent(html: '<p>B</p>')},
          defaultOption: 'k', // resolves against empty variables
        ),
      ]),
    );
    await tester.pumpAndSettle();
    // resolved -> [A(false), B]; loop -> [A, B, sep] -> 1 separator
    expect(find.byType(ContentSeparator), findsOneWidget);
  });

  testWidgets('conditional content actually resolves and renders', (
    tester,
  ) async {
    // This test guards against resolution regressions: if resolution stops
    // happening anywhere in the pipeline (ContentWidget, SurveyEngine, etc.),
    // the resolved text "resolved_branch" will not appear, and the test fails.
    // The unresolved ConditionalContent.createWidget() returns SizedBox.shrink(),
    // so the absence of the resolved text is discriminating.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SurveyKit(
            task: OrderedTask(
              id: 't',
              steps: [
                Step(
                  id: 's',
                  content: const [
                    ConditionalContent(
                      variable: 'branch',
                      options: {'alpha': TextContent(text: 'resolved_branch')},
                      defaultOption: 'alpha',
                    ),
                  ],
                  buttonText: 'Next',
                ),
                CompletionStep(title: 'Done', text: 'x', buttonText: 'Submit'),
              ],
            ),
            onResult: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // If resolution happened, the resolved TextContent renders and its text
    // appears. If resolution stopped, SizedBox.shrink() renders nothing and
    // this assertion fails — making the test discriminating.
    expect(find.text('resolved_branch'), findsOneWidget);
  });
}
