import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/answer/answer_format.dart';
import 'package:survey_kit/src/model/answer/boolean_answer_format.dart';
import 'package:survey_kit/src/model/answer/date_answer_format.dart';
import 'package:survey_kit/src/model/answer/double_answer_format.dart';
import 'package:survey_kit/src/model/answer/image_answer_format.dart';
import 'package:survey_kit/src/model/answer/integer_answer_format.dart';
import 'package:survey_kit/src/model/answer/multiple_choice_answer_format.dart';
import 'package:survey_kit/src/model/answer/multiple_choice_answer_with_feedback_format.dart';
import 'package:survey_kit/src/model/answer/multiple_choice_auto_complete_answer_format.dart';
import 'package:survey_kit/src/model/answer/multiple_double_answer_format.dart';
import 'package:survey_kit/src/model/answer/scale_answer_format.dart';
import 'package:survey_kit/src/model/answer/single_choice_answer_format.dart';
import 'package:survey_kit/src/model/answer/single_choice_answer_with_feedback_format.dart';
import 'package:survey_kit/src/model/answer/text_answer_format.dart';
import 'package:survey_kit/src/model/answer/time_answer_format.dart';

/// The complete set of built-in [AnswerFormat] discriminators.
///
/// This enum *is* the dispatch table. A member cannot exist without a
/// [fromJson] factory, and [AnswerFormat.answerType] returns this type — so a
/// fifteenth format cannot compile without being registered here, and
/// `StepResult._convert`'s switch cannot compile without handling it.
///
/// Every member carries its wire string **twice**, and both are required:
///
/// * [JsonValue] is read by json_serializable at build time and produces the
///   generated `_$AnswerFormatTypeEnumMap`, which is private to each `.g.dart`
///   that uses it. It is what makes each format's generated `toJson` emit the
///   right string **without** a per-subclass `toJson:` converter — and
///   `JsonKey` annotations are not inherited, so a converter would be
///   forgettable in exactly the way that caused ADO #1001 and #1012.
/// * [wireName] is the same string reachable at runtime, which the generated
///   map is not. [byWireName] drives the dispatch in [AnswerFormat.fromJson],
///   which is not a `@JsonSerializable` class and has no generated file at all.
///
/// Dart cannot read annotations at runtime, so neither can be derived from the
/// other. `answer_format_type_test.dart` pins them together.
enum AnswerFormatType {
  @JsonValue('bool')
  boolean('bool', BooleanAnswerFormat.fromJson),
  @JsonValue('date')
  date('date', DateAnswerFormat.fromJson),
  // Named `doubleValue`, not `double`: a member named `double` would shadow the
  // `double` type inside this enum's own scope.
  @JsonValue('double')
  doubleValue('double', DoubleAnswerFormat.fromJson),
  @JsonValue('integer')
  integer('integer', IntegerAnswerFormat.fromJson),
  @JsonValue('image')
  image('image', ImageAnswerFormat.fromJson),
  @JsonValue('text')
  text('text', TextAnswerFormat.fromJson),
  @JsonValue('time')
  time('time', TimeAnswerFormat.fromJson),
  @JsonValue('scale')
  scale('scale', ScaleAnswerFormat.fromJson),
  @JsonValue('single')
  single('single', SingleChoiceAnswerFormat.fromJson),
  @JsonValue('single_with_feedback')
  singleWithFeedback(
    'single_with_feedback',
    SingleChoiceAnswerWithFeedbackFormat.fromJson,
  ),
  @JsonValue('multi')
  multi('multi', MultipleChoiceAnswerFormat.fromJson),
  @JsonValue('multi_with_feedback')
  multiWithFeedback(
    'multi_with_feedback',
    MultipleChoiceAnswerWithFeedbackFormat.fromJson,
  ),
  @JsonValue('multiple_auto_complete')
  multipleAutoComplete(
    'multiple_auto_complete',
    MultipleChoiceAutoCompleteAnswerFormat.fromJson,
  ),
  @JsonValue('multiple_double')
  multipleDouble('multiple_double', MultipleDoubleAnswerFormat.fromJson);

  const AnswerFormatType(this.wireName, this.fromJson);

  /// The JSON `type` value, reachable at runtime.
  final String wireName;

  /// Builds the concrete format from its JSON object.
  final AnswerFormat Function(Map<String, dynamic> json) fromJson;

  static final Map<String, AnswerFormatType> _byWireName = {
    for (final member in AnswerFormatType.values) member.wireName: member,
  };

  /// The member for [name], or null when [name] is null or unrecognised.
  static AnswerFormatType? byWireName(String? name) =>
      name == null ? null : _byWireName[name];

  /// The wire string for [type], or null when [type] is null.
  ///
  /// Public because `StepResult`'s `JsonKey(toJson:)` names it from another
  /// library — each answer-format file is its own library, so a private helper
  /// would not resolve.
  static String? wireNameOf(AnswerFormatType? type) => type?.wireName;
}
