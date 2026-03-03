import 'package:core/core.dart';
import 'package:skeleton/skeleton.dart';
import 'package:flutter/material.dart';

const _perPageList = [10, 20, 50, 100, 200, 500];

class SuperSelectionDataGrid<TModel extends BaseModel> extends StatefulWidget {
  final List<TModel> items;
  final int page;
  final int? total;
  final int? perPage;
  final List<int>? pages;
  final List<Widget> tools;

  /// tools that require selection
  final List<Widget> keyedTools;
  final List<String> columns;
  final List<DataCell> Function(TModel item) cellsBuilder;
  final Function(int?)? loadPerPage;
  final Function(int)? loadPage;
  final Function()? loadNext;
  final Function()? loadPrevious;
  final void Function(Set<dynamic> selectedIds, List<TModel> selectedItems)? onSelection;
  final Set<dynamic> initialSelectedIds;
  final bool selectionEnabled;
  const SuperSelectionDataGrid({
    super.key,
    required this.items,
    required this.columns,
    required this.cellsBuilder,
    this.initialSelectedIds = const {},
    this.onSelection,
    this.selectionEnabled = false,
    this.loadNext,
    this.loadPrevious,
    this.loadPage,
    this.loadPerPage,
    this.total,
    this.page = 0,
    this.perPage,
    this.pages,
    this.tools = const [],
    this.keyedTools = const [],
  });

  @override
  State<SuperSelectionDataGrid<TModel>> createState() => _SuperSelectionDataGridState<TModel>();
}

class _SuperSelectionDataGridState<TModel extends BaseModel> extends State<SuperSelectionDataGrid<TModel>> {
  late Set<dynamic> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<dynamic>.from(widget.initialSelectedIds);
  }

  // This is called when the widget is rebuilt with new properties (e.g., new items or initial IDs)
  @override
  void didUpdateWidget(SuperSelectionDataGrid<TModel> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the initial selected IDs from the parent have changed, update the local state.
    if (widget.initialSelectedIds != oldWidget.initialSelectedIds) {
      setState(() {
        _selectedIds = Set<dynamic>.from(widget.initialSelectedIds);
      });
    }
  }

  void _handleSelectionChanged(bool? isSelected, TModel item) {
    setState(() {
      if (isSelected == true) {
        _selectedIds.add(item.getId());
      } else {
        _selectedIds.remove(item.getId());
      }

      // Notify the parent widget with the updated set of IDs and the corresponding items.
      widget.onSelection?.call(_selectedIds, widget.items.where((item) => _selectedIds.contains(item.getId())).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(children: [if (_selectedIds.isNotEmpty) ...widget.keyedTools, ...widget.tools]),

        SizedBox(
          width: MediaQuery.of(context).size.width,
          child: DataTable(
            showCheckboxColumn: widget.selectionEnabled,
            columns: widget.columns.map<DataColumn>((e) => DataColumn(label: Text(e.toUpperCase()), numeric: e.toLowerCase() == 'id')).toList(),
            rows: widget.items.map<DataRow>((item) {
              final isSelected = _selectedIds.contains(item.getId());

              return DataRow(
                selected: isSelected,
                onSelectChanged: !widget.selectionEnabled ? null : (selected) => _handleSelectionChanged(selected, item),
                cells: widget.cellsBuilder(item),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: Sz.xl),
        if (widget.pages != null && widget.loadPage != null)
          Row(
            children: [
              if (widget.total != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  child: SizedBox(width: 60, child: Text('${"total".i18n()}: ${widget.total}')),
                ),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // const Spacer(),
                    TextButton(onPressed: widget.loadPrevious, child: const Icon(Icons.chevron_left)),
                    ...widget.pages!.map((e) => TextButton(onPressed: (widget.page == e) ? null : () => widget.loadPage?.call(e), child: Text('$e'))),
                    TextButton(onPressed: widget.loadNext, child: const Icon(Icons.chevron_right)),
                  ],
                ),
              ),
              if (widget.loadPerPage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  child: SizedBox(
                    width: 60,
                    child: DropdownButton<int>(
                      key: const Key('perPage'),
                      isExpanded: true,
                      value: widget.perPage == null || !_perPageList.contains(widget.perPage) ? _perPageList.first : widget.perPage,
                      items: _perPageList.map((e) => DropdownMenuItem<int>(value: e, child: Text('$e'))).toList(),
                      onChanged: widget.loadPerPage,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
