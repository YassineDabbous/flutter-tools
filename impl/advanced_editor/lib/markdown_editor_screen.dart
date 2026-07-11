import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';
import 'package:markdown_editor_plus/markdown_editor_plus.dart';
import 'package:markdown_editor_plus/src/toolbar.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownEditorScreen extends StatefulWidget {
  const MarkdownEditorScreen({super.key, required this.initial});
  final String initial;

  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen> {
  bool preview = false;

  final TextEditingController _textEditorController = TextEditingController();

  // ValueNotifier<String> s = ValueNotifier('');

  @override
  void initState() {
    _textEditorController.text = widget.initial;
    // s.value = widget.initial;
    // _textEditorController.addListener(() {
    //   s.value = _textEditorController.text;
    // });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'edit content'.i18n(),
        ), // ${isSupported ? "" : "(${'html editor not supported on this plateform'.i18n()}.)"}
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () async {
              Navigator.of(context).pop<String>(_textEditorController.text);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // SplittedMarkdownFormField(
            //   controller: _textEditorController,
            //   minLines: 4,
            // ),
            // MarkdownAutoPreview(
            //   controller: _textEditorController,
            //   emojiConvert: false,
            //   minLines: 6,
            // ),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.code),
                  label: Text('write'.i18n()),
                  onPressed: !preview
                      ? null
                      : () => setState(() => preview = false),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.preview),
                  label: Text('preview'.i18n()),
                  onPressed: preview
                      ? null
                      : () => setState(() => preview = true),
                ),
                if (!preview)
                  Expanded(
                    child: DraggableScroll(
                      child: MarkdownToolbar(
                        showPreviewButton: false,

                        // emojiConvert: false,
                        // showEmojiSelection: false,
                        controller: _textEditorController,
                        toolbar: Toolbar(controller: _textEditorController),
                      ),
                    ),
                  ),
              ],
            ),
            if (!preview)
              MarkdownField(
                controller: _textEditorController,
                emojiConvert: false,
                minLines: 20,
                decoration: InputDecoration(
                  hintText: 'type here'.i18n(),
                  isDense: true,
                ),
              ),
            if (preview) MarkdownBody(data: _textEditorController.text),

            // MarkdownWidget(
            //   markdown: _textEditorController.text,
            // ),

            // ValueListenableBuilder(
            //   valueListenable: s,
            //   builder: (context, value, child) => MarkdownBody(
            //     data: value.toString(),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
