import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownWidget extends StatefulWidget {
  final TextStyle? style;
  final String? markdown;
  final TextEditingController? controller;
  const MarkdownWidget({super.key, this.controller, this.markdown, this.style})
    : assert(controller != null || markdown != null);

  @override
  State<MarkdownWidget> createState() => _MarkdownWidgetState();
}

class _MarkdownWidgetState extends State<MarkdownWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //return Text(markdown);
    return MarkdownBody(data: widget.controller?.text ?? widget.markdown!);
    // return MarkdownAutoPreview(
    //   controller: widget.controller ?? (TextEditingController()..text = widget.markdown!),
    //   style: widget.style,
    //   emojiConvert: true,
    //   readOnly: true,
    // );
  }
}
