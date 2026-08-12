import 'package:flutter/material.dart' hide Step;
import 'package:survey_kit/src/view/step_view.dart';
import 'package:survey_kit/src/view/widget/answer/answer_session.dart';
import 'package:survey_kit/survey_kit.dart';

class AnswerView extends StatefulWidget {
  const AnswerView({
    super.key,
    required this.answer,
    required this.step,
    required this.stepResult,
  });
  final AnswerFormat? answer;

  final Step step;
  final StepResult? stepResult;

  @override
  State<AnswerView> createState() => _AnswerViewState();
}

class _AnswerViewState extends State<AnswerView> {
  late final AnswerSession<dynamic> _session = AnswerSession<dynamic>(
    step: widget.step,
  );

  @override
  void didUpdateWidget(AnswerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // AnswerSession is keyed to a step and created once. That is safe only
    // while every transition pushes a new route, so this element is never
    // reused across steps. If that ever changes, answers would be recorded
    // under the previous step's id, silently. (ADO #1033)
    assert(
      _session.step.id == widget.step.id,
      'AnswerView element reused across steps: AnswerSession is keyed to '
      '${_session.step.id} but the widget now carries ${widget.step.id}.',
    );
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget? answerView;
    if (widget.answer != null) {
      answerView = widget.answer!.createView(widget.step, widget.stepResult);
    }
    final stepShell =
        widget.step.stepShell ?? SurveyStateProvider.of(context).stepShell;

    return QuestionAnswer<dynamic>(
      session: _session,
      child: Builder(
        builder: (context) => stepShell != null
            ? stepShell.call(widget.step, answerView, context)
            : StepView(step: widget.step, answerView: answerView),
      ),
    );
  }
}
