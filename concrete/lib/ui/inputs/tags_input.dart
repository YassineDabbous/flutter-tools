import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';

// https://pub.dev/packages/textfield_tags
class TextFieldTags extends StatefulWidget {
  final List<String>? initial;
  final Function(List<String>) onChanges;
  final String? Function(String tag)? tagValidator;
  final String? hint;
  final String? errorText;
  final List<String> textSeparators;

  const TextFieldTags({
    super.key,
    this.tagValidator,
    this.initial,
    this.hint,
    this.errorText,
    this.textSeparators = const [' ', ','],
    required this.onChanges,
    // this.textfieldTagsController,
  });

  @override
  createState() => _TextFieldTagsState();
}

class _TextFieldTagsState extends State<TextFieldTags> {
  final FocusNode focusNode = FocusNode();
  final TextEditingController textCtrl = TextEditingController();
  final ScrollController sc = ScrollController();

  List<String> tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      tags = widget.initial!;
    }
  }

  List<String> errors = [];
  bool _onTagOperation(String tag) {
    if (tag.isNotEmpty) {
      if (tags.contains(tag)) {
        errors.add(tag + ' exists'.i18n());
        return false;
      } else {
        final error = widget.tagValidator != null
            ? widget.tagValidator!(tag)
            : null;
        if (error != null) {
          errors.add(error);
          return false;
        }
        tags.add(tag);
        return true;
      }
    }
    return false;
  }

  void _onTagDelete(String tag) {
    tags.remove(tag);
    setState(() {});
    widget.onChanges(tags);
  }

  void onSubmitted(String value) {
    errors.clear();
    final separator = widget.textSeparators.firstWhere(
      (element) => value.contains(element) && value.indexOf(element) != 0,
      orElse: () => ',',
    );
    final splits = value.split(separator).map((e) => e.trim()).toList()
      ..removeWhere((element) => element.isEmpty);
    if (splits.isNotEmpty) {
      var i = 0;
      List<String> refusedList = [];
      while (i < splits.length) {
        if (!_onTagOperation(splits[i])) {
          refusedList.add(splits[i]);
        }
        i++;
      }

      if (refusedList.isEmpty) {
        textCtrl.clear();
        // sc.animateTo(sc.position.maxScrollExtent, duration: const Duration(milliseconds: 100), curve: Curves.linear);
      } else {
        textCtrl.text = refusedList.join(separator);
      }
      if (i > 0) {
        widget.onChanges(tags);
      }
      setState(() {});
    }
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return TextField(
          // onChanged: onChanged,
          onSubmitted: onSubmitted,
          controller: textCtrl,
          focusNode: focusNode,
          decoration: InputDecoration(
            isDense: true,
            border: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color.fromARGB(255, 74, 137, 92),
                width: 3.0,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color.fromARGB(255, 74, 137, 92),
                width: 3.0,
              ),
            ),
            labelText: tags.isNotEmpty ? '' : widget.hint,
            hintText: widget.hint,
            errorText: errors.join(', '),
            prefixIconConstraints: BoxConstraints(
              maxWidth: constraints.maxWidth * 0.75,
            ),
            prefixIcon: tags.isNotEmpty
                ? SingleChildScrollView(
                    controller: sc,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: tags.map((String tag) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12.0),
                            ),
                            color: context.colorScheme.primary,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 3.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tag,
                                style: TextStyle(
                                  color: context.colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              InkWell(
                                child: Icon(
                                  Icons.cancel,
                                  size: 14.0,
                                  color: context.colorScheme.onPrimary,
                                ),
                                onTap: () => _onTagDelete(tag),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
