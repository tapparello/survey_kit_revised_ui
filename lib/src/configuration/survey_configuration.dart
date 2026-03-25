import 'package:flutter/material.dart';
import 'package:survey_kit/src/configuration/survey_registries.dart';
import 'package:survey_kit/src/controller/survey_controller.dart';
import 'package:survey_kit/src/model/content/styled_text_content.dart';
import 'package:survey_kit/src/navigator/task_navigator.dart';
import 'package:survey_kit/src/widget/survey_progress_configuration.dart';

class SurveyConfiguration extends InheritedWidget {
  const SurveyConfiguration({
    super.key,
    required this.surveyProgressConfiguration,
    required this.taskNavigator,
    required this.surveyController,
    required this.localizations,
    required this.padding,
    this.registries,
    this.contentStyles,
    this.variables = const {},
    required super.child,
  });

  final SurveyProgressConfiguration surveyProgressConfiguration;
  final TaskNavigator taskNavigator;
  final SurveyController surveyController;
  final Map<String, String>? localizations;
  final EdgeInsets padding;
  final SurveyRegistries? registries;
  final Map<String, StyledTextContent>? contentStyles;
  final Map<String, dynamic> variables;

  static SurveyConfiguration of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<SurveyConfiguration>();
    assert(result != null, 'No SurveyConfiguration found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(SurveyConfiguration oldWidget) =>
      surveyProgressConfiguration != oldWidget.surveyProgressConfiguration ||
      registries != oldWidget.registries ||
      contentStyles != oldWidget.contentStyles;
}
