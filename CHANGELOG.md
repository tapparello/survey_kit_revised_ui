# 1.0.0-dev.16

- **BREAKING: `AnswerFormat.answerType` returns `AnswerFormatType`, not
  `String?`,** and `StepResult.answerType` is `AnswerFormatType?`. The serialized
  wire values are unchanged, so no persisted data needs migrating. Read a
  discriminator's JSON string with `AnswerFormatType.<member>.wireName`. (ADO
  #1015)
- **BREAKING: the 14 `static const String type` constants on the answer format
  subclasses are removed.** `BooleanAnswerFormat.type` becomes
  `AnswerFormatType.boolean`, or `AnswerFormatType.boolean.wireName` where a
  `String` is required.
- **BREAKING: an external `AnswerFormat` subclass must now return an
  `AnswerFormatType`, and cannot introduce a new discriminator.** The enum is
  closed, so a subclass has to reuse one of the 14 members — which also means it
  shares that member's result conversion in `StepResult`. Subclassing itself
  still works; `AnswerFormat` remains a plain abstract class. Nothing in the
  library, the example, or the consumer subclasses it today.
- **BREAKING: `TaskNotDefinedException` and `RuleNotDefinedException` are
  removed.** Both meant "the JSON `type` discriminator matched nothing", which is
  what `UnknownTypeException` already said. `Task.fromJson` and
  `NavigationRule.fromJson` now throw `UnknownTypeException` with `kind: 'Task'` /
  `kind: 'NavigationRule'`, and it gained an optional `String? expected` carrying
  the old messages' hint. Note the sealed `SurveyKitException` hierarchy lost two
  subtypes, which is breaking for an exhaustive `switch` over it.
- **BREAKING: `Content.fromJson` throws `UnknownTypeException` for an absent or
  unrecognised `type`** instead of silently returning `TextContent('')`. Its
  shape-inference fallback is also removed — that existed only for the
  persisted-result re-parse path deleted in `1.0.0-dev.15`, and is unreachable
  for old and new records alike. Content whose type comes from a registry now
  fails loudly when parsed without that registry, rather than becoming a blank
  block.
- **BREAKING: a result whose `answerType` is not a known discriminator now
  throws even when its value is null.** Previously such a record decoded
  successfully if `result` was null or absent — the generic decoder
  short-circuits on null, so the conversion never ran and the unrecognised string
  was retained in the `String?` field. With `answerType` typed as an enum there is
  no place to keep it, so `StepResult.fromJson` throws `ResultCodecException`
  naming the offending string. This makes the failure uniform with the
  non-null-result case.
- **BREAKING: conditional answer formats use `"type": "conditional"`, and
  `default` is required.** A `default` naming a key absent from `variants` throws
  `MalformedValueException` at parse, so an authoring typo fails when the survey
  loads rather than when a user reaches the step. `"type": "custom"` is
  deliberately not accepted — it is already `CustomNavigationRule`'s
  discriminator.
- **BREAKING (behaviour): `SurveyRegistries.customStepTypes` is honoured.**
  `resolveStep` was exported and documented but called by nothing in the
  library, so a consumer that registered a custom step factory got silence.
  `Step.fromJson` now consults it. This changes behaviour only for a consumer
  that had registered `customStepTypes`; a survey that had not is unaffected.
  An absent or unregistered step `type` still yields a built-in `Step` — steps
  are deliberately the one family where a missing discriminator is not an
  error.
- ADDED: `AnswerFormatType`, the answer format dispatch table. Each member
  carries its wire string and its `fromJson` factory, so a member cannot exist
  without one, and `StepResult`'s result conversion is now a compiler-checked
  exhaustive switch. This closes the hole `1.0.0-dev.15` left open, where a
  format absent from both the dispatch and the conversion compiled cleanly and
  failed at runtime.
- ADDED: conditional answer formats. `{"type": "conditional", "variable": ...,
  "default": ..., "variants": {...}}` resolves to its concrete variant at parse
  time, against the task's `variables`. No conditional value exists at runtime,
  so a result always records the variant's discriminator. Resolving against prior
  in-section answers, as conditional *content* does, is not supported yet.
- ADDED: `Step.fromJson` and `AnswerFormat.fromJson` take an optional
  `variables:` map, used to resolve conditional answer formats. Both are named and
  defaulted, so existing calls are unaffected.
- ADDED: `Task.fromJson` and `NavigationRule.fromJson` throw
  `UnknownTypeException` instead of a raw `TypeError` when `type` is absent. Both
  read `json['type'] as String` — a non-null cast on a nullable value — so a
  missing key surfaced from inside a cast rather than as a typed failure.
