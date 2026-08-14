import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:survey_kit/src/engine/survey_engine.dart';
import 'package:survey_kit/survey_kit.dart';

class SurveyStateProvider extends InheritedWidget {
  @internal
  const SurveyStateProvider({
    super.key,
    required this.taskNavigator,
    required this.engine,
    required super.child,
    this.stepShell,
  });

  final TaskNavigator taskNavigator;
  final StepShell? stepShell;
  @internal
  final SurveyEngine engine;

  // Delegations. Every one of these was a mutable field on this widget until
  // ADO #1033, and lived on a SurveySession until ADO #1041; they stay on the
  // public surface so no `of(context)` call site changed.
  SurveyState get state => engine.state;
  Set<StepResult> get results => engine.results;
  DateTime get startDate => engine.startDate;
  StreamController<SurveyState> get surveyStateStream => engine.stateStream;
  void updateState(SurveyState newState) => engine.updateState(newState);
  StepResult? getStepResultById(String id) => engine.resultById(id);
  ValueListenable<bool> get isAdvancing => engine.isAdvancing;

  /// Dispatches [event] to the engine. The state machine itself lives in
  /// `lib/src/engine/`, outside the widget layer. (ADO #1041)
  Future<void> onEvent(SurveyEvent event) => engine.handleEvent(event);

  static SurveyStateProvider of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<SurveyStateProvider>();
    if (result == null) {
      throw const SurveyKitScopeException(
        widgetType: 'SurveyStateProvider',
        hint: 'Wrap the widget tree in SurveyKit.',
      );
    }
    return result;
  }

  /// Compares what dependents actually read from this widget.
  ///
  /// `engine` is created in `initState` and is as identity-stable as the
  /// `session` it replaced, so this comparison is unchanged in behaviour.
  ///
  /// `stepShell` stays because `AnswerView` reads it — but note it is a function
  /// compared by identity, so a consumer passing an inline `stepShell` closure
  /// still gets a notification on every parent rebuild. That is now harmless:
  /// `AnswerSession` holds the answer, not `QuestionAnswer`.
  @override
  bool updateShouldNotify(SurveyStateProvider oldWidget) =>
      taskNavigator != oldWidget.taskNavigator ||
      engine != oldWidget.engine ||
      stepShell != oldWidget.stepShell;
}
