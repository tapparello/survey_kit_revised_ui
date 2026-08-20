# 1.0.0-dev.22

- **BREAKING: `OrderedTask.toJson()`'s output shape changes.** `initialStep` (a
  whole nested `Step`) and `hashCode` are gone; `type` and `initialStepId` are
  new. The old output could never be read back — `fromJson` reads
  `initialStepId` and the writer emitted `initialStep`, so the two keys never
  met — which is why nothing consumed it. Both task writers now go through one
  shared `Task.baseJson` helper, so they cannot drift apart again.
- **BREAKING: `ConditionalNavigationRule.toJson()` throws on a closure-built
  rule.** It previously returned `{'values': {}}`, which does not merely lose
  the mapping but asserts there was none: a rule that navigated correctly
  round-tripped into one that navigates nowhere. A rule parsed from JSON now
  retains its authored mapping in a new `values` field and serializes properly;
  a rule built from the public closure constructor throws
  `UnserializableRuleException`, because arbitrary Dart code is not data. The
  closure constructor itself is unchanged.
- **BREAKING: `UnserializableRuleException` is a new `SurveyKitException`
  subtype.** The hierarchy is sealed, so an exhaustive `switch` over it needs a
  new case.
- **BREAKING: `NavigableTask.toJson()`'s output shape changes.** With zero
  navigation rules the old writer produced `{'id', 'steps',
  'navigationRules': {}}`; that key is gone and `id`/`steps` are now joined by
  four new ones. It previously emitted live `NavigationRule` objects in a map,
  under a key its own reader never looked at; `jsonEncode` threw as soon as any
  rule was present. Rules are now emitted as the list `fromJson` reads, each
  carrying the `triggerStepIdentifier` that only the map key used to hold. It
  also emits `initialStepId`, `variables` and `stepCount`, all of which it
  silently dropped.
- **`ConditionalNavigationRule.fromJson` now rejects a non-String destination at
  parse time.** It previously deferred the check to navigation, so a rule
  authored as `{"values": {"yes": 2}}` loaded fine and threw only if the user
  reached that answer. It now fails when the task loads. Every authored
  conditional rule surveyed uses quoted string step ids, so this is expected to
  be unreachable in practice; it is listed because it is a change in what a
  public reader accepts.
- **`Task.fromJson(task.toJson())` now works** for both task types. Neither
  writer emitted the `type` discriminator the dispatcher reads, so feeding a
  task's own output back in threw `UnknownTypeException`. (ADO #1052, #1007)
- **`DirectNavigationRule.toJson()` emits its `type` discriminator.** Without
  it, `NavigationRule.fromJson` could not dispatch on the second most common
  rule type in authored surveys.
- `Task.toJson()` now returns a shallow copy of `variables` rather than the task's
  own map, so a caller cannot replace or remove a top-level entry through the
  serialized output. The copy is one level deep: `variables` is
  `Map<String, dynamic>`, so a nested map or list is still shared, and mutating
  one through `task.toJson()['variables']` does reach the task.
- Two generated writers are deleted (`ordered_task.g.dart`,
  `direct_navigation_rule.g.dart`), both replaced by hand-written ones. The
  latter also carried a dead generated reader that nothing called.
- For a `NavigableTask` that has been run, `toJson()['variables']` now contains
  engine and action-handler scratch alongside authored variables — specifically
  `_currentStepId`, which the navigator writes whenever it evaluates a
  `CustomNavigationRule` — including on read-only probes, since
  `peekNextStep` goes through the same path, which is why it can appear
  without the user having advanced — and which `SurveyRegistries`'
  custom-rule contract documents. `variables` was
  never emitted before this release, so there was nowhere for that state to
  leak; it is reachable now. Serializing a task definition is therefore best
  done before a run, not after one — and if any `variables` value is not
  JSON-encodable (a `DateTime`, say), `jsonEncode` will throw on the result.
  Moving engine state off `task.variables` is tracked separately.

# 1.0.0-dev.21

