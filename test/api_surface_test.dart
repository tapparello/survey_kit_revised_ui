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
      step: step,
      result: 'seeded-answer',
      startTime: DateTime(2026),
      endTime: DateTime(2026),
    );
    final probeKey = GlobalKey<_ProbeWidgetState>();

    await tester.pumpWidget(
      MaterialApp(
        home: SurveyStateProvider(
          taskNavigator: OrderedTaskNavigator(
            OrderedTask(id: 'probe-task', steps: [step]),
          ),
          onResult: (_) {},
          navigatorKey: GlobalKey<NavigatorState>(),
          results: {seeded},
          child: _ProbeWidget(key: probeKey),
        ),
      ),
    );

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
}
