import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';

class DropDownSearch<K> extends StatefulWidget {
  final Map<K, String> options;
  final bool isMultiSelect;
  final bool searchable;
  // final bool isRequired;
  final String? hint;
  final List<K> selectedValues;
  final void Function(List<K>) onChanged;
  final Widget Function(String, Function())? builder;
  final String? Function(List<K>)? validator;
  const DropDownSearch({
    super.key,
    this.isMultiSelect = true,
    this.searchable = true,
    // this.isRequired = false,
    this.hint,
    this.validator,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.builder,
  });

  @override
  State<DropDownSearch<K>> createState() => _DropDownSearchState<K>();
}

class _DropDownSearchState<K> extends State<DropDownSearch<K>> {
  FocusNode fcn = FocusNode();
  String search = '';

  @override
  void initState() {
    fcn.requestFocus();
    super.initState();
  }

  @override
  void dispose() {
    search = '';
    fcn.dispose();
    super.dispose();
  }

  Map<K, String> get suggestions => Map.fromEntries(widget.options.entries)
    ..removeWhere(
      (key, value) => !value.toLowerCase().contains(search.toLowerCase()),
    );

  @override
  Widget build(BuildContext context) {
    final x = widget.selectedValues.isNotEmpty
        ? widget.options.entries
              .where((e) => widget.selectedValues.contains(e.key))
              .map((e) => e.value)
              .join(', ')
        : '';

    return widget.builder != null
        ? widget.builder!(x, showSearcher)
        : TextInput(
            validator: widget.validator == null
                ? null
                : (p0) => widget.validator!(widget.selectedValues),
            // key: Key('search$x'),
            hint: widget.hint,
            // textStyle: TextStyle(fontSize: 12),
            // padding: Edges.sm,
            leading: const Icon(Icons.arrow_drop_down),
            initialValue: x,
            onChanged: (p0) => showSearcher(),
            onTap: showSearcher,
          );
  }

  void showSearcher() {
    final mxh = ((widget.searchable ? 80 : 16) + widget.options.length * 50)
        .toDouble();
    dialogView(
      maxHeight: mxh > 400 ? 400 : mxh,
      maxWidth: 300,
      context: context,
      view: StatefulBuilder(
        builder: (context, setStateX) {
          return Material(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  if (widget.searchable)
                    TextInput(
                      hint: 'search'.i18n(),
                      focusNode: fcn,
                      onChanged: (p0) => setStateX(() => search = p0),
                      onSubmitted: (p0) {
                        search = '';
                        Navigator.of(context).pop();
                      },
                    ),
                  Expanded(
                    child: ListView(
                      children: suggestions
                          .map(
                            (key, value) => MapEntry(
                              key,
                              _SelectRow(
                                isMultiSelect: widget.isMultiSelect,
                                selected: widget.selectedValues.contains(key),
                                text: value,
                                onChange: (isSelected) => onChecked(key),
                              ),
                            ),
                          )
                          .values
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void onChecked(K x) {
    if (!widget.isMultiSelect) {
      widget.onChanged([x]);
      search = '';
      Navigator.of(context).pop();
      fcn.requestFocus();
      return;
    }
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
  final bool isMultiSelect;
  final dynamic text;

  const _SelectRow({
    required this.onChange,
    required this.selected,
    required this.isMultiSelect,
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
            if (widget.isMultiSelect)
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
