import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:survey_kit/src/model/content/html_content.dart';

class HtmlWidget extends StatelessWidget {
  const HtmlWidget({
    super.key,
    required this.htmlContent,
  });

  final HtmlContent htmlContent;

  @override
  Widget build(BuildContext context) {
    return Html(data: htmlContent.html,
      extensions: const [
        TableHtmlExtension(),
      ],
    style: {
      'table': Style(
        backgroundColor: const Color.fromARGB(0x50, 0xee, 0xee, 0xee),
      ),
      // 'tr': Style(
      //   border: const Border(left: BorderSide(color: Colors.grey), top: BorderSide(color: Colors.grey),bottom: BorderSide(color: Colors.grey)),
      // ),
      'th': Style(
        padding: HtmlPaddings.all(6),
        verticalAlign: VerticalAlign.middle,
        backgroundColor: Colors.grey,
      ),
      'td': Style(
        verticalAlign: VerticalAlign.middle,
        padding: HtmlPaddings.all(6),
        border: const Border(left: BorderSide(color: Colors.grey, width: 0.5), right: BorderSide(color: Colors.grey, width: 0.5),
          top: BorderSide(color: Colors.grey),bottom: BorderSide(color: Colors.grey),
        ),
      )
    },);
  }
}
