import 'package:core/core.dart';
import 'package:skeleton/skeleton.dart';

/// Base class for UI controllers that manage state for a specific resource type.
/// 
/// Type Parameters:
/// - [TFilterRequest]: The request model used for filtering and searching.
/// - [TModel]: The data model for the resource.
/// - [ID]: The identifier type (defaults to `dynamic` to support both int and String).
abstract class BaseController<TFilterRequest extends SuperModel<TFilterRequest>, TModel, ID> {
  /// whether dealing with Admin API
  bool forAdmin;

  /// Model type ("user" for "User")
  String type;

  /// List of model fields, used with HTTP requests to get only needed model fields.
  List<String> fields;

  /// Search filter
  late TFilterRequest filter;

  /// Fixed Filter fields
  late TFilterRequest fixed; 

  /// Make a fresh filter request
  Function()? refresh;

  /// Run a user action on list of items
  Function(List<TModel> items, UserAction action)? bulkAction;

  /// Validates filter form
  bool Function()? validateFilter;

  Function()? fillFilter;

  Function()? clearForm;

  /// Constructor
  BaseController({
    required this.type,
    TFilterRequest? filter,
    TFilterRequest? fixed,
    this.onIdsSelection,
    this.initialySelectedIds,
    this.forAdmin = false,
    this.enableSelection = true,
    this.fields = const [],
  }) {
    this.filter = filter ?? newInstance;
    this.fixed = fixed ?? newInstance;
  }

  /// Clears filter form
  void clear() {
    if (fixed.toJson().isNotEmpty) {
      fillFromJson(fixed.toJson());
    } else {
      filter = newInstance;
    }
    clearForm?.call();
  }

  /// Creates filter instance
  TFilterRequest get newInstance;

  /// Merges new filters with fixed one.
  TFilterRequest get request => filter.merge(fixed);

  /// Fill filter from query parameters
  void fillFromQuery(Map<String, String> params) {
    filter = filter.merge(newInstance.fromJson(params));
  }

  /// Fill filter from json map
  void fillFromJson(Map<String, dynamic> json) {
    filter = newInstance.fromJson(json);
  }

  //
  // Selection helpers
  //

  bool enableSelection;
  final Function(List<ID> ids)? onIdsSelection;
  bool get isSelectionEnabled => enableSelection || onIdsSelection != null;

  /// Selected indexes in a table/grid
  List<int> selectedIndexes = [];

  /// Initialy selected IDs
  List<ID>? initialySelectedIds;

  /// IDs of selected items
  List<ID> selectedIds = [];

  /// Selection Listener
  void onSelection(List<int> indexes, List<ID> ids) {
    logUI.debug('selected ids are $ids');
    selectedIndexes = indexes;
    selectedIds = ids;
    onIdsSelection?.call(ids);
  }
}
