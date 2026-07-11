import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:flutter/foundation.dart';

import 'dart:io';

class HtmlEditorScreen extends StatelessWidget {
  final bool isSupported = kIsWeb || Platform.isAndroid || Platform.isIOS;
  HtmlEditorScreen({super.key, required this.initial}) {
    if (!isSupported) {
      _textEditorController.text = initial;
    }
  }
  final String initial;
  final HtmlEditorController _htmlEditorController = HtmlEditorController();
  final TextEditingController _textEditorController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'edit content'.i18n() +
              (isSupported
                  ? ""
                  : "(Html editor not supported on this plateform.)"),
        ),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () async {
              //_htmlEditorController.setFullScreen();
              if (isSupported) {
                Navigator.of(
                  context,
                ).pop<String>(await _htmlEditorController.getText());
              } else {
                Navigator.of(context).pop<String>(_textEditorController.text);
              }
            },
          ),
        ],
      ),
      body: Container(
        child: !isSupported
            ? TextInput(
                padding: const EdgeInsets.all(8),
                expands: true,
                initialValue: initial,
                controller: _textEditorController,
                hint: 'write here'.i18n(),
                leading: const Icon(Icons.edit),
              )
            : HtmlEditor(
                controller: _htmlEditorController, //required
                htmlEditorOptions: HtmlEditorOptions(
                  hint: "write here".i18n(),
                  initialText: initial,
                ),
                htmlToolbarOptions: const HtmlToolbarOptions(
                  initiallyExpanded: true,
                  defaultToolbarButtons: [FontButtons()],
                  toolbarPosition: ToolbarPosition.belowEditor,
                  // toolbarType: ToolbarType.nativeExpandable,
                ),

                otherOptions: OtherOptions(
                  height:
                      MediaQuery.of(context).size.height -
                      112, // 56* 2 (appbar + toolbar)
                ),
              ),
      ),
    );
  }
}
