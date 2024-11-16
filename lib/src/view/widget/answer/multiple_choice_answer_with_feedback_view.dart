import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:survey_kit/src/model/answer/multiple_choice_answer_with_feedback_format.dart';
import 'package:survey_kit/src/model/answer/text_choice.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/util/measure_date_state_mixin.dart';
import 'package:survey_kit/src/view/widget/answer/answer_mixin.dart';
import 'package:survey_kit/src/view/widget/answer/answer_question_text.dart';
import 'package:survey_kit/src/view/widget/answer/selection_list_tile.dart';
import 'package:survey_kit/src/view/widget/question_answer.dart';
import 'package:flutter_html/flutter_html.dart' hide Content;
import 'package:shared_preferences/shared_preferences.dart';

class MultipleChoiceAnswerWithFeedbackView extends StatefulWidget {
  final Step questionStep;
  final StepResult? result;

  const MultipleChoiceAnswerWithFeedbackView({
    Key? key,
    required this.questionStep,
    required this.result,
  }) : super(key: key);

  @override
  _MultipleChoiceAnswerWithFeedbackView createState() => _MultipleChoiceAnswerWithFeedbackView();
}

class _MultipleChoiceAnswerWithFeedbackView extends State<MultipleChoiceAnswerWithFeedbackView>
    with
        MeasureDateStateMixin,
        AnswerMixin<MultipleChoiceAnswerWithFeedbackView, List<TextChoice>> {
  late final MultipleChoiceAnswerWithFeedbackFormat _multipleChoiceAnswer;

  late final SharedPreferences prefs;
  List<TextChoice> _selectedChoices = [];
  late List<TextChoice> _textChoices = [];
  late final TextChoice _noneOfTheAboveOption;

  @override
  void initState() {
    super.initState();

    final answer = widget.questionStep.answerFormat;
    if (answer == null) {
      throw Exception('MultiSelectAnswer is null');
    }
    _multipleChoiceAnswer = answer as MultipleChoiceAnswerWithFeedbackFormat;

    if (_multipleChoiceAnswer.choicesFromVariable != null) {
      getTextChoices();
    } else {
      _textChoices = _multipleChoiceAnswer.textChoices;
    }

    if (_multipleChoiceAnswer.shuffleChoices) {
      _multipleChoiceAnswer.textChoices.shuffle();
    }

    _selectedChoices = widget.result?.result as List<TextChoice>? ?? [];

    _noneOfTheAboveOption = TextChoice(id: 'None', text: _multipleChoiceAnswer.noneOptionText ?? 'None of the above', value: _multipleChoiceAnswer.noneOptionText ?? 'None of the above');
  }

  Future<void> getTextChoices() async {

    prefs = await SharedPreferences.getInstance();
    final textChoices = prefs.getStringList(_multipleChoiceAnswer.choicesFromVariable!);

    if (textChoices != null){
      final choices = textChoices.map((String choice) => TextChoice(text: choice, value: choice)).toList();
      if (_multipleChoiceAnswer.shuffleChoices) {
        choices.shuffle();
      }

      setState(() {
        _textChoices = choices;
      });
    }

  }

  @override
  bool isValid(List<TextChoice>? result) {
    if (widget.questionStep.isMandatory) {
      return (_selectedChoices.length >= _multipleChoiceAnswer.minRequiredChoices) ?? false;
      //return _selectedChoices.isNotEmpty ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final questionText = widget.questionStep.answerFormat?.question;

    _selectedChoices = QuestionAnswer.of(context).stepResult?.result as List<TextChoice>? ??
        widget.result?.result as List<TextChoice>? ??
        [];

    // Handle results from previous runs of the survey
    if (_selectedChoices.isNotEmpty) {
      onValidationChanged = isValid(_selectedChoices);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Column(
        children: [
          if (questionText != null) AnswerQuestionText(text: questionText),
          const Divider(
            color: Colors.grey,
          ),
          ..._textChoices //_multipleChoiceAnswer.textChoices
              .map(
                (TextChoice tc) => SelectionListTile(
                  text: tc.text,
                  onTap: () {
                    if (_selectedChoices.contains(tc)) {
                      _selectedChoices.remove(tc);
                    } else {
                      if(_selectedChoices.contains(_noneOfTheAboveOption)){
                        _selectedChoices.remove(_noneOfTheAboveOption);
                      }
                      if(_selectedChoices.length < _multipleChoiceAnswer.maxAllowedChoices){
                        _selectedChoices.add(tc);
                      } else {
                        var message = _multipleChoiceAnswer.maxAllowedChoicesErrorMessage ?? 'You can only select up to ${_multipleChoiceAnswer.maxAllowedChoices} options from the list.</p><p>Remove one of the existing options before selecting a new one.';
                        _dialogBuilder(context, '<p>$message</p>');
                      }
                      // _selectedChoices.add(tc);
                    }
                    setState( () {},);
                    //onChange([..._selectedChoices, tc]);
                    super.onChange(_selectedChoices);
                  },
                  isSelected: _selectedChoices.contains(tc),
                ),
              )
              .toList(),
          if (_multipleChoiceAnswer.noneOption) ...[
            SelectionListTile(
              text: _noneOfTheAboveOption.text,
              onTap: () {
                if (_selectedChoices.contains(_noneOfTheAboveOption)) {
                  _selectedChoices.remove(_noneOfTheAboveOption);
                } else {
                  _selectedChoices..clear()
                  ..add(_noneOfTheAboveOption);
                }
                setState(() {});
                super.onChange(_selectedChoices);
              },
              isSelected: _selectedChoices.contains(_noneOfTheAboveOption),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _dialogBuilder(BuildContext context, String message) {

    final htmlStyle = <String, Style>{
      'p': Style(
        textAlign: TextAlign.center,
        fontWeight: FontWeight.bold,
        fontSize: FontSize(16.0),
      ),
      'ul': Style(
        fontSize: FontSize(16.0),
      ),
    };

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Html(data: message, style: htmlStyle),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}
