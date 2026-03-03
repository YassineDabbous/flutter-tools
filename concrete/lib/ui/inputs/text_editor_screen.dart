import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';

class TextEditorScreen extends StatelessWidget {
  TextEditorScreen({super.key, required this.initial}) {
    _textEditorController.text = initial;
  }
  final String initial;
  final TextEditingController _textEditorController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('edit content'.i18n()),
        centerTitle: true,
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () {
              Navigator.of(context).pop<String>(_textEditorController.text);
            },
          ),
        ],
      ),
      // body: SizedBox(
      //   child: TextInput(
      //     padding: const EdgeInsets.all(8),
      //     expands: true,
      //     initialValue: initial,
      //     controller: _textEditorController,
      //     hint: 'Enter a description',
      //     leading: const Icon(Icons.edit),
      //   ),
      // ),
      body: TextField(
        controller: _textEditorController,
        textAlignVertical: TextAlignVertical.top,
        expands: true,
        maxLines: null,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
          hintText: 'write here'.i18n(),
        ),
      ),
    );
  }
}
