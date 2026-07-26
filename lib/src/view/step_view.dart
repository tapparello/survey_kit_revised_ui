import 'package:flutter/material.dart' hide Step;
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;
import 'package:survey_kit/survey_kit.dart';

class StepView extends StatefulWidget {
  final Step step;
  final Widget? answerView;
  final SurveyController? controller;

  const StepView({
    super.key,
    required this.step,
    this.answerView,
    this.controller,
  });

  @override
  State<StepView> createState() => _StepViewState();
}

class _StepViewState extends State<StepView> {
  final startTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final surveyConfiguration = SurveyConfiguration.of(context);
    final _surveyController =
        widget.controller ?? surveyConfiguration.surveyController;

    final questionAnswer = QuestionAnswer.of(context);

    Widget? saveAndCloseButton = OutlinedButton(
      onPressed: () => _surveyController.closeSurvey(context: context),
      child: Text(surveyConfiguration.localizations?['cancel'] ?? 'Cancel'),
    );

    var nextStepButtonText =
        widget.step.buttonText ??
        toBeginningOfSentenceCase(surveyConfiguration.localizations?['next']) ??
        'Next';

    if (!surveyConfiguration.taskNavigator.hasNextStep(
      widget.step,
      SurveyStateProvider.of(context).results.toList(),
    )) {
      // ADO #968: a "forward-chrome" label (no explicit label, the literal
      // 'Next' default, or a resolved @next == the localized 'next') is not a
      // deliberate completion label — on a terminal step show the localized
      // 'Done'. A deliberate label (e.g. 'Submit survey') is still honored.
      final localizedNext = toBeginningOfSentenceCase(
        surveyConfiguration.localizations?['next'],
      );
      final buttonText = widget.step.buttonText;
      final isForwardChrome =
          buttonText == null ||
          buttonText == 'Next' ||
          buttonText == localizedNext;
      nextStepButtonText = isForwardChrome
          ? (toBeginningOfSentenceCase(
                  surveyConfiguration.localizations?['done'],
                ) ??
                'Done')
          : buttonText;
      saveAndCloseButton = const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      persistentFooterButtons: [
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: AnimatedBuilder(
                  animation: questionAnswer.isValid,
                  builder: (context, child) {
                    return ElevatedButton(
                      onPressed:
                          questionAnswer.isValid.value ||
                              !widget.step.isMandatory
                          ? () => _surveyController.nextStep(
                              context,
                              questionAnswer.stepResult,
                            )
                          : null,
                      child: Text(nextStepButtonText),
                    );
                  },
                ),
              ),
              saveAndCloseButton,
            ],
          ),
        ),
      ],
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              // top: BorderSide(width: 1.0, color: Colors.blue),
              bottom: BorderSide(width: 0.2, color: Colors.black),
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraint) {
                return Scrollbar(
                  // thumbVisibility: true,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 16.0,
                      left: 16.0,
                      right: 16.0,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ContentWidget(content: widget.step.content),
                          if (widget.answerView != null) widget.answerView!,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
