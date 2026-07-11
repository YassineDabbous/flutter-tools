import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// ------------------------------ ChoiceButtonWidget --------------------------
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
class ChoiceButtonWidget extends StatefulWidget {
  final Function(int?) onChange;
  final int? initial;
  final bool readOnly;
  final Map<int, String> choices;
  const ChoiceButtonWidget({
    super.key,
    required this.choices,
    required this.onChange,
    this.initial,
    this.readOnly = false,
  });

  @override
  State<ChoiceButtonWidget> createState() => _ChoiceButtonWidgetState();
}

class _ChoiceButtonWidgetState extends State<ChoiceButtonWidget> {
  int? _selectedKey;

  @override
  void initState() {
    super.initState();
    if (widget.choices.keys.contains(widget.initial)) {
      _selectedKey = widget.initial;
    }
    // else {
    //   _selectedKey = widget.choices.keys.first;
    // }
  }

  final pressedState = WidgetStatesController()
    ..value = <WidgetState>{WidgetState.pressed};

  Widget buildSelectionButton(int key, String value, {bool selected = false}) {
    //bool isNotEdge = key != 0 && key != widget.choices.length - 1;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        backgroundColor: !selected
            ? null
            : context.theme.buttonTheme.colorScheme?.secondary,
      ),
      statesController: !selected ? null : pressedState,
      onPressed: () {
        if (widget.readOnly) {
          return;
        }
        if (selected) {
          setState(() {
            _selectedKey = null;
          });
          widget.onChange(null);
          return;
        }
        setState(() {
          _selectedKey = key;
        });
        widget.onChange(key);
      },
      child: Text(
        value,
        style: context.textTheme.titleMedium?.copyWith(
          color: !selected
              ? null
              : context.theme.buttonTheme.colorScheme?.onPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      // mainAxisAlignment: MainAxisAlignment.center,
      alignment: WrapAlignment.center,
      children: widget.choices.keys
          .map(
            (key) => buildSelectionButton(
              key,
              widget.choices[key]!,
              selected: _selectedKey == key,
            ),
          )
          .toList(),
    );
  }
}

// class Triplet extends StatelessWidget {
//   final String name;
//   final int? initial;
//   final bool readOnly;
//   final Function(int)? onChange;
//   final Map<int, String> choices;
//   const Triplet({
//     required this.name,
//     this.initial,
//     this.onChange,
//     this.choices = const {},
//     this.readOnly = false,
//   });
//   factory Triplet.binary({required String name, required bool initial}) {
//     return Triplet(
//       initial: initial ? 0 : 1,
//       name: name,
//       readOnly: true,
//       choices: {0: S.current.home, 1: S.current.home},
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//             child: Text(
//               name,
//               style: Theme.of(context).textTheme.subtitle1,
//             ),
//           ),
//           SizedBox(
//             width: 64 * choices.length * 1.0,
//             height: 36,
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(8.0),
//               child: ChoiceButtonWidget(initial: initial, readOnly: readOnly, choices: choices, onChange: (p0) => onChange?.call(p0)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
