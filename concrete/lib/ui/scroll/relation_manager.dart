import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:skeleton/skeleton.dart';

/// A dual list box widget that allows users to select items from a list of available
/// options and move them to a list of selected options.
class RelationsSelector<T extends BaseModel> extends StatefulWidget {
  /// The title displayed above the two lists.
  final String? title;

  /// The complete list of items to be displayed in the selector.
  final List<T> allItems;

  /// The set of IDs for items that should be initially marked as selected.
  final Set<dynamic> initialSelectedIds;

  /// A callback function that is invoked whenever the selection changes.
  /// It provides the new set of selected item IDs.
  final void Function(Set<dynamic> selectedIds)? onSelection;
  final void Function(Set<dynamic> selectedIds)? onConfirm;

  const RelationsSelector({
    super.key,
    this.title,
    required this.allItems,
    this.initialSelectedIds = const {},
    this.onSelection,
    this.onConfirm,
  });

  @override
  State<RelationsSelector<T>> createState() => _RelationsSelectorState<T>();
}

class _RelationsSelectorState<T extends BaseModel>
    extends State<RelationsSelector<T>> {
  // Lists to hold the state of available and selected items
  late List<T> _availableItems;
  late List<T> _selectedItems;

  // Sets to track which items are highlighted by the user for moving
  final Set<dynamic> _highlightedAvailable = {};
  final Set<dynamic> _highlightedSelected = {};

  // Controllers for the search fields
  final TextEditingController _availableSearchController =
      TextEditingController();
  final TextEditingController _selectedSearchController =
      TextEditingController();

  String _availableSearchQuery = '';
  String _selectedSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _splitAndSortItems();

    // Add listeners to update the UI on search query changes
    _availableSearchController.addListener(() {
      setState(
        () => _availableSearchQuery = _availableSearchController.text
            .toLowerCase(),
      );
    });
    _selectedSearchController.addListener(() {
      setState(
        () =>
            _selectedSearchQuery = _selectedSearchController.text.toLowerCase(),
      );
    });
  }

  @override
  void didUpdateWidget(covariant RelationsSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the incoming data changes, re-initialize the lists
    if (widget.allItems != oldWidget.allItems ||
        widget.initialSelectedIds != oldWidget.initialSelectedIds) {
      _splitAndSortItems();
    }
  }

  void _splitAndSortItems() {
    final selectedIds = widget.initialSelectedIds;
    _availableItems = widget.allItems
        .where((item) => !selectedIds.contains(item.getId()))
        .toList();
    _selectedItems = widget.allItems
        .where((item) => selectedIds.contains(item.getId()))
        .toList();

    _availableItems.sort((a, b) => a.getLabel().compareTo(b.getLabel()));
    _selectedItems.sort((a, b) => a.getLabel().compareTo(b.getLabel()));
  }

  @override
  void dispose() {
    _availableSearchController.dispose();
    _selectedSearchController.dispose();
    super.dispose();
  }

  void _notifySelectionChanged() {
    widget.onSelection?.call(
      _selectedItems.map((item) => item.getId()).toSet(),
    );
  }

  void _moveItems(List<T> source, List<T> destination, Set<dynamic> idsToMove) {
    setState(() {
      final itemsToMove = source
          .where((item) => idsToMove.contains(item.getId()))
          .toList();
      destination.addAll(itemsToMove);
      source.removeWhere((item) => idsToMove.contains(item.getId()));

      source.sort((a, b) => a.getLabel().compareTo(b.getLabel()));
      destination.sort((a, b) => a.getLabel().compareTo(b.getLabel()));

      _highlightedAvailable.clear();
      _highlightedSelected.clear();
      _notifySelectionChanged();
    });
  }

  void _moveAllItems(List<T> source, List<T> destination) {
    setState(() {
      destination.addAll(source);
      source.clear();

      destination.sort((a, b) => a.getLabel().compareTo(b.getLabel()));

      _highlightedAvailable.clear();
      _highlightedSelected.clear();
      _notifySelectionChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredAvailable = _availableItems
        .where(
          (item) =>
              item.getLabel().toLowerCase().contains(_availableSearchQuery),
        )
        .toList();
    final filteredSelected = _selectedItems
        .where(
          (item) =>
              item.getLabel().toLowerCase().contains(_selectedSearchQuery),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title ?? '-',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onConfirm?.call(
                      _selectedItems.map((item) => item.getId()).toSet(),
                    );
                  },
                  child: Text('save'.i18n()),
                ),
              ],
            ),
          ),
        Expanded(
          // For RTL, the Row order is visually flipped.
          // Child 0 is on the far right, Child 1 is in the middle, Child 2 is on the far left.
          child: Row(
            children: [
              // Available Items Panel (Visually on the right in RTL)
              _buildListPanel(
                title: '${"items".i18n()} ${_availableItems.length}',
                items: filteredAvailable,
                highlightedIds: _highlightedAvailable,
                searchController: _availableSearchController,
                onItemTap: (id) => setState(() {
                  _highlightedAvailable.contains(id)
                      ? _highlightedAvailable.remove(id)
                      : _highlightedAvailable.add(id);
                }),
                onLongPress: (item) =>
                    _moveItems(_availableItems, _selectedItems, {item.getId()}),
              ),
              _buildCenterControls(),
              // Selected Items Panel (Visually on the left in RTL)
              _buildListPanel(
                title: '${"items".i18n()} ${_selectedItems.length}',
                items: filteredSelected,
                highlightedIds: _highlightedSelected,
                searchController: _selectedSearchController,
                onItemTap: (id) => setState(() {
                  _highlightedSelected.contains(id)
                      ? _highlightedSelected.remove(id)
                      : _highlightedSelected.add(id);
                }),
                onLongPress: (item) =>
                    _moveItems(_selectedItems, _availableItems, {item.getId()}),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCenterControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_double_arrow_right),
            onPressed: _availableItems.isNotEmpty
                ? () => _moveAllItems(_availableItems, _selectedItems)
                : null,
            tooltip: 'Move all to selected',
          ),
          const SizedBox(height: 8),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_right),
            onPressed: _highlightedAvailable.isNotEmpty
                ? () => _moveItems(
                    _availableItems,
                    _selectedItems,
                    _highlightedAvailable,
                  )
                : null,
            tooltip: 'Move highlighted to selected',
          ),
          const SizedBox(height: 16),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_left),
            onPressed: _highlightedSelected.isNotEmpty
                ? () => _moveItems(
                    _selectedItems,
                    _availableItems,
                    _highlightedSelected,
                  )
                : null,
            tooltip: 'Move highlighted to available',
          ),
          const SizedBox(height: 8),
          IconButton(
            icon: const Icon(Icons.keyboard_double_arrow_left),
            onPressed: _selectedItems.isNotEmpty
                ? () => _moveAllItems(_selectedItems, _availableItems)
                : null,
            tooltip: 'Move all to available',
          ),
        ],
      ),
    );
  }

  Widget _buildListPanel({
    required String title,
    required List<T> items,
    required Set<dynamic> highlightedIds,
    required TextEditingController searchController,
    required void Function(dynamic id) onItemTap,
    required void Function(T item) onLongPress,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'filter'.i18n(),
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isHighlighted = highlightedIds.contains(item.getId());
                  return ListTile(
                    title: Text(item.getLabel()),
                    onTap: () => onItemTap(item.getId()),
                    onLongPress: () => onLongPress(item),
                    selected: isHighlighted,
                    selectedTileColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.2),
                    dense: true,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
