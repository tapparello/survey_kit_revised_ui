import 'package:flutter/material.dart';
import 'package:survey_kit/src/model/content/separator_content.dart';

class SeparatorWidget extends StatelessWidget {
  const SeparatorWidget({
    super.key,
    required this.separatorContent,
  });

  final SeparatorContent separatorContent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: separatorContent.height,
    );
  }
}
