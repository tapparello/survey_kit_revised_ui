import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:survey_kit/src/configuration/survey_configuration.dart';
import 'package:survey_kit/src/configuration/survey_handler_failure.dart';
import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/controller/survey_controller.dart';
import 'package:survey_kit/src/engine/survey_engine.dart';
import 'package:survey_kit/src/engine/survey_feedback.dart';
import 'package:survey_kit/src/engine/survey_host.dart';
import 'package:survey_kit/src/exception/survey_kit_exception.dart';
import 'package:survey_kit/src/model/content/styled_text_content.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/result/survey_result.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/navigator/navigable_task_navigator.dart';
import 'package:survey_kit/src/navigator/ordered_task_navigator.dart';
import 'package:survey_kit/src/navigator/task_navigator.dart';
import 'package:survey_kit/src/presenter/survey_event.dart';
import 'package:survey_kit/src/presenter/survey_state.dart';
import 'package:survey_kit/src/presenter/survey_state_provider.dart';
import 'package:survey_kit/src/task/navigable_task.dart';
import 'package:survey_kit/src/task/ordered_task.dart';
import 'package:survey_kit/src/task/task.dart';
import 'package:survey_kit/src/view/widget/answer/answer_view.dart';
import 'package:survey_kit/src/widget/survey_app_bar.dart';
import 'package:survey_kit/src/widget/survey_feedback_dialog.dart';
import 'package:survey_kit/src/widget/survey_kit_page_route_builder.dart';
import 'package:survey_kit/src/widget/survey_progress_configuration.dart';

typedef StepShell =
    Widget Function(Step step, Widget? answerWidget, BuildContext context);

class SurveyKit extends StatefulWidget {
  /// [Task] for the configuraton of the survey
  final Task task;

  /// Function which is called after the results are collected
  final Function(SurveyResult) onResult;

  /// [SurveyController] to override the navigation methods
  /// onNextStep, onBackStep, onCloseSurvey
  final SurveyController? surveyController;

  /// The appbar that is shown at the top
  final PreferredSizeWidget? appBar;

  // Changes the styling of the progressbar in the appbar
  final SurveyProgressConfiguration? surveyProgressbarConfiguration;

  /// Localizations for the survey
  final Map<String, String>? localizations;

  /// Step shell
  final StepShell? stepShell;

  /// Results to seed the survey with, e.g. when resuming a saved run.
  ///
  /// Read once, when the widget mounts. Passing a different set on a later
  /// build has no effect — changing it does not restart the survey. The same is
  /// true of [task], [registries] and [onHandlerError]. (ADO #1033)
  final Set<StepResult>? initialResults;

  /// Decoration which is applied to the survey container
  final BoxDecoration? decoration;

  /// Survey registries for custom content/step types and navigation handlers
  final SurveyRegistries? registries;

  /// Named content styles keyed by style name
  final Map<String, StyledTextContent>? contentStyles;

  /// Called when a registered handler fails while the survey is navigating —
  /// an action handler throwing, a rule naming an unregistered action id, or a
  /// custom navigation rule handler throwing.
  ///
  /// Reporting only: navigation proceeds either way. When null, failures are
  /// logged through `SurveyKitLogger` at error level.
  ///
  /// Read once, when the widget mounts, like [task] and [initialResults] —
  /// the navigator is built in `initState`. The same is true of [registries].
  final SurveyHandlerErrorCallback? onHandlerError;

  const SurveyKit({
    super.key,
    required this.task,
    required this.onResult,
    this.surveyController,
    this.surveyProgressbarConfiguration,
    this.appBar,
    this.localizations,
    this.stepShell,
    this.initialResults,
    this.decoration,
    this.registries,
    this.contentStyles,
    this.onHandlerError,
  });

  @override
  _SurveyKitState createState() => _SurveyKitState();
}

class _SurveyKitState extends State<SurveyKit> implements SurveyHost {
  late TaskNavigator _taskNavigator;
  late final GlobalKey<NavigatorState> _navigatorKey;
  late final SurveyEngine _engine;

  @override
  void initState() {
    super.initState();
    // Order is load-bearing: _createTaskNavigator can throw
    // UnsupportedTaskException, and when initState throws Flutter never calls
    // dispose(), so the `late final _engine` must not have been assigned.
    // Constructing the engine first breaks parse_throws_test.dart. (ADO #1033)
    _taskNavigator = _createTaskNavigator();
    _navigatorKey = GlobalKey<NavigatorState>();
    _engine = SurveyEngine(
      taskNavigator: _taskNavigator,
      host: this,
      initialResults: widget.initialResults,
    );
  }

