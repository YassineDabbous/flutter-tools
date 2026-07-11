import 'package:flutter/material.dart';

class DataGrid<T> extends StatefulWidget {
  final int itemsCount;
  final int page;
  final List<Widget> tools;
  final List<String> columns;
  final List<DataCell> Function(int) cellsBuilder;
  final Function()? loadNext;
  final Function()? loadPrevious;
  final Function(List<int> indexes)? onSelection;
  final List<int>? initialSelectedIndexes;
  final bool selectionEnabled;
  const DataGrid({
    super.key,
    required this.itemsCount,
    required this.columns,
    required this.cellsBuilder,
    this.loadNext,
    this.loadPrevious,
    this.initialSelectedIndexes,
    this.onSelection,
    this.page = 0,
    this.selectionEnabled = false,
    this.tools = const [],
  });

  @override
  State<DataGrid> createState() => _DataGridState();
}

class _DataGridState extends State<DataGrid> {
  List<int> selection = [];
  @override
  void initState() {
    selection = widget.initialSelectedIndexes ?? [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              ...widget.tools,
              const Spacer(),
              if (selection.isNotEmpty) Text('  ${selection.length} selected'),
              IconButton(
                onPressed: widget.loadPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              if (widget.page != 0) Text(' ${widget.page} '),
              IconButton(
                onPressed: widget.loadNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width,
          child: DataTable(
            sortColumnIndex: 0,
            //sortAscending: true,
            showCheckboxColumn: widget.selectionEnabled,
            columns: widget.columns
                .map<DataColumn>(
                  (e) => DataColumn(
                    label: Text(e.toUpperCase()),
                    numeric: e.toLowerCase() == 'id',
                    // onSort: (columnIndex, sortAscending) => setState(() {
                    //   //store.lista = store.lista.reversed.toList();
                    // }),
                  ),
                )
                .toList(),
            rows: List<DataRow>.generate(
              widget.itemsCount,
              (rowIndex) => DataRow(
                selected: selection.contains(rowIndex),
                onSelectChanged: !widget.selectionEnabled
                    ? null
                    : (b) => setState(() {
                        (b != null && b)
                            ? selection.add(rowIndex)
                            : selection.remove(rowIndex);
                        widget.onSelection?.call(selection);
                      }),
                cells: widget.cellsBuilder(rowIndex),
              ),
            ).toList(),
          ),
        ),
      ],
    );
  }
}
