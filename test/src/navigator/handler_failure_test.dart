import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:survey_kit/survey_kit.dart';

import 'action_task_harness.dart';

/// Before ADO #1040 an async handler's throw reached the top-level zone and
/// NOTHING was logged — the try/catch in _evaluateActionRule could only catch
/// what was thrown before the handler's first await, which is nothing a PDF
/// generator does. Navigation is unchanged by a failure: the destination is
/// rule.nextStepIdentifier regardless, and halting would strand the user on a
/// step whose Next keeps failing with no retry affordance.
void main() {
  test(
    'a handler that throws after an await reports, and still advances',
    () async {
      final failures = <SurveyHandlerFailure>[];
      final navigator = NavigableTaskNavigator(
        actionTask(),
        registries: SurveyRegistries(
          actionHandlers: {
            'side_effect': (ctx) async {
              await Future<void>.delayed(const Duration(milliseconds: 5));
              throw StateError('boom');
            },
          },
        ),
        onHandlerError: failures.add,
      );

      final next = await navigator.nextStep(
        step: navigator.task.steps.first,
        previousResults: const [],
      );

      expect(next?.id, 's2', reason: 'a failed action still advances');
      expect(failures, hasLength(1));
      expect(failures.single.kind, SurveyHandlerKind.action);
      expect(failures.single.handlerId, 'side_effect');
      expect(failures.single.trigger, ActionTrigger.advance);
      expect(failures.single.error, isA<StateError>());
      expect(failures.single.stackTrace, isNotNull);
    },
  );

  test(
    'an unregistered action id reports UnregisteredActionException and advances',
    () async {
      final failures = <SurveyHandlerFailure>[];
      final navigator = NavigableTaskNavigator(
        actionTask(),
        registries: const SurveyRegistries(),
        onHandlerError: failures.add,
      );

      final next = await navigator.nextStep(
        step: navigator.task.steps.first,
        previousResults: const [],
      );

      expect(next?.id, 's2');
      expect(failures.single.trigger, ActionTrigger.advance);
      expect(failures.single.error, isA<UnregisteredActionException>());
      expect(
        (failures.single.error as UnregisteredActionException).actionId,
        'side_effect',
      );
    },
  );

  test(
    'a CustomNavigationRule handler that throws reports and falls back to nextInList',
    () {
      final failures = <SurveyHandlerFailure>[];
      final fixture = ruleTask();
      final navigator = NavigableTaskNavigator(
        fixture.task,
        registries: SurveyRegistries(
          customNavigationRules: {
            'route': (results, currentResult, variables) =>
                throw StateError('rule boom'),
          },
        ),
        onHandlerError: failures.add,
      );

      final next = navigator.peekNextStep(
        step: fixture.task.steps.first,
        previousResults: const [],
      );

      expect(next?.id, 's2', reason: 'nextInList after s1');
      expect(failures.single.kind, SurveyHandlerKind.navigationRule);
      expect(failures.single.handlerId, 'route');
      expect(failures.single.trigger, isNull, reason: 'rules have no trigger');
    },
  );

  // Spec criterion 2 — with onHandlerError unset, the failure must still reach
  // SurveyKitLogger at ERROR level, not the debug level it used today (where it
  // never fired at all, because nothing was caught). `Logger.addLogListener` is
  // a static on package:logger that fires for every Logger instance, including
  // SurveyKitLogger's private one, so this needs no seam in the library.
  group('with no onHandlerError', () {
    late List<LogEvent> logged;
    late LogCallback listener;

    setUp(() {
      logged = <LogEvent>[];
      listener = logged.add;
      // api_surface_test.dart also mutates the global level, so set it here
      // rather than relying on the debug-mode default, and restore it after.
      SurveyKitLogger.setLevel(SurveyKitLogLevel.debug);
      Logger.addLogListener(listener);
    });

    tearDown(() {
      Logger.removeLogListener(listener);
      SurveyKitLogger.setLevel(SurveyKitLogLevel.debug);
    });

    test(
      'the failure is logged at error level, and the survey advances',
      () async {
        final navigator = NavigableTaskNavigator(
          actionTask(),
          registries: SurveyRegistries(
            actionHandlers: {
              'side_effect': (ctx) async {
                await Future<void>.delayed(const Duration(milliseconds: 5));
                throw StateError('boom');
              },
            },
          ),
        );

        final next = await navigator.nextStep(
          step: navigator.task.steps.first,
          previousResults: const [],
        );

        expect(next?.id, 's2');
        expect(
          logged.where(
            (e) => e.level == SurveyKitLogLevel.error && e.error is StateError,
          ),
          hasLength(1),
        );
      },
    );
  });
}
