import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TranslationFields extends StatefulWidget {
  final Widget? leading;
  final Map<String, String> initial;
  final Map<String, String> locals;
  final dynamic Function(String, String) onChanged;
  const TranslationFields({
    super.key,
    required this.initial,
    required this.onChanged,
    this.leading,
    this.locals = const {'en': 'English', 'ar': 'Arabic'},
  });

  @override
  State<TranslationFields> createState() => _TranslationFieldsState();
}

class _TranslationFieldsState extends State<TranslationFields> {
  // late Map<String, String> current;
  @override
  void initState() {
    print('translations');
    print(widget.initial);
    // current = widget.initial;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          // widget.initial.entries
          widget.locals.entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextInput(
                    leading: widget.leading,
                    hint: e.value,
                    initialValue: widget.initial[e.key] ?? '',
                    onChanged: (p0) => widget.onChanged(e.key, p0),
                  ),
                  // child: Row(
                  //   children: [
                  //     Padding(
                  //       padding: const EdgeInsets.all(8.0),
                  //       child: Text(e.value),
                  //     ),
                  //     Expanded(
                  //       child: TextInput(
                  //         initialValue: widget.initial[e.key] ?? '',
                  //         onChanged: (p0) => widget.onChanged(e.key, p0),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ),
              )
              .toList(),
    );
  }
}
