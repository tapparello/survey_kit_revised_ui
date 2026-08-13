// A host that mounts SurveyKit over a task with an action rule, and a handler
// whose completion the test controls. Several acceptance criteria are only
// falsifiable if the test can pump *inside* the await window; a Completer-gated
// handler is what makes that window observable.
import 'package:flutter/material.dart' hide Step;
import 'package:survey_kit/survey_kit.dart';

/// Mounts SurveyKit with [task] and [registries].
///
/// A StatefulWidget, mirroring `rebuild_harness.dart`, for a lint reason rather
/// than a state reason: `onResult` must be an inline closure — that is what
/// every real consumer passes, and its identity changes on every build — and
/// `onResult: (result) => onResult(result)` on a StatelessWidget trips
/// `unnecessary_lambdas` (`analysis_options.yaml:155`), which `flutter analyze`
/// counts as an issue. Routing it through `widget.onResult` makes the target a
/// property access, which the lint does not flag.
class ActionHost extends StatefulWidget {
  const ActionHost({
    super.key,
    required this.task,
    required this.registries,
    required this.onResult,
    this.onHandlerError,
  });

  final Task task;
  final SurveyRegistries registries;
  final void Function(SurveyResult) onResult;
  final SurveyHandlerErrorCallback? onHandlerError;

  @override
  State<ActionHost> createState() => _ActionHostState();
}

class _ActionHostState extends State<ActionHost> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SurveyKit(
          task: widget.task,
          registries: widget.registries,
          onHandlerError: widget.onHandlerError,
          onResult: (result) => widget.onResult(result),
        ),
      ),
    );
  }
}
