// Shared harness: a host whose State survives while its build() reruns, which
// is what a consumer's Theme.of(context) dependency does when the app theme
// changes. Rebuilding SurveyKit this way is the trigger for ADO #1033.
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

class RebuildHost extends StatefulWidget {
  const RebuildHost({
    super.key,
    required this.task,
    required this.onResult,
    this.initialResults,
    this.localizations,
  });

  final Task task;
  final void Function(SurveyResult) onResult;
  final Set<StepResult>? initialResults;
  final Map<String, String>? localizations;

  @override
  State<RebuildHost> createState() => RebuildHostState();
}

class RebuildHostState extends State<RebuildHost> {
  int _tick = 0;
  Map<String, String>? _localizationsOverride;

  // Held, not constructed in build(). SurveyProgressConfiguration declares no
  // operator== (survey_progress_configuration.dart:37), so a fresh instance per
  // build makes SurveyConfiguration.updateShouldNotify return true every time —
  // which would rebuild SurveyAppBar and StepView regardless of anything this
  // plan changes, and make the Task 3 localizations test guard nothing.
  final SurveyProgressConfiguration _progress = SurveyProgressConfiguration();

  /// Forces exactly one rebuild of the SurveyKit subtree.
  void rebuild() => setState(() => _tick++);

  /// Rebuilds with different localizations, for the Task 3 regression test.
  void setLocalizations(Map<String, String> value) =>
      setState(() => _localizationsOverride = value);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SurveyKit(
          // onResult is deliberately an inline closure, not a tear-off: that is
          // what every real consumer passes, and its identity changes on every
          // build. See the spec's updateShouldNotify section.
          onResult: (result) => widget.onResult(result),
          task: widget.task,
          initialResults: widget.initialResults,
          localizations: _localizationsOverride ?? widget.localizations,
          surveyProgressbarConfiguration: _progress,
        ),
      ),
    );
  }
}

/// A two-step navigable task: q1 (single choice) then q2 (single choice).
NavigableTask twoStepTask() {
  final q1 = QuestionStep(
    id: 'q1',
    title: 'One',
    answerFormat: SingleChoiceAnswerFormat(
      textChoices: [
        TextChoice(text: 'Alpha', value: 'alpha'),
        TextChoice(text: 'Beta', value: 'beta'),
      ],
    ),
    buttonText: 'Next',
    // isOptional defaults to TRUE on the deprecated QuestionStep helper, which
    // sets isMandatory: !isOptional. Without this, StepView's Next button is
    // never disabled and the mandatory-gating test in Task 2 cannot pass at all.
    isOptional: false,
  );
  final q2 = QuestionStep(
    id: 'q2',
    title: 'Two',
    answerFormat: SingleChoiceAnswerFormat(
      // Deliberately not 'One': that is q1's title, and find.text would match both.
      textChoices: [TextChoice(text: 'Yes', value: 'yes')],
    ),
    buttonText: 'Submit',
  );
  return NavigableTask(id: 't', steps: [q1, q2]);
}

/// Reads the provider from a context inside the survey subtree.
SurveyStateProvider providerFrom(WidgetTester tester, Finder anchor) =>
    SurveyStateProvider.of(tester.element(anchor));
