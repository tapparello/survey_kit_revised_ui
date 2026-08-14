import 'package:flutter/material.dart';
import 'package:survey_kit/src/configuration/survey_configuration.dart';
import 'package:survey_kit/src/controller/survey_controller.dart';
import 'package:survey_kit/src/presenter/survey_state.dart';
import 'package:survey_kit/src/presenter/survey_state_provider.dart';
import 'package:survey_kit/src/widget/survey_progress.dart';

class SurveyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final SurveyController? controller;

  const SurveyAppBar({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    final progressbarConfiguration = SurveyConfiguration.of(
      context,
    ).surveyProgressConfiguration;

    final surveyController =
        controller ?? SurveyConfiguration.of(context).surveyController;

    final surveyStream = SurveyStateProvider.of(
      context,
    ).surveyStateStream.stream;

    final cancelButton = TextButton(
      child: Text(
        SurveyConfiguration.of(context).localizations?['cancel'] ?? 'Cancel',
        style: TextStyle(
          color:
              Theme.of(context).appBarTheme.toolbarTextStyle?.color ??
              Theme.of(context).primaryColor,
        ),
      ),
      onPressed: () => surveyController.closeSurvey(context: context),
    );

    final backButton = BackButton(
      onPressed: () {
        surveyController.stepBack(context: context);
      },
    );

    final actionWidget = progressbarConfiguration.showCloseButton
        ? StreamBuilder<SurveyState>(
            stream: surveyStream,
            builder: (context, snapshot) {
              final state = snapshot.data;
              // Hidden only until the first step is presented, where
              // CloseSurvey is gated out and the button would be inert.
              // Deliberately NOT `state is PresentingSurveyState`: that would
              // also hide Cancel for the whole terminal SurveyResultState
              // window, which is a second rendered change this phase does not
              // own. (ADO #1041)
              //
              // LoadingSurveyState is named even though it is never streamed
              // today — `stateStream.add` has one call site, inside
              // updateState, and the initial LoadingSurveyState is a field
              // initialiser that never routes through it. That is a property of
              // the current call graph, not a stated invariant; a later phase
              // that emits it would otherwise silently un-hide the button with
              // no failing test.
              if (state == null || state is LoadingSurveyState) {
                return const SizedBox.shrink();
              }
              return cancelButton;
            },
          )
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
            final label = progressbarConfiguration.label;

            // The app bar action label is independent of `showLabel`, which
            // only controls the label rendered above the bar by
            // SurveyProgress. Render it whenever a label builder is provided
            // (the null check guards the default config where label == null).
            if (state is PresentingSurveyState && label != null) {
              return label(
                (state.currentStepIndex + 1).toString(),
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
  Size get preferredSize => const Size(double.infinity, 40);
}
