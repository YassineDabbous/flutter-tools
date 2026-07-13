import 'package:flutter/material.dart';

/// https://pub.dev/packages/multiselect
class DropDownMultiMapSelect<K, V> extends StatefulWidget {
  final Map<K, V> options;

  final List<K> selectedValues;
  final void Function(List<K>) onChanged;

  /// defines whether the field is dense
  final bool isDense;

  /// defines whether the widget is enabled;
  final bool enabled;

  /// Input decoration
  final InputDecoration? decoration;

  /// this text is shown when there is no selection
  final String? whenEmpty;

  /// a function to build custom childern
  // final Widget Function(List<String> selectedValues)? childBuilder;

  /// a function to build custom menu items
  final Widget Function(V option)? menuItembuilder;

  /// a function to validate
  // final String Function(String? selectedOptions)? validator;

  /// defines whether the widget is read-only
  final bool readOnly;

  /// icon shown on the right side of the field
  final Widget? icon;

  /// Textstyle for the hint
  final TextStyle? hintStyle;

  /// hint to be shown when there's nothing else to be shown
  final Widget? hint;

  /// https://pub.dev/packages/multiselect
  const DropDownMultiMapSelect({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.icon,
    this.hint,
    this.whenEmpty,
    this.hintStyle,
    // this.childBuilder,
    this.menuItembuilder,
    this.decoration,
    // this.validator,
    this.isDense = true,
    this.enabled = true,
    this.readOnly = false,
  });

  @override
  State<DropDownMultiMapSelect<K, V>> createState() =>
      _DropDownMultiMapSelectState<K, V>();
}

class _DropDownMultiMapSelectState<K, V>
    extends State<DropDownMultiMapSelect<K, V>> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // _theState.rebuild(() => widget.childBuilder != null
        //     ? widget.childBuilder!(widget.selectedValues) :
        Padding(
          padding: widget.decoration != null
              ? widget.decoration!.contentPadding != null
                    ? widget.decoration!.contentPadding!
                    : const EdgeInsets.symmetric(horizontal: 10)
              : const EdgeInsets.symmetric(horizontal: 10),
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              widget.selectedValues.isNotEmpty
                  ? widget.options.entries
                        .where((e) => widget.selectedValues.contains(e.key))
                        .map((e) => e.value)
                        .join(', ')
                  : widget.whenEmpty ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ), //)
        DropdownButtonFormField<K>(
          hint: widget.hint,
          style: widget.hintStyle,
          icon: widget.icon,
          // validator: widget.validator ?? widget.validator,
          decoration:
              widget.decoration ??
              const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 10,
                ),
              ),
          isDense: widget.isDense,
          onChanged: widget.enabled ? (x) {} : null,
          isExpanded: false,
          initialValue: widget.selectedValues.isNotEmpty
              ? widget.selectedValues[0]
              : null,
          selectedItemBuilder: (context) => widget.options.entries
              .map((e) => const DropdownMenuItem(child: SizedBox()))
              .toList(),
          items: widget.options.entries
              .map(
                (x) => DropdownMenuItem<K>(
                  value: x.key,
                  onTap: !widget.readOnly ? () => onChecked(x.key) : null,
                  child: widget.menuItembuilder != null
                      ? widget.menuItembuilder!(x.value)
                      : _SelectRow(
                          selected: widget.selectedValues.contains(x.key),
                          text: x.value,
                          onChange: (isSelected) => onChecked(x.key),
                        ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  void onChecked(K x) {
    if (widget.selectedValues.contains(x)) {
      var ns = widget.selectedValues;
      ns.remove(x);
      widget.onChanged(ns);
    } else {
      var ns = widget.selectedValues;
      ns.add(x);
      widget.onChanged(ns);
    }
  }
}

class _SelectRow extends StatefulWidget {
  final Function(bool) onChange;
  final bool selected;
  final dynamic text;

  const _SelectRow({
    required this.onChange,
    required this.selected,
    required this.text,
  });

  @override
  State<_SelectRow> createState() => _SelectRowState();
}

class _SelectRowState extends State<_SelectRow> {
  late bool isSelected;
  @override
  void initState() {
    isSelected = widget.selected;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        isSelected = !isSelected;
        widget.onChange(isSelected);
        setState(() {});
      },
      child: SizedBox(
        height: kMinInteractiveDimension,
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (x) {
                isSelected = x ?? false;
                widget.onChange(isSelected);
                setState(() {});
              },
            ),
            Text(widget.text.toString()),
          ],
        ),
      ),
    );
  }
}
