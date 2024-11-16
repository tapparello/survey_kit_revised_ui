import 'package:flutter/material.dart' hide Step;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survey_kit/src/model/answer/single_choice_answer_format.dart';
import 'package:survey_kit/src/model/answer/text_choice.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/util/measure_date_state_mixin.dart';
import 'package:survey_kit/src/view/widget/answer/answer_mixin.dart';
import 'package:survey_kit/src/view/widget/answer/answer_question_text.dart';
import 'package:survey_kit/src/view/widget/answer/selection_list_tile.dart';
import 'dart:convert';

class SingleChoiceAnswerView extends StatefulWidget {
  final Step questionStep;
  final StepResult? result;

  const SingleChoiceAnswerView({
    Key? key,
    required this.questionStep,
    required this.result,
  }) : super(key: key);

  @override
  _SingleChoiceAnswerViewState createState() => _SingleChoiceAnswerViewState();
}

class _SingleChoiceAnswerViewState extends State<SingleChoiceAnswerView>
    with
        MeasureDateStateMixin,
        AnswerMixin<SingleChoiceAnswerView, TextChoice> {

  late final SingleChoiceAnswerFormat _singleChoiceAnswerFormat;
  TextChoice? _selectedChoice;
  late final SharedPreferences prefs;
  late List<TextChoice> _textChoices = [];


  @override
  void initState() {
    super.initState();
    final answer = widget.questionStep.answerFormat;
    if (answer == null) {
      throw Exception('SingleSelectAnswer is null');
    }
    _singleChoiceAnswerFormat = answer as SingleChoiceAnswerFormat;

    if (_singleChoiceAnswerFormat.choicesFromVariable != null) {
      getTextChoices();
    } else {
      _textChoices = _singleChoiceAnswerFormat.textChoices;
    }

    if (_singleChoiceAnswerFormat.shuffleChoices) {
      _singleChoiceAnswerFormat.textChoices.shuffle();
    }

    TextChoice? previousChoice;

    if (widget.result?.result is TextChoice) {
      previousChoice = widget.result?.result as TextChoice;
    } else if (widget.result?.result is Map<String, dynamic>) {
      previousChoice = TextChoice.fromJson(widget.result?.result);
    }

    _selectedChoice = previousChoice ?? _singleChoiceAnswerFormat.defaultSelection;

    // Handle results from previous runs of the survey
    WidgetsFlutterBinding.ensureInitialized();
    Future.delayed(Duration.zero, () {
      if (_selectedChoice != null) {
        super.onChange(_selectedChoice);
      }
    });

  }

  Future<void> getTextChoices() async {

    prefs = await SharedPreferences.getInstance();
    final textChoices = prefs.getStringList(_singleChoiceAnswerFormat.choicesFromVariable!);

    if (textChoices != null){
      final choices = textChoices.map((String choice) => TextChoice(text: choice, value: choice)).toList();
      if (_singleChoiceAnswerFormat.shuffleChoices) {
        choices.shuffle();
      }

      setState(() {
        _textChoices = choices;
      });
    }

  }

  @override
  void onChange(TextChoice? choice) {
    if (_selectedChoice == choice) {
      _selectedChoice = null;
    } else {
      _selectedChoice = choice;
    }
    setState(() {});
    super.onChange(choice);
  }

  @override
  bool isValid(TextChoice? result) {
    if (widget.questionStep.isMandatory) {
      return _selectedChoice != null;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final questionText = widget.questionStep.answerFormat?.question;

    // if (_selectedChoice != null) {
    //   onValidationChanged = isValid(_selectedChoice);
    // }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Column(
        children: [
          if (questionText != null) AnswerQuestionText(text: questionText),
          const Divider(
            color: Colors.grey,
          ),
          ..._textChoices.map( //_singleChoiceAnswerFormat.textChoices.map(
            (TextChoice tc) {
              return SelectionListTile(
                text: tc.text,
                onTap: () {
                  onChange(tc);
                },
                isSelected: _selectedChoice == tc,
              );
            },
          ).toList(),
        ],
      ),
    );
  }
}
