import 'package:json_annotation/json_annotation.dart';
import 'package:survey_kit/src/model/answer/answer_format.dart';
import 'package:survey_kit/src/model/answer/answer_format_type.dart';

part 'date_answer_format.g.dart';

@JsonSerializable()
class DateAnswerFormat extends AnswerFormat {
  /// Default date which will be preselected on datepicker opening
  final DateTime? defaultDate;

  /// Lowest date which can be selected via the datepicker
  final DateTime? minDate;

  /// Highest date which can be selected via the datepicker
  final DateTime? maxDate;

  /// When true, only today and future dates can be selected (e.g. a reminder
  /// date). Without an explicit [maxDate] the picker otherwise defaults to a
  /// past-only range, so this opts a step into a future range instead.
  final bool futureOnly;

  DateAnswerFormat({
    this.defaultDate,
    this.minDate,
    this.maxDate,
    this.futureOnly = false,
    super.question,
  }) : assert(
         minDate == null || maxDate == null || minDate.isBefore(maxDate),
         'mindate must be before maxdate',
       ),
       assert(
         defaultDate == null ||
             minDate == null ||
             defaultDate.isAtSameMomentAs(minDate) ||
             defaultDate.isAfter(minDate),
         'defaultDate must be after minDate',
       ),
       assert(
         defaultDate == null ||
             maxDate == null ||
             defaultDate.isAtSameMomentAs(maxDate) ||
             defaultDate.isBefore(maxDate),
         'defaultDate must be before maxDate',
       ),
       super();

  @override
  @JsonKey(name: 'type', includeToJson: true, includeFromJson: false)
  AnswerFormatType get answerType => AnswerFormatType.date;

  factory DateAnswerFormat.fromJson(Map<String, dynamic> json) =>
      _$DateAnswerFormatFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DateAnswerFormatToJson(this);
}