- **BREAKING: `ContentFactory` and `StepFactory` gain a `registries` parameter.**
  Every `customContentTypes` / `customStepTypes` entry changes from
  `(json) => Foo.fromJson(json)` to `(json, {registries}) => Foo.fromJson(json)`.
  Dart function subtyping tolerates extra optional named parameters but not
  missing ones, so this is a compile error rather than a silent mismatch. The
  parameter exists so a custom type can resolve nested content —
  `Content.fromJson(json['child'], registries: registries)` — including other
  custom types, to any depth. `variables` is **not** part of the parse contract;
  Phase 3d removed it.
- **A custom factory must parse its children, not itself.** `resolveContent` and
  `resolveStep` forward the registries they were called on, which is what lets
  custom types nest to any depth. It also means a factory that re-enters
  `Content.fromJson` or `Step.fromJson` with the *same* JSON map hits the same
  registry entry again and recurses without bound. There is no depth guard, by
  the same choice made for renderers: register a factory that constructs its
  type directly, and call `fromJson` only on nested values. Passing a
  dispatching `fromJson` as its own handler is the trap — it terminated before
  this release only because the factory received no registries to recurse with.
- **BREAKING: `Content.createWidget` is deleted.** A `Content` subclass that
  rendered itself now registers a renderer in `SurveyRegistries.contentRenderers`,
  keyed by the same JSON discriminator it parses under. A registered content type
  with no renderer throws `UnregisteredRendererException` when it is rendered.
  A renderer is a `Widget Function(Content content, ContentRenderContext context)`;
  the `variables` and `contentStyles` that `createWidget` received as named
  parameters are now `context.variables` and `context.contentStyles`, and
  `context.render` renders a nested `Content`.
- **BREAKING: `AnswerFormat.createView` is deleted.** The 14 built-in answer
  views moved to an internal table keyed by `AnswerFormatType`. There is no
  override map: answer discriminators are a closed set.
  A consumer-defined `AnswerFormat` subclass can therefore no longer supply its
  own view: it resolves to the built-in view for whichever `AnswerFormatType` its
  `answerType` returns, which throws `AnswerFormatMismatchException` at render
  time rather than failing to compile. Custom *content* remains the extension
  point.
- **Nested rendering is preserved, not lost.** `createWidget` let any `Content`
  render any other, because it was a method on the base class. Registered
  renderers get the same reach through `ContentRenderContext.render`, which
  resolves through the registry the renderer itself came from. There is no cycle
  guard — content that renders itself overflows the stack, as before.
- **Consumers can now override a built-in renderer.** `contentRenderers` is
  consulted before the built-in table, the same precedence `Content.fromJson`
  already uses for parsers.
  An override replaces the built-in rather than wrapping it: the built-in table
  is not exported, so a renderer cannot delegate to the one it shadows. Reaching
  built-in renderers for nested *children* still works through `context.render`.
- **No file under `lib/src/model/` builds a widget.** 25 renderers moved out, and
  `test/src/model/layering_test.dart` pins five import routes shut — including
  the public barrel, which re-exports the answer views and content widgets,
  and `src/survey_kit.dart`, which `step.dart` imported for one typedef.
  `TimeOfDay`, `BoxFit` and `TextAlign` remain as model *fields*; replacing
  those held Flutter value types is a follow-up item.
- `typedef StepShell` moves to `lib/src/configuration/step_shell.dart`. Still
  exported from the barrel under the same name and signature — no consumer change.

# 1.0.0-dev.20

- **BREAKING: `Step.fromJson` and `AnswerFormat.fromJson` lose their `variables`
  parameter.** Conditional answer formats no longer resolve at parse time, so
  parsing no longer needs the variables map. `Task.fromJson` is unchanged and
  the `task.variables` field is unchanged; only these two signatures shrink.
  Call `Task.fromJson`, as every consumer already does, and nothing changes.
- **BREAKING: a conditional answer format now validates *every* variant when the
  task loads, not just the selected one.** Previously only the variant a
  directive actually selected was parsed, so a malformed variant that was never
  chosen was inert dead JSON. It now throws at `Task.fromJson`. This is what
  makes selection total: by the time a step is presented, resolution is a map
  lookup that cannot fail.
