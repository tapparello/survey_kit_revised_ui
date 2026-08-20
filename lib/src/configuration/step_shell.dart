import 'package:flutter/widgets.dart';
import 'package:survey_kit/src/model/step.dart';

/// Wraps a step's answer view, letting a consumer supply the surrounding
/// chrome instead of [StepView].
///
/// Declared here rather than in `src/survey_kit.dart`, where it used to live:
/// `Step` holds one as a field, and that file imports the answer view, so a
/// model importing it for this typedef pulled the whole widget layer in with
/// it. Flutter-typed by nature — the signature names `Widget` and
/// `BuildContext` — which is a value-type dependency, not a widget being built
/// in a model.
typedef StepShell =
    Widget Function(Step step, Widget? answerWidget, BuildContext context);
