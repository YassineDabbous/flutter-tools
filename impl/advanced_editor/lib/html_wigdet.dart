import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:flutter_markdown/flutter_markdown.dart';

class HtmlWidget extends StatelessWidget {
  final String html;
  final double? size;
  const HtmlWidget({super.key, required this.html, this.size});

  @override
  Widget build(BuildContext context) {
    //return Text(html);
    return MarkdownBody(
      selectable: true,
      data: html2md.convert(html),
      styleSheet: MarkdownStyleSheet(
        p: size == null
            ? null
            : context.textTheme.bodyMedium?.copyWith(fontSize: size!),
      ),
    );
  }
}
