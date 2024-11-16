import 'package:flutter/material.dart' hide Step;
import 'package:survey_kit/src/model/answer/scale_answer_format.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/util/measure_date_state_mixin.dart';
import 'package:survey_kit/src/view/widget/answer/answer_mixin.dart';
import 'package:survey_kit/src/view/widget/answer/answer_question_text.dart';
import 'package:survey_kit/src/view/widget/question_answer.dart';

class ScaleAnswerView extends StatefulWidget {
  final Step questionStep;
  final StepResult? result;

  const ScaleAnswerView({
    Key? key,
    required this.questionStep,
    required this.result,
  }) : super(key: key);

  @override
  _ScaleAnswerViewState createState() => _ScaleAnswerViewState();
}

class _ScaleAnswerViewState extends State<ScaleAnswerView>
    with MeasureDateStateMixin, AnswerMixin<ScaleAnswerView, double> {
  late final ScaleAnswerFormat _scaleAnswerFormat;

  @override
  void initState() {
    super.initState();
    final answer = widget.questionStep.answerFormat;
    if (answer == null) {
      throw Exception('ScaleAnswerFormat is null');
    }
    _scaleAnswerFormat = answer as ScaleAnswerFormat;
  }

  @override
  Widget build(BuildContext context) {
    final result = QuestionAnswer.of(context).stepResult?.result as double? ??
        _scaleAnswerFormat.defaultValue;
    final questionText = widget.questionStep.answerFormat?.question;

    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (questionText != null) AnswerQuestionText(text: questionText),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Text(
              result.toStringAsFixed(0),
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      _scaleAnswerFormat.minimumValue.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  Expanded(
                    flex: 8,
                    child: Slider.adaptive(
                      value: result,
                      onChanged: (double value) {
                        setState(() {
                          onChange(value);
                        });
                      },
                      min: _scaleAnswerFormat.minimumValue,
                      max: _scaleAnswerFormat.maximumValue,
                      // activeColor: Theme.of(context).sliderTheme.activeTrackColor,
                      divisions: (_scaleAnswerFormat.maximumValue -
                              _scaleAnswerFormat.minimumValue) ~/
                          _scaleAnswerFormat.step,
                      label: result.toString(),
                    ),
                  ),
                  Text(
                      _scaleAnswerFormat.maximumValue.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      _scaleAnswerFormat.minimumValueDescription,
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const Expanded(
                    flex: 3,
                    child: Spacer(),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      _scaleAnswerFormat.maximumValueDescription,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool isValid(double? result) {
    return true;
  }
}