- **BREAKING: a conditional answer format may no longer nest inside another
  conditional's `variants` map.** Previously, nested conditionals resolved
  recursively during parse-time resolution; now every variant is parsed eagerly
  as a concrete `AnswerFormat`, and since `conditional` is no longer an accepted
  concrete type, nested directives throw `MalformedValueException` at task load.
- **BREAKING (behaviour): conditional content resolves once per presentation
  instead of once per rebuild.** Step answers only change at submission, which
  pushes a new state, and `ActionContext.variables` writes are contracted as
  "visible to the next step", so the two normally coincide. Two things still
  diverge: a step whose content branches on its *own* live answer, which
  previously updated as the user answered and now resolves once on entry; and a
  `CustomNavigationRule` handler that derives variables — `NavigationRuleHandler`
  is explicitly sanctioned to do this, and `StepView.build` calls `hasNextStep`
  on every render, which reaches the handler through `peekNextStep`, writing
  into `task.variables`, the same map instance as `SurveyConfiguration.variables`.
  Before this branch, `ContentWidget.build` ran later in the same frame and saw
  those writes; now the step's content is resolved and frozen before `StepView`
  builds. Not a regression for this package's own consumer: rule-derived keys
  there are read only through `{{...}}` interpolation, which still re-resolves
  on every rebuild.
- **A recorded `StepResult` can outlive the format that produced it.**
  Resolution now runs on every presentation, including back-navigation, so a
  step whose format branches on an earlier answer can resolve to a different
  `AnswerFormat` after the user changes that earlier answer via Back. Nothing
  invalidates a `StepResult` recorded under the step's previous resolution: if
  the restored value is rejected by the new view (e.g. `int.tryParse` fails on
  a string typed under the old, text, resolution) `onChange` never fires, and if
  the step is not mandatory the user can still press Next with
  `questionAnswer.stepResult == null` — `SurveyEngine.addResult(null)` returns
  early, so the stale result recorded under the old format survives into the
  delivered `SurveyResult`. Not a coding defect; it is inherent to letting a
  format branch on a mutable earlier answer, and it is new to this branch:
  parse-time resolution could never change mid-run.
- **`PresentingSurveyState` equality weakens for conditional steps.** It compares
  `currentStep` by reference, and a conditional step is now a fresh resolved copy
  per presentation, so two states for the same conditional step no longer compare
  equal. Ordinary steps are unaffected. Not a change anything in this package
  consumes; tracked separately along with three pre-existing defects in that
  equality.
- NEW: `Step.conditionalAnswerFormat` holds a validated but unresolved
  `ConditionalAnswerFormat`. `Step.answerFormat` and it are mutually exclusive,
  and `answerFormat` stays **concrete** wherever a view or a result sees it —
  the directive is deliberately not an `AnswerFormat` and not an
  `AnswerFormatType` member.
- **Conditional answer formats now resolve against a live, mutating map.**
  `task.variables` also receives internal bookkeeping writes — `_currentStepId`,
  written by `NavigableTaskNavigator._evaluateCustomRule`. Conditional *content*
  already read that live map, so this is not new in kind, but it is the first
  time an answer format reads it rather than a snapshot frozen at parse.
- NEW: `Step.copyResolved` is the seam a resolved copy is built through. Override
  it in a `Step` subclass that adds state, or the copy downgrades to a plain
  `Step` and that state is lost; the engine logs a warning when that happens.
  Subclasses with no conditional content and no conditional answer format never
  reach it.
- FIX: `TaskNavigator.currentStepIndex` compares steps by id instead of by
  identity, so it can no longer return `-1` for a step read back out of
  `PresentingSurveyState`. This also fixes the exported
  `SurveyStateProvider.currentStepIndex` passthrough.
- **BREAKING (behaviour): the exported `ContentWidget` no longer resolves
  conditional content.** It takes a bare `List<Content>` and now expects it to
  already be resolved — resolution happens once, in `SurveyEngine`, before a
  step reaches the widget tree. A consumer constructing `ContentWidget` directly
  outside the engine's path (a preview screen, say) must resolve
  `ConditionalContent` itself first, or a conditional branch renders as
  `SizedBox.shrink()`.

