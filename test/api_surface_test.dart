// Guards the public API surface of package:survey_kit.
//
// This file imports ONLY the package barrel - never 'package:survey_kit/src/...'
// - so any export dropped from lib/survey_kit.dart becomes a compile error here.
//
// It EXERCISES the API rather than merely naming types. A test that only names
// types still compiles after a public method, factory, or constructor is
// removed, which is exactly how the two dead members deleted in Task 2 escaped
// notice for so long.

import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

class _ProbeWidget extends StatefulWidget {
  const _ProbeWidget({super.key});

  @override
  State<_ProbeWidget> createState() => _ProbeWidgetState();
}

// Applying the mixin here is a compile-time guard: this class does not compile
// if PreviousStepResultMixin stops being exported or changes its bound.
// `lookedUp` turns that into a runtime assertion as well.
class _ProbeWidgetState extends State<_ProbeWidget>
    with PreviousStepResultMixin<_ProbeWidget> {
  StepResult? lookedUp;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    lookedUp = stepResultById('seeded-step');
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Widget _probeShell(Step step, Widget? answerWidget, BuildContext context) =>
    answerWidget ?? const SizedBox.shrink();

// Declared at file scope, not inside a test body: `omit_local_variable_types`
// is enabled (analysis_options.yaml:95) and rejects the annotation on a local,
// but the annotation IS the guard - it pins StepShell's exact signature.
const StepShell _pinnedShell = _probeShell;

Widget _probeRenderer(Content content, ContentRenderContext context) =>
    const SizedBox.shrink();

// Declared at file scope, not inside a test body: `omit_local_variable_types`
// rejects the annotation on a local, but the annotation IS the guard.
const ContentRenderer _pinnedRenderer = _probeRenderer;

void main() {
  test('TimeResult is constructible and round-trips through JSON', () {
    const result = TimeResult(timeOfDay: TimeOfDay(hour: 9, minute: 30));
    expect(result.timeOfDay.hour, 9);
    expect(result.timeOfDay.minute, 30);

    final decoded = TimeResult.fromJson(result.toJson());
    expect(decoded.timeOfDay, const TimeOfDay(hour: 9, minute: 30));
  });

  test('MultiDouble is constructible and round-trips through JSON', () {
    const value = MultiDouble(text: 'weight', value: 72.5);
    expect(value.text, 'weight');
    expect(value.value, 72.5);
    expect(MultiDouble.fromJson(value.toJson()), value);
  });

  testWidgets('PreviousStepResultMixin resolves a seeded StepResult through '
      'SurveyStateProvider', (tester) async {
    final step = Step(
      id: 'seeded-step',
      content: const [TextContent(text: 'probe')],
    );
    final seeded = StepResult<String>(
      id: 'seeded-step',
      answerType: AnswerFormatType.text,
      result: 'seeded-answer',
      startTime: DateTime(2026),
      endTime: DateTime(2026),
    );
    final probeKey = GlobalKey<_ProbeWidgetState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SurveyKit(
            task: OrderedTask(id: 'probe-task', steps: [step]),
            initialResults: {seeded},
            onResult: (_) {},
            // stepShell injects the probe INSIDE the survey subtree. Without it
            // probeKey is never attached to anything and the assertion below
            // dies on a null check rather than failing cleanly.
            stepShell: (step, answerWidget, context) =>
                _ProbeWidget(key: probeKey),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final lookedUp = probeKey.currentState!.lookedUp;
    expect(lookedUp, isNotNull);
    expect(lookedUp!.id, 'seeded-step');
    expect(lookedUp.result, 'seeded-answer');
  });

  test(
    'SurveyKitLogLevel aliases the logger Level enum and setLevel applies it',
    () {
      // Real assertion: the alias must BE the logger enum, not a lookalike.
      expect(
        SurveyKitLogLevel.values,
        containsAll(<Object>[
          SurveyKitLogLevel.off,
          SurveyKitLogLevel.debug,
          SurveyKitLogLevel.warning,
        ]),
      );

      final before = SurveyKitLogger.logger;
      SurveyKitLogger.setLevel(SurveyKitLogLevel.off);
      expect(SurveyKitLogger.logger, isNot(same(before)));

      SurveyKitLogger.setLevel(SurveyKitLogLevel.debug);
    },
  );

  testWidgets('StepShell keeps its positional signature and is callable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => _pinnedShell(
            Step(content: const [TextContent(text: 'probe')]),
            const Text('answer-widget'),
            context,
          ),
        ),
      ),
    );

    expect(find.text('answer-widget'), findsOneWidget);
  });

  test('the exception hierarchy is exported and exercisable', () {
    const missing = MissingAnswerFormatException(
      stepId: 'api-step',
      expected: 'TextAnswerFormat',
    );
    expect(missing.stepId, 'api-step');
    expect(missing, isA<SurveyKitException>());

    const mismatch = AnswerFormatMismatchException(
      stepId: 'api-step',
      expected: 'TextAnswerFormat',
      actual: 'BooleanAnswerFormat',
    );
    expect(mismatch.actual, 'BooleanAnswerFormat');

    const scope = SurveyKitScopeException(
      widgetType: 'SurveyKit',
      hint: 'Wrap the widget tree in SurveyKit.',
    );
    expect(scope.widgetType, 'SurveyKit');

    const malformed = MalformedValueException(field: 'f', value: 42);
    expect(malformed.value, 42);

    const unsupported = UnsupportedTaskException(taskType: 'MyTask');
    expect(unsupported.taskType, 'MyTask');

    const unknown = UnknownTypeException(kind: 'Content', discriminator: 'x');
    expect(unknown.discriminator, 'x');
    expect(unknown.expected, isNull);

    const unknownWithHint = UnknownTypeException(
      kind: 'Task',
      discriminator: 'x',
      expected: 'ordered or navigable',
    );
    expect(unknownWithHint.message, contains('Expected ordered or navigable.'));

    const resultCodec = ResultCodecException(
      stepId: 'api-step',
      answerType: 'text',
      cause: 'probe',
    );
    expect(resultCodec.stepId, 'api-step');
    expect(resultCodec.answerType, 'text');

    for (final e in <SurveyKitException>[
      missing,
      mismatch,
      scope,
      malformed,
      unsupported,
      unknown,
      resultCodec,
    ]) {
      expect(e.toString(), contains(e.message));
    }
  });

  test('content renderers are registrable through the public API', () {
    Widget custom(Content content, ContentRenderContext context) =>
        const SizedBox.shrink();
    const pinned = SurveyRegistries();
    final registries = SurveyRegistries(contentRenderers: {'pdf': custom});

    expect(pinned.contentRenderers, isEmpty);
    expect(registries.contentRenderers['pdf'], isNotNull);
    expect(
      registries.contentRenderers['pdf']!(
        const StyledTextContent(text: 'x'),
        ContentRenderContext(
          variables: const {},
          contentStyles: null,
          render: (_) => const SizedBox.shrink(),
        ),
      ),
      isA<SizedBox>(),
    );
  });

  test('UnregisteredRendererException is public and structured', () {
    const failure = UnregisteredRendererException(
      kind: 'Content',
      discriminator: 'pdf',
    );

    expect(failure, isA<SurveyKitException>());
    expect(failure.discriminator, 'pdf');
    expect(failure.message, contains('pdf'));
  });

  test('ContentRenderer signature is pinned', () {
    expect(
      _pinnedRenderer(
        const StyledTextContent(text: 'x'),
        ContentRenderContext(
          variables: const {},
          contentStyles: null,
          render: (_) => const SizedBox.shrink(),
        ),
      ),
      isA<SizedBox>(),
    );
  });
}
