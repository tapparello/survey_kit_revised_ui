import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_html/flutter_html.dart' hide Content;
import 'package:survey_kit/src/configuration/survey_configuration.dart';
import 'package:survey_kit/src/model/answer/multiple_choice_answer_format.dart';
import 'package:survey_kit/src/model/answer/text_choice.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/model/step.dart';
import 'package:survey_kit/src/presenter/survey_state_provider.dart';
import 'package:survey_kit/src/util/measure_date_state_mixin.dart';
import 'package:survey_kit/src/view/widget/answer/answer_format_guard.dart';
import 'package:survey_kit/src/view/widget/answer/answer_mixin.dart';
import 'package:survey_kit/src/view/widget/answer/answer_question_text.dart';
import 'package:survey_kit/src/view/widget/answer/none_option_selection.dart';
import 'package:survey_kit/src/view/widget/answer/selection_list_tile.dart';

class MultipleChoiceAnswerView extends StatefulWidget {
  final Step questionStep;
  final StepResult? result;

  const MultipleChoiceAnswerView({
    Key? key,
    required this.questionStep,
    required this.result,
  }) : super(key: key);

  @override
  _MultipleChoiceAnswerView createState() => _MultipleChoiceAnswerView();
}

class _MultipleChoiceAnswerView extends State<MultipleChoiceAnswerView>
    with
        MeasureDateStateMixin,
        AnswerMixin<MultipleChoiceAnswerView, List<TextChoice>> {
  late final MultipleChoiceAnswerFormat _multipleChoiceAnswer;

  List<TextChoice> _selectedChoices = [];
  late List<TextChoice> _textChoices = [];
  late final TextChoice _noneOfTheAboveOption;
  final TextEditingController _otherController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _multipleChoiceAnswer = requireAnswerFormat<MultipleChoiceAnswerFormat>(
      widget.questionStep,
    );

    _noneOfTheAboveOption = TextChoice(
      id: 'None',
      text: _multipleChoiceAnswer.noneOptionText ?? 'None of the above',
      value: _multipleChoiceAnswer.noneOptionText ?? 'None of the above',
    );

    if (_multipleChoiceAnswer.choicesFromVariable != null) {
      // getTextChoices() is called in didChangeDependencies() because it
      // needs SurveyConfiguration.of(context) which isn't available in initState()
      _selectedChoices = NoneOptionSelection.initial(
        null,
        none: _noneOfTheAboveOption,
        hasNoneOption: _multipleChoiceAnswer.noneOption,
      );
    } else {
      _textChoices = _multipleChoiceAnswer.textChoices;
      List<TextChoice>? previousChoices;

      if (widget.result?.result is List<TextChoice>) {
        previousChoices = widget.result?.result as List<TextChoice>;
      } else if (widget.result?.result is List<dynamic>) {
        previousChoices = (widget.result?.result as List<dynamic>)
            .map((e) => TextChoice.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // ADO #977: when the None option is enabled, a fresh question (no prior
      // result) defaults to "None of these" so there is always one selection.
      _selectedChoices = NoneOptionSelection.initial(
        previousChoices,
        none: _noneOfTheAboveOption,
        hasNoneOption: _multipleChoiceAnswer.noneOption,
      );
    }

    if (_multipleChoiceAnswer.shuffleChoices) {
      _multipleChoiceAnswer.textChoices.shuffle();
    }

    // ADO #978: restore the "Other" write-in text so it is shown when the
    // question is revisited (a new widget instance on back-nav or a new run).
    // The value survives in the result but the field needs to be seeded.
    if (_multipleChoiceAnswer.otherField) {
      final existingOther = _selectedChoices.firstWhereOrNull(
        (c) => c.id == 'Other',
      );
      if (existingOther != null) {
        _otherController.text = existingOther.value ?? existingOther.text;
      }
    }

    // Handle results from previous runs of the survey
    WidgetsFlutterBinding.ensureInitialized();
    Future.delayed(Duration.zero, () {
      super.onChange(_selectedChoices);
    });
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_multipleChoiceAnswer.choicesFromVariable != null) {
      getTextChoices();
    }
  }

  void getTextChoices() {
    final variableKey = _multipleChoiceAnswer.choicesFromVariable!;
    final variables = SurveyConfiguration.of(context).variables;
    final variableValue = variables[variableKey];

    var choices = <TextChoice>[];

    if (variableValue is List<String>) {
      choices = variableValue
          .map((String choice) => TextChoice(text: choice, value: choice))
          .toList();
    } else {
      // Fall back to looking up a previous step result by ID
      final provider = SurveyStateProvider.of(context);
      final stepResult = provider.getStepResultById(variableKey);
      if (stepResult?.result is List<TextChoice>) {
        choices = List<TextChoice>.from(stepResult!.result as List<TextChoice>);
      } else if (stepResult?.result is List<dynamic>) {
        choices = (stepResult!.result as List<dynamic>).map((e) {
          if (e is TextChoice) return e;
          if (e is Map<String, dynamic>) return TextChoice.fromJson(e);
          return TextChoice(text: e.toString(), value: e.toString());
        }).toList();
      }
    }

    if (choices.isNotEmpty) {
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
      return _selectedChoices.length >=
          _multipleChoiceAnswer.minRequiredChoices;
      //return _selectedChoices.isNotEmpty ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final questionText = widget.questionStep.answerFormat?.question;

    // _selectedChoices = QuestionAnswer.of(context).stepResult?.result as List<TextChoice>? ??
    //     widget.result?.result as List<TextChoice>? ??
    //     [];

    // Handle results from previous runs of the survey
    if (_selectedChoices.isNotEmpty) {
      // onValidationChanged = isValid(_selectedChoices);
      super.onChange(_selectedChoices);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Column(
        children: [
          if (questionText != null) AnswerQuestionText(text: questionText),
          const Divider(color: Colors.grey),
          ..._textChoices //_multipleChoiceAnswer.textChoices
              .map(
                (TextChoice tc) => SelectionListTile(
                  text: tc.text,
                  onTap: () {
                    if (_selectedChoices.contains(tc)) {
                      _selectedChoices.remove(tc);
                      // ADO #977: deselecting the last real option falls back to
                      // "None of these" so there is always one selection.
                      _selectedChoices = NoneOptionSelection.ensureNotEmpty(
                        _selectedChoices,
                        none: _noneOfTheAboveOption,
                        hasNoneOption: _multipleChoiceAnswer.noneOption,
                      );
                    } else {
                      if (_selectedChoices.contains(_noneOfTheAboveOption)) {
                        _selectedChoices.remove(_noneOfTheAboveOption);
                      }
                      if (_selectedChoices.length <
                          _multipleChoiceAnswer.maxAllowedChoices) {
                        _selectedChoices.add(tc);
                      } else {
                        final message =
                            _multipleChoiceAnswer
                                .maxAllowedChoicesErrorMessage ??
                            'You can only select up to ${_multipleChoiceAnswer.maxAllowedChoices} options from the list.</p><p>Remove one of the existing options before selecting a new one.';
                        _dialogBuilder(context, '<p>$message</p>');
                      }
                      // _selectedChoices.add(tc);
                    }
                    setState(() {});
                    //onChange([..._selectedChoices, tc]);
                    super.onChange(_selectedChoices);
                  },
                  isSelected: _selectedChoices.contains(tc),
                ),
              )
              .toList(),
          if (_multipleChoiceAnswer.otherField) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: ListTile(
                trailing:
                    (_selectedChoices.firstWhereOrNull(
                          (choice) => choice.id == 'Other',
                        ) ==
                        null)
                    ? Container(width: 32, height: 32)
                    : Icon(
                        Icons.check,
                        size: 32,
                        color: Theme.of(context).listTileTheme.selectedColor,
                      ),
                title: TextField(
                  controller: _otherController,
                  onChanged: (v) {
                    int? currentIndex;
                    final otherTextChoice = _selectedChoices
                        .firstWhereIndexedOrNull((index, element) {
                          final isOtherField = element.id == 'Other';

                          if (isOtherField) {
                            currentIndex = index;
                          }

                          return isOtherField;
                        });

                    setState(() {
                      if (v.isEmpty && otherTextChoice != null) {
                        _selectedChoices.remove(otherTextChoice);
                        // ADO #977: clearing the last selection falls back to None.
                        _selectedChoices = NoneOptionSelection.ensureNotEmpty(
                          _selectedChoices,
                          none: _noneOfTheAboveOption,
                          hasNoneOption: _multipleChoiceAnswer.noneOption,
                        );
                      } else if (v.isNotEmpty) {
                        final updatedTextChoice = TextChoice(
                          id: 'Other',
                          value: v,
                          text: v,
                        );
                        if (otherTextChoice == null) {
                          // Typing "Other" is a real selection; it clears None
                          // (ADO #977). Done before adding so the index below is
                          // unaffected (currentIndex is only set once Other exists).
                          _selectedChoices
                            ..remove(_noneOfTheAboveOption)
                            ..add(updatedTextChoice);
                        } else if (currentIndex != null) {
                          _selectedChoices[currentIndex!] = updatedTextChoice;
                        }
                      }
                      onChange(_selectedChoices);
                    });
                  },
                  decoration: InputDecoration(
                    // labelText: 'Other',
                    // labelStyle: Theme.of(context).textTheme.titleLarge,
                    hintText:
                        _multipleChoiceAnswer.otherHintText ??
                        'Write more here...',
                    hintStyle: Theme.of(context).textTheme.titleMedium,
                    // floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
              ),
            ),
            const Divider(color: Colors.grey),
          ],
          if (_multipleChoiceAnswer.noneOption) ...[
            SelectionListTile(
              text: _noneOfTheAboveOption.text,
              onTap: () {
                // ADO #977: tapping "None of these" makes it the sole selection.
                // It is not deselectable to empty — there is always one
                // selection, so re-tapping it is a no-op.
                _selectedChoices
                  ..clear()
                  ..add(_noneOfTheAboveOption);
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
    final okLabel =
        SurveyConfiguration.of(context).localizations?['ok'] ?? 'OK';
    final htmlStyle = <String, Style>{
      'p': Style(
        textAlign: TextAlign.center,
        fontWeight: FontWeight.bold,
        fontSize: FontSize(16.0),
      ),
      'ul': Style(fontSize: FontSize(16.0)),
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
                  child: Text(okLabel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