# 1.0.0-dev.19

- **BREAKING: `SurveyStateProvider` loses its public `onResult`, `navigatorKey`
  and `localizations` fields.** All three now live on `SurveyKit`'s `State`,
  which is what reaches the widget layer on the engine's behalf; nothing outside
  the package read them from the provider. They were public, so their removal is
  a break. The `@internal` constructor also swaps `session:` for `engine:` and
  drops those three arguments; that part is not a published break, the
  constructor was already internal.
- NEW (internal): the survey state machine moved out of the widget layer into
  `lib/src/engine/`. `SurveyEngine` owns the state, the stream, the results, the
  start time and the in-flight flag, and reaches the widget layer only through a
  `SurveyHost` port implemented by `SurveyKit`'s `State`. None of it is
  exported. The former internal `SurveySession` is absorbed and removed.
- FIXED: the app-bar Cancel button is no longer painted while the survey is
  still starting up. `CloseSurvey` is gated on a presented step, so the button
  was inert for the whole startup window — which 1.0.0-dev.18 lengthened to
  include the awaited replay of every action handler on a resumed path. It is
  hidden until the first step is presented, mirroring the app bar's own Back
  button, and remains visible after the survey terminates. Consumers setting
  `showCloseButton: false` are unaffected.
- `onResult` and `localizations` are now resolved when they are used — when the
  result is delivered, and when the feedback dialog is shown — rather than
  captured when the survey starts. A consumer that rebuilds with a different
  callback or a different localization map gets the current one. Unobservable
  for a consumer whose callback and map are the same on every build.
