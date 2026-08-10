# 1.0.0-dev.13

- BUGFIX: `build_runner` regeneration is reproducible again. Previously the
  regenerated code did not compile (all 14 answer formats), silently dropped the
  JSON `type` discriminator from all 10 `Content` subclasses, and reverted the
  hand-applied nested `toJson()` fix for `Step` / `StepResult`. A round-tripped
  `Content` would have degraded to a different type on the next regeneration.
  (ADO #1001)
- BUGFIX: integer fields on `IntegerAnswerFormat`, `TextAnswerFormat` and the
  multiple-choice formats no longer throw when the value arrives as a JSON
  double (e.g. `1.0`).
- CHANGE: `toJson()` now returns a fully JSON-encodable map everywhere; nested
  models are converted rather than embedded as live objects.
- CHANGE: key **order** in serialized output changed for 16 models. The decoded
  map is equivalent, but the encoded string is no longer byte-identical -
  consumers comparing persisted JSON as a string will see one inequality per
  existing record. Self-correcting once each record is next written; update
  any byte-comparison golden tests.
- CHANGE: `OrderedTask.toJson()` now includes `variables` and `stepCount`.
- CHANGE: the `type` discriminator on the abstract `Content` and `AnswerFormat`
  bases is now write-only (`includeToJson: true, includeFromJson: false`). If you
  subclass either and generate your own `.g.dart`, your subclass must supply the
  discriminator default (e.g. `super.answerType = type`) or `toJson()` will emit
  `"type": null` and the next load will throw. `explicit_to_json` is
  package-local, so set it in your own `build.yaml` to keep nested `toJson()`
  calls.
- ADDED: a root `build.yaml` restricting codegen to `lib/**`.
- ADDED: a CI job enforcing that regeneration is a no-op.
- ADDED: `.fvmrc` pinning Flutter 3.44.7, and a README section on regenerating
  code.

# 1.0.0-dev.3 - 1.0.0-dev.12

Not previously recorded. The notable change in this range:

- BREAKING: two unused public members were removed during Phase 1 library
  hardening. (ADO #1000, `d870dad`)

# 1.0.0-dev.2
- BREAKING: `resultToStepIdentifierMapper` now also returns the previous results
  - (StepResult? result) -> (List<StepResult> results, StepResult? result)
- BUGFIX: Fixed a bug where `resultToStepIdentifierMapper` was not called when the result was null
# 1.0.0-dev.1
- INFO: We we completly reworked how survey_kit works and want to get it to a stable release version 1.0
  
- BREAKING: Enum BooleanResult is now lowercase
- BREAKING: Enum FinishReason is now lowercase
- BREAKING: Id's are now simple Strings
- BREAKING: TextChoice is not const anymore
- BREAKING: SurveyResult: Every Step has now one Result with a generic parameter instead of different objects
- BREAKING: Return typoe of the boolean step is now a TimeResult objects which wraps TimeOfDay
- FEATURE: survey_kit is now more dynamic and every content can be used before the question
    - VideoContent
    - AudioContent
    - MarkdownContent
    - TextContent
    - LottieContent
- FEATURE: MeasureDateStateMixin to measure when the user entered and left a step
- FEATURE: PreviousStepResultMixin: If one of your steps depends on a previous step just implement this mixin and you can access the previous result
- CHORE: Updated dependecies

HOW TO MIGRATE:
- JSON
- Code-Definition
  
# 0.1.2
- INFO: Update dependencies (Flutter 3.7.0)

# 0.1.1
- INFO: Update dependencies (Flutter 3.0.2)
# 0.1.0
- INFO: Updated dependencies
# 0.0.21
- BREAKING: Adapated text styles to to TextThemes - You can find a complete list in the README.md

# 0.0.20
- BREAKING: Value identifier for Single-/Multiplechoice answers is now the value
- BREAKING: You now have to close the survey yourself when finished in onResult
- BREAKING: Remove video player step for now because of dependency issues (If you rely on it use https://github.com/quickbirdstudios/survey_kit.git)

- FEATURE: Progressbar
- FEATURE: Transition between questions
- FEATURE: Localization of text

- BUGFIX: isOptional Flag works now as expected
- BUGFIX: Textinput does not spit text in half anymore
- BUGFIX: Text in Single-/Multiplechoice answers does now break the same if selected or unselected

- INFO: Updated dependencies

# 0.0.12
- FEATURE: Video-Step

- BUGFIX: isOptional Parameter works now as expected
- BUGFIX: DefaultSelection in SingleChoiceAnswer now works as expected
- BUGFIX: Use of TimePicker source

# 0.0.11

- BREAKING: 'TextAnswerFormat' 'isValid' Function is now just a regular expression
- BREAKING: Renamed Step 'id' to 'stepIdentifier' to make it more clearer for JSON use

- FEATURE: Survey can now be created via JSON
- FEATURE: Added documentation to the task definition

- BUGFIX: Survey - Navigator is not popped twice
- BUGFIX: Overflowing of text on ListTile
- BUGFIX: Added keys to different TextChoice to avoid falsly reapiting answers

# 0.0.10

- BREAKING: Migrated to null-safety
- BREAKING: Upgrade Dart SDK constraints to >=2.12.0-0 <3.0.0
- BREAKING: Expose SurveyController to add the possiblity to override the navigation (StepBack, NextStep and CloseSurvey)
- Flutter SurveyKit can now also be used with Web, MacOS, Linux and Windows (Not optimized)
- Updated platform dependend widgets to flutter_platform_widgets

# 0.0.2 - 0.0.8

- README updates
- Added additional licence information

# 0.0.1

Initial Version of the library.

- Includes the ability to create a surveys with prebuild and customs step.