  TaskNavigator _createTaskNavigator() {
    final task = widget.task;
    if (task is OrderedTask) {
      return OrderedTaskNavigator(widget.task);
    }
    if (task is NavigableTask) {
      return NavigableTaskNavigator(
        widget.task,
        registries: widget.registries,
        onHandlerError: widget.onHandlerError,
      );
    }

    throw UnsupportedTaskException(taskType: '${task.runtimeType}');
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  // SurveyHost. NONE of these may read `context` or `mounted`.
  //
  // Every one can be called from a suspension that outlives this State — an
  // action handler completing after SurveyKit unmounts is the ordinary case.
  // `if (!mounted) return;` in deliverResult would silently discard the user's
  // finished survey, and it would pass all 254 pre-existing tests. Measured on
  // 56473c4: a terminal advance across an unmount DOES fire onResult today.
  //
  // Reading `widget` post-dispose is safe: StatefulElement.unmount clears
  // _element and _state, never _widget. Reading `context` is NOT — it throws
  // after unmount, which is why these use _navigatorKey rather than
  // Navigator.of(context). The GlobalKey returns null once its Navigator
  // unmounts, which is the same null-guarded no-op the pre-3c code relied on.
  //
  // `unawaited`, not `await`: pushNamed's future does not resolve until the
  // pushed route is popped, so awaiting it would hang the advance and leave
  // isAdvancing set forever. These being `void` keeps that temptation out of
  // the engine entirely. (ADO #1040, review A6)

  @override
  void pushState(SurveyState state) =>
      unawaited(_navigatorKey.currentState?.pushNamed('/', arguments: state));

  @override
  void replaceState(SurveyState state) => unawaited(
    _navigatorKey.currentState?.pushReplacementNamed('/', arguments: state),
  );

  @override
  void popSurvey() => _navigatorKey.currentState?.pop();

  @override
  void deliverResult(SurveyResult result) => widget.onResult(result);

  @override
  Future<void> showFeedback(SurveyFeedback feedback) =>
      showSurveyFeedbackDialog(
        navigatorKey: _navigatorKey,
        feedback: feedback,
        localizations: widget.localizations,
      );

  @override
  Widget build(BuildContext context) {
    return SurveyConfiguration(
      surveyProgressConfiguration:
          widget.surveyProgressbarConfiguration ??
          SurveyProgressConfiguration(),
      taskNavigator: _taskNavigator,
      surveyController: widget.surveyController ?? SurveyController(),
      localizations: widget.localizations,
      padding: const EdgeInsets.all(14),
      registries: widget.registries,
      contentStyles: widget.contentStyles,
      variables: widget.task.variables,
      child: SurveyStateProvider(
        taskNavigator: _taskNavigator,
        stepShell: widget.stepShell,
        engine: _engine,
        child: SurveyPage(
          length: widget.task.steps.length,
          onResult: widget.onResult,
          appBar: widget.appBar,
          navigatorKey: _navigatorKey,
          decoration: widget.decoration,
        ),
      ),
    );
  }
}

class SurveyPage extends StatefulWidget {
  final int length;
  final Function(SurveyResult) onResult;
  final PreferredSizeWidget? appBar;
  final GlobalKey<NavigatorState> navigatorKey;
  final Decoration? decoration;

  const SurveyPage({
    super.key,
    required this.length,
    required this.onResult,
    required this.navigatorKey,
    this.appBar,
    this.decoration,
  });

  @override
  _SurveyPageState createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(SurveyStateProvider.of(context).onEvent(StartSurvey())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar ?? const SurveyAppBar(),
      body: Container(
        decoration: widget.decoration,
        child: Navigator(
          key: widget.navigatorKey,
          onGenerateRoute: (settings) {
            final isPrevious =
                settings.arguments is PresentingSurveyState &&
                (settings.arguments! as PresentingSurveyState).isPreviousStep;
            return SurveyKitPageRouteBuilder<Widget>(
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) =>
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(isPrevious ? -1.0 : 1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
              pageBuilder: (_, __, ___) {
                if (settings.arguments is! PresentingSurveyState) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }

                final currentState =
                    settings.arguments! as PresentingSurveyState;

                final step = currentState.currentStep;
                return _SurveyView(
                  id: step.id,
                  createView: () => AnswerView(
                    answer: step.answerFormat,
                    step: step,
                    stepResult: currentState.questionResults.firstWhereOrNull(
                      (element) => element.id == step.id,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SurveyView extends StatelessWidget {
  const _SurveyView({required this.id, required this.createView});

  final String id;
  final Widget Function() createView;

  @override
  Widget build(BuildContext context) {
    return Container(key: ValueKey<String>(id), child: createView());
  }
}