- The answer-feedback dialog's colour is now chosen in the widget layer from a
  semantic tone rather than in the presenter from a `Color`. The three rendered
  outcomes are unchanged. (ADO #1041)

# 1.0.0-dev.18

- **BREAKING: `ActionHandler` is now
  `Future<void> Function(ActionContext context)`.** It was
  `void Function(List<StepResult>, Map<String, dynamic>)`. Rewrite each handler
  to read `context.results` and `context.variables`; a handler with no
  asynchronous work is written `(ctx) async {}`. `Future<void>` rather than
  `FutureOr<void>` is deliberate: `void` is a top type, so `FutureOr<void>`
  would have accepted a statement-bodied handler that is silently never
  awaited. (ADO #1040)
- **BREAKING: `TaskNavigator.nextStep` returns `Future<Step?>`, loses
  `recordStep`, and gains `ActionTrigger trigger`.** It now always records the
  step and always fires the action. The read-only probe moved to the new
  synchronous `TaskNavigator.peekNextStep`, which does neither — subclasses
  outside this package must implement it.
- **BREAKING: `SurveyStateProvider.onEvent` and `SurveyController.nextStep` /
  `.stepBack` / `.closeSurvey` return `Future<void>`.** Source-compatible for
  callers that ignore the return value.
- NEW: `SurveyKit(onHandlerError:)`, typed `SurveyHandlerErrorCallback`, reports
  a failed action handler, an unregistered action id, or a throwing custom
  navigation rule handler. Navigation proceeds either way. When unset, failures
  are logged at error level. Previously an async handler's failure reached the
  top-level zone and **nothing was logged at all**.
- NEW: `SurveyHandlerFailure` (`kind`, `handlerId`, `error`, `stackTrace`,
  `trigger`) and `SurveyHandlerKind` (`action`, `navigationRule`) — the payload
  of that callback.
- NEW: `UnregisteredActionException`, a new member of the sealed
  `SurveyKitException` hierarchy. A `switch` over that hierarchy with no
  `default` will need a new arm.
- NEW: `ActionContext` and `ActionTrigger`. `trigger` distinguishes
  `ActionTrigger.advance` from `ActionTrigger.replay`, so a handler can decide
  whether resuming a survey past its rule should re-run its side effect.
- NEW: `SurveyStateProvider.isAdvancing`, a `ValueListenable<bool>` a host can
  render a progress affordance from.
- BUGFIX: the survey no longer presents a step before the action that feeds it
  has finished. A handler that writes `variables` after its first `await` used
  to race the step that renders them.
- BUGFIX: a feedback dialog dismissed with the hardware back button now
  advances the survey. It previously stranded the user on the step.
- BUGFIX: a `CustomNavigationRule` handler that throws no longer propagates; it
  is reported and navigation falls back to the next step in the list.
- CHANGE: the action fires *after* the feedback dialog is acknowledged rather
  than concurrently with it, so awaiting it does not delay the dialog.
- CHANGE: `firstStep()` no longer re-fires an action or double-records
  `history.last` for the step it resumes from — it now probes via
  `peekNextStep` rather than advancing. A second `StartSurvey` dispatch is
  still not fully clean, though: `_handleInitialStep`'s replay loop walks the
  path to that step regardless, firing its action once more (as
  `ActionTrigger.replay`) and recording it a second time. Still an
  improvement — before this change, the same sequence double-fired the
  action and triple-recorded the step.
- CHANGE: a `CustomNavigationRule` handler that throws is now reported
  through `onHandlerError` on every rebuild of its trigger step, not once —
  `StepView` calls `hasNextStep` on every build, and that path reaches the
  handler through `peekNextStep`. Previously such a throw propagated out of
  `build` loudly, and only once. The destination still falls back to the
  next step in the list.

**Migrating is not purely mechanical, and a changelog cannot tell you the
substantive half.** Rewriting the lambdas is uniform. Deciding which handlers
need `if (ctx.trigger == ActionTrigger.replay) return;` is not: it depends on
whether each action rule's trigger step has steps after it in its own task, and
therefore whether a resume can replay across it. Audit your rules; a handler
whose effect is a side effect (writing a file, inserting a row) almost always
wants the short-circuit, and one that populates a variable a later step renders
must not have it.

# 1.0.0-dev.17

- **BREAKING: `SurveyStateProvider(...)` drops `results:` and requires
  `session:`; the constructor is now `@internal`.** External code can no
  longer construct `SurveyStateProvider` directly — only `SurveyKit` builds
  one now. `SurveyStateProvider.of` and every accessor on it (`state`,
  `results`, `startDate`, `surveyStateStream`, `getStepResultById`,
  `updateState`) are unchanged and still public. (ADO #1033)
- **BREAKING: `QuestionAnswer(...)` drops `step:` and requires `session:`;
  the constructor is now `@internal`.** External code can no longer
  construct `QuestionAnswer` either — for example to wrap a custom answer
  view in a test. `QuestionAnswer.of` and every accessor on it (`step`,
  `startTime`, `isValid`, `stepResult`, `setIsValid`, `setStepResult`) are
  unchanged and still public. Use a full `SurveyKit` with `stepShell` to
  inject a widget into the survey subtree instead — see
  `test/api_surface_test.dart` for the pattern.
- **BREAKING: `results`, `surveyStateStream` and `startDate` are getters,
  not fields.** Their implicit setters are gone. Both widgets' mutable state
  moved to `SurveySession` and `AnswerSession`, owned by `_SurveyKitState`
  and `_AnswerViewState` respectively, so a parent rebuild no longer resets
  them.
- BUGFIX: a parent rebuild of `SurveyKit` no longer resets the survey
  session. This previously froze the survey permanently — Next, Back and
  save-and-close all became no-ops and `onResult` never fired.
- BUGFIX: a parent rebuild no longer discards the in-progress answer. This
  previously advanced the survey with a null result, defeating
  mandatory-step gating.
- BUGFIX: the leaked `StreamController` behind `surveyStateStream` is now
  closed when `SurveyKit` is disposed.
- CHANGE: `initialResults` is read once at mount and copied, not aliased.
  The library no longer mutates the caller's `Set`, and
  `SurveyKit(initialResults: Set.unmodifiable(...))` no longer crashes on
  the first answer.
- CHANGE: `results` is now one `Set` for the whole survey, aliased into
  every `PresentingSurveyState.questionResults` and so into
  `surveyStateStream`. Previously each parent rebuild handed out a fresh
  set. `onResult`'s payload is unaffected — it still receives a copy via
  `.toList()`.
- CHANGE: a feedback dialog straddling a parent rebuild now completes
  correctly.

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