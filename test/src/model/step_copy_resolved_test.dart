// copyResolved is the seam that keeps a resolved Step copy from downgrading a
// consumer's Step subclass. Every assertion here is about a field that a
// default would otherwise mask: isMandatory defaults to true and buttonText
// defaults to 'Next', so a dropped field still looks right in a naive test.
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_kit/survey_kit.dart';

/// A subclass that adds state and overrides the seam to stay itself.
class TypedStep extends Step {
  TypedStep({required super.id, required super.content, required this.marker});

  final String marker;

  @override
  Step copyResolved({
    required List<Content> content,
    required AnswerFormat? answerFormat,
  }) => TypedStep(id: id, content: content, marker: marker);
}

void main() {
  test('the base implementation carries every field forward', () {
    Widget shell(Step step, Widget? answerWidget, BuildContext context) =>
        answerWidget ?? const SizedBox();

    final step = Step(
      id: 'authored-id',
      content: const [TextContent(text: 'before')],
      isMandatory: false,
      buttonText: 'Continue',
      stepShell: shell,
    );

    final resolved = step.copyResolved(
      content: const [TextContent(text: 'after')],
      answerFormat: const TextAnswerFormat(),
    );

    expect(resolved.id, 'authored-id');
    expect(resolved.isMandatory, isFalse);
    expect(resolved.buttonText, 'Continue');
    expect(resolved.stepShell, same(shell));
    expect(resolved.answerFormat, isA<TextAnswerFormat>());
    expect((resolved.content.single as TextContent).text, 'after');
  });

  test('an overriding subclass keeps its own type and state', () {
    final resolved = TypedStep(
      id: 's1',
      content: const [TextContent(text: 'x')],
      marker: 'kept',
    ).copyResolved(content: const [], answerFormat: null);

    expect(resolved, isA<TypedStep>());
    expect((resolved as TypedStep).marker, 'kept');
  });
}
