import 'package:concrete/concrete.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';

// mixin GridSelection<TModel> {
//   List<int> selectedIndexs = [];
//   List<TModel> selectedItems(List<TModel> pageItems) {
//     List<TModel> values = [];
//     for (var i = 0; i < pageItems.length; i++) {
//       if (selectedIndexs.contains(i)) {
//         values.add(pageItems.elementAt(i));
//       }
//     }
//     return values;
//   }
// }

const _perPageList = [10, 20, 50, 100, 200, 500];

class SuperDataGrid<TModel> extends StatefulWidget {
  final List<TModel> items;
  final int page;
  final int? total;
  final int? perPage;
  final List<int>? pages;
  final List<Widget> tools;

  /// tools that require _selectedIds
  final List<Widget> keyedTools;
  final List<String> columns;
  final List<DataCell> Function(int) cellsBuilder;
  final Function(int?)? loadPerPage;
  final Function(int)? loadPage;
  final Function()? loadNext;
  final Function()? loadPrevious;
  final void Function(List<int> indexes, List<TModel> selectedItems)?
  onSelection;
  final List<int>? initialSelectedIndexes;
  final bool selectionEnabled;
  final int minWidth;
  const SuperDataGrid({
    super.key,
    required this.items,
    required this.columns,
    required this.cellsBuilder,
    this.initialSelectedIndexes,
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
    this.minWidth = 1024,
  });

  @override
  State<SuperDataGrid> createState() => _SuperDataGridState<TModel>();
}

class _SuperDataGridState<TModel> extends State<SuperDataGrid<TModel>> {
  List<int> _selectedIds = [];
  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initialSelectedIndexes ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: [
            if (_selectedIds.isNotEmpty) ...widget.keyedTools,
            ...widget.tools,
          ],
        ),
        if (w < widget.minWidth)
          SizedBox(
            width: w,
            child: DraggableScroll(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: buildDataTable(),
              ),
            ),
          )
        else
          Row(children: [Expanded(child: buildDataTable())]),
        const SizedBox(height: Sz.xl),
        if (widget.pages != null && widget.loadPage != null)
          Row(
            children: [
              if (widget.total != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 8,
                  ),
                  child: SizedBox(
                    child: Text('${"total".i18n()}: ${widget.total}'),
                  ),
                ),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // const Spacer(),
                    TextButton(
                      onPressed: widget.loadPrevious,
                      child: const Icon(Icons.chevron_left),
                    ),
                    ...widget.pages!.map(
                      (e) => TextButton(
                        onPressed: (widget.page == e)
                            ? null
                            : () => widget.loadPage?.call(e),
                        child: Text('$e'),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.loadNext,
                      child: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              if (widget.loadPerPage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 8,
                  ),
                  child: SizedBox(
                    width: 60,
                    child: DropdownButton<int>(
                      key: const Key('perPage'),
                      isExpanded: true,
                      value:
                          widget.perPage == null ||
                              !_perPageList.contains(widget.perPage)
                          ? _perPageList.first
                          : widget.perPage,
                      items: _perPageList
                          .map(
                            (e) => DropdownMenuItem<int>(
                              value: e,
                              child: Text('$e'),
                            ),
                          )
                          .toList(),
                      onChanged: widget.loadPerPage,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget buildDataTable() {
    return DataTable(
      showCheckboxColumn: widget.selectionEnabled,
      columns: widget.columns
          .map<DataColumn>(
            (e) => DataColumn(
              label: Flexible(child: Text(e.toUpperCase(), softWrap: true)),
              numeric: e.toLowerCase() == 'id',
            ),
          )
          .toList(),
      rows: List<DataRow>.generate(
        widget.items.length,
        (rowIndex) => DataRow(
          selected: _selectedIds.contains(rowIndex),
          onSelectChanged: !widget.selectionEnabled
              ? null
              : (b) => setState(() {
                  (b != null && b)
                      ? _selectedIds.add(rowIndex)
                      : _selectedIds.remove(rowIndex);
                  widget.onSelection?.call(
                    _selectedIds,
                    _selectedIds
                        .map<TModel>((e) => widget.items.elementAt(e))
                        .toList(),
                  );
                }),
          cells: widget.cellsBuilder(rowIndex),
        ),
      ).toList(),
    );
  }
}