- BUGFIX: `SectionContent` is reachable through `Content.fromJson`. It had no
  case in the dispatch, so any authored `"type": "section"` degraded to an empty
  `TextContent` even though the class was exported, declared its discriminator,
  and had a generated `fromJson`. (ADO #1006)
- BUGFIX: content nested inside a `conditional` block now receives the
  registries. The dispatch dropped them, so a registry-provided type inside a
  conditional resolved without its factory.
- REMOVED: the dead generated `_$StepFromJson`. `Step` declares a hand-written
  `fromJson`, and the generated one — which could pass neither `registries` nor
  `variables` — had no callers. It was the only reason `Content.fromJson` carried
  a shape-inference fallback.

# 1.0.0-dev.15

- **BREAKING (data): survey results saved by an earlier version will not load.**
  `StepResult` no longer embeds a `Step`, and results are reconstructed using the
  answer format's discriminator, which older records do not carry.
  `StepResult.fromJson` throws `ResultCodecException` for such a record and
  `SurveyResult.fromJson` propagates it, so a caller should catch it and start the
  survey with no prior answers. Persisted results are unrecoverable across this
  upgrade by design: the package is pre-1.0, and the alternative was carrying a
  shape-guessing fallback forward. (ADO #1012)
- **BREAKING: `StepResult.step` is removed**, along with the `step` constructor
  argument. Results are keyed by `id`, which already equalled `step.id`. Replace
  `result.step.id` with `result.id`. A new optional `answerType` carries the
  answer format's discriminator and is required for any non-null result to
  serialize.
- **BREAKING: `AnswerFormat.answerType` is a getter, not a constructor
  parameter.** It was overridable — `TextAnswerFormat(answerType: 'time')`
  compiled — which now would select the wrong result conversion. Subclasses
  override the getter. If you subclass `AnswerFormat`, you must override
  `answerType` **and repeat the `@JsonKey(name: 'type', includeToJson: true,
  includeFromJson: false)` annotation on your override**; without it
  `json_serializable` silently omits `type` from your `toJson` and the next load
  cannot dispatch.
- BUGFIX: a persisted result now reconstructs its declared type.
  `_decodeResult` dispatched on the reified type argument, which is `dynamic` for
  every result reached through `SurveyResult`, so `if (value is S)` always
  matched and raw JSON was returned — `date` and `bool` answers came back as
  `String`, `time` as a `Map`. Views casting those crashed on resume;
  `TextChoice` answers did not crash but read as unanswered, so a regenerated PDF
  silently omitted them. (ADO #1009)
- BUGFIX: `CustomDateTimeConverter.toJson` shifted an already-UTC `DateTime` by
  the local zone offset — it rebuilt the value with the local `DateTime`
  constructor from its own field values and then called `toUtc()`. Latent while
  the only values passing through were `startTime` / `endTime`, which come from
  `DateTime.now()`; date answers now go through it too.
- BUGFIX: five answer views (`date`, `boolean`, `time`,
  `multiple_choice_auto_complete`, `text`) read the restored result with an
  unchecked cast; they now type-test it like the other views.
- CHANGE: a result that cannot be serialized now throws `ResultCodecException`
  instead of being silently persisted as its `toString()`, which was
  unrecoverable on read. If your `onResult` handler must not fail, wrap it.
- CHANGE: `type` moves to the end of the emitted map for the 14 answer formats,
  a consequence of `answerType` becoming a getter. Key order only; the decoded
  map is unchanged. Same class of change as `1.0.0-dev.13`.
- ADDED: `ResultCodecException`, carrying the step id and the answer-format
  discriminator. Note the sealed `SurveyKitException` hierarchy gained a subtype,
  which is breaking for an exhaustive `switch` over it.
- REMOVED: four redundant `@JsonSerializable(explicitToJson: true)` annotations,
  superseded by the global `explicit_to_json` build option. Generated output is
  byte-identical.

# 1.0.0-dev.14

- ADDED: `SurveyKitException`, a sealed base type for every failure the library
  throws, with 8 subtypes: `MissingAnswerFormatException`,
  `AnswerFormatMismatchException`, `SurveyKitScopeException`,
  `MalformedValueException`, `UnsupportedTaskException`, `UnknownTypeException`,
  and the two pre-existing `TaskNotDefinedException` and
  `RuleNotDefinedException`. A single `on SurveyKitException` now catches
  everything the library throws, and a `switch` over it can be exhaustive.
  Because the hierarchy is sealed, a future release adding a subtype is a
  breaking change for any consumer relying on that exhaustiveness. (ADO #1010)
- CHANGE: `TaskNotDefinedException` and `RuleNotDefinedException` keep their
  names and their zero-argument `const` constructors, but now extend
  `SurveyKitException`, carry an optional `discriminator`, and have a real
  `toString()`. Code logging `'$e'` previously saw
  `Instance of 'TaskNotDefinedException'`. It now sees
  `TaskNotDefinedException: <message>` in **debug** builds; in profile and
  release, `toString()` reports the shared fallback
  `SurveyKitException: <message>` for every subtype, because it uses Flutter's
  `objectRuntimeType`, which resolves the concrete type inside an `assert`. The
  `message` text and the typed `catch` clause are unaffected in all modes —
  branch on the type or the structured fields, not on the string.
- CHANGE: 18 failures previously raised as `Error` subtypes are now `Exception`
  subtypes — the 14 unchecked answer-format casts (`TypeError`), the three
  `of(context)` lookups (`Null check operator used on a null value` in release),
  and `DateAnswerView` with a null `answerFormat` (also a null-check error). If
  you wrap survey_kit calls in `on Exception catch`, those clauses now match
  failures that previously escaped as hard crashes.
- CHANGE: `SurveyConfiguration.of`, `SurveyStateProvider.of` and
  `QuestionAnswer.of` throw `SurveyKitScopeException` in **release** builds too.
  Previously the check was an `assert`, so release builds raised a bare
  null-check error with no indication of the missing ancestor.
- CHANGE: `AnswerFormat.fromJson` throws `UnknownTypeException` instead of
  `Exception('Unknown type: ...')`. Its redundant debug-only
  `assert(type != null)` is removed; an absent `type` already fell through to
  the `default` branch, which throws in all modes. In debug that case previously
  raised an `AssertionError`.
- CHANGE: `TimeResult` throws `MalformedValueException` instead of
  `Exception('TimeOfDay cannot be ...')`.
- CHANGE: `SurveyKit` throws `UnsupportedTaskException` instead of
  `Exception('Task must be either OrderedTask or NavigableTask')`.
- CHANGE: four answer-view error messages named classes that do not exist
  (`MultiSelectAnswer`, `SingleSelectAnswer`). Messages are now generated from
  the actual types involved.
- NOTE: no change to which inputs are accepted or rejected. Every condition that
  failed before still fails; only the thrown type and its message changed.

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