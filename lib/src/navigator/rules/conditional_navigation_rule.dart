import 'package:survey_kit/src/exception/survey_kit_exception.dart';
import 'package:survey_kit/src/model/answer/text_choice.dart';
import 'package:survey_kit/src/model/result/step_result.dart';
import 'package:survey_kit/src/navigator/rules/navigation_rule.dart';

class ConditionalNavigationRule implements NavigationRule {
  /// Chooses the next step's id from the results so far.
  ///
  /// The `fromJson` factory supplies a pure closure over an authored value map,
  /// but this is a public constructor field: a rule built in Dart carries
  /// arbitrary consumer code. Like `NavigationRuleHandler`, it is invoked for
  /// read-only probes as well as real advances, with a **null** second argument
  /// on a probe, so it must be safe to re-run and free of side effects.
  final String? Function(List<StepResult>, StepResult?)
  resultToStepIdentifierMapper;

  /// The authored mapping, present only when this rule came from JSON.
  ///
  /// Null for a closure-built rule: that mapping is code, not data, and cannot
  /// be recovered. [toJson] throws rather than emit an empty map. The invariant
  /// is structural rather than documented — the only constructor that sets this
  /// is private, so `values != null` if and only if the rule was parsed.
  final Map<String, String>? values;

  /// Takes arbitrary consumer logic, which cannot be serialized. A rule built
  /// this way throws from [toJson].
  ConditionalNavigationRule({required this.resultToStepIdentifierMapper})
    : values = null;

  ConditionalNavigationRule._fromValues({
    required this.values,
    required this.resultToStepIdentifierMapper,
  });

  factory ConditionalNavigationRule.fromJson(Map<String, dynamic> json) {
    final inputValues = json['values'] as Map<String, dynamic>;
    // Entrywise, NOT `as Map<String, String>`. Whether that cast throws depends
    // on where the map came from, which was measured: a Dart map literal nested
    // in a Map<String, dynamic> reifies as _Map<String, String> and the cast
    // SUCCEEDS, while jsonDecode output reifies as _Map<String, dynamic> and
    // the same cast THROWS. Production always takes the second path, so the
    // cast would pass every literal-based test and fail every real survey.
    final values = inputValues.map(
      (key, value) => MapEntry(key, value as String),
    );
    return ConditionalNavigationRule._fromValues(
      // The SAME object the closure below captures, deliberately not a copy.
      // Sharing one map is the point: it is what makes the field and the
      // navigation behaviour impossible to diverge. `toJson` defends its own
      // output with a copy, which is where the aliasing risk actually is.
      values: values,
      resultToStepIdentifierMapper: (results, input) {
        if (input == null) return null;
        final answerValue = _extractValue(input.result);
        return values[answerValue];
      },
    );
  }

  static String? _extractValue(dynamic result) {
    if (result is TextChoice) return result.value;
    if (result is Map<String, dynamic>) return result['value']?.toString();
    return result?.toString();
  }

  @override
  Map<String, dynamic> toJson() {
    final authored = values;
    if (authored == null) {
      throw const UnserializableRuleException(
        ruleType: 'ConditionalNavigationRule',
      );
    }
    return <String, dynamic>{
      'type': 'conditional',
      'values': Map<String, String>.from(authored),
    };
  }
}
