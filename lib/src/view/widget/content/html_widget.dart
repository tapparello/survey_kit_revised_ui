import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:survey_kit/src/model/content/html_content.dart';

class HtmlWidget extends StatelessWidget {
  const HtmlWidget({
    super.key,
    required this.htmlContent,
  });

  final HtmlContent htmlContent;

  @override
  Widget build(BuildContext context) {
    return Html(data: htmlContent.html);
  }
}
