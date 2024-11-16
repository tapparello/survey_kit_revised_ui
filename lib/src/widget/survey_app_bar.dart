import 'package:flutter/material.dart';
import 'package:survey_kit/src/configuration/survey_configuration.dart';
import 'package:survey_kit/src/controller/survey_controller.dart';
import 'package:survey_kit/src/presenter/survey_state.dart';
import 'package:survey_kit/src/presenter/survey_state_provider.dart';
import 'package:survey_kit/src/widget/survey_progress.dart';

class SurveyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final SurveyController? controller;

  const SurveyAppBar({
    super.key,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final progressbarConfiguration =
        SurveyConfiguration.of(context).surveyProgressConfiguration;

    final surveyController =
        controller ?? SurveyConfiguration.of(context).surveyController;

    final surveyStream =
        SurveyStateProvider.of(context).surveyStateStream.stream;

    final cancelButton = TextButton(
      child: Text(
        SurveyConfiguration.of(context).localizations?['cancel'] ?? 'Cancel',
        style: TextStyle(
          color: Theme.of(context).appBarTheme.toolbarTextStyle?.color ??
              Theme.of(context).primaryColor,
        ),
      ),
      onPressed: () => surveyController.closeSurvey(
        context: context,
      ),
    );

    final backButton = BackButton(
      onPressed: () {
        surveyController.stepBack(
          context: context,
        );
      },
    );

    final actionWidget = progressbarConfiguration.showCloseButton
        ? cancelButton
        : const SizedBox.shrink();

    return AppBar(
      elevation: 0,
      leading: StreamBuilder<SurveyState>(
        stream: surveyStream,
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return const SizedBox.shrink();
          }

          final state = snapshot.data!;

          if (state is PresentingSurveyState) {
            return state.isFirstStep ? const SizedBox.shrink() : backButton;
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
      title: const SurveyProgress(),
      actions: [
        StreamBuilder<SurveyState>(
          stream: surveyStream,
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return const SizedBox.shrink();
            }

            final state = snapshot.data!;

            if (state is PresentingSurveyState) {
              return progressbarConfiguration.label!(
                (state.currentStepIndex+1).toString(),
                state.stepCount.toString(),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        actionWidget,
      ],
    );
  }

  @override
  Size get preferredSize => const Size(
        double.infinity,
        40,
      );
}
