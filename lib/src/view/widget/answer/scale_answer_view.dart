import 'package:flutter/material.dart' hide Step;
import 'package:survey_kit/src/model/answer/scale_answer_format.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/util/measure_date_state_mixin.dart';
import 'package:survey_kit/src/view/widget/answer/answer_mixin.dart';
import 'package:survey_kit/src/view/widget/answer/answer_question_text.dart';
import 'package:survey_kit/src/view/widget/question_answer.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

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

  double _value = 0.0;

  @override
  void initState() {
    super.initState();
    final answer = widget.questionStep.answerFormat;
    if (answer == null) {
      throw Exception('ScaleAnswerFormat is null');
    }
    _scaleAnswerFormat = answer as ScaleAnswerFormat;

    if (widget.result?.result is double) {
      _value = widget.result?.result as double;
    } else {
      _value = _scaleAnswerFormat.defaultValue;
    }

    WidgetsFlutterBinding.ensureInitialized();
    Future.delayed(Duration.zero, () {
      super.onChange(_value);
    });

    //_value = _scaleAnswerFormat.minimumValue;
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result?.result as double? ?? //QuestionAnswer.of(context).stepResult?.result
        _scaleAnswerFormat.defaultValue;

    final questionText = widget.questionStep.answerFormat?.question;

    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (questionText != null) AnswerQuestionText(text: questionText),
          if (!_scaleAnswerFormat.isVertical) Padding(
            padding: const EdgeInsets.all(14.0),
            child: Text(
              _value.toStringAsFixed(0),
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          if (_scaleAnswerFormat.isVertical)
            Container(
              height: 350,
              child: SfSliderTheme(
                data: SfSliderThemeData(
                  activeTickColor: Colors.blue,
                  inactiveTickColor: Colors.blue[200],
                  tooltipBackgroundColor: Colors.blue,
                  tooltipTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                child: SfSlider.vertical(
                  inactiveColor: Colors.blue[200],
                  min: _scaleAnswerFormat.minimumValue,
                  max: _scaleAnswerFormat.maximumValue,
                  value: _value,
                  interval: _scaleAnswerFormat.step,
                  stepSize: _scaleAnswerFormat.step,
                  showTicks: true,
                  showLabels: true,
                  tooltipPosition: SliderTooltipPosition.right,
                  tooltipTextFormatterCallback: (dynamic actualValue, String formattedText) {
                    switch (actualValue) {
                      case 1:
                        if (_scaleAnswerFormat.isAge) {
                          return 'Acts Younger Than Age in Years';
                        }
                        return 'Well below average for age';
                      case 2:
                        if (_scaleAnswerFormat.isAge) {
                          return 'Acts Younger Than Age in Years';
                        }
                        return 'Below average for age';
                      case 3:
                        if (_scaleAnswerFormat.isAge) {
                          return 'Acts Younger Than Age in Years';
                        }
                        return 'Below average for age';
                      case 4:
                        if (_scaleAnswerFormat.isAge) {
                          return 'Acts Younger Than Age in Years';
                        }
                        return 'Low average for age';
                      case 5:
                        if (_scaleAnswerFormat.isAge) {
                          return 'Acts Younger Than Age in Years';
                        }
                        return 'Low average for age';
                      case >= 6 && < 10:
                        if (_scaleAnswerFormat.isAge) {
                          return 'Acts Own Age in Years';
                        }
                        return 'Average for age';
                      case 10:
                        if (_scaleAnswerFormat.isAge) {
                          return 'Acts Older Than Age in Years';
                        }
                        return 'High average for age';
                      case 11:
                        if (_scaleAnswerFormat.isAge) {
                          return 'Acts Older Than Age in Years';
                        }
                        return 'High average for age';
                      case 12:
                        if (_scaleAnswerFormat.isAge) {
                          return 'Acts Older Than Age in Years';
                        }
                        return 'Above average for age';
                      default:
                        return formattedText;
                    }
                  },
                  labelFormatterCallback: (dynamic actualValue, String formattedText) {
                    switch (actualValue) {
                      case 1:
                        if (_scaleAnswerFormat.isAge) {
                          return '';
                        }
                        return 'Well below average for age';
                      case 2:
                        return '';
                      case 3:
                        if (_scaleAnswerFormat.isAge) {
                          return '';
                        }
                        return 'Below average for age';
                      case 4:
                        if (_scaleAnswerFormat.isAge) {
                          return 'Acts Younger Than Age in Years';
                        }
                        return 'Low average for age';
                      case 5:
                        return '';
                      case 6:
                        return '';
                      case 7:
                        if (_scaleAnswerFormat.isAge) {
                          return 'Acts Own Age in Years';
                        }
                        return 'Average for age';
                      case 8:
                        return '';
                      case 9:
                        return '';
                      case 10:
                        if (_scaleAnswerFormat.isAge) {
                          return 'Acts Older Than Age in Years';
                        }
                        return 'High average for age';
                      case 11:
                        return '';
                      case 12:
                        if (_scaleAnswerFormat.isAge) {
                          return '';
                        }
                        return 'Above average for age';
                      default:
                        return formattedText;
                    }
                  },
                  enableTooltip: true,
                  minorTicksPerInterval: 0,
                  onChanged: (dynamic value){
                    setState(() {
                      _value = value;
                      onChange(_value);
                    });
                    },
                ),
              ),
            ) else Column(
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
                      value: _value,
                      onChanged: (double value) {
                        setState(() {
                          _value = value;
                          onChange(_value);
                        });
                      },
                      min: _scaleAnswerFormat.minimumValue,
                      max: _scaleAnswerFormat.maximumValue,
                      // activeColor: Theme.of(context).sliderTheme.activeTrackColor,
                      divisions: (_scaleAnswerFormat.maximumValue -
                              _scaleAnswerFormat.minimumValue) ~/
                          _scaleAnswerFormat.step,
                      label: _value.toString(),
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
                  const Spacer(),
                  // const Expanded(
                  //   flex: 3,
                  //   child: Spacer(),
                  // ),
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